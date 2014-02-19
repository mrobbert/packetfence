package pfappserver::Form::Portal::Profile::Default;

=head1 NAME

pfappserver::Form::Portal::Profile

=head1 DESCRIPTION

Portal profile.

=cut

use pf::authentication;

use HTML::FormHandler::Moose;
extends 'pfappserver::Base::Form';
with 'pfappserver::Form::Portal::Common';

=head1 Blocks

=head2 definition

The main definition block

=cut

has_block 'definition' =>
  (
   render_list => [ qw(id description logo locale redirecturl always_use_redirecturl billing_engine) ],
  );


=head1 Fields

=head2 logo

The logo field

=cut

has_field 'logo' =>
  (
   type => 'Text',
   label => 'Logo',
   required => 1,
  );


=head1 METHODS

=head2 update_fields

The redirection URL is mandatory for the default profile.

=cut

sub update_fields {
    my $self = shift;

    $self->field('redirecturl')->required(1);

    # Call the theme implementation of the method
    $self->SUPER::update_fields();
}


=head1 COPYRIGHT

Copyright (C) 2012-2013 Inverse inc.

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
