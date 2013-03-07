package Zaaksysteem::Zaken::Roles::ZaakSetup;

use Moose::Role;
use Data::Dumper;

use File::Copy;

use Zaaksysteem::Constants qw/
    ZAKEN_STATUSSEN
    ZAKEN_STATUSSEN_DEFAULT
    LOGGING_COMPONENT_ZAAK
    ZAAK_CREATE_PROFILE
/;


### Roles
with
    'Zaaksysteem::Zaken::Roles::BetrokkenenSetup',
    'Zaaksysteem::Zaken::Roles::BagSetup',
    'Zaaksysteem::Zaken::Roles::KenmerkenSetup',
    'Zaaksysteem::Zaken::Roles::RelatieSetup';

has 'log'   => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        shift->{attrs}->{log};
    }
);

has 'z_betrokkene'   => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        shift->{attrs}->{betrokkene_model};
    }
);


{

    sub find_as_session {
        my $self            = shift;
        my $zaak            = shift;

        unless (
            $zaak &&
            (
                ref($zaak) ||
                $zaak =~ /^\d+$/
            )
        ) {
            die('Kan niet dupliceren, geen zaak of zaaknr meegegeven');
        }

        unless (ref($zaak)) {
            $zaak = $self->find($zaak)
                or die('Geen zaak gevonden met nummer: ' .  $zaak);
        }

        my $pp_profile      = Params::Profile->get_profile(
            method  => 'create_zaak'
        );

        ### _get_zaak_as_session
        my %zaak_data   = $zaak->get_columns;
        my %zaak_copy;
        for my $col (keys %zaak_data) {
            next if grep( { $_ eq $col } qw/
                id
                pid
                relates_to
                vervolg_van
                related_because
                vervolg_because
                child_because

                zaaktype_node_id

                last_modified
                created

                days_perc
                days_running
                days_left

                aanvrager
                coordinator
                behandelaar
                locatie_zaak
                locatie_correspondentie
            /);

            $zaak_copy{$col} = $zaak_data{$col};
        }

        ### _get_betrokkenen
        for my $btype (qw/behandelaar coordinator aanvrager/) {
            next unless $zaak->$btype;


            my $btype_p     = $btype . 's';

            my $get_sub     = $btype . '_object';

            $zaak_copy{$btype_p} = [{
                betrokkene_type => $zaak->$get_sub->btype,
                betrokkene      => $zaak->$get_sub->betrokkene_identifier,
                verificatie     => ($zaak->$btype->verificatie || 'medewerker'),
            }]
        }

        ### _get_locatie
        for my $locatie (qw/locatie_zaak locatie_correspondentie/) {
            next unless $zaak->$locatie;

            $zaak_copy{$locatie}    = {
                bag_type        => $zaak->$locatie->bag_type,
                bag_id          => $zaak->$locatie->bag_id,
            }
        }

        ### _get_kenmerken
        my $kenmerken           = $zaak->zaak_kenmerken->search_all_kenmerken;

        if (scalar(keys %{ $kenmerken })) {
            $zaak_copy{kenmerken} = [];

            while (my ($kenmerk_id, $kenmerk_value) = each %{ $kenmerken }) {
                push(
                    @{ $zaak_copy{kenmerken} },
                    { $kenmerk_id   => $kenmerk_value }
                );
            }
        }

        return \%zaak_copy;
    }

    Params::Profile->register_profile(
        method  => 'create_zaak',
        profile => ZAAK_CREATE_PROFILE,
    );

    sub create_zaak {
        my $self        = shift;
        my $params      = shift;
        my ($zaak, $opts);

        ### VALIDATION
        {
            my $dv = Params::Profile->check(
                params  => $params,
            );

            do {
                $self->log->error(
                    'Zaaktype->retrieve: invalid options:'
                    . Dumper($dv)
                );
                return;
            } unless $dv->success;


            $opts = $dv->valid;

            $self->_validate_zaaktype($opts) or return;
        }

        $self->log->debug('START ZAAK CREATE PROCEDURE {');

        eval {
            $self->result_source->schema->txn_do(sub {
                $zaak = $self->_create_zaak($opts);

                $zaak->logging->add(
                    {
                        component       => LOGGING_COMPONENT_ZAAK,
                        component_id    => $zaak->id,
                        onderwerp       => 'Zaak (' . $zaak->id
                             . ') aangemaakt'
                    },
                );

                $self->log->info('Created zaak in DB: ' . $zaak->id);

                ### Zaak loaded, now ask zaak to bootstrap himself with given options
                $zaak->_bootstrap($opts);
            });
        };
        $self->log->debug('} EINDE ZAAK CREATE PROCEDURE');

        if ($@) {
            $self->log->error('There was a problem creating this zaak:' .
                $@
            );
        }

        return $zaak;
    }

    sub _validate_zaaktype {
        my ($self, $opts) = @_;
        my ($ztn);

        if ($opts->{zaaktype_node_id}) {
            $ztn = $self->result_source->schema->resultset('ZaaktypeNode')->find(
                $opts->{zaaktype_node_id},
                {
                    prefetch    => 'zaaktype_id'
                }
            );

            unless ($ztn) {
                die(
                    'Zaken->_validate_zaaktype: '
                    .'cannot find zaaktype_node_id '
                    .  $opts->{zaaktype_node_id}
                );
            }

            $opts->{zaaktype_id} = $ztn->zaaktype_id->id;
        } else {
            my $zt = $self->result_source->schema->resultset('Zaaktype')->find(
                $opts->{zaaktype_id},
                {
                    prefetch    => 'zaaktype_node_id'
                }
            );

            unless ($zt) {
                die(
                    'Zaken->_validate_zaaktype: '
                    .'cannot find zaaktype_id '
                    .  $opts->{zaaktype_id}
                );
            }

            $opts->{zaaktype_node_id} = $zt->zaaktype_node_id->id;

            $ztn = $self->result_source->schema->resultset('ZaaktypeNode')->find(
                $opts->{zaaktype_node_id}
            );
        }

        $opts->{aanvraag_trigger} = $ztn->trigger;

        return $ztn;
    }

    sub _create_betrokkenen {
        my ($self, $opts) = @_;

        return unless $opts->{aanvragers};

        # DUMMY
        $opts->{aanvrager} = $self->result_source->schema->resultset('ZaakBetrokkenen')->create(
            {
                betrokkene_type         => 'natuurlijk_persoon',
                betrokkene_id           => 1,
                gegevens_magazijn_id    => 24640,
                verificatie             => 'digid',
            },
        );

        push(@{ $opts->{_update_zaak_ids} },
            $opts->{aanvrager}
        );
    }

    sub _create_zaak {
        my ($self, $opts) = @_;
        my (%create_params);

        $self->log->debug(
            'Z::Zaken->_create_zaak: Try to create zaak in DB'
        );

        $create_params{ $_ } = $opts->{ $_ }
            for $self->result_source->columns;

        $self->log->info(
            'Z::Zaken->_create_zaak: '
            .'options to create: '
           # . Dumper(\%create_params)
        );

        ### Delete autoincrement integer, UNLESS IT IS SET and OVERRIDE
        ### zaak_nr is true
        unless ($opts->{override_zaak_id}) {
            delete($create_params{id});
        }

        ### registratiedatum eq created
        ###

        $create_params{created} = $create_params{registratiedatum};

        my $zaak = $self->create(
            \%create_params
        );

        $self->log->info(
            'Z::Zaken->_create_zaak: '
            .'created zaak with id: ' . $zaak->id
        );

        return $zaak;
    }
}

