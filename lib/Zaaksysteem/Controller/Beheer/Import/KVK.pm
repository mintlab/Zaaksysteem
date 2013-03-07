package Zaaksysteem::Controller::Beheer::Import::KVK;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }




sub base : Chained('/') : PathPart('beheer/import/kvk'): CaptureArgs(1) {
    my ( $self, $c, $import_id ) = @_;

    $c->stash->{import_data} = $c->model('DB::BeheerImport')->find($import_id);
    $c->stash->{import_type} = 'kvk';

    if (!$c->stash->{import_data}) {
        $c->res->redirect($c->uri_for('/beheer/import/kvk'));
        $c->detach;
    }
}

sub index : Chained('/') : PathPart('beheer/import/kvk'): Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{import_type} = 'kvk';
    $c->stash->{import_list} = $c->model('DB::BeheerImport')->search(
        {
            importtype  => 'KVK',
        },
        {
            order_by    => { -desc => ['created'] },
        }
    );

    $c->stash->{template} = 'beheer/import/kvk/list.tt';
}

sub view : Chained('base') : PathPart(''): Args() {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'beheer/import/kvk/view.tt'
}


sub run : Local {
    my ( $self, $c ) = @_;

    $c->model('Beheer::Import::KVK')->import(
        'type'      => 'KVKCsv',
        'options'   => {
            'filename'  => (
                $ENV{USER} eq 'michiel'
                    ?'/home/michiel/dev/Zaaksysteem/tmp/kvkexport.csv'
                    :'/home/zaaksysteem/bussum/import/kvk.csv'
                ),
        }
    );

    $c->res->body('OK');


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

