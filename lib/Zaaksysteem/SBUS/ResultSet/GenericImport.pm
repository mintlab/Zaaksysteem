package Zaaksysteem::SBUS::ResultSet::GenericImport;

use Moose;

extends 'DBIx::Class::ResultSet';

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


sub import_entries {
    my $self        = shift;
    my $c           = shift;
    my $records     = shift;

    die('Records not ARRAYREF')
        unless UNIVERSAL::isa($records, 'ARRAY');

    my $logging = Zaaksysteem::SBUS::Logging::Objecten->new();

    for my $record (@{ $records }) {
        unless (
            UNIVERSAL::isa($record, 'HASH') ||
            !exists($record->{options}) ||
            !exists($record->{params})
        ) {
            die('Record not HASHREF or does not contain options and params');
        }

        my $result = $self->import_entry(
            $record->{params},
            $record->{options}
        );

        $logging->object($result);
    }

    return $logging;
}

sub import_entry {
    my $self        = shift;
    my $c           = shift;
    my $raw_params  = shift;
    my ($options)   = @_;
    my $params;

    Params::Profile->register_profile(
        method  => 'import_entry',
        profile => $self->_import_entry_profile,
    );

    ### VALIDATION
    my $dv;
    {
        $dv = Params::Profile->check(
            params  => $raw_params,
        );

        $params = $dv->valid;

        ### XXX KERNGEGEVENS CHECK
    }

    ### Check mutatieType (create/delete/edit)
    $self->_check_mutatie_type( $params, @_ );

    ### Die when mutatietype is T and not all options
    ### are given
    die(
        'Z::Import::GBA: invalid parameters:'
        . Dumper($dv)
    ) unless (
        $options->{mutatie_type} ne 'T' ||
        $dv->success
    );

    unless ($options->{logobject}) {
        $options->{logobject} = Zaaksysteem::SBUS::Logging::Object->new()
    }

    my $label   = $self->_import_kerngegeven_label;

    $options->{logobject}->mutatie_type(uc($options->{mutatie_type}));
    $options->{logobject}->object_type($self->_import_objecttype);
    $options->{logobject}->label($params->{ $label });
    $options->{logobject}->params($params);

    $c->log->info(
        'Import ' . $self->_import_objecttype
        . ' entry: ' . $params->{ $label }
    );

    ### Update or create entry

    eval {
        $self->result_source->schema->txn_do(sub {
            $self->_import_real_entry($params, $options);

            if (uc($options->{mutatie_type}) eq 'V') {
                $self->_delete_real_entry($params, $options);
            }
        });
    };

    if ($@) {
        $options->{logobject}->error('Import error: ' . $@);
        warn('IMPORT ERROR: ' . $@);
    }

    return $options->{logobject};
}


sub _get_kern_record {
    my ($self, $params, $options) = @_;

    my $IMPORT_KERNGEGEVENS = $self->_import_kerngegevens;

    my $search  = {
        map { $_ => $params->{ $_ } } @{ $IMPORT_KERNGEGEVENS }
    };

    ### Check against database
    my $records = $self->search($search);

    return $records->first;
}

sub _detect_changes {
    my ($self, $params, $options, $record) = @_;

    for my $param (keys %{ $params }) {
        my ($old, $new) = ('','');
        $old = $record->$param if $record && $record->$param;
        $new = $params->{$param} if $params->{$param};

        if ($old ne $new) {
            $options->{logobject}->change({
                column  => $param,
                old     => $old,
                new     => $new,
            });
        }
    }
}


sub _check_mutatie_type {
    my ($self, $params, $options) = @_;

    ### Verwijderd?
    if (
        $params->{datum_overlijden} ||
        $options->{verhuisd} ||
        uc($options->{mutatie_type}) eq 'V'
    ) {
        $options->{mutatie_type}    = 'V';
        return;
    }

    ### Toevoegen of wijzigen?
    my $IMPORT_KERNGEGEVENS = $self->_import_kerngegevens;

    ### Check against database
    my $records = $self->search(
        { map { $_ => $params->{ $_ } } @{ $IMPORT_KERNGEGEVENS } }
    );

    if ($records->count) {
        $options->{mutatie_type}    = 'W';
        return;
    }

    $options->{mutatie_type}        = 'T';
    return;
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

