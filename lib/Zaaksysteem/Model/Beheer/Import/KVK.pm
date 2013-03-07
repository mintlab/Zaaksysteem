package Zaaksysteem::Model::Beheer::Import::KVK;
use Moose;
use namespace::autoclean;

use DateTime;
use GnuPG::Interface;
use Fcntl;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;

use Data::Dumper;

use Zaaksysteem::Constants qw/
    GEGEVENSMAGAZIJN_KVK_PROFILE
/;

extends 'Catalyst::Model';

has 'c' => (
    'is'    => 'rw'
);

has 'import_rv' => (
    'is'    => 'rw',
);

has 'options'   => (
    'is'    => 'rw'
);

{
    Zaaksysteem->register_profile(
        method  => 'import',
        profile => {
            required => [ qw/
                type
                options
            /],
            optional => [ qw/
            /],
            constraint_methods => {
                filename    => qr/^[\w]+$/,
            },
        }
    );

    sub import {
        my ($self, %params) = @_;
        my ($ic);

        my $dv = $self->c->check(
            params  => \%params,
        );

        return unless $dv->success;

        $self->options($dv->valid('options'));

        ### Load filename
        {
            $self->c->log->debug(
                'B::I::KVK: Loading import system for type'
                . $dv->valid('type')
            );

            return unless ($ic = $self->_load_import_system($dv));

            $self->c->log->debug(
                'B::I::KVK: Loaded import system ' . $dv->valid('type')
            );
        }

        my $search = $ic->search;

        if ($search->count) {
            my $entrycount = 0;

            $self->import_rv($self->c->model('DB::BeheerImport')->create({
                'importtype'      => 'KVK',
            }));

            eval {
                $self->c->log->info('B::I::KVK: Import start');
                $self->c->model('DBG')->txn_do(sub {
                    while (my $entry  = $search->next) {
                        if ($entry->{handelsnaam} !~ /Winetracks International/) {
                            $self->_import_entry($entry);
                        }
                        $entrycount++;
                    }
                    #die('rollback');
                });

                $self->c->log->info('B::I::KVK: Import succesvol');
                $self->import_rv->succesvol(1);
                $self->import_rv->entries($entrycount);
                $self->import_rv->finished(DateTime->now());
                $self->import_rv->update;
            };

            if ($@) {
                my $errormsg = 'B::I::KVK: Import failure: ' . $@;
                $self->c->log->error($errormsg);
                $self->import_rv->error(1);
                $self->import_rv->error_message(
                    $errormsg
                );

                $self->import_rv->update;
            }
        }
    }
}


{
    Zaaksysteem->register_profile(
        method  => '_import_entry',
        profile => GEGEVENSMAGAZIJN_KVK_PROFILE
    );

    sub _import_entry {
        my ($self, $raw_entry) = @_;

        my $dv = $self->c->check(
            params  => $raw_entry
        );

        unless ($dv->success) {
            $self->c->log->debug(
                'Failed loading import entry, missing params: '
                . join("\n - ", $dv->missing)
                . "\nInvalid params: "
                . join("\n - ", $dv->invalid)
            );
            return;
        }

        ### Valid entry, load into database
        my $entry   = $dv->valid;
        $entry->{authenticated} = 1;

        $self->c->log->debug('Verstigingsstatus: ' .
            lc($raw_entry->{vestigingsstatus}));
        if (
            lc($raw_entry->{vestigingsstatus}) eq 'd' ||
            lc($raw_entry->{vestigingsstatus}) eq 'e' ||
            lc($raw_entry->{vestigingsstatus}) eq 'h'
        ) {
            my $delete_result = $self->_delete_from_database($entry);
        } else {
            my $import_result = $self->_import_into_database($entry);

            $self->_log_changed($import_result, $entry);
        }


    }
}

