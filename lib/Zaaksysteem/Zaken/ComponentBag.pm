package Zaaksysteem::Zaken::ComponentBag;

use strict;
use warnings;

use base qw/DBIx::Class/;

sub update_bag {
    my  $self   = shift;
    my  $params = shift;

    if ($params) {
        return 1 unless (
            UNIVERSAL::isa($params, 'HASH') &&
            scalar(%{ $params })
        );
    } else {
        $params = $self;
    }

    my $gegevens_model =
        $self->result_source->schema->resultset('Zaak')->gegevens_model;

    ### Get default resultset
    if (my $fixed_row = $gegevens_model->resultset('BagNummeraanduiding')->_retrieve_zaakbag_data(
            $params
        )
    ) {
        $self->update($fixed_row);
    }
}

sub columns_bag {
    my $self        = shift;
    my %columns_bag;

    my %cols        = $self->get_columns;
    while (my ($colname, $colvalue) = each %cols) {
        next if grep { $colname eq $_ } qw/zaak_id pid id/;

        $colname    =~ s/bag_//;
        $colname    =~ s/_id//;

        $columns_bag{$colname} = $colvalue;
    }

    return %columns_bag;
}

sub _verify_bagdata {
    my $self    = shift;

    my $gegevens_model =
        $self->result_source->schema->resultset('Zaak')->gegevens_model;

    ### Get default resultset
    return $gegevens_model->resultset('BagNummeraanduiding')->_retrieve_zaakbag_data(
        $self,
        @_
    );
}

sub maps_adres {
    my $self    = shift;

    return '' unless $self->bag_nummeraanduiding_id;

    my $gegevens_model =
        $self->result_source->schema->resultset('Zaak')->gegevens_model;

    ### Get gegevens_model
    my $nummeraanduiding    = $gegevens_model->resultset('BagNummeraanduiding')->search(
        identificatie   => $self->bag_nummeraanduiding_id
    )->first or return '';

    return '' unless $nummeraanduiding->openbareruimte;

    return 'Netherlands, '
        . $nummeraanduiding->openbareruimte->woonplaats->naam . ', '
        . $nummeraanduiding->openbareruimte->naam . ', '
        . $nummeraanduiding->huisnummer;
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

