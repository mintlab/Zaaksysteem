package Zaaksysteem::Controller::Beheer::Zaaktypen::Version;
use Moose;
use namespace::autoclean;

use Hash::Merge::Simple qw( clone_merge );
use XML::Simple;

use Data::Dumper;
use Zaaksysteem::Constants;


BEGIN {extends 'Catalyst::Controller'; }

use constant ZAAKTYPEN              => 'zaaktypen';
use constant ZAAKTYPEN_MODEL        => 'DB::Zaaktype';
use constant CATEGORIES_DB          => 'DB::BibliotheekCategorie';




sub base : Chained('/') : PathPart('beheer/zaaktypen'): CaptureArgs(1) {
    my ( $self, $c, $zaaktype_id ) = @_;

    $c->stash->{zaaktype_id} = $zaaktype_id;
    $c->stash->{nowrapper} = 1;
}


sub version : Chained('base') : PathPart('version') {
    my ( $self, $c ) = @_;

    $c->stash->{max_rows} = 25;

    my $zaaktype = $c->model('DB::Zaaktype')->find($c->stash->{zaaktype_id});
    
    $c->stash->{titel} = $zaaktype->zaaktype_node_id->titel;
    $c->stash->{current_zaaktype_node_id} = $zaaktype->zaaktype_node_id->id;

    my $options = {
        order_by => {-desc => 'id'},
    };

    unless($c->req->param('show_all_results')) {
        $options->{rows} = $c->stash->{max_rows};
        $options->{page} = 1;
    }

    $c->stash->{zaaktype_nodes} = $c->model('DB::ZaaktypeNode')->search({
        deleted => undef,
        zaaktype_id => $c->stash->{zaaktype_id},
    }, $options);

    $c->stash->{template} = 'beheer/zaaktypen/version.tt';
}


sub activate : Chained('base') : PathPart('version/activate') : Args() {
    my ( $self, $c, $zaaktype_node_id ) = @_;
 
    my $zaaktype_row = $c->model("DB::Zaaktype")->find($c->stash->{zaaktype_id});
    $zaaktype_row->zaaktype_node_id($zaaktype_node_id);
    $zaaktype_row->update();
    $c->stash->{nowrapper} = 1;
    $c->stash->{message} = 'Het zaaktype is ingesteld op versie ' .$zaaktype_node_id;
    $c->forward("version");
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

