package Zaaksysteem::Controller::Plugins::Parkeergebied;

use strict;
use warnings;
use Data::Dumper;
use parent 'Catalyst::Controller';




sub _get_parkeergebied {
    my ($self, $c, $params) = @_;
    my $rv;

    ### VALIDATION
    unless (
            $params->{ztc_aanvrager_id}
    ) {
        $c->log->debug('Geen aanvrager meegekregen');
        return;
    }

    my $aanvrager = $c->model('Betrokkene')->get(
        {},
        $params->{ztc_aanvrager_id}
    );

    return unless $aanvrager;

    my $hoofdadres;
    if (
        $aanvrager->verblijfsobject &&
        $aanvrager->verblijfsobject->hoofdadres
    ) {
        $hoofdadres = $aanvrager->verblijfsobject->hoofdadres->identificatie;
    }

    ### Search parameters
    my $search_opts     = {};
    if ($hoofdadres) {
        $search_opts->{bag_hoofdadres}   = $hoofdadres;
    } else {
        for (qw/postcode huisnummer/) {
            next unless ($aanvrager->can( $_ ));

            $search_opts->{ $_ } = $aanvrager->$_;
        }
    }

    my $rows = $c->model('DBG::Parkeergebied')->search($search_opts);

    ### FALLBACK
    if (!$rows->count) {
        my $parkeergebied   = $params->{parkeergebied};

        $rows = $c->model('DBG::Parkeergebied')->search({
            'parkeergebied' => $parkeergebied
        });

        $c->log->debug('Fallback: ' . $rows->count);

    }

    if ($rows->count) {
        my $row = $rows->first;
        my $kosten;

        my $search_opts = {
            parkeergebied   => $row->parkeergebied,
            betrokkene_type => $aanvrager->btype,
        };

        $kosten = $c->model('DBG::ParkeergebiedKosten')->search({
            %{ $search_opts },
            aanvraag_soort  => (
                (
                    !$params->{vergunningtype} ||
                    $params->{vergunningtype} eq 'Nieuwe vergunning'
                )   ? 1
                    : 2
            ),
        });

        if (!$kosten->count) {
            $kosten = $c->model('DBG::ParkeergebiedKosten')->search({
                %{$search_opts},
                aanvraag_soort  => 1,
            });
        }

        if ($kosten->count) {
            $rv = { $row->get_columns };

            if ( $aanvrager->btype eq 'bedrijf' ) {
                if (lc($rv->{parkeergebied}) !~ /centrum/) {
                    $rv->{heeft_algemeen_kenteken} = 1;
                }

                $rv->{heeft_vergunninghouder} = 1;
            }

            $rv->{geldigheden}  = [];
            $rv->{prijzen}      = [];

            my $primary_geldigheid;
            my %geldigheid_prijs;
            while (my $kost = $kosten->next) {
                if (!$c->user_exists) {
                    if (lc($rv->{parkeergebied}) =~ /centrum/) {
                        next unless (
                            $kost->geldigheid eq '12' ||
                            $kost->geldigheid eq '0'
                        );
                    } else {
                        next unless $kost->geldigheid eq '24';
                    }
                }

                $geldigheid_prijs{$kost->geldigheid} = $kost->prijs;

                push(
                    @{ $rv->{geldigheden} },
                    $kost->geldigheid
                );

                push(
                    @{ $rv->{prijzen} },
                    $kost->prijs
                );

                if (!$primary_geldigheid) {
                    $primary_geldigheid = $kost->geldigheid;
                }
            }

            # Make sure there is a default
            if (
                ($params->{geldigheid} || $params->{geldigheid} eq '0') &&
                $geldigheid_prijs{ $params->{geldigheid} }
            ) {
                $primary_geldigheid = $params->{geldigheid};
                $rv->{prijzen}      = [ $geldigheid_prijs{ $params->{geldigheid} } ];
            } elsif (
                defined($primary_geldigheid) &&
                $geldigheid_prijs{ $primary_geldigheid }
            ) {
                $rv->{prijzen}      = [ $geldigheid_prijs{ $primary_geldigheid } ];
            }


            ### Calculate einddatum
            $rv->{einddatum} = '';
            if ($params->{startdatum}) {
                if ($primary_geldigheid) {
                    my ($day, $month, $year) = $params->{startdatum}
                        =~ /^(\d+)-(\d+)-(\d{4})$/;

                    my $einddatum = DateTime->new(
                        year    => $year,
                        month   => $month,
                        day     => $day,
                    );

                    $einddatum->add(
                        'months'     => $primary_geldigheid
                    );

                    $rv->{einddatum} = $einddatum->dmy;
                } else {
                    $rv->{einddatum} = '-';
                }
            }

            if (lc($rv->{parkeergebied}) !~ /centrum/) {
                $rv->{toon_geldigheidsdagen} = 1;
            }
        }
    } else {
        return;
    }

    ### Fallback, wanneer geen prijzen bekend
    if (
        !$params->{geldigheid} && (
            !$rv->{prijzen} ||
            scalar(@{ $rv->{prijzen} }) < 1
        )
    ) {
        $c->log->error('Z:C:Parkeergebied: geen prijzen gevonden');
        return;
    }

    ### parkeergebied bezoeker
    if ($params->{parkeergebied_bezoeker}) {
        $rv->{prijzen} = [ 6.6 ];

        if ($params->{parkeergebied_vergunningen}) {
            $rv->{prijzen} = [
                (6.6 * $params->{parkeergebied_vergunningen})
            ];
        }
    }

    if ($c->user_exists) {
        $rv->{betaalwijze} = undef;
    } else {
        $rv->{betaalwijze} = 'iDeal';
    }

    $c->log->debug('Serving parkeergebied: ' . Dumper($rv));

    return $rv;

}

