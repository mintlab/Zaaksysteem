package Zaaksysteem::Model::Beheer::Import::KVK::KVKCsv;
use Moose;
use namespace::autoclean;

use Text::CSV;
use utf8;

has ['c','options'] => (
    'is'    => 'rw'
);

sub search {
    my ($self, $search)     = @_;

    my $it_class            = __PACKAGE__ . '::_Iterator';

    my $data                = $self->_load_file or return;

    $it_class->new(
        'data'  => $data,
    );
}
sub _load_file {
    my ($self)  = @_;
    my $data    = [];

    my $csv = Text::CSV->new( {
        binary      => 1,
        sep_char    => ','
    });

    open (my $fh, '<:encoding(iso-8859-1)', $self->options->{filename}) or return;
    while (my $row = $csv->getline($fh)) {
        push (@{ $data }, $row);
    }

    $csv->eof or $self->c->log->error(
        'B::I::KVK::KVKCsv import CSV error: '
        . $csv->error_diag
    );

    close($fh);

    return $data;
}


__PACKAGE__->meta->make_immutable;

package Zaaksysteem::Model::Beheer::Import::KVK::KVKCsv::_Iterator;

use strict;
use Moose;
use namespace::autoclean;

use Text::CSV;

use constant    CSV_MAP   => [qw/
        tmp01
        tmp02
        tmp1
        tmp2
        tmp3
        vorig_dossiernummer
        vorig_subdossiernummer
        tmp4
        dossiernummer
        subdossiernummer
        tmp5
        handelsnaam
        tmp6
        tmp7
        tmp8
        tmp9
        tmp10
        tmp11
        vestiging_adres
        tmp12
        vestiging_straatnaam
        tmp13
        vestiging_huisnummer
        tmp14
        vestiging_huisnummertoevoeging
        tmp15
        vestiging_postcodewoonplaats
        tmp16
        vestiging_postcode
        tmp17
        vestiging_woonplaats
        tmp18
        tmp19
        vestigingsstatus
        correspondentie_adres
        tmp20
        correspondentie_straatnaam
        tmp21
        correspondentie_huisnummer
        tmp22
        correspondentie_huisnummertoevoeging
        tmp23
        correspondentie_postcodewoonplaats
        tmp24
        correspondentie_postcode
        tmp25
        correspondentie_woonplaats
        tmp26
        rechtsvorm
        tmp27
        hoofdactiviteitencode
        nevenactiviteitencode1
        nevenactiviteitencode2
        tmp30
        werkzamepersonen
        tmp31
        telefoonnummer_netnummer
        telefoonnummer_nummer
        tmp32
        faillissement
        tmp33
        surseance
        tmp34
        kamernummer
        tmp36
        tmp37
        tmp38
        tmp381
        tmp382
        tmp383
        tmp41
        tmp40
        contact_naam
        tmp385
        tmp386
        tmp387
        contact_aanspreektitel
        tmp39
        tmp391
        tmp392
        contact_voorletters
        contact_voorvoegsel
        contact_geslachtsnaam
        tmp41
        contact_geslachtsaanduiding
/];

has 'data'      => (
    'is'    => 'rw',
);

has '_pointer'  => (
    'is'        => 'rw',
    'default'   => sub { return 1; },
);

sub next {
    my ($self) = @_;

    $self->_pointer(
        $self->_pointer + 1
    );

    if ($self->data->[$self->_pointer]) {
        return $self->_parse_entry($self->data->[$self->_pointer]);
    }

    return;
}

sub _parse_entry {
    my ($self, $data) = @_;
    my $rv;

    my $csv_map     = CSV_MAP;

    for (my $i = 0; $i < scalar(@{ $csv_map }); $i++) {
        my $field   = $self->_parse_field($data->[$i]);

        next unless $field;
        next if ($csv_map->[$i] =~ /^tmp.*/);

        if (
            $csv_map->[$i] eq 'vestiging_huisnummer' ||
            $csv_map->[$i] eq 'correspondentie_huisnummer'
        ) {
            $field =~ s/^0*//g;
        }

        $rv->{ $csv_map->[$i] } = $field;
    }

    return $rv;
}

sub _parse_field {
    my ($self, $field) = @_;


    $field =~ s/^\s+//;
    $field =~ s/\s+$//;

    return $field;
}

sub count {
    my ($self) = @_;

    if ($self->data && @{ $self->data }) {
        return scalar(@{ $self->data });
    }

    return 0;
}


__PACKAGE__->meta->make_immutable;
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

