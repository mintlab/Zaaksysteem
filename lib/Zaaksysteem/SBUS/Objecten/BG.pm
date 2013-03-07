package Zaaksysteem::SBUS::StUF::BG;

use strict;
use warnings;

use Zaaksysteem::Constants;
use XML::LibXML;

use Params::Profile;
use Data::Dumper;

use Moose;
use namespace::autoclean;

extends 'Zaaksysteem::SBUS::StUF';

my $nil_geenwaarde = sub {
    my ($col)  = @_;

    my $nilvalue    = XML::LibXML::Element->new( 'BG:' . $col );
    $nilvalue->setAttribute('xsi:nil', 'true');
    $nilvalue->setAttribute('StUF:noValue', 'geenWaarde');

    return $nilvalue;
};

my $XML_DEFINITION = {
    'PRS'  => {
        'soortEntiteit' => 'F',
        'a-nummer' => $nil_geenwaarde->('a-nummer'),
        'bsn-nummer' => $nil_geenwaarde->('bsn-nummer'),
        'voornamen' => $nil_geenwaarde->('voornamen'),
        'voorletters' => $nil_geenwaarde->('voorletters'),
        'voorvoegselGeslachtsnaam' => $nil_geenwaarde->('voorvoegselGeslachtsnaam'),
        'geslachtsnaam' => $nil_geenwaarde->('geslachtsnaam'),
        'geboortedatum' => $nil_geenwaarde->('geboortedatum'),
        'geboorteplaats' => $nil_geenwaarde->('geboorteplaats'),
        'codeGeboorteland' => $nil_geenwaarde->('codeGeboorteland'),
        'geslachtsaanduiding' => $nil_geenwaarde->('geslachtsaanduiding'),
        'datumOverlijden' => $nil_geenwaarde->('datumOverlijden'),
        'indicatieGeheim' => $nil_geenwaarde->('indicatieGeheim'),
        'codeLandEmigratie' => $nil_geenwaarde->('codeLandEmigratie'),
        'datumVertrekUitNederland' => $nil_geenwaarde->('datumVertrekUitNederland'),
        'datumVestigingInNederland' => $nil_geenwaarde->('datumVestigingInNederland'),
        'burgerlijkeStaat' => $nil_geenwaarde->('burgerlijkeStaat'),
        'aanduidingNaamgebruik' => $nil_geenwaarde->('aanduidingNaamgebruik'),
    },
    'ADR'   => {
        'soortEntiteit' => 'F',
        'adresBuitenland1' => $nil_geenwaarde->('adresBuitenland1'),
        'adresBuitenland2' => $nil_geenwaarde->('adresBuitenland2'),
        'adresBuitenland3' => $nil_geenwaarde->('adresBuitenland3'),
        'landcode' => $nil_geenwaarde->('landcode'),
        'postcode' => $nil_geenwaarde->('postcode'),
        'woonplaatsnaam' => $nil_geenwaarde->('woonplaatsnaam'),
        'straatnaam' => $nil_geenwaarde->('straatnaam'),
        'huisnummer' => $nil_geenwaarde->('huisnummer'),
        'huisletter' => $nil_geenwaarde->('huisletter'),
        'huisnummertoevoeging' => $nil_geenwaarde->('huisnummertoevoeging'),
        'aanduidingBijHuisnummer' => $nil_geenwaarde->('aanduidingBijHuisnummer'),
        'ingangsdatum' => $nil_geenwaarde->('ingangsdatum'),
        'einddatum' => $nil_geenwaarde->('einddatum'),
        'straatcode' => $nil_geenwaarde->('straatcode'),
        'buurtcode' => $nil_geenwaarde->('buurtcode'),
        'wijkcode' => $nil_geenwaarde->('wijkcode'),
        'gemeentecode' => $nil_geenwaarde->('gemeentecode'),
    },
    'NAT'   => {
        'soortEntiteit' => 'T',
        'node' => $nil_geenwaarde->('node'),
    },
};

my $XML_STRUCTURE = {
    'PRS'   => {
        %{ $XML_DEFINITION->{PRS} },
        'PRSADRCOR' => {
            soortEntiteit   => 'R',
            ADR => $XML_DEFINITION->{ADR},
        },
        'PRSADRINS' => {
            soortEntiteit   => 'R',
            ADR => $XML_DEFINITION->{ADR},
        },
        'PRSADRVBL' => {
            soortEntiteit   => 'R',
            ADR => $XML_DEFINITION->{ADR},
        },
        'PRSPRSHUW' => {
            soortEntiteit   => 'R',
            PRS => $XML_DEFINITION->{PRS},
        },
        'PRSNAT'    => {
            soortEntiteit   => 'R',
            NAT => $XML_DEFINITION->{NAT},
        }
    },
};

around 'search' => sub {
    my $orig    = shift;
    my $self    = shift;
    my $search  = shift;
    my $opt     = shift;

    $opt->{sectormodel}     = 'BG';

    ### Default search
    unless ($opt->{entiteittype}) {
        $opt->{entiteittype}    = 'PRS';
    }

    $self->$orig($search, $opt, @_);
};

around 'xml_invalid' => sub {
    my $orig    = shift;
    my $self    = shift;
    my $xml     = shift;

    $self->$orig($xml);
};

sub xml_definition {
    my $self    = shift;

    return $XML_DEFINITION;
}

sub xml_structure {
    my $self    = shift;

    return $XML_STRUCTURE;
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