{
    Params::Profile->register_profile(
        method  => 'create_relatie',
        profile => {
            required        => [ qw/
                zaaktype_id
                type_zaak
            /],
            'optional'      => [ qw/
                subject
                add_days
                actie_kopieren_kenmerken
                actie_automatisch_behandelen
                role_id
                ou_id

                behandelaar_id
                behandelaar_type
            /],
            'require_some'  => {
                'aanvrager_id_or_aanvrager_type' => [
                    1,
                    'aanvrager_id',
                    'aanvrager_type'
                ],
            },
            'constraint_methods'    => {
                type_zaak       =>
                    qr/^gerelateerd|vervolgzaak|deelzaak|wijzig_zaaktype$/,
                add_days        => qr/^[\d\-]+$/,
                #'behandelaar_id'       => qr/^$/,
                #'behandelaar_type'     => qr/^\d+$/,
                #'aanvrager_id'      => qr/^\d+$/,
                #'aanvrager_type'    => qr/^\d+$/,
            },
        }
    );

    sub create_relatie {
        my ($self, $zaak, %opts) = @_;
        my ($nid, $aanvrager_id, $behandelaar_id, $start_time);

        ### VALIDATION
        my $dv = Params::Profile->check(
            params  => \%opts,
        );

        do {
            $self->log->error(
                'Zaaktype->retrieve: invalid options:'
                . Dumper($dv)
            );
            return;
        } unless $dv->success;

        ### Aanvrager information
        if ($dv->valid('aanvrager_type')) {
            if ($dv->valid('aanvrager_type') eq 'aanvrager') {
                $aanvrager_id = $zaak->aanvrager_object->betrokkene_identifier;
            } elsif ($dv->valid('aanvrager_type') eq 'behandelaar') {
                $aanvrager_id = $zaak->behandelaar_object->betrokkene_identifier;
            }
        } else {
            $aanvrager_id = $dv->valid('aanvrager_id');
        }

        my $behandelaars    = [];
        if ($dv->valid('behandelaar_type')) {
            if ($zaak->behandelaar_object && $dv->valid('behandelaar_type') eq 'behandelaar') {
                $behandelaar_id = $zaak->behandelaar_object->betrokkene_identifier;
            }
        } elsif ($dv->valid('behandelaar_id')) {
            $behandelaar_id = $dv->valid('behandelaar_id');
        }

        if ($behandelaar_id) {
            $behandelaars   = [{
                betrokkene          => $behandelaar_id,
                verificatie         => 'medewerker',
            }];
        }

        if (
            $dv->valid('add_days') &&
            $dv->valid('add_days') =~ /^\d+\-\d+\-\d+$/
        ) {
            my ($day,$month,$year) = $dv->valid('add_days') =~ /^(\d+)-(\d+)-(\d+)$/;
            $start_time = DateTime->new(
                year    => $year,
                day     => $day,
                month   => $month,
            );

            $start_time = DateTime->now() unless $start_time->epoch > DateTime->now()->epoch;

        } elsif ($dv->valid('add_days') > 0) {
            $start_time = DateTime->now->add(days => $dv->valid('add_days'));
        } else {
            $start_time = DateTime->now;
        }

        ### Subject
        my $subject = $dv->valid('subject') ||
            ucfirst($dv->valid('type_zaak')) . ' van zaaknummer: ' .  $zaak->id;

        ### First, search for acturele zaaktype_node_id
        my $zaaktype_node_id;
        {
            my $zt = $self->result_source->schema->resultset('Zaaktype')->find(
                $dv->valid('zaaktype_id')
            );

            unless ($zt) {
                warn(
                    'Grrrr: zaaktype_id not found or incomplete: '
                    . $dv->valid('zaaktype_id')
                );

                return;
            }

            $zaaktype_node_id = $zt->zaaktype_node_id->id;
        }


        ### Zaak informatie
        my $zaak_opts = {
            'zaaktype_node_id'  => $zaaktype_node_id,
            'aanvragers'        => [{
                betrokkene          => $aanvrager_id,
                verificatie         => 'medewerker',
            }],
            'behandelaars'      => $behandelaars,
            'onderwerp'         => $subject,
            'registratiedatum'  => $start_time,
            'relatie'           => $dv->valid('type_zaak'),
            'contactkanaal'     => $zaak->contactkanaal,
            'aanvraag_trigger'  => $zaak->aanvraag_trigger,
            'actie_kopieren_kenmerken' => (
                $dv->valid('actie_kopieren_kenmerken')
                    ? 1
                    : undef
            ),
            'route_role'        => ($dv->valid('role_id') || undef),
            'route_ou'          => ($dv->valid('ou_id') || undef)
        };

        {
            my $tmp_OPT = $dv->valid;

            $self->log->debug(
                'Zaak->start_extra_zaakOPT: create zaak with options'
                . Dumper($tmp_OPT)
            );
        }

        $self->log->debug(
            'Zaak->start_extra_zaak: create zaak with options'
            . Dumper($zaak_opts)
        );

        my $nieuwe_zaak = $self->create_zaak({
            %{ $zaak_opts },
            zaak    => $zaak,
        }) or return;

        if ($dv->valid('actie_automatisch_behandelen')) {

            $nieuwe_zaak->open_zaak;
        }

        return $nieuwe_zaak;
    }
}

