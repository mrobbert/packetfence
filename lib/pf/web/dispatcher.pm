package pf::web::dispatcher;
=head1 NAME

dispatcher.pm

=cut

use strict;
use warnings;

use Apache2::Const -compile => qw(OK DECLINED HTTP_MOVED_TEMPORARILY);
use Apache2::Request;
use Apache2::RequestIO ();
use Apache2::RequestRec ();
use Apache2::Response ();
use Apache2::RequestUtil ();
use Apache2::ServerRec;
use Apache2::URI ();
use Apache2::Util ();

use APR::Table;
use APR::URI;
use Log::Log4perl;
use Template;
use URI::Escape qw(uri_escape);

use pf::config;
use pf::util;
use pf::web::constants;
use pf::web::util;
use pf::proxypassthrough::constants;
use pf::Portal::Session;
use pf::iplog qw(iplog_update);
use pf::locationlog qw(locationlog_view_open_mac);

=head1 SUBROUTINES

=over

=item translate

Implementation of PerlTransHandler. Rewrite all URLs except those explicitly
allowed by the Captive portal.

For simplicity and performance this doesn't consume and leverage
L<pf::Portal::Session>.

Reference: http://perl.apache.org/docs/2.0/user/handlers/http.html#PerlTransHandler

=cut

sub handler {
    my $r = Apache::SSLLookup->new(shift);
    my $logger = Log::Log4perl->get_logger(__PACKAGE__);
    $logger->trace("hitting translator with URL: " . $r->uri);
    # Test if the hostname is include in the proxy_passthroughs configuration
    # In this case forward to mad_proxy
    if ( ( $r->hostname =~ /$PROXYPASSTHROUGH::ALLOWED_PASSTHROUGH_DOMAINS/o && $PROXYPASSTHROUGH::ALLOWED_PASSTHROUGH_DOMAINS ne '') || ($r->hostname =~ /$PROXYPASSTHROUGH::ALLOWED_PASSTHROUGH_REMEDIATION_DOMAINS/o && $PROXYPASSTHROUGH::ALLOWED_PASSTHROUGH_REMEDIATION_DOMAINS ne '') ) {
        my $parsed_request = APR::URI->parse($r->pool, $r->uri);
        $parsed_request->hostname($r->hostname);
        $parsed_request->scheme('http');
        $parsed_request->scheme('https') if $r->is_https;
        $parsed_request->path($r->uri);
        return proxy_redirect($r, $parsed_request->unparse);
    }

    # be careful w/ performance here
    # Warning: we might want to revisit the /o (compile Once) if we ever want
    #          to reload Apache dynamically. pf::web::constants will need some
    #          rework also
    if ($r->uri =~ /$WEB::ALLOWED_RESOURCES/o) {
        my $s = $r->server();
        my $proto = isenabled($Config{'captive_portal'}{'secure_redirect'}) ? $HTTPS : $HTTP;
        #Because of chrome captiv portal detection we have to test if the request come from http request
        if (defined($r->headers_in->{'Referer'})) {
            my $parsed = APR::URI->parse($r->pool,$r->headers_in->{'Referer'});
            if ($s->port eq '80' && $proto eq 'https' && $r->uri !~ /$WEB::ALLOWED_RESOURCES/o && $parsed->path !~ /$WEB::ALLOWED_RESOURCES/o) {
                #Generate a page with a refresh tag
                $r->handler('modperl');
                $r->set_handlers( PerlResponseHandler => \&html_redirect );
                return Apache2::Const::OK;
            } else {
                # DECLINED tells Apache to continue further mod_rewrite / alias processing
                return Apache2::Const::DECLINED;
            }
        }
        else {
            # DECLINED tells Apache to continue further mod_rewrite / alias processing
            return Apache2::Const::DECLINED;
        }
    }
    if ($r->uri =~ /$WEB::ALLOWED_RESOURCES_MOD_PERL/o) {
        $r->handler('modperl');
        $r->pnotes->{session_id} = $1;
        $r->set_handlers( PerlResponseHandler => ['pf::web::wispr'] );
        return Apache2::Const::OK;
    }

    # fallback to a redirection: inject local redirection handler
    $r->handler('modperl');
    $r->set_handlers( PerlResponseHandler => \&redirect );
    # OK tells Apache to stop further mod_rewrite / alias processing
    return Apache2::Const::OK;
}

