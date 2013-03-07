package Zaaksysteem::SBUS::ResultSet::BAG;

use Moose;

extends qw/Zaaksysteem::SBUS::ResultSet::GenericImport/;

use Zaaksysteem::Constants;
use Zaaksysteem::SBUS::Constants;
use Zaaksysteem::SBUS::Logging::Object;
use Zaaksysteem::SBUS::Logging::Objecten;

use Data::Dumper;

use constant IMPORT_KERNGEGEVENS   => [qw/
    identificatie
/];

use constant IMPORT_KERNGEGEVEN_LABEL   => 'identificatie';

use constant BAG_PROFILE            => {
    'ADR'       => {
        required    => [qw/
            identificatie
            woonplaats
            openbareruimte
            postcode
            begindatum
            huisnummer
            officieel
            status
            inonderzoek
        /],
        optional    => [qw/
            huisletter
            huisnummertoevoeging

            correctie
            documentnummer
            documentdatum
            type
            einddatum
            gebruiksobject_id
        /],
        defaults    => {
            'correctie'         => 'N',
            'documentnummer'    => '',
            'documentdatum'     => '',
        },
        field_filters   => {
            'begindatum'    => sub {
                ### Todo, postfix with zero's
                return shift;
            },
            'einddatum'     => sub {
                ### Todo, postfix with zero's
                return shift;
            },
        }
    },
    'R02'       => {
        required    => [qw/
            identificatie
            naam
            woonplaats
            begindatum
            officieel
        /],
        optional    => [qw/
            inonderzoek
            correctie
            documentnummer
            documentdatum
            type
            einddatum
            status
        /],
        defaults    => {
            'correctie'         => 'N',
            'documentnummer'    => '',
            'documentdatum'     => '',
            'type'              => 'Weg',
            'inonderzoek'       => 'N',
            'officieel'         => 'N',
            'status'            => 'Naamgeving uitgegeven',
        },
        field_filters   => {
            'begindatum'    => sub {
                ### Todo, postfix with zero's
                return shift;
            },
            'einddatum'     => sub {
                ### Todo, postfix with zero's
                return shift;
            },
        }
    },
    'R03'       => {
        required    => [qw/
            identificatie
            naam
            begindatum
            officieel
        /],
        optional    => [qw/
            inonderzoek
            correctie
            documentnummer
            documentdatum
            einddatum
            status
        /],
        defaults    => {
            'correctie'         => 'N',
            'documentnummer'    => '',
            'documentdatum'     => '',
            'inonderzoek'       => 'N',
            'officieel'         => 'N',
            'status'            => 'Woonplaats aangewezen',
        },
        field_filters   => {
            'begindatum'    => sub {
                ### Todo, postfix with zero's
                return shift;
            },
            'einddatum'     => sub {
                ### Todo, postfix with zero's
                return shift;
            },
        }
    },
};

use constant BAG_MINIMAL_GEBRUIKSOBJECT_COLUMNS => [qw/
    begindatum
    einddatum
    officieel
    status
    inonderzoek
    documentdatum
    documentnummer
    correctie
/];

use constant BAG_DEFAULT_BEGINDATUM => '00000000000000';
use constant BAG_DEFAULT_STATUS     => 'Onbekend';


has '_import_kerngegevens'  => (
    'is'        => 'ro',
    'lazy'      => 1,
    default     => sub {
        return IMPORT_KERNGEGEVENS;
    }
);

has '_import_kerngegeven_label'  => (
    'is'        => 'ro',
    'lazy'      => 1,
    default     => sub {
        return IMPORT_KERNGEGEVEN_LABEL;
    }
);

has '_import_objecttype'  => (
    'is'        => 'rw',
    'lazy'      => 1,
    default     => sub {
        return SBUS_LOGOBJECT_PRS;
    }
);

has '_import_entry_profile' => (
    'is'        => 'rw',
    'lazy'      => 1,
    default     => sub {
        return {};
    }
);

around 'import_entry'   => sub {
    my $orig                = shift;
    my $class               = shift;
    my ($c, $raw_params)    = @_;

    $class->_import_entry_profile(
        BAG_PROFILE->{ $raw_params->{ object_type } }
    );

    $class->_import_objecttype(
        $raw_params->{object_type}
    );

    $class->$orig(@_);
};

sub _delete_real_entry {
    my ($self, $params, $options) = @_;

    my $record = $self->_get_kern_record($params, @_);

    ### record not found in the first place, not in ZS
    return unless $record;

    $record->delete;
}

sub _import_real_entry {
    my $self                        = shift;
    my ($input_params, $options)    = @_;
    my ($record);

    ### Clone and delete gebruiksobject_id, use this for below relatie
    my $params = { %{ $input_params } };

    delete($params->{gebruiksobject_id});

    if (uc($options->{mutatie_type}) =~ /W|V/) {
        $record = $self->_get_kern_record($params, @_);

        unless ($record) {
            warn(
                $self->_import_objecttype . '-Entry niet gevonden in database: ' .
                $params->{ $self->_import_kerngegeven_label }
            );
            return;
        }
    }

    ### Detect changes
    $self->_detect_changes($params, $options, $record);

    if ($record) {
        $record->update($params);
    } else {
        $record = $self->update_or_create($params);
    }

    ### In case of gebruiksobject_id (ADR), update verblijfsobject,ligplaats etc
    $self->_import_real_entry_relatie($record, @_);

    return $record;
}

sub _import_real_entry_relatie {
    my $self                                = shift;
    my ($record, $input_params, $options)   = @_;

    return unless (
        $input_params->{type} &&
        exists($input_params->{gebruiksobject_id}) &&
        $input_params->{gebruiksobject_id}
    );

    my $method = lc($input_params->{type}) . 'en';

    if ($record->can($method)) {
        my $MINIMAL_GEBRUIKSOBJECT_COLUMNS =
                    BAG_MINIMAL_GEBRUIKSOBJECT_COLUMNS;

        my $gebruiksobject_params = {
            map { $_  => $input_params->{ $_ } }
            @{ $MINIMAL_GEBRUIKSOBJECT_COLUMNS }
        };

        $gebruiksobject_params->{identificatie} = $input_params->{gebruiksobject_id};
        $gebruiksobject_params->{hoofdadres}    = $input_params->{identificatie};
        $gebruiksobject_params->{status}        = BAG_DEFAULT_STATUS;
        $gebruiksobject_params->{begindatum}    = BAG_DEFAULT_BEGINDATUM;

        if (lc($input_params->{type}) eq 'verblijfsobject') {
            $gebruiksobject_params->{oppervlakte} = 0;
        }

        if (
            (my $gebruiksobject =
                $record->$method->update_or_create($gebruiksobject_params)
            ) && lc($input_params->{type}) eq 'verblijfsobject'
        ) {
            $self->result_source
                ->schema
                ->resultset('BagVerblijfsobjectGebruiksdoel')
                ->update_or_create({
                    identificatie   => $input_params->{gebruiksobject_id},
                    begindatum      => BAG_DEFAULT_BEGINDATUM,
                    gebruiksdoel    => BAG_DEFAULT_STATUS,
                    correctie       => 'N',
                });
        }
    } else {
        warn('Cannot find method ' . $method);
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

