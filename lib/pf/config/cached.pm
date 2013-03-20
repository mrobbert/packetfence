package pf::config::cached;
=head1 NAME

pf::config::cached

=cut

=head1 DESCRIPTION

A module to provide a layer for reading a cached config

=cut

use strict;
use warnings;
use constant INSTALL_DIR => '/usr/local/pf';
use lib INSTALL_DIR . "/lib";
use CHI;
use Config::IniFiles;
use Scalar::Util qw(refaddr);

our $CACHE;
our %LOADED_CONFIGS;
our @ON_RELOAD;

=head2 Methods

=over
=item new

Creates a new pf::config::cached proxy for Config::IniFiles

=cut

sub new {
    my ($proto,%params) = @_;
    my $class = ref($proto) || $proto;
    my $self = {
        on_reload => []
    };
    my $file = $params{'-file'};
    if($file) {
        if(exists $LOADED_CONFIGS{$file}) {
            return $LOADED_CONFIGS{$file};
        }
        $self->{config} = $class->computeFromPath(
            $file,
            sub {
                return Config::IniFiles->new(%params);
            }
        );
        $LOADED_CONFIGS{$file} = $self;
    } else {
        die "param -file missing or empty";
    }
    bless $self,$class;
    return $self;
}


=item ReadConfig

Will reload the config when changed on the filesystem and call any register callbacks

=cut

sub ReadConfig {
    my ($self) = @_;
    my $config = $self->{config};
    my $cache  = $self->cache;
    my $file   = $config->{cf};
    my $reloaded = 0;
    my $reloaded_from_cache = 0;
    my $result;
    $self->{config} = $self->computeFromPath(
        $file,
        sub {
            #reread files
            $result = $config->ReadConfig();
            $reloaded = 1;
            return $config;
        }
    );
    if (refaddr($config) != refaddr($self->{config})) {
        $reloaded = 1;
        $reloaded_from_cache = 1;
    }
    if($reloaded) {
        local $_;
        $_->() foreach (@{$self->{on_reload}});
    }
    $self->{reloaded} = $reloaded;
    $self->{reloaded_from_cache} = $reloaded_from_cache;
    return $result;
}


=item TIEHASH

Creating a tied pf::config::cached object

=cut

sub TIEHASH {
    my ($proto,@args) = @_;
    return $proto->new(@args);
}

=item AUTOLOAD

Will proxy all unknown functions to Config::IniFiles

=cut

sub AUTOLOAD {
    my ($self) = @_;
    my $command = our $AUTOLOAD;
    $command =~ s/.*://;
    if(Config::IniFiles->can($command) ) {
        no strict qw{refs};
        *$AUTOLOAD = sub  {
            my ($self,@args) = @_;
            return  wantarray ? ($self->{config}->$command(@args)) : scalar $self->{config}->$command(@args);
        };
        goto &$AUTOLOAD;
    }
    die;
}

=item computeFromPath

Will load the Config::IniFiles object from cache or filesystem and update the cache

=cut

sub computeFromPath {
    my ($self,$file,$computeSub) = @_;
    return $self->cache->compute(
        $file,
        {
            expire_if => \&_expire_if
        },
        $computeSub
    );
}

=item cache - get the global CHI object

=cut

sub cache {
    my ($self) = @_;
    unless (defined($CACHE)) {
        $CACHE = $self->_cache();
    }
    return $CACHE;
}

=item _cache

builds the CHI object

=cut

sub _cache {
    return CHI->new(
        driver => 'Memcached',   # or 'Memcached::Fast', or 'Memcached::libmemcached'
        namespace => __PACKAGE__,
        servers => ['localhost:11211'],
        l1_cache => {
            driver => 'RawMemory', global => 1
        }
    );
}

=item _expire_if

check to see if the config file needs to be reread

=cut

sub _expire_if {
    my ($cache_object) = @_;
    return $cache_object->created_at < get_mod_timestamp($cache_object->key);
}

=item get_mod_timestamp

simple util function for getting the modification timestamp

=cut

sub get_mod_timestamp {
    return (stat($_[0]))[9];
}


=item ReloadConfigs

ReloadConfigs reload all configs and call any register callbacks

=cut

sub ReloadConfigs {
    my $any_reloaded = 0;
    foreach my $config (values %LOADED_CONFIGS) {
        $config->ReadConfig();
        $any_reloaded += $config->{reloaded};
    }
    if($any_reloaded) {
        local $_;
        $_->() for (@ON_RELOAD);
    }
}


=item AddReloadCallback

Add callbacks config have been reloaded

=cut

sub AddReloadCallback {
    my ($self,@callbacks) = @_;
    local $_;
    push @{$self->{on_reload}}, grep { ref($_) eq 'CODE' } @callbacks;
}

=item AddGlobalReloadCallback

Add global callbacks when configs have been reloaded

=cut

sub AddGlobalReloadCallback {
    local $_;
    push @ON_RELOAD, grep { ref($_) eq 'CODE' } @_;
}


=item DESTROY

to avoid AUTOLOAD being called on object destruction

=cut

sub DESTROY {}

=back

=head1 COPYRIGHT

Copyright (C) 2013 Inverse inc.

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