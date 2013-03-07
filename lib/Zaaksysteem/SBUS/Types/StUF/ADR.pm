package Zaaksysteem::SBUS::Types::StUF::ADR;

use Data::Dumper;
use Moose;

use Zaaksysteem::SBUS::Constants;

extends 'Zaaksysteem::SBUS::Types::StUF::GenericAdapter';

sub _stuf_to_params {
    my ($self, $prs_xml, $stuf_options) = @_;

    my $adres_mapping = STUF_PRS_ADRES_MAPPING;
    return $self->_convert_stuf_to_hash(
        $prs_xml,
        {
            %{ $adres_mapping },
            ingangsdatum        => 'begindatum'
        }
    );
}

sub _stuf_relaties {
    my ($self, $prs_xml, $stuf_options, $create_options) = @_;

    ### Handle real data
    return unless $prs_xml->{extraElementen};

    my $bag         = $self->_convert_stuf_extra_elementen_to_hash(
        $prs_xml->{extraElementen}
    );

    my $mapping     = {
        identificatieWoonplaats         => 'woonplaats',
        identificatieOpenbareRuimte     => 'openbareruimte',
        status                          => 'status',
        identificatieAOA                => 'identificatie',
        identificatieTGO                => 'gebruiksobject_id',
        indicatieAuthentiekAdresCentric => 'officieel',
        adresseerbaarObjectAanduidingTyperingCentric => 'type',
        inOnderzoek                     => 'inonderzoek',
    };

    my $bag_data    = $self->_convert_stuf_to_hash(
        $bag,
        $mapping
    );

    $create_options->{ $_ } = $bag_data->{ $_ }
        for keys %{ $bag_data };
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

