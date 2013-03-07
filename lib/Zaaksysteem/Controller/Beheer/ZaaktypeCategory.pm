package Zaaksysteem::Controller::Beheer::ZaaktypeCategory;
use Moose;
use namespace::autoclean;

use Hash::Merge::Simple qw( clone_merge );

use Data::Dumper;

BEGIN {extends 'Catalyst::Controller'; }

#sub index :Path :Args(0) {
#    my ( $self, $c ) = @_;
#
#    $c->response->body('Matched Zaaksysteem::Controller::Beheer::ZaaktypeCategory in Beheer::ZaaktypeCategory.');
#}

use constant ZAAKTYPEN              => 'zaaktypen';
use constant ZAAKTYPEN_MODEL        => 'DB::Zaaktype';
use constant CATEGORIES_DB          => 'DB::BibliotheekCategorie';



sub base : Chained('/') : PathPart('beheer/zaaktype_catalogus'): CaptureArgs(2) {
    my ( $self, $c, $catid, $zaaktype_node_id ) = @_;

    $c->stash->{zaaktype_node_id}   = $zaaktype_node_id;
    $c->stash->{categorie_id}       = $catid;
}


sub list : Chained('/'): PathPart('beheer/zaaktype_catalogus'): Args() {
    my ( $self, $c, $categorie_id ) = @_;

    $c->stash->{bib_type}   = ZAAKTYPEN;
    $c->stash->{dest_type}   = ZAAKTYPEN;
    $c->stash->{'list_table'} = ZAAKTYPEN_MODEL;
    $c->stash->{'apply_text_filter_function'} = \&_apply_text_filter;

    $c->forward('/beheer/bibliotheek/list');
    
    $c->stash->{'entries'} = $c->stash->{'entries'}->search({'deleted' => undef}); 
}




__PACKAGE__->meta->make_immutable;


=head1 PROJECT FOUNDER

Mintlab B.V. <info@mintlab.nl>

=head1 CONTRIBUTORS

Arne de Boer

Nicolette Koedam

Marjolein Bryant

Peter Moen

Michiel Ootjers

Jonas Paarlberg

Jan-Willem Buitenhuis

Martin Kip

Gemeente Bussum

=head1 COPYRIGHT

Copyright (c) 2009, the above named PROJECT FOUNDER and CONTRIBUTORS.

=head1 LICENSE

The contents of this file and the complete zaaksysteem.nl distribution
are subject to the EUPL, Version 1.1 or - as soon they will be approved by the
European Commission - subsequent versions of the EUPL (the "Licence"); you may
not use this file except in compliance with the License. You may obtain a copy
of the License at
L<http://joinup.ec.europa.eu/software/page/eupl>

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

=cut

