package pfappserver::Form::Node;

=head1 NAME

pfappserver::Form::Node - Web form for a node

=head1 DESCRIPTION

Form definition to create or update a node.

=cut

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
with 'pfappserver::Form::Widget::Theme::Pf';

has '+field_name_space' => ( default => 'pfappserver::Form::Field' );
has '+widget_name_space' => ( default => 'pfappserver::Form::Widget' );
has '+language_handle' => ( builder => 'get_language_handle_from_ctx' );

# Form select options
has 'categories' => ( is => 'ro' );
has 'status' => ( is => 'ro' );

# Form fields
has_field 'pid' =>
  (
   type => 'Uneditable',
   label => 'Identifier',
  );
has_field 'status' =>
  (
   type => 'Select',
   label => 'Status',
   element_class => ['chzn-select'],
  );
has_field 'category_id' =>
  (
   type => 'Select',
   label => 'Category',
   element_class => ['chzn-deselect'],
   element_attr => {'data-placeholder' => 'No category'},
  );
has_field 'regdate' =>
  (
   type => '+DateTimePicker',
   label => 'Registration',
  );
has_field 'unregdate' =>
  (
   type => '+DateTimePicker',
   label => 'Unregistration',
  );
has_field 'vendor' =>
  (
   type => 'Uneditable',
   label => 'MAC Vendor',
  );
has_field 'computername' =>
  (
   type => 'Uneditable',
   label => 'Name',
  );
has_field 'voip' =>
  (
   type => 'Checkbox',
   label => 'Is Voice Over IP',
   checkbox_value => 'yes',
  );
has_field 'last_dot1x_username' =>
  (
   type => 'Uneditable',
   label => '802.1X Username',
  );
has_field 'user_agent' =>
  (
   type => 'Uneditable',
   label => 'User Agent',
  );
has_field 'useragent' =>
  (
   type => 'Compound', # virtual field to access the 'useragent' hash
  );
has_field 'useragent.mobile' =>
  (
   type => 'Toggle',
   label => 'Is a mobile',
   element_attr => {disabled => 1},
  );
has_field 'useragent.device' =>
  (
   type => 'Toggle',
   label => 'Is a device',
   element_attr => {disabled => 1},
  );

=head2 get_language_handle_from_ctx

=cut

sub get_language_handle_from_ctx {
    my $self = shift;

    return pfappserver::I18N->get_handle(
        @{ $self->ctx->languages } );
}

=head2 options_status

=cut

sub options_status {
    my $self = shift;

    # $self->status comes from pfappserver::Model::Node->availableStatus
    my @status = map { $_ => $_ } @{$self->status} if ($self->status);

    return @status;
}

=head2 options_category_id

=cut

sub options_category_id {
    my $self = shift;

    # $self->categories comes from pfappserver::Model::NodeCategory
    my @categories = map { $_->{category_id} => $_->{name} } @{$self->categories} if ($self->categories);

    return ('' => '', @categories);
}

=head2 html_attributes

Translate placeholders if defined

=cut

sub html_attributes {
    my ( $self, $obj, $type, $attr, $result ) = @_;
    # obj is either form or field
    if (exists $attr->{'data-placeholder'}) {
        $attr->{'data-placeholder'} = $self->_localize($attr->{'data-placeholder'});
    }
    return $attr;
}

=head2 field_errors

Return a hashref of field errors. Can be called once the form has been processed.

=cut

sub field_errors {
    my ($self) = @_;

    my %errors = ();
    if ($self->has_errors) {
        foreach my $field ($self->error_fields) {
            $errors{$field->name} = join(' ', @{$field->errors});
        }
    }

    return \%errors;
}

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