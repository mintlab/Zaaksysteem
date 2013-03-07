package Zaaksysteem::Gegevens::BAG::Import::ImportCentric;

use strict;
use warnings;

use Params::Profile;
use Data::Dumper;
use Zaaksysteem::Constants;

use Moose;
use namespace::autoclean;

use Text::CSV;
use Unicode::String;
use Encode qw/from_to/;

use utf8;

use constant BAG_CSV_TABLE  => [
    qw/
        tmp_einddatum
        tmp_startdatum
        aanduiding
        huisnummer_huisletter
        huisnummer
        huisnummer_toevoeging
        locatiebeschrijving
        postcode
        tmp_straatnaam_uppercase
        straatnaam
        officieel
        inonderzoek
        correctie
        status
        openbareruimte
        tmp_openbareruimte_uppercase
        openbareruimte_id
        nummeraanduiding_id
        aoatype
        tgo_id
        woonplaats_id
        woonplaats
        is_hoofdadres
        begindatum
        einddatum
        is_plusadres
    /
];

use constant BAG_NUMBER_TO_TYPE => {
    1       => 'verblijfsobject',
    2       => 'ligplaats',
    3       => 'standplaats',
};

use constant BAG_CSV_TO_TABLE   => {
    nummeraanduiding    => {
        identificatie       => 'csv_nummeraanduiding_id',
        begindatum          => 'csv_begindatum',
        einddatum           => 'csv_einddatum',
        huisnummer          => 'csv_huisnummer',
        officieel           => 'csv_officieel',
        huisletter          => 'csv_huisletter',
        huisnummertoevoeging => 'csv_huisnummer_toevoeging',
        postcode            => 'csv_postcode',
        woonplaats          => 'csv_woonplaats_id',
        inonderzoek         => 'csv_inonderzoek',
        openbareruimte      => 'csv_openbareruimte_id',
        status              => 'csv_status',
        type                => 'csv_type',

        documentnummer      => 'UNKNOWN',
        documentdatum       => '00000000',
        correctie           => 'N',
    },
    openbareruimte      => {
        identificatie       => 'csv_openbareruimte_id',
        naam                => 'csv_openbareruimte',
        woonplaats          => 'csv_woonplaats_id',

        begindatum          => '00000000',
        #einddatum           => '',
        officieel           => 'N',
        type                => 'Weg',
        status              => 'Naamgeving uitgegeven',
        documentnummer      => 'UNKNOWN',
        documentdatum       => '00000000',
        correctie           => 'N',
        inonderzoek         => 'N',
    },
    woonplaats          => {
        identificatie       => 'csv_woonplaats_id',
        begindatum          => '00000000',
        #einddatum           => '',
        naam                => 'csv_woonplaats',
        officieel           => 'N',
        status              => 'Woonplaats aangewezen',
        inonderzoek         => 'N',
        documentdatum       => '00000000',
        documentnummer      => 'UNKNOWN',
        correctie           => 'N'
    }
};

use constant BAG_CSV_TO_TABLE_OPTIONAL   => {
    verblijfsobject    => {
        identificatie       => 'csv_tgo_id',
        begindatum          => '00000000',
        officieel           => 'N',
        hoofdadres          => 'csv_nummeraanduiding_id',
        oppervlakte         => '0',
        status              => 'Verblijfsobject in gebruik',
        inonderzoek         => 'N',
        documentdatum       => '00000000',
        documentnummer      => 'UNKNOWN',
        correctie           => 'N'
    },
    ligplaats    => {
        identificatie       => 'csv_tgo_id',
        begindatum          => '00000000',
        officieel           => 'N',
        hoofdadres          => 'csv_nummeraanduiding_id',
        status              => 'Ligplaats in gebruik',
        inonderzoek         => 'N',
        documentdatum       => '00000000',
        documentnummer      => 'UNKNOWN',
        correctie           => 'N'
    },
    standplaats    => {
        identificatie       => 'csv_tgo_id',
        begindatum          => '00000000',
        officieel           => 'N',
        hoofdadres          => 'csv_nummeraanduiding_id',
        status              => 'Standplaats in gebruik',
        inonderzoek         => 'N',
        documentdatum       => '00000000',
        documentnummer      => 'UNKNOWN',
        correctie           => 'N'
    },
};



has [qw/prod log dbicg config/] => (
    'weak_ref'  => 1,
    'is'    => 'rw',
);

my $csv_values  = BAG_CSV_TABLE;

Params::Profile->register_profile(
    method  => 'run',
    profile => {
        required            => [],
        optional            => [ @{ $csv_values }, 'type' ],
        defaults            => {
            type => sub {
                my ($dfv)   = @_;

                my $types   = BAG_NUMBER_TO_TYPE;

                my $id      = $dfv->get_filtered_data->{'tgo_id'};

                my $type    = $types->{ substr($id, 5,1) };

                return ucfirst($type);
            },
        }
    }
);

sub run {
    my $self        = shift;

    Unicode::String->stringify_as( 'utf8' );

    my $csv = Text::CSV->new( {
        binary      => 1,
        sep_char    => ';',
        allow_whitespace => 1,
    });

    open (my $fh, '<' . $self->config->{filename}) or return;


    $csv->column_names(BAG_CSV_TABLE);

    while (my $rawrow = $csv->getline_hr($fh)) {
        my $dv  = Params::Profile->check(params => $rawrow);
        my $row = $dv->valid;

        eval {
            $self->dbicg->schema->txn_do(sub {
                $self->_insert_row($row);
            });
        };

        if ($@) {
            $self->log->error(
                'Problems inserting row in BAG: ' . $@
            );
        }
    }

    if (!$csv->eof) {
        $self->log->error(
            'ImportCentric: error: '
            . $csv->error_diag
        );

        close($fh);
        return;
    }

    close($fh);
}

sub _insert_row {
    my ($self, $row) = @_;

    my $table_def       = BAG_CSV_TO_TABLE;
    my $opt_table_def   = BAG_CSV_TO_TABLE_OPTIONAL;

    # UPDATE primary tables
    for my $table (keys %{ $table_def }) {
        my $rs = $self->dbicg->resultset('Bag' . ucfirst($table));

        my $create_opts = $self->_get_database_columns(
            $row,
            $table_def->{$table}
        );

        $rs->update_or_create($create_opts);
    }

    # UPDATE optional tables
    if ($row->{type}) {
        my $rs = $self->dbicg->resultset('Bag' . ucfirst($row->{type}));

        my $create_opts = $self->_get_database_columns(
            $row,
            $opt_table_def->{ lc($row->{type}) }
        );

        $self->log->debug('Added type: ' . $row->{type}
            . Dumper($create_opts)
        );

        $rs->update_or_create($create_opts);
    }
}

sub _get_database_columns {
    my ($self, $row, $table)    = @_;
    my $rv                      = {};

    while (my ($dbcol, $csvcol) = each %{ $table }) {
        # Convert complete row to utf-8
        #$csvcol                 = Unicode::String::latin1( $csvcol );
        my $value;

        if ($csvcol =~ /^csv_/) {
            $csvcol =~ s/^csv_//;
            $value = $row->{$csvcol};
        } else {
            $value = $csvcol;
        }

        from_to($value, 'ISO-8859-1','utf8');

        $rv->{$dbcol}  = $value;
    }

    return $rv;
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

