package Zaaksysteem::Model::Beheer::Import::GBA;
use Moose;
use namespace::autoclean;

use DateTime;
use GnuPG::Interface;
use Fcntl;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;

use Data::Dumper;

use Zaaksysteem::Constants qw/
    GEGEVENSMAGAZIJN_GBA_PROFILE
    GEGEVENSMAGAZIJN_GBA_ADRES_EXCLUDES
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

        ### Prepare input
        {
            $self->_decrypt_gba or return;
            $self->_gunzip_gba or return;
        }

        ### Load filename
        {
            $self->c->log->debug(
                'B::I::GBA: Loading import system for type'
                . $dv->valid('type')
            );

            return unless ($ic = $self->_load_import_system($dv));

            $self->c->log->debug(
                'B::I::GBA: Loaded import system ' . $dv->valid('type')
            );
        }

        my $search = $ic->search;

        if ($search->count) {
            my $entrycount = 0;

            $self->import_rv($self->c->model('DB::BeheerImport')->create({
                'importtype'      => 'GBA',
            }));

            eval {
                $self->c->log->info('B::I::GBA: Import start: ' .  $search->count);
                my %done_bsns   = ();

                $self->c->model('DBG')->txn_do(sub {
                    my $totalcount  = $search->count;
                    my $options = {
                        burgerservicenummers => {},
                    };
                    while (my $entry  = $search->next) {
                        $self->_import_entry($entry, $options);
                        $entrycount++;
                        warn 'Counter: ' . sprintf('%10d', $entrycount) . '/'
                        . sprintf('%10d', $totalcount);

                        if ($ic->capabilities->{missing_is_verhuisd}) {
                            $done_bsns{$entry->{burgerservicenummer}} = 1;
                        }
                    }
                    #die('rollback');
                });

                if ($ic->capabilities->{missing_is_verhuisd}) {
                    $self->_remove_missing(\%done_bsns);
                }

                $self->c->log->info('B::I::GBA: Import succesvol');
                $self->import_rv->succesvol(1);
                $self->import_rv->entries($entrycount);
                $self->import_rv->finished(DateTime->now());
                $self->import_rv->update;
            };

            if ($@) {
                my $errormsg = 'B::I::GBA: Import failure: ' . $@;
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

sub _gunzip_gba {
    my ($self, $options) = @_;

    if (
        exists($self->options->{filename}) &&
        $self->options->{filename} =~ /\.gz/
    ) {
        my $output_file             = $self->options->{filename};
        $output_file                =~ s/\.gz//;

        my $status =
            gunzip (
                $self->options->{filename} => $output_file
            );

        $self->c->log->debug('Unzipping: ' . $self->options->{filename} . " =>
            " . $output_file);

        if (!$status) {
            $self->c->log->error("gunzip failed: $GunzipError\n");
            return;
        }

        $self->options->{filename}  = $output_file;

        $self->c->log->debug('Unzipping');
    }

    return 1;
}

sub _decrypt_gba {
    my ($self) = @_;

    if (
        $self->options->{filename} =~ /\.gpg/
    ) {
        my $output_file             = $self->options->{filename};
        $output_file                =~ s/\.gpg//;

        eval {
            my $return = system(
                '/usr/bin/gpg -d '
                . $self->options->{filename}
                . ' > ' . $output_file);
        };

        if ($@) {
            $self->c->log->error(
                'B::I::GBA: Failed decrypting: '
                . $self->options->{filename} . ': ' . $@
            );

            return;
        }

        $self->options->{filename}  = $output_file;
    }

    return 1;
}

{
    Zaaksysteem->register_profile(
        method  => '_import_entry',
        profile => GEGEVENSMAGAZIJN_GBA_PROFILE
    );

    sub _import_entry {
        my ($self, $raw_entry, $options) = @_;

        my $dv = $self->c->check(
            params  => $raw_entry
        );

        ### It could be a deleted user, so delete her and not return when
        ### status is > 0
        if (!$dv->success && $raw_entry->{status} < 1) {
            $self->c->log->debug(
                "Could not validate:\nMissing:"
                . ($dv->missing ? join(',', @{ $dv->missing }) : '')
                . "\nInvalid: "
                #. ($dv->invalid ? join(',', @{ $dv->invalid }) : '')
                . ' / ' . $dv->valid->{burgerservicenummer}
            );

            return;
        }

        my $entry   = $dv->valid;

        ### Valid entry, load into database
        $entry->{authenticated} = 1;

        ### Check for 0 status, 1 = moved, 2 = death
        if ($raw_entry->{status} > 0) {
            my $delete_result = $self->_delete_from_database($entry, $raw_entry->{status}, $options);
        } else {
            my $import_result = $self->_import_into_database($entry, $options);

            $self->_log_changed($import_result, $entry);
        }

    }
}

sub _remove_missing {
    my ($self, $done_bsns) = @_;

    my $rows        = $self->c->model('DBG::NatuurlijkPersoon')->search({
        'authenticated'         => 1,
        'deleted_on'            => undef,
    });

    while (my $row  = $rows->next) {
        next if $done_bsns->{ $row->burgerservicenummer };

        $self->_delete_from_database(
            {
                datum_overlijden        => $row->datum_overlijden,
                burgerservicenummer     => $row->burgerservicenummer,
            },
            1
        );

        warn ('Removing bsn: ' . $row->burgerservicenummer . '. because it is moved')
    }
}

sub _log_changed {
    my ($self, $changes, $entry) = @_;

    return unless UNIVERSAL::isa($changes, 'HASH');

    if ($changes->{del_record}) {
        $self->c->log->debug(
            'Deleted record with data_id: '
            . $entry->{burgerservicenummer}
        );

        $self->import_rv->beheer_import_logs->create({
            'identifier'    => $entry->{burgerservicenummer},
            'action'        => 'delete',
        });
    } elsif ($changes->{new_record}) {
        $self->c->log->debug(
            'Added new record with data_id: '
            . $entry->{burgerservicenummer}
        );

        $self->import_rv->beheer_import_logs->create({
            'identifier'    => $entry->{burgerservicenummer},
            'action'        => 'create',
        });
    } elsif (%{ $changes } && scalar(keys %{ $changes })) {
        $self->c->log->debug(
            'Added changed record with data_id: '
            . $entry->{burgerservicenummer} . "\nChanges:",
            join("\n- ", keys %{ $changes })
        );

        while (my ($kolom, $update_info) = each %{ $changes }) {
            $self->import_rv->beheer_import_logs->create({
                'old_data'      => $update_info->{old},
                'new_data'      => $update_info->{new},
                'identifier'    => $entry->{burgerservicenummer},
                'action'        => 'update',
                'kolom'         => $kolom,
            });
        }
    }

    return 1;
}

sub _delete_from_database {
    my ($self, $entry, $status)  = @_;
    my $whats_changed   = {};

    ### Search by burgerservicenummer
    my $rows = $self->c->model('DBG::NatuurlijkPersoon')->search({
        'burgerservicenummer'   => $entry->{burgerservicenummer},
        'authenticated'         => 1,
        'deleted_on'            => undef
    });

    if ($rows->count) {
        ### New to be deleted entry, first update this entry
        $self->_import_into_database($entry);

        $self->c->log->debug('Start deleting entry: ' .
            $entry->{burgerservicenummer}
        );

        while (my $row = $rows->next) {
            $row->adres_id->deleted_on(DateTime->now(
                    'time_zone' => 'Europe/Amsterdam',
            ));
            $row->adres_id->update;

            $row->deleted_on(DateTime->now(
                    'time_zone' => 'Europe/Amsterdam',
            ));
            if ($row->update) {
                $whats_changed->{del_record} = 1;

                $self->_log_changed($whats_changed, $entry);
            }
        }
    } elsif ($status == 2) {
        ### Secure the dead people

        my $rows = $self->c->model('DBG::NatuurlijkPersoon')->search({
            'burgerservicenummer'   => $entry->{burgerservicenummer},
            'authenticated'         => 1,
            'datum_overlijden'      => undef
        });

        if ($rows->count) {

            $self->c->log->info(
                'Make sure people are dead mechanism initiated for '.
                $entry->{burgerservicenummer}
            );

            while (my $row = $rows->next) {
                $row->datum_overlijden($entry->{datum_overlijden});
                $row->update;
            }
        }
    }

    return $whats_changed;
}

sub _import_into_database {
    my ($self, $entry, $options) = @_;
    my %update          = %{ $entry };
    my $whats_changed    = {};

    $self->c->log->debug('Start importing entry: ' .
        $entry->{burgerservicenummer}
    );

    ### Search by burgerservicenummer
    my $rows = $self->c->model('DBG::NatuurlijkPersoon')->search({
        'burgerservicenummer'   => $entry->{burgerservicenummer},
        'authenticated'         => 1,
    });

    return unless $rows;

    if ($rows->count) {
        ### This is an update query
        my $row = $rows->first;

        ### Remove fields which are not changed
        {
            my %without_adres   = %{ $self->_remove_adres_from_entry($entry) };

            ### DUPLICATE row check:
            ### Wanneer iemand opnieuw een partnerschap of huwelijk aangaat
            ### verschijnen er 2 rows in de result. Nu moeten we kijken welke
            ### ontbindingsdatum recenter is. De meest recente is de
            ### actuele...
            if (
                $options->{burgerservicenummers}->{
                    $without_adres{burgerservicenummer}
                }
            ) {
                $self->c->log->info('GBA entry: DUBBEL');

                if (
                    $row->datum_huwelijk_ontbinding ||
                    $without_adres{datum_huwelijk_ontbinding}
                ) {
                    $self->c->log->info('GBA entry: Controleer huwelijk ontbinding');
                    my $update_row_date = DateTime->now();
                    $update_row_date = $without_adres{datum_huwelijk_ontbinding}
                        if $without_adres{datum_huwelijk_ontbinding};

                    my $current_row_date = DateTime->now();
                    $current_row_date = $row->datum_huwelijk_ontbinding
                        if $row->datum_huwelijk_ontbinding;

                    if (
                        (
                            $current_row_date->epoch - $update_row_date->epoch
                        ) > 0
                    ) {

                        $self->c->log->info(
                            'GBA entry: bestaande row = recenter'
                            . 'Current: ' . $current_row_date->dmy
                            . ' / New: ' . $update_row_date->dmy
                        );
                        return {};
                    }
                }
            }

            ### Make sure on update, we will mark this entry as not deleted
            $without_adres{deleted_on} = undef;

            $options->{'burgerservicenummers'}->{
                $without_adres{burgerservicenummer}
            } = 1;

            while (my ($entry_key, $entry_value) = each %without_adres) {
                if (utf8::is_utf8($row->$entry_key)) {
                    $entry_value = pack("U0a*", $entry_value);
                }

                if ($row->$entry_key eq $entry_value) {
                    delete($without_adres{$entry_key});
                    next;
                }

                $whats_changed->{$entry_key} = {
                    'old'   => $row->$entry_key,
                    'new'   => $entry_value,
                };
            }

            ### Update when needed
            if (%without_adres && scalar(keys(%without_adres))) {
                $self->c->log->info('Updating GBA entry: ' .
                    $entry->{burgerservicenummer});

                $row->update(\%without_adres)
            }
        }

        ### Do the same for adres part
        {
            my %adres_update    = %{ $self->_get_adres_from_entry($entry) };

            ### Make sure on update, we will mark this entry as not deleted
            $adres_update{deleted_on} = undef;

            my $adres = $row->adres_id;
            while (my ($entry_key, $entry_value) = each %adres_update) {
                if (
                    (!$entry_value && !$adres->$entry_key) ||
                    (
                        $entry_value &&
                        $adres->$entry_key &&
                        $adres->$entry_key eq $entry_value
                    )
                ) {
                    delete($adres_update{$entry_key});
                    next;
                }
                $whats_changed->{$entry_key} = {
                    'old'   => $adres->$entry_key,
                    'new'   => $entry_value,
                };
            }

            ### Update when needed
            if (%adres_update && scalar(keys(%adres_update))) {
                $self->c->log->info('Updating GBA entry ADRES: ' .
                    $entry->{burgerservicenummer});

                $adres->update(\%adres_update)
            }
        }

        return $whats_changed;
    } else {
        #### This is an insert
        my %without_adres = %{ $self->_remove_adres_from_entry($entry) };

        if (my $create = $self->c->model('DBG::NatuurlijkPersoon')->create(
                {
                    %without_adres,
                    import_datum => DateTime->now,
                }
            )
        ) {
            $whats_changed->{new_record} = 1;
            my %adres_update = %{ $self->_get_adres_from_entry($entry) };
            my $adres = $self->c->model('DBG::Adres')->create({
                %adres_update,
                #'woonplaats'    => 'Bussum',
            });

            $create->adres_id(
                $adres->id
            );
            $create->update;
        }

        return $whats_changed;
    }

    return;
}

sub _remove_adres_from_entry {
    my ($self, $entry) = @_;

    my $excludes = GEGEVENSMAGAZIJN_GBA_ADRES_EXCLUDES;

    my %data = %{ $entry };
    delete($data{$_}) for @{ $excludes };

    return \%data;
}


sub _get_adres_from_entry {
    my ($self, $entry) = @_;
    my (%adres);

    my $excludes = GEGEVENSMAGAZIJN_GBA_ADRES_EXCLUDES;

    $adres{$_} = $entry->{ $_ } for @{ $excludes };

    return \%adres;
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