sub get_parkeergebied : Local {
    my ($self, $c) = @_;
    my $json;

    unless ($json = $self->_get_parkeergebied($c, $c->req->params)) {
        $c->stash->{json} = {
            success => 0,
        };
    } else {
        $c->stash->{json} = {
            success => 1,
            %{ $json },
        };
    }

    $c->forward('View::JSON');
}


sub load_plugin_config {
    my ($self, $c) = @_;
    my $rv = {};

    my $kenmerkc        = $c->config->{'Z::Plugins::Parkeergebied'}->{kenmerk};

    my $kenmerken       = $c->model('DB::BibliotheekKenmerken')->search(
        naam    => [
            values %{ $kenmerkc },
        ],
    );

    my %swapped_config = map({ $kenmerkc->{$_} => $_ } keys
        %{ $kenmerkc }
    );

    while (my $kenmerk = $kenmerken->next) {
        $rv->{'plugin_' . $swapped_config{$kenmerk->naam}} = $kenmerk->id;
    }

    return $rv;

}

sub prepare_zaak_form {
    my ($self, $c) = @_;

    $c->stash->{plugin_parkeervergunning_config} =
        $self->load_plugin_config($c);

    $c->log->debug('Stash: ' .
        Dumper($c->stash->{plugin_parkeervergunning_config}));

    my $params  = $c->req->params;

    if ($c->stash->{aanvrager}) {
        $params->{ztc_aanvrager_id} =
            $c->stash->{aanvrager}->betrokkene_identifier;
    }

    my $fields = $c->stash->{fields};
    $fields->reset;

    while (my $field = $fields->next) {
        if ($field->naam eq 'Aantal bezoekersvergunningen') {
            my $rv = $self->_get_parkeergebied($c, $params);

            if (lc($rv->{parkeergebied}) =~ /centrum/) {
                $c->flash->{result} = 'Helaas, parkeergebied Centrum'
                    . ' staat geen bezoekersvergunningen toe.';

                return;
            }
        }
    }

    return 1 if $self->_get_parkeergebied($c, $params);

    if ($c->user_exists) {
        $c->flash->{result} = 'Helaas, parkeergebied is niet gevonden '
            . ' voor binnen deze postcode+huisnummer of prijzen zijn niet'
            . ' bekend.';

            return 1;
    } else {
        $c->stash->{foutmelding} = 'Binnen uw postcodegebied is geen '
            .'vergunning benodigd of beschikbaar.';

        return;
    }
}

sub prepare_zaak_create {
    my ($self, $c) = @_;
    my ($parkeergebied, $params);

    if ($c->session->{_zaak_create}->{raw_kenmerken}) {
        $params  =  { %{ $c->session->{_zaak_create}->{raw_kenmerken} } };
    } else {
        $params  = { %{ $c->req->params } };
    }

    $c->log->debug('prepare_zaak_create: Parkeergebied params:'
        . Dumper($params)
    );

    $c->stash->{plugin_parkeervergunning_config} =
        $self->load_plugin_config($c);

    my $kenmerkc        = $c->stash->{plugin_parkeervergunning_config};

    unless (
        $parkeergebied = $self->_get_parkeergebied($c,
            {
                %{ $params },
                vergunningtype  => $params->{
                        $kenmerkc->{'plugin_vergunningtype_id'}
                    },
                geldigheid      => $params->{
                        $kenmerkc->{'plugin_geldigheid_id'}
                    },
                startdatum      => $params->{
                        $kenmerkc->{'plugin_startdatum_id'}
                    },

            }
        )
    ) {
        # Not found, cannot continue
        return;
    }

    $c->log->debug('prepare_zaak_create: Parkeergebied result:'
        . Dumper($parkeergebied)
    );

    $c->stash->{'_parkeergebied_parkeergebied'} = $parkeergebied;

    # Update kenmerken
    $params->{'kenmerk_id_' . $kenmerkc->{'plugin_parkeergebied_id'}} =
        $parkeergebied->{parkeergebied};

    $params->{'kenmerk_id_' . $kenmerkc->{'plugin_einddatum_id'}} =
        $parkeergebied->{einddatum};

    $params->{'kenmerk_id_' . $kenmerkc->{'plugin_prijs'}} =
        $parkeergebied->{prijzen}->[0];

    if ($parkeergebied->{heeft_algemeen_kenteken}) {
        $params->{'kenmerk_id_' . $kenmerkc->{'plugin_kenteken_id'}} =
            $c->config->{'Z::Plugins::Parkeergebied'}->{kenteken_algemeen_tekst};
    }

    $params->{'kenmerk_id_' . $kenmerkc->{'plugin_betaalwijze_id'}} =
        $parkeergebied->{betaalwijze} if $parkeergebied->{betaalwijze};

    if (!$c->user_exists) {
        $c->stash->{_online_betaling_kosten} =
            sprintf("%.2f", $parkeergebied->{prijzen}->[0]);
    }
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