sub duplicate {
    my ($self, $zaak, $opts) = @_;

    unless (
        $zaak &&
        (
            ref($zaak) ||
            $zaak =~ /^\d+$/
        )
    ) {
        die('Kan niet dupliceren, geen zaak of zaaknr meegegeven');
    }

    unless (ref($zaak)) {
        $zaak = $self->find($zaak)
            or die('Geen zaak gevonden met nummer: ' .  $zaak);
    }

    ### Retrieve aanvragers / kenmerken / bag data etc
    my $new_zaak_session    = $self->find_as_session($zaak);

    $opts                  ||= {};

    ### Change behandelaar to current user
    $opts->{behandelaars}   = [
        {
            betrokkene  => $self->current_user->betrokkene_identifier,
            verificatie => 'medewerker',
        }
    ];

    ### Commit new zaak
    my ($new_zaak);

    eval {
        $self->result_source->schema->txn_do(sub {
            if ($opts->{simpel}) {
                $opts->{registratiedatum}   = DateTime->now();
                $opts->{streefafhandeldatum}= undef;

                warn('SIMPEL VERSION!!!!');
            }

            $new_zaak            = $self->create_zaak({
                %{ $new_zaak_session },
                %{ $opts }
            });

            if ($opts->{simpel}) {
                $new_zaak->milestone(1);
                $new_zaak->set_heropen;
            } else {
                ### Copy checklist items
                my $checklist_answers   = $zaak->checklist->search(
                    {},
                    {
                        order_by => { '-asc' => 'id' }
                    }
                );

                while (my $answer   = $checklist_answers->next) {
                    my $new_row = $answer->copy;

                    $new_row->zaak_id($new_zaak->id);
                    $new_row->update;
                }

                ### Copy documents
                my $zaak_documents  = $zaak->documents->search(
                    {},
                    {
                        order_by => { '-asc' => 'id' }
                    }
                );

                while (my $document = $zaak_documents->next) {
                    my $new_document = $document->copy(
                        {
                            zaak_id => $new_zaak->id
                        }
                    );

                    $self->_copy_document($document, $new_document);
                }

                ### Copy logboek
                my $zaak_logging  = $zaak->logging->search(
                    {},
                    {
                        order_by => { '-asc' => 'id' }
                    }
                );
                while (my $logging = $zaak_logging->next) {
                    $logging->copy(
                        {
                            zaak_id => $new_zaak->id
                        }
                    );
                }
            }
        });
    };

    if ($@) {
        $self->log->error(
            'Failed duplicating zaak: ' . $zaak->id
            . ': ' . $@
        );
        return;
    }

    $new_zaak->logging->add(
        {
            component       => LOGGING_COMPONENT_ZAAK,
            component_id    => $zaak->id,
            onderwerp       => 'Nieuwe kopie van zaak (' . $zaak->id
                 . ') succesvol onder nieuw zaaknummer: '
                 . $new_zaak->id
        },
    );

    $zaak->logging->add(
        {
            component       => LOGGING_COMPONENT_ZAAK,
            component_id    => $new_zaak->id,
            onderwerp       => 'Een kopie van zaak ' . $zaak->id
                 . ' is aangemaakt onder zaaknummer: '
                 . $new_zaak->id
        },
    );

    return $new_zaak;
}


