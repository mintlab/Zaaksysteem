package Zaaksysteem::SBUS::Types::StUF::PRS;

use Data::Dumper;
use Moose;

use Zaaksysteem::SBUS::Constants;

extends 'Zaaksysteem::SBUS::Types::StUF::GenericAdapter';

has 'xml_structure' => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $xml_structure   = STUF_XML_STRUCTURE;
        my $xml_definition  = STUF_XML_DEFINITION;

        $xml_structure->{PRS}->{ $_ } = $xml_definition->{PRS}->{$_}
            for keys %{ $xml_definition->{PRS} };

        return $xml_structure;
    }
);

sub _stuf_to_params {
    my ($self, $prs_xml, $stuf_options) = @_;

    my $create_params = $self->_convert_stuf_to_hash(
        $prs_xml,
        STUF_PRS_NP_MAPPING
    );


    $create_params->{geboorteplaats} = GBA_CODE_GEMEENTE->{
        int($create_params->{geboorteplaats})
    };

    $create_params->{geboorteland} = GBA_CODE_LAND->{
        int($create_params->{geboorteland})
    };

    return $create_params;
}

sub _stuf_relaties {
    my ($self, $prs_xml, $stuf_options, $create_options) = @_;

    ### Handle partnerdata
    if (
        $prs_xml->{PRSPRSHUW} &&
        (my $partner = $prs_xml->{PRSPRSHUW}->[0]->{PRS})
    ) {
        my $PARTNER_MAPPING = STUF_PRS_PARTNER_MAPPING;

        my $partner_data    = {};

        $partner_data = $self->_convert_stuf_to_hash(
            $partner,
            $PARTNER_MAPPING
        );

        $partner_data->{datum_huwelijk} = $self->_parse_value(
            $prs_xml->{PRSPRSHUW}->[0]->{datumSluiting}
        );
        $partner_data->{datum_huwelijk_ontbinding} = $self->_parse_value(
            $prs_xml->{PRSPRSHUW}->[0]->{datumOntbinding}
        );

        $create_options->{ $_ } = $partner_data->{ $_ }
            for keys %{ $partner_data };
    }

    ### Handle verblijfsadres
    {
        my ($prsadr, $verblijf);
        if (
            $prs_xml->{PRSADRVBL} &&
            ref($prs_xml->{PRSADRVBL}) &&
            ($verblijf = $prs_xml->{PRSADRVBL}->{ADR})
        ) {
            $prsadr = $verblijf;
            $create_options->{functie_adres} = 'W';
        } elsif (
            $prs_xml->{PRSADRCOR} &&
            ref($prs_xml->{PRSADRCOR}) &&
            ($verblijf = $prs_xml->{PRSADRCOR}->{ADR})
        ) {
            $prsadr = $verblijf;
            $create_options->{functie_adres} = 'B';
        }

        my $adres_data      = $self->_stuf_prs_adres(
            $prsadr
        );

        $create_options->{ $_ } = $adres_data->{ $_ }
            for keys %{ $adres_data };
    }
}

sub _stuf_prs_adres {
    my ($self, $adresxml) = @_;

    my $ADRES_MAPPING = STUF_PRS_ADRES_MAPPING;

    my $adres_data = $self->_convert_stuf_to_hash(
        $adresxml,
        $ADRES_MAPPING
    );

    my $extra_elementen = $self->_convert_stuf_extra_elementen_to_hash(
        $adresxml->{extraElementen}
    );

    if ($extra_elementen->{authentiekeWoonplaatsnaam}) {
        my $mapping         = {
            identificatiecodeVerblijfplaats => 'verblijfsobject_id',
            woonplaatsNaamBAG               => 'woonplaats',
        };

        my $extra   = $self->_convert_stuf_to_hash(
            $extra_elementen,
            $mapping,
        );

        $adres_data->{ $_ }     = $extra->{ $_ }
            for keys %{ $extra };
    }

    return $adres_data;
}

around 'search' => sub {
    my $orig    = shift;
    my $self    = shift;
    my $search  = shift;
    my $opt     = shift;
    my $stuf_options = shift;

    ### Default search
    unless ($opt->{entiteittype}) {
        $opt->{entiteittype}        = 'PRS';
        $opt->{sectormodel}         = 'BG';
        $opt->{versieStUF}          = '0204';
        $opt->{versieSectormodel}   = '0204';
        $opt->{referentienummer}    = $stuf_options->{traffic_object}->id;
        $opt->{tijdstipBericht}     =
            $stuf_options->{traffic_object}->created->strftime('%Y%m%d%H%M%S00');
        $stuf_options->{dispatch_method} = 'ontvangAsynchroneVraag';
    }

    $self->$orig($search, $opt, @_);

};

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

