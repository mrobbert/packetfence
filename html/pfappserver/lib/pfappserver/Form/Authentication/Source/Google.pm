package pfappserver::Form::Authentication::Source::Google;

=head1 NAME

pfappserver::Form::Authentication::Source::Google - Web form for a Google user source

=head1 DESCRIPTION

Form definition to create or update a Google user source.

=cut

use HTML::FormHandler::Moose;
extends 'pfappserver::Form::Authentication::Source';
with 'pfappserver::Form::Widget::Theme::Pf';

use pf::Authentication::Source::GoogleSource;

# Form fields
has_field 'client_id' =>
  (
   type => 'Text',
   label => 'API ID',
   required => 1,
   default => pf::Authentication::Source::GoogleSource->meta->get_attribute('client_id')->default,
   element_attr => {'placeholder' => pf::Authentication::Source::GoogleSource->meta->get_attribute('client_id')->default},
   element_class => ['input-xlarge'],
  );
has_field 'client_secret' =>
  (
   type => 'Text',
   label => 'API Secret',
   required => 1,
  );
has_field 'site' =>
  (
   type => 'Text',
   label => 'API URL',
   required => 1,
   default => pf::Authentication::Source::GoogleSource->meta->get_attribute('site')->default,
   element_class => ['input-xlarge'],
  );
has_field 'authorize_path' =>
  (
   type => 'Text',
   label => 'API Authorize Path',
   required => 1,
   default => pf::Authentication::Source::GoogleSource->meta->get_attribute('authorize_path')->default,
  );
has_field 'access_token_path' =>
  (
   type => 'Text',
   label => 'API Token Path',
   required => 1,
   default => pf::Authentication::Source::GoogleSource->meta->get_attribute('access_token_path')->default,
  );
has_field 'access_token_param' =>
  (
   type => 'Text',
   label => 'Access Token Parameter',
   required => 1,
   default => pf::Authentication::Source::GoogleSource->meta->get_attribute('access_token_param')->default,
  );
has_field 'scope' =>
  (
   type => 'Text',
   label => 'Scope',
   required => 1,
   default => pf::Authentication::Source::GoogleSource->meta->get_attribute('scope')->default,
   element_class => ['input-xlarge'],
   tags => { after_element => \&help,
             help => 'The permissions the application requests.' },
  );
has_field 'protected_resource_url' =>
  (
   type => 'Text',
   label => 'API URL of logged user',
   required => 1,
   default => pf::Authentication::Source::GoogleSource->meta->get_attribute('protected_resource_url')->default,
   element_class => ['input-xlarge'],
  );
has_field 'redirect_url' =>
  (
   type => 'Text',
   label => 'Portal URL',
   required => 1,
   default => pf::Authentication::Source::GoogleSource->meta->get_attribute('redirect_url')->default,,
   element_attr => {'placeholder' => pf::Authentication::Source::GoogleSource->meta->get_attribute('redirect_url')->default,},
   element_class => ['input-xlarge'],
   tags => { after_element => \&help,
             help => 'The hostname must be the one of your captive portal.' },
  );

=head1 COPYRIGHT

Copyright (C) 2012 Inverse inc.

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

__PACKAGE__->meta->make_immutable;
1;