=item external_captive_portal

Instantiate the switch module and use a specific captive portal

=cut

sub external_captive_portal {
    my ($switchId, $req, $r, $session) = @_;
    my $logger = Log::Log4perl->get_logger(__PACKAGE__);
    my $switch;
    if (defined($switchId)) {
        if (pf::SwitchFactory::hasId($switchId)) {
            $switch =  pf::SwitchFactory->getInstance()->instantiate($switchId);
        } else {
            my $locationlog_entry = locationlog_view_open_mac($switchId);
            $switch = pf::SwitchFactory->getInstance()->instantiate($locationlog_entry->{'switch'});
        }

        if (defined($switch) && $switch ne '0' && $switch->supportsExternalPortal) {
            my ($client_mac,$client_ssid,$client_ip,$redirect_url,$grant_url,$status_code) = $switch->parseUrl(\$req);
            my %info = (
                'client_mac' => $client_mac,
            );
            my $portalSession = pf::Portal::Session->new(%info);
            $portalSession->setClientIp($client_ip) if (defined($client_ip));
            #$portalSession->setClientMac($client_mac) if (defined($client_mac));
            $portalSession->setDestinationUrl($redirect_url) if (defined($redirect_url));
            $portalSession->setGrantUrl($grant_url) if (defined($grant_url));
            #$portalSession->cgi->param("do_not_deauth", $TRUE) if (defined($grant_url));
            iplog_update($client_mac,$client_ip,100) if (defined ($client_ip) && defined ($client_mac));
            # Have to update location_log ...
            return $portalSession->session->id();
        } else {
            return 0;
        }
    }
    elsif (defined($session)) {
        my (%session_id);
        pf::web::util::session(\%session_id,$session);
        if ($session_id{_session_id} eq $session) {
            my $switch = $session_id{switch};
            #if ($$switch->supportsExternalPortal) {
                my $portalSession = pf::Portal::Session->new(%session_id);
                $portalSession->setClientMac($session_id{client_mac}) if (defined($session_id{client_mac}));
                $portalSession->setDestinationUrl($r->headers_in->{'Referer'}) if (defined($r->headers_in->{'Referer'}));
                return $portalSession->session->id();
            #}
        } else {
            return 0;
        }
    }
    else {
        return 0;
    }
}

=item redirect

For simplicity and performance this doesn't consume and leverage
L<pf::Portal::Session>.

=cut

