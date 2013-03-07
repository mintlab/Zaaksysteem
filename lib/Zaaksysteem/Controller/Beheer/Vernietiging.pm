package Zaaksysteem::Controller::Beheer::Vernietiging;
use Moose;
use namespace::autoclean;

use Hash::Merge::Simple qw( clone_merge );

use Data::Dumper;

BEGIN {extends 'Catalyst::Controller'; }

use constant ZAAKTYPEN              => 'zaaktypen';
use constant ZAAKTYPEN_MODEL        => 'DB::Zaaktype';
use constant CATEGORIES_DB          => 'DB::BibliotheekCategorie';



sub list : Chained('/'): PathPart('beheer/vernietiging'): Args(0) {
    my ( $self, $c ) = @_;

    my $where                   = {
        'me.status'             => { '!='   => 'deleted' },
        'me.vernietigingsdatum' => { '<'    => DateTime->now(time_zone =>
                'Europe/Amsterdam') },
    };

    if ($c->req->params->{vernietig}) {
        $c->detach('actie');
    }

    my $params                  = $c->req->params();
    my $sort_field              = $params->{'sort_field'} || 'id';
    $c->stash->{'sort_field'}   = $sort_field;

    my $sort_direction          = $params->{'sort_direction'} || 'DESC';
    $c->stash->{'sort_direction'} = $sort_direction;

    my $order_by                = {
        '-' . $sort_direction => 'me.'. $sort_field
    };
    my $ROWS_PER_PAGE           = 10;
    my $page                    = $params->{'page'} || 1;

    my $resultset = $c->model('DB::Zaak')->search_extended($where, {
        page        => $page,
        rows        => $ROWS_PER_PAGE,
        order_by    => $order_by,
    })->with_progress();

    $resultset = $c->model('Zaken')->filter({
        resultset   => $resultset,
        dropdown    => $params->{'filter'},
        textfilter  => $params->{'textfilter'},
    });

    my $search_query                = $c->model('SearchQuery');
    $c->stash->{'display_fields'}   = $search_query->get_display_fields();
    $c->stash->{'results'}          = $resultset;

    $c->stash->{template}           = 'beheer/vernietiging/list.tt';
}


#sub base : Chained('/') : PathPart('beheer/vernietiging'): CaptureArgs(1) {
#    my ( $self, $c, $zaaknr ) = @_;
#
#    $c->res->redirect('/beheer/vernietiging');
#    $c->detach unless (
#        $zaaknr =~ /^\d+$/ &&
#        $c->model('Zaak')->get($zaaknr)
#    );
#}

sub actie : Private {
    my ( $self, $c ) = @_;

    $c->res->redirect('/beheer/vernietiging');

    $c->detach unless (
        $c->req->params->{vernietig}
    );

    my (@zaaknrs);
    if (UNIVERSAL::isa($c->req->params->{vernietig}, 'ARRAY')) {
        @zaaknrs    = @{ $c->req->params->{vernietig} }
    } else {
        $zaaknrs[0] = $c->req->params->{vernietig};
    }

    $c->detach unless @zaaknrs;

    my @result;
    for my $zaaknr (@zaaknrs) {
        next unless $zaaknr =~ /^\d+$/;

        $c->log->debug('Found zaaknr voor vernietiging: ' . $zaaknr);

        my $zaak    = $c->model('DB::Zaak')->find(
            $zaaknr
        );

        unless ($zaak) {
            push(
                @result,
                'Error: zaaknummer ' . $zaaknr . ' niet gevonden.'
            );
            next;
        }

        if ($c->req->params->{actie} =~ /vernietigen/i) {
            $zaak->status('deleted');
            $zaak->deleted(DateTime->now());
            $zaak->update;
            push(
                @result,
                'Succes: zaaknummer ' . $zaaknr . ' is vernietigd.'
            );
        }
    }

    $c->flash->{result} = join("<br />", @result);
}

1;

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

