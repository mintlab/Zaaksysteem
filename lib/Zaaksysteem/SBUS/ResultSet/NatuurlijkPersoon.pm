package Zaaksysteem::SBUS::ResultSet::NatuurlijkPersoon;

use Moose;

extends qw/DBIx::Class::ResultSet Zaaksysteem::SBUS::ResultSet::GenericImport/;

use Zaaksysteem::Constants;
use Zaaksysteem::SBUS::Constants;
use Zaaksysteem::SBUS::Logging::Object;
use Zaaksysteem::SBUS::Logging::Objecten;

use Data::Dumper;

use constant IMPORT_KERNGEGEVENS   => [qw/
    burgerservicenummer
    a_nummer
/];

use constant IMPORT_KERNGEGEVEN_LABEL   => 'burgerservicenummer';


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
    'is'        => 'ro',
    'lazy'      => 1,
    default     => sub {
        return SBUS_LOGOBJECT_PRS;
    }
);

has '_import_entry_profile' => (
    'is'        => 'ro',
    'lazy'      => 1,
    default     => sub {
        return GEGEVENSMAGAZIJN_GBA_PROFILE;
    }
);

sub _delete_real_entry {
    my ($self, $params, $options) = @_;

    my $record = $self->_get_kern_record($params, @_);

    ### XXX
    return;

    ### record not found in the first place, not in ZS
    return unless $record;

    $record->adres_id->deleted_on(DateTime->now(
            'time_zone' => 'Europe/Amsterdam',
    ));

    $record->adres_id->update;

    $record->deleted_on(DateTime->now(
            'time_zone' => 'Europe/Amsterdam',
    ));

    $record->update;
}

sub _import_real_entry {
    my ($self, $params, $options) = @_;
    my ($record, $adres_record);

    if (uc($options->{mutatie_type}) =~ /W|V/) {
        $record = $self->_get_kern_record($params, @_);

        unless ($record) {
            warn(
                'Persoon niet gevonden in database: ' .
                $params->{burgerservicenummer}
            );
            return;
        }

        if (ref($record->adres_id)) {
            $adres_record   = $record->adres_id;
        }
    } else {
        my $GBA_KERNGEGEVENS = IMPORT_KERNGEGEVENS;

        $record = $self->create(
            { map { $_ => $params->{ $_ } } @{ $GBA_KERNGEGEVENS } }
        );
    }

    if (!$adres_record) {
        $adres_record   = $self->result_source
            ->schema
            ->resultset('Adres')
            ->create({});
    }

    my $GEGEVENSMAGAZIJN_GBA_ADRES_EXCLUDES
        = GEGEVENSMAGAZIJN_GBA_ADRES_EXCLUDES;


    ### Alleen adres params
    my ($adres_params, $gba_params) = ({},{});
    for my $param (keys %{ $params }) {
        if (grep { $param eq $_ } @{ $GEGEVENSMAGAZIJN_GBA_ADRES_EXCLUDES }) {
            $adres_params->{$param} = $params->{$param};
            next
        }
        $gba_params->{$param} = $params->{$param};
    }

    ### Detect changes
    $self->_detect_changes($adres_params, $options, $adres_record);

    ### Detect changes
    $self->_detect_changes($gba_params, $options, $record);


    $gba_params->{adres_id}         = $adres_record->id;
    $gba_params->{authenticated}    = 1;
    $gba_params->{authenticatedby}  = 'gba';


    $adres_record   ->update($adres_params);
    $record         ->update($gba_params);
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

