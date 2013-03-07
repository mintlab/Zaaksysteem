package Zaaksysteem::Controller::Gegevens::BAG;

use strict;
use warnings;
use Data::Dumper;
use parent 'Catalyst::Controller';


sub base : Chained('/') : PathPart('gegevens/bag'): CaptureArgs(1) {
    my ($self, $c, $bagid) = @_;

    $c->stash->{bag} = $c->model('Gegevens::BAG')->retrieve(
        'id'    => $bagid
    ) or $c->detach;
}

sub info : Chained('base') : PathPart('info'): Args(1) {
    my ($self, $c, $template) = @_;

    $c->stash->{nowrapper} = 1;
    $c->stash->{template} = 'widgets/gegevens/bag/' . $template . '.tt';
}


sub search : Local {
    my ($self, $c) = @_;

    if (
        $c->req->header("x-requested-with") eq 'XMLHttpRequest' &&
        $c->req->params->{json_response}
    ) {

        $c->stash->{json} = {
            'entries'    => []
        };

        my $entries = [];
        if ($c->req->params->{searchtype} eq 'openbareruimte') {
            $c->detach unless (
                $c->req->params->{straatnaam}
            );

            my $straatnaam = $c->req->params->{straatnaam};
            $straatnaam =~ s/.+> //;

            my $ors = $c->model('DBG::BagOpenbareruimte')->search(
                {
                    'lower(naam)'    => {
                        like    => lc($straatnaam) . '%'
                    }
                },
            );

            while (my $or = $ors->next) {
                push( @{ $entries },
                    {
                        nummeraanduiding => undef,
                        straatnaam       => $or->naam,
                        woonplaats       => $or->woonplaats->naam,
                        identificatie    => 'openbareruimte-' . $or->identificatie
                    },
                );
            }
        } else {
            $c->detach unless (
                (
                    (
                        $c->req->params->{postcode} ||
                        $c->req->params->{straatnaam}
                    ) &&
                    $c->req->params->{huisnummer}
                )
            );
            my $straatnaam = $c->req->params->{straatnaam};
            $straatnaam =~ s/.+> //;

            my $huisnummer  = $c->req->params->{huisnummer};
            $huisnummer =~ s/[^\d]//g;

            $c->detach unless (
                $huisnummer =~ /^\d+$/
            );

            if ( $c->req->params->{postcode} ) {
                my $nas = $c->model('DBG::BagNummeraanduiding')->search(
                    {
                        postcode    => uc($c->req->params->{postcode}),
                        huisnummer  => $huisnummer,
                    },
                );

                while (my $na = $nas->next) {
                    push( @{ $entries },
                        {
                            nummeraanduiding => $na->nummeraanduiding,
                            straatnaam       => $na->openbareruimte->naam,
                            woonplaats       => $na->woonplaats->naam,
                            identificatie    => 'nummeraanduiding-' . $na->identificatie
                        },
                    );
                }
            } else {
                my $straten = $c->model('DBG::BagOpenbareruimte')->search(
                    {
                        naam  => $straatnaam
                    },
                );

                my $straat  = $straten->first;

                my $nas     = $straat->hoofdadressen->search(
                    {
                        huisnummer  => $huisnummer,
                    }
                );

                while (my $na = $nas->next) {
                    push( @{ $entries },
                        {
                            nummeraanduiding => $na->nummeraanduiding,
                            straatnaam       => $straat->naam,
                            woonplaats       => $straat->woonplaats->naam,
                            identificatie    => 'nummeraanduiding-' . $na->identificatie
                        },
                    );
                }

            }
        }

        $c->stash->{json} = {
            'entries'    => $entries,
        };
        $c->forward('Zaaksysteem::View::JSON');
        $c->detach;
    }
}

sub search_andere_zaken_met_bag_id : Local {
    my ($self, $c, $bagid) = @_;

    unless (
        $c->req->header("x-requested-with") eq 'XMLHttpRequest'
    ) {
        $c->detach;
    }

}

sub import : Local {
    my ($self, $c) = @_;

    $c->model('Gegevens::BAG')->import_start;

    $c->res->body('OK');
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

