package pfappserver::Base::Model::SavedSearch;
=head1 NAME

pfappserver::Model::SavedSearch

=head1 DESCRIPTION

Base class for SavedSearch

Example usage:

package pfappserver::Model::SavedSearch::Type;

use Moose;

extends 'pfappserver::Base::Model::SavedSearch';

__PACKAGE__->meta->make_immutable;

=head2 Methods

=over

=cut

use strict;
use warnings;
use Moose;

use pf::savedsearch;
use HTML::FormHandler::Params;
use HTTP::Status qw(:constants is_error is_success);

=item namespace

=cut

sub namespace {
    my ($self_or_class) = @_;
    return ref($self_or_class) || $self_or_class;
};

=item create

=cut

sub create {
    my ($self,$saved_search) = @_;
    $saved_search->{namespace} = $self->namespace;
    if( savedsearch_add($saved_search) ) {
        return ($STATUS::OK,"");
    } else {
        return ($STATUS::INTERNAL_SERVER_ERROR,"cannot create saved search");
    }

}

=item read

=cut

sub read {
    my ($self,$id) = @_;
    my ($saved_search) =  savedsearch_view($id);
    if($saved_search) {
        return ($STATUS::OK,_expand_query($saved_search));
    } else {
        return ($STATUS::INTERNAL_SERVER_ERROR,"cannot read saved search");
    }
}

=item read_all

=cut

sub read_all {
    my ($self,$pid) = @_;
    return ($STATUS::OK, [map { _expand_query($_) } savedsearch_for_pid_and_namespace($pid,$self->namespace)]);
}

=item update

=cut

sub update {
    my ($self,undef,$saved_search) = @_;
    return savedsearch_update($saved_search);
}

=item remove

=cut

sub remove {
    my ($self,$saved_search) = @_;
    if(savedsearch_delete($saved_search->{id})) {
        return ($STATUS::OK,savedsearch_delete($saved_search));
    } else {
        return ($STATUS::INTERNAL_SERVER_ERROR,"cannot remove saved search");
    }
}

=item _expand_query

=cut

sub _expand_query {
    my ($saved_search) = @_;
    my $params_handler =  HTML::FormHandler::Params->new;
    my $uri = URI->new($saved_search->{query});
    my $form = $uri->query_form_hash;
    $saved_search->{form} = $form;
    $saved_search->{params} = $params_handler->expand_hash($form);
    $saved_search->{path} = $uri->path;
    return $saved_search;
}

__PACKAGE__->meta->make_immutable;

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