sub redirect {
   my ($r) = @_;
   my $logger = Log::Log4perl->get_logger(__PACKAGE__);
   $logger->trace('hitting redirector');
   my $captivePortalDomain = $Config{'general'}{'hostname'}.".".$Config{'general'}{'domain'};
   my $destination_url = '';
   my $url = $r->construct_url;
   if ($url !~ m#://\Q$captivePortalDomain\E/#) {
       $destination_url = Apache2::Util::escape_path($url,$r->pool);
   }
   my $orginal_url = Apache2::Util::escape_path($url,$r->pool);

   # External Captive Portal Detection

   my $req = Apache2::Request->new($r);
   my $is_external_portal;
   foreach my $param ($req->param) {
       if ($param =~ /$WEB::EXTERNAL_PORTAL_PARAM/o) {
           my $value;
           $value = clean_mac($req->param($param)) if valid_mac($req->param($param));
           $value = $req->param($param) if  valid_ip($req->param($param));
           if (defined($value)) {
               my $cgi_session_id = external_captive_portal($value,$req,$r,undef);
               if ($cgi_session_id ne '0') {
                   # Set the cookie for the captive portal
                   $r->err_headers_out->add('Set-Cookie' => "CGISESSID=".  $cgi_session_id . "; path=/");
                   $logger->warn("Dumping session id: $cgi_session_id");
                   $is_external_portal = 1;
                   last;
               }
           }
       }
   }

   # Try to fetch the parameters in the session
   if ($r->uri =~ /$WEB::EXTERNAL_PORTAL_PARAM/o) {
       my $cgi_session_id = external_captive_portal(undef,undef,$r,$1);
           if ($cgi_session_id ne '0') {
               # Set the cookie for the captive portal
               $r->err_headers_out->add('Set-Cookie' => "CGISESSID=".  $cgi_session_id . "; path=/");
               $destination_url=$r->headers_in->{'Referer'} if (defined($r->headers_in->{'Referer'}));
           }
           $is_external_portal = 1;
   }

   my $proto;
   # Google chrome hack redirect in http
   if ($r->uri =~ /\/generate_204/) {
       $proto = $HTTP;
   } else {
       $proto = isenabled($Config{'captive_portal'}{'secure_redirect'}) ? $HTTPS : $HTTP;
   }

   my $captiv_url;
   my $wispr_url;
   if ( $is_external_portal ) {
      $captiv_url = APR::URI->parse($r->pool,"$proto://".$r->hostname."/captive-portal");
      $captiv_url->query($r->args);
      $wispr_url = APR::URI->parse($r->pool,"$proto://".$r->hostname."/wispr");
      $wispr_url->query($r->args);
   }
   else {
      $captiv_url = APR::URI->parse($r->pool,"$proto://".${captivePortalDomain}."/captive-portal");
      $captiv_url->query($r->args);
      $wispr_url = APR::URI->parse($r->pool,"$proto://".${captivePortalDomain}."/wispr");
      $wispr_url->query($r->args);
   }
    my $stash = {
        'login_url' => $captiv_url->unparse()."?destination_url=$destination_url",
        'login_url_wispr' => $wispr_url->unparse(),
    };

    # prepare custom REDIRECT response
    my $response = '';
    my $template = Template->new({
        INCLUDE_PATH => [$CAPTIVE_PORTAL{'TEMPLATE_DIR'}],
    });
    if(defined ($r->headers_in->{'User-Agent'}) && $r->headers_in->{'User-Agent'} !~ /WISPR\!Microsoft Hotspot Authentication/g) {
        $template->process( "redirection.tt", $stash, \$response ) || $logger->error($template->error());;
    }

    # send out the redirection in a custom response
    # a custom response is required otherwise Apache take over the rendering
    # of redirects and we are unable to inject the WISPR XML
    $r->headers_out->set('Location' => $stash->{'login_url'});
    $r->content_type('text/html');
    $r->no_cache(1);
    $r->custom_response(Apache2::Const::HTTP_MOVED_TEMPORARILY, $response);
    return Apache2::Const::HTTP_MOVED_TEMPORARILY;
}

=item html_redirect

html redirection to captive portal

=cut

sub html_redirect {
    my ($r) = @_;
    my $logger = Log::Log4perl->get_logger(__PACKAGE__);
    $logger->trace('hitting html redirector');

    my $proto = isenabled($Config{'captive_portal'}{'secure_redirect'}) ? $HTTPS : $HTTP;

     my $captiv_url = APR::URI->parse($r->pool,"$proto://".$r->hostname."/captive-portal");
    $captiv_url->query($r->args);

    my $stash = {
        'login_url' => $captiv_url->unparse(),
    };




    # prepare custom REDIRECT response
    my $response = '';
    my $template = Template->new({
        INCLUDE_PATH => [$CAPTIVE_PORTAL{'TEMPLATE_DIR'}],
    });
    $template->process( "redirection.html", $stash, \$response ) || $logger->error($template->error());;
    $r->content_type('text/html');
    $r->no_cache(1);
    $r->print($response);
    return Apache2::Const::OK;
}

=item proxy_redirect

Mod_proxy redirect

=cut

sub proxy_redirect {
        my ($r, $url) = @_;
        my $logger = Log::Log4perl->get_logger(__PACKAGE__);
        $r->set_handlers(PerlResponseHandler => []);
        $r->filename("proxy:".$url);
        $r->proxyreq(2);
        $r->handler('proxy-server');
        return Apache2::Const::OK;
}

=back

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2013 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

1;

