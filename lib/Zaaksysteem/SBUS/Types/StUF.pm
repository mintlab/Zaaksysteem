package Zaaksysteem::SBUS::Types::StUF;

use strict;
use warnings;

use Zaaksysteem::Constants;
use XML::Twig;

use Params::Profile;
use Data::Dumper;

use XML::Tidy;

use FindBin qw/$Bin/;

use Moose;
use namespace::autoclean;

extends 'Zaaksysteem::SBUS';

use constant BERICHTSOORTEN => {
    'search'        => {
        'berichtsoort'  => 'Lv01',
        'soap_call'     => 'beantwoordSynchroneVraag',
    }
    #'search'        => 'Lk01',
};

#sub sectormodellen {
#    my $self    = shift;
#
#    return $self->{_sectormodellen}
#        if $self->{_sectormodellen};
#
#    $self->{_sectormodellen} = {
#        'BG' => 1
#    };
#
#    return $self->{_sectormodellen};
#}
#
#sub _is_valid_sectormodel {
#    my ($self, $search, $opt) = @_;
#
#    die('STuF: Geen sectormodel gegeven') unless $opt->{'sectormodel'};
#    die('STuF: Onjuist sectormodel: ' . $opt->{'sectormodel'})
#        unless $self->sectormodellen->{uc($opt->{'sectormodel'})}
#}

sub _generate_stuf_definition {
    my $self    = shift;
    my $type    = shift;
    my $search  = shift;
    my $opt     = shift;

    my $def     = {
        'stuurgegevens'     => {
            'berichtsoort'      => BERICHTSOORTEN->{ $type }->{berichtsoort},
            'zender'            => {
                'applicatie'        => 'ZSML',
            },
            'ontvanger'         => {
                'applicatie'        => 'CMG',
            },
            'vraag'             => {
                'sortering'         => $opt->{sortering},
                'maximumAantal'     => $opt->{rows},
            },
            'kennisgeving'      => {
                'mutatiesoort'  => 'T',
                'indicatorOvername' => 'V',
            }
        },
        'body'              => {},
    };

    $def->{ stuurgegevens }->{ $_ } = $opt->{ $_ } for qw/
        entiteittype
        sectormodel
        versieStUF
        versieSectormodel
        referentienummer
        tijdstipBericht
    /;

    ### Vraag
    my $question    = $self->_generate_question($search, $opt);

    my $columns     = {
        $opt->{entiteittype} => $self->xml_structure->{
            $opt->{entiteittype}
        }
    };

    warn(Dumper($columns));

    my $body = $question;
    while (my ($column, $value) = each %{ $columns }) {
        if ($question->{$column}) {
            push (@{ $body->{$column} }, $value);
            next;
        }

        $body->{$column} = $value;
    }

    $def->{body}    = $body;
#    $def->{body}    = {
#        PRS => {
#            'verwerkingssoort'  => 'T',
#            'a-nummer'  => '2929292929',
#            'bsn-nummer' => '231513987',
#        }
#    };

#    print Dumper($def);

    return $def;
}

sub _generate_question {
    my $self    = shift;
    my $search  = shift;
    my $opt     = shift;
    my $rv      = {};

    die('No entiteittype given, no idea how to define a question')
        unless $opt->{entiteittype};

    $rv->{ $opt->{entiteittype} } = [
        $search,
        $search
    ];

    return $rv;
}


sub search {
    my $self    = shift;

    #$self->_is_valid_sectormodel(@_);

    my $def     = $self->_generate_stuf_definition('search', @_);

    return $def;
}

#sub xml_invalid {
#    my $self    = shift;
#    my $xml     = shift;
#
#    ### Validate stuurgegevens
#    ## VALID:
#    return;
#}
#
#sub handle_response {
#    my ($self, $params, $options) = @_;
#
#    my $operation   = $params->{operation};
#    my $stufxml     = $params->{input};
#
#    eval {
#        ### Do stuff
#        my $entiteit = uc(
#            $stufxml
#            ->{$operation}
#            ->{stuurgegevens}
#            ->{entiteittype}
#        );
#
#        die('Entiteit niet gevonden?!?') unless $entiteit;
#
#        my $adapter_package = __PACKAGE__ . '::Adapter::' . $entiteit;
#
#        my $adapter = $adapter_package->new(
#            app => $self->app
#        );
#
#        $adapter->handle_stuf_body(
#            $stufxml->{$operation}->{body},
#            {
#                'mutatie_type'  => $stufxml->{$operation}
#                    ->{stuurgegevens}->{kennisgeving}->{mutatiesoort},
#                'entiteit_type' => $entiteit,
#                traffic_object  => $options->{traffic_object},
#            }
#        );
#
#    };
#
#    if ($@) {
#        $options->{traffic_object}->error(1);
#        $options->{traffic_object}->error_message(
#            'Error handling stuf XML: ' . $@
#        );
#        $self->app->log->error('Error handling stuf XML: ' . $@);
#    }
#
#    return $self->compile_bevestiging;
#}

sub generate_return {
    return {
       'bevestiging'    => {
           'stuurgegevens'  => {
                'berichtsoort'      => 'Bv01',
                'referentienummer'  => '2322232323',
                'tijdstipBericht'   => '2009040717084815',
                'entiteittype'      => 'PRS',
                'zender'            => {
                    'applicatie'        => 'zaaksysteem.nl',
                    'organisatie'       => 'Baarn'
                },
                'ontvanger'         => {
                    'applicatie'        => 'ONBEKEND'
                },
                'kennisgeving'      => {
                    'indicatorOvername' => 'V',
                    'mutatiesoort'      => 'T'
                },
                'sectormodel'       => 'BG',
                'versieSectormodel' => '0204',
                'versieStUF'        => '0204',
            }
        }
    };
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

