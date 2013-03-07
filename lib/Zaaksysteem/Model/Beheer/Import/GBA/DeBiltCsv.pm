package Zaaksysteem::Model::Beheer::Import::GBA::DeBiltCsv;
use Moose;
use namespace::autoclean;
use Data::Dumper;

use Text::CSV;
use Unicode::String;

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
        'log'   => $self->c->log,
    );
}
sub _load_file {
    my ($self)  = @_;
    my $data    = [];

    my $csv = Text::CSV->new( {
        binary      => 1,
        sep_char    => ';',
        allow_whitespace => 1,
    });

    open (my $fh, '<' . $self->options->{filename}) or return;
    while (my $row = $csv->getline($fh)) {
        # Convert complete row to utf-8

        push (@{ $data }, $row);
    }

    if (!$csv->eof) {
        $self->c->log->error(
            'B::I::GBA::BussumCsv import CSV error: '
            . $csv->error_diag
        );

        close($fh);
        return;
    }

    close($fh);

    return $data;
}

has 'capabilities'  => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return {
            'missing_is_verhuisd' => 1,
        };
    }
);


__PACKAGE__->meta->make_immutable;

package Zaaksysteem::Model::Beheer::Import::GBA::DeBiltCsv::_Iterator;

use strict;
use Moose;
use namespace::autoclean;

use Text::CSV;
use Data::Dumper;
use Encode qw/from_to/;

use constant    CSV_MAP   => [qw/
    a_nummer
    burgerservicenummer
    status
    voornamen
    tmp_adelijke_titel
    voorvoegsel
    geslachtsnaam
    geboortedatum
    geboorteplaats
    tmp_geboorteplaats_buitenland
    geboorteland
    geslachtsaanduiding
    onderzoek_persoon
    onderzoek_persoon_ingang
    onderzoek_persoon_einde
    onderzoek_persoon_onjuist
    aanduiding_naamgebruik
    tmp_tmp_anummer_partner
    partner_burgerservicenummer
    partner_voorvoegsel
    partner_geslachtsnaam
    tmp_datum_huwelijk
    tmp_datum_scheiding
    onderzoek_huwelijk
    onderzoek_huwelijk_ingang
    onderzoek_huwelijk_einde
    onderzoek_huwelijk_onjuist
    datum_overlijden
    onderzoek_overlijden
    onderzoek_overlijden_ingang
    onderzoek_overlijden_einde
    onderzoek_overlijden_onjuist
    tmp_geheim
    tmp_gemeente_inschrijving
    tmp_datum_inschrijving
    functie_adres
    woonplaats
    tmp_datum_adreshouding
    straatnaam
    huisnummer
    huisletter
    huisnummertoevoeging
    tmp_huisnummer_aanduiding_bij_huisnummer
    postcode
    tmp_locatiebeschrijving
    tmp_land_waarnaar_vertrokken
    tmp_datum_exit
    adres_buitenland1
    adres_buitenland2
    adres_buitenland3
    onderzoek_verblijfplaats
    onderzoek_verblijfplaats_ingang
    onderzoek_verblijfplaats_einde
    onderzoek_verblijfplaats_onjuist
/];

has 'data'      => (
    'is'    => 'rw',
);

has 'log'      => (
    'is'    => 'rw',
);

has '_pointer'  => (
    'is'        => 'rw',
    'default'   => sub { return 0; },
);

sub count {
    my ($self) = @_;

    return 0 unless (
        $self->data &&
        UNIVERSAL::isa($self->data, 'ARRAY')
    );

    return scalar(@{ $self->data });
}

sub next {
    my ($self) = @_;

    $self->_pointer(
        $self->_pointer + 1
    );

    #if ($self->data->[($self->_pointer - 1)]) {
    my $entry;

    while (
        $self->data->[($self->_pointer - 1)] &&
        !(
            $entry =
                $self->_parse_entry($self->data->[($self->_pointer - 1)])
        )
    ) {
        $self->_pointer(
            $self->_pointer + 1
        );
    }

    return $entry;
}

sub _parse_entry {
    my ($self, $data) = @_;
    my $rv;

    my $csv_map     = CSV_MAP;

    #Unicode::String->stringify_as( 'utf8' );

    eval {
        for (my $i = 0; $i < scalar(@{ $csv_map }); $i++) {
            my $field      = $self->_parse_field($data->[$i]);

            next unless $field;

            next if ($csv_map->[$i] =~ /^tmp.*/);

            $rv->{ $csv_map->[$i] } = $field;
        }
    };

    if ($@) {
        $self->log->error(
            'Problem importing csv row: ' . $@
        );
        #warn('Problem importing csv row: ' . $@);

        return;
    }

    $self->_special_cases($rv);

    return $rv;
}

sub _special_cases {
    my ($self, $rv) = @_;

    ## Remove starting numbers
    $rv->{huisnummer} =~ s/^0*//g
        if $rv->{huisnummer};

    for my $field (qw/
        onderzoek_persoon_ingang
        onderzoek_persoon_einde
        onderzoek_huwelijk_ingang
        onderzoek_huwelijk_einde
        onderzoek_overlijden_ingang
        onderzoek_overlijden_einde
        onderzoek_verblijfplaats_ingang
        onderzoek_verblijfplaats_einde
        datum_overlijden
    /) {
        if (!$rv->{$field} || $rv->{$field} =~ /^[0 ]+$/) {
            $rv->{$field} = undef;
        } else {
            my ($year, $month, $day) = $rv->{$field} =~
                /^(\d{4})(\d{2})(\d{2})$/;

            if ($year && $month && $day) {
                $rv->{$field} = DateTime->new(
                    'year'  => $year,
                    'month' => $month,
                    'day'   => $day
                );
            } else {
                $rv->{$field}    = undef;
            }
        }
    }

    ### BOOLEANS
    for my $field (qw/
        onderzoek_persoon
        onderzoek_huwelijk
        onderzoek_overlijden
        onderzoek_verblijfplaats
        onderzoek_persoon_onjuist
        onderzoek_huwelijk_onjuist
        onderzoek_overlijden_onjuist
        onderzoek_verblijfplaats_onjuist
    /) {
        if ($rv->{$field}) {
            $rv->{$field} = 1;
        } else {
            $rv->{$field} = 0;
        }
    }

    ### Status overlijden
    if ($rv->{datum_overlijden}) {
        $rv->{status}       = 2;
    }

    if (!$rv->{postcode}) {
        $rv->{straatnaam}   = 'unknown';
        $rv->{huisnummer}   = 9999;
        $rv->{postcode}     = '9999UN';
    }

    ### Woonplaats
    #$rv->{woonplaats} = 'Bussum';
}

sub _parse_field {
    my ($self, $field) = @_;

    from_to($field, 'iso-8859-1','utf8');

    $field =~ s/^\s+//;
    $field =~ s/\s+$//;

    return $field;
}

#sub count {
#    my ($self) = @_;
#
#    if ($self->data && @{ $self->data }) {
#        return scalar(@{ $self->data });
#    }
#
#    return 0;
#}


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

