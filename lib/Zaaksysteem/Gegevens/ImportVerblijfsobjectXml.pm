package Zaaksysteem::Gegevens::ImportVerblijfsobjectXml;

use Zaaksysteem::Gegevens::SaxXmlProcessing;
use strict;
use warnings;

use Params::Profile;
use Data::Dumper;
use Zaaksysteem::Constants;

use Moose;
use namespace::autoclean;


extends qw(Zaaksysteem::Gegevens::SaxXmlProcessing);



sub set_db_columns {
    my ($self) = @_;

    $self->table_name('BagVerblijfsobject');

    $self->db_cols({
            'xpath_group' => { 'bag_LVC:Standplaats' => {
                    'bag_LVC:identificatie'                                         => 'identificatie',
                    'bag_LVC:tijdvakgeldigheid' => {
                            'bagtype:begindatumTijdvakGeldigheid' => 'begindatum'
                        },
                   # ''      => 'einddatum',
                    'bag_LVC:officieel'                                             => 'officieel',

                    'bag_LVC:gerelateerdeAdressen' => {
                            'bag_LVC:hoofdadres' => {
                                'bag_LVC:identificatie'                             => 'hoofdadres'
                                }
                            },
                    'bag_LVC:oppervlakteVerblijfsobject'                            => 'oppervlakte',

                    'bag_LVC:verblijfsobjectStatus'                                 => 'status',
                    'bag_LVC:inOnderzoek'                                           => 'inonderzoek',
                    'bag_LVC:bron' => {
                            'bagtype:documentdatum'  => 'documentdatum',
                            'bagtype:documentnummer' => 'documentnummer'
                        },
                    'bag_LVC:aanduidingRecordCorrectie'                             => 'correctie' 
                }
            }
    });
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