sub _delete_from_database {
    my ($self, $entry)  = @_;
    my $whats_changed   = {};

    ### Search by burgerservicenummer
    my $rows = $self->c->model('DBG::Bedrijf')->search({
        'fulldossiernummer'     => $entry->{fulldossiernummer},
        'authenticated'         => 1,
        'deleted_on'            => undef
    });

    if ($rows->count) {
        $self->c->log->debug('Start deleting entry: ' .
            $entry->{fulldossiernummer}
        );

        while (my $row = $rows->next) {
            $row->deleted_on(DateTime->now(
                    'time_zone' => 'Europe/Amsterdam',
            ));
            if ($row->update) {
                $whats_changed->{del_record} = 1;

                $self->_log_changed($whats_changed, $entry);
            }
        }
    }

    return $whats_changed;
}

sub _log_changed {
    my ($self, $changes, $entry) = @_;

    return unless UNIVERSAL::isa($changes, 'HASH');

    if ($changes->{del_record}) {
        $self->c->log->debug(
            'Deleted record with data_id: '
            . $entry->{fulldossiernummer}
        );

        $self->import_rv->beheer_import_logs->create({
            'identifier'    => $entry->{fulldossiernummer},
            'action'        => 'delete',
        });
    } elsif ($changes->{new_record}) {
        $self->c->log->debug(
            'Added new record with data_id: '
            . $entry->{dossiernummer}
        );

        $self->import_rv->beheer_import_logs->create({
            'identifier'    => $entry->{fulldossiernummer},
            'action'        => 'create',
        });
    } elsif (%{ $changes } && scalar(keys %{ $changes })) {
        $self->c->log->debug(
            'Added changed record with data_id: '
            . $entry->{dossiernummer} . "\nChanges:",
            join("\n- ", keys %{ $changes })
        );

        while (my ($kolom, $update_info) = each %{ $changes }) {
            $self->import_rv->beheer_import_logs->create({
                'identifier'    => $entry->{dossiernummer},
                'kolom'         => $kolom,
                'old_data'      => $update_info->{old},
                'new_data'      => $update_info->{new},
            });
        }
    }

    return 1;
}

sub _import_into_database {
    my ($self, $entry) = @_;
    my %update          = %{ $entry };
    my $whats_changed    = {};

    ### Search by burgerservicenummer
    my $rows = $self->c->model('DBG::Bedrijf')->search({
        'fulldossiernummer'     => $entry->{fulldossiernummer},
        'authenticated'         => 1,
    });

    return unless $rows;

    if ($rows->count) {
        ### This is an update query
        my $row = $rows->first;

        my %bedrijf   = %{ $entry };

        while (my ($entry_key, $entry_value) = each %bedrijf) {
            if ($row->$entry_key eq $entry_value) {
                delete($bedrijf{$entry_key});
                next;
            }
            $whats_changed->{$entry_key} = {
                'old'   => $row->$entry_key,
                'new'   => $entry_value,
            };
        }

        ### Update when needed
        if (%bedrijf && scalar(keys(%bedrijf))) {
            $self->c->log->info('Updating KVK entry: ' .
                $entry->{dossiernummer});

            $row->update(\%bedrijf)
        }

        return $whats_changed;
    } else {
        #### This is an insert
        my %bedrijf = %{ $entry };

        if (my $create = $self->c->model('DBG::Bedrijf')->create(
                {
                    %bedrijf,
                }
            )
        ) {
            $whats_changed->{new_record} = 1;
        }

        return $whats_changed;
    }

    return;
}

sub _load_import_system {
    my ($self, $dv) = @_;
    my ($ic);
    my $gba_type    = ucfirst($dv->valid('type'));

    my $class       = __PACKAGE__ . '::' . $gba_type;

    eval {
        $ic = $class->new(
            c       => $self->c,
            options => $self->options
        );
    };

    if ($@) {
        $self->c->log->error(
            'Failed loading GBA-Import type: ' .
            $gba_type . ':' . $@
        );

        return;
    }

    $self->c->log->info('Loading GBA-Import type: ' . $gba_type);

    return $ic;
}



sub ACCEPT_CONTEXT {
    my ($self, $c) = @_;

    $self->c($c);

    return $self;
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