sub _copy_document {
    my $self        = shift;
    my $document    = shift;
    my $nieuwe_doc  = shift;

    return 1 if $document->documents_mails->count;

    my $files_dir   = $self->config->{files} . '/documents';

    die('File not found: ' . $files_dir . '/' . $document->id)
        unless ( -f $files_dir . '/' . $document->id);

    die('Failed copying: ' . $files_dir . '/' . $document->id
       . ' TO ' . $files_dir . '/' . $nieuwe_doc->id
    ) unless copy(
        $files_dir . '/' . $document->id,
        $files_dir . '/' . $nieuwe_doc->id
    );

    return 1;
}


sub wijzig_zaaktype {
    my ($self, $zaak, $opts) = @_;

    unless($opts && $opts->{zaaktype_id}) {
        die "wijzig_zaaktype: need zaaktype_id";
    }
    
    my $zaaktype = $self->result_source->schema->resultset('Zaaktype')->find($opts->{zaaktype_id});
                
    $opts->{zaaktype_node_id} = $zaaktype->zaaktype_node_id->id;
#    die "zaaknode: " . $opts->{zaaktype_node_id};

#    unless ($opts && $opts->{zaaktype_id}) {
#        die "wijzig_zaaktype: need zaaktype_id";
#    }

    my $change = $self->duplicate($zaak, $opts)
        or return;

    $zaak->set_deleted;

    $zaak->logging->add(
        {
            component       => LOGGING_COMPONENT_ZAAK,
            component_id    => $change->id,
            onderwerp       => 'Daze zaak is vernietigd'
                 . ' in verband met zaaktype wijziging, nieuw zaaknummer: '
                 . $change->id
        },
    );

    $change->logging->add(
        {
            component       => LOGGING_COMPONENT_ZAAK,
            component_id    => $zaak->id,
            onderwerp       => 'Zaaktype gewijzigd, oude zaak vernietigd: '
                . $zaak->id
        },
    );

    return $change;
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

