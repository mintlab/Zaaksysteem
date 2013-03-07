package Zaaksysteem::Controller::Beheer::Import::GBA;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }




sub base : Chained('/') : PathPart('beheer/import/gba'): CaptureArgs(1) {
    my ( $self, $c, $import_id ) = @_;

    $c->stash->{import_data} = $c->model('DB::BeheerImport')->find($import_id);

    if (!$c->stash->{import_data}) {
        $c->res->redirect($c->uri_for('/beheer/import/gba'));
        $c->detach;
    }
}

sub index : Chained('/') : PathPart('beheer/import/gba'): Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{paging_page} = $c->req->params->{paging_page} || 1;
    $c->stash->{paging_rows} = $c->req->params->{paging_rows} || 25;

    $c->stash->{import_list} = $c->model('DB::BeheerImport')->search(
        {
            importtype  => 'GBA',
        },
        {
            order_by    => { -desc => ['id'] },
            page        => $c->stash->{paging_page},
            rows        => $c->stash->{paging_rows},
        }
    );

    $c->stash->{paging_total}       = $c->stash->{import_list}->pager->total_entries;
    $c->stash->{paging_lastpage}    = $c->stash->{import_list}->pager->last_page;

    $c->stash->{template} = 'beheer/import/gba/list.tt';
}

sub view : Chained('base') : PathPart(''): Args() {
    my ( $self, $c ) = @_;

    $c->stash->{paging_page} = $c->req->params->{paging_page} || 1;
    $c->stash->{paging_rows} = $c->req->params->{paging_rows} || 25;

    $c->stash->{import_log} = $c->stash->{import_data}->beheer_import_logs->search(
        {},
        {
            order_by    => { -desc => ['id'] },
            page        => $c->stash->{paging_page},
            rows        => $c->stash->{paging_rows},
        }
    );

    $c->stash->{paging_total}       = $c->stash->{import_log}->pager->total_entries;
    $c->stash->{paging_lastpage}    = $c->stash->{import_log}->pager->last_page;

    $c->stash->{template}   = 'beheer/import/gba/view.tt'
}


sub run : Local {
    my ( $self, $c ) = @_;

    $c->model('Beheer::Import::GBA')->import(
        'type'      => $c->customer_instance
            ->{start_config}
            ->{'Plugin::Import'}
            ->{GBA}
            ->{import_class},
        'options'   => {
            'filename'  => (
                $ENV{USER} eq 'michiel'
                    ?'/home/michiel/gbatmp/toimport.csv'
                    : $c->customer_instance
                        ->{start_config}
                        ->{'Plugin::Import'}
                        ->{GBA}
                        ->{filename}
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

