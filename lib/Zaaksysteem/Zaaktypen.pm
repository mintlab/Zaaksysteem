package Zaaksysteem::Zaaktypen;

use strict;
use warnings;

use Params::Profile;
use Data::Dumper;
use Zaaksysteem::Constants;

use Moose;
use namespace::autoclean;

use constant ZAAKTYPEN_PREFIX   => 'zaaktype_';
#use constant ZAAKTYPEN_RELATIES => [qw/
#    zaaktype_authorisaties
#    zaaktype_betrokkenen
#    zaaktype_attributen
#    zaaktypes
#    zaaktype_statusen
#    zaaktype_sjablonen
#    zaaktype_kenmerken
#    zaaktype_checklisten
#    zaaktype_ztc_documenten
#    zaaktype_resultaten
#    zaaktype_notificaties
#    zaaktype_relatie_zaaktype_node_ids
#/];
use constant ZAAKTYPEN_RELATIES => [qw/
    zaaktype_authorisaties
    zaaktype_betrokkenen
    zaaktype_statussen
/];
##  zaaktype_attributen


has [qw/prod log dbic rt/] => (
    'is'    => 'rw',
);



{
    my $SESSION_TEMPLATE    = {
        'zaaktype'      => 'Zaaktype',
        'definitie'     => 'ZaaktypeDefinitie',
        'node'          => 'ZaaktypeNode',
        'statussen'     => 'ZaaktypeStatus',
    };

    sub session_template {
        my ($self) = @_;

        my $template    = {};
        while (my ($key, $table) = each %{ $SESSION_TEMPLATE }) {
            $template->{$key} = $self->dbic->resultset($table)->_get_session_template;
        }

        return $template;
    }
}

{
    Params::Profile->register_profile(
        method  => 'retrieve',
        profile => {
            required        => [ qw/
            /],
            'optional'      => [ qw/
                as_session
                as_clone
            /],
            'require_some'  => {
                'zaaktype_id_or_node_id' => [
                    1,
                    'id',
                    'nid'
                ],
            },
            'constraint_methods'    => {
                'id'    => qr/^\d+$/,
                'nid'   => qr/^\d+$/,
            },
        }
    );

    sub retrieve {
        my ($self, %opts) = @_;
        my ($nid);

        my $dv = Params::Profile->check(
            params  => \%opts
        );

        do {
            $self->log->error(
                'Zaaktype->retrieve: invalid options'
            );
            return;
        } unless $dv->success;

        ### Retrieve resultset
        my ($zt_node);
        if ($opts{id}) {
            $zt_node = $self->_retrieve_node_by_zaaktype_id($opts{id});
        } else {
            $zt_node = $self->_retrieve_node_by_zaaktype_node_id($opts{nid});
        }

        ### Retrieve as session when asked
        if ($opts{as_session}) {
            my $session = $self->_retrieve_as_session($zt_node);
            return unless $session;

            if ($opts{as_clone}) {
                ### Delete id and version
                delete($session->{zaaktype}->{id});
                $session->{node}->{version} = 1;
            }

            return $session;
        }

        return $zt_node;
    }

    sub _retrieve_as_session {
        my ($self, $node)   = @_;
        my $rv              = {};

        return unless ref($node);

        ### Retrieve all relaties
        my $relaties        = ZAAKTYPEN_RELATIES;
        my $relatieprefix   = ZAAKTYPEN_PREFIX;

        ### Retrieve zaaktype and zaaktypenode
        {
            ### ZAAKTYPE
            $rv->{zaaktype}     = {};
            my @columns         = $node->zaaktype_id->result_source->columns;

            for my $column (@columns) {
                ### When this is a reference to another table, just
                ### retrieve the id
                if (ref($node->zaaktype_id->$column) && $node->zaaktype_id->$column->can('id')) {
                    $rv->{zaaktype}->{$column}  = $node->zaaktype_id->$column->id;
                } elsif (!ref($node->zaaktype_id->$column)) {
                    $rv->{zaaktype}->{$column} = $node->zaaktype_id->$column;
                }
            }


            ### DEFINITIE XXX TEMPORARILY IF
            $rv->{definitie}     =
                $self->_retrieve_as_session_definitie($node);

            ### NODE
            $rv->{node}         = {};
            @columns            = $node->result_source->columns;

            for my $column (@columns) {
                ### When this is a reference to another table, just
                ### retrieve the id
                if (ref($node->$column) && $node->$column->can('id')) {
                    $rv->{node}->{$column}  = $node->$column->id;
                } elsif (!ref($node->$column)) {
                    $rv->{node}->{$column} = $node->$column;
                }
            }
        }

        for my $relatie (@{ $relaties }) {
            ### Remove prefix,
            ### eg: $rv->{kenmerken} ipv $rv->{zaaktype_kenmerken}
            my $key         = $relatie;
            $key            =~ s/^$relatieprefix//;

            ### XXX Generic bitte
            if ($relatie eq 'zaaktype_authorisaties') {
                next unless $node->zaaktype_id->$relatie->can('_retrieve_as_session');
                $rv->{$key}     =
                    $node->zaaktype_id->$relatie->_retrieve_as_session({ node => $node });
            } else {
                next unless $node->$relatie->can('_retrieve_as_session');
                $rv->{$key}     = $node->$relatie->_retrieve_as_session({ node => $node });
            }

        }

        return $rv;
    }


    sub _retrieve_as_session_definitie {
        my ($self, $node)   = @_;
        my $rv              = {};

        if ($node->zaaktype_definitie_id) {
            my @columns         = $node->zaaktype_definitie_id->result_source->columns;
            for my $column (@columns) {
                ### When this is a reference to another table, just
                ### retrieve the id
                if (
                    ref($node->zaaktype_definitie_id->$column) &&
                    $node->zaaktype_definitie_id->$column->can('id')
                ) {
                    $rv->{$column} =
                        $node->zaaktype_definitie_id->$column->id;
                } elsif (!ref($node->zaaktype_definitie_id->$column)) {
                    $rv->{$column}
                        = $node->zaaktype_definitie_id->$column;
                }
            }

            ### Tarief
            if ($rv->{'pdc_tarief'}) {
                ($rv->{pdc_tarief_eur}, $rv->{pdc_tarief_cnt}) = split(
                    /\./, $rv->{pdc_tarief}
                );
            }
        } else {
            ### WATCH IT, THIS IS AN OLD DEFINITION
            $rv->{oud_zaaktype} = 1;

            my $attributen  = $node->zaaktype_attributen->search();
            while (my $attr = $attributen->next) {
                my $values  = $attr->zaaktype_values;
                if ($values->count == 1) {
                    my $value = $values->first;

                    my $key = $attr->key;
                    $key    =~ s/^ztc_//g;

                    $rv->{$key} = $value->value;
                }
            }

            ### BACKWARDS COMPATIBILITY
            $rv->{'extra_informatie'} = $node->toelichting;
        }

        return $rv;
    }


    sub _retrieve_node_by_zaaktype_node_id {
        my ($self, $nid) = @_;
        my ($zt_node);

        unless (
            $zt_node = $self->dbic->resultset('ZaaktypeNode')->find($nid)
        ) {
            $self->log->error(
                'Zaaktype->retrieve: Cannot find zaaktype with node_id: '
                . $nid
            );

            return;
        }

        return $zt_node;
    }


    sub _retrieve_node_by_zaaktype_id {
        my ($self, $id) = @_;
        my ($zt_node);

        my $zaaktype = $self->dbic->resultset('Zaaktype')->find($id);

        if (
            !$zaaktype ||
            !$zaaktype->zaaktype_node_id ||
            !$zaaktype->zaaktype_node_id->id
        ) {
            $self->log->error(
                'Zaaktype->retrieve: Cannot find zaaktype with id: '
                . $id
            );

            return;
        }

        return $zaaktype->zaaktype_node_id;
    }
}


{
    Params::Profile->register_profile(
        method  => 'validate_session',
        profile => {
            required        => [ qw/
                session
            /],
            'optional'      => [ qw/
                zs_fields
            /],
            'constraint_methods'    => {
            },
        }
    );

    sub validate_session {
        my ($self, %opts) = @_;
        my ($rv);

        my $dv = Params::Profile->check(
            params  => \%opts
        );

        do {
            $self->log->error(
                'Zaaktype->retrieve: invalid options'
            );
            return;
        } unless $dv->success;

        my $relaties        = ZAAKTYPEN_RELATIES;
        my $relatieprefix   = ZAAKTYPEN_PREFIX;

        $rv->{node}         =
            $self->dbic->resultset('ZaaktypeNode')->_validate_session(
                $dv->valid('session')->{node}
            );

        $rv->{zaaktype}     =
            $self->dbic->resultset('Zaaktype')->_validate_session(
                $dv->valid('session')->{zaaktype}
            );

        $rv->{definitie}    =
            $self->dbic->resultset('ZaaktypeDefinitie')->_validate_session(
                $dv->valid('session')->{definitie}
            );


        for my $relatie (@{ $relaties }) {
            my $relatie_info    = $self->dbic->resultset('ZaaktypeNode')
                                    ->result_source->relationship_info($relatie);
            next unless $relatie_info && $relatie_info->{source};

            my $relatie_object  = $self->dbic->resultset($relatie_info->{source});

            next unless $relatie_object->can('_validate_session');

            ### Remove prefix,
            ### eg: $rv->{kenmerken} ipv $rv->{zaaktype_kenmerken}
            my $key         = $relatie;
            $key            =~ s/^$relatieprefix//;

            $rv->{$key}     = $relatie_object->_validate_session($dv->valid('session')->{statussen});
        }

        ### Everything validated, now make a validation profile when params are
        ### given
        $rv->{validation_profile}   = $self->_make_validation_profile(
            $rv,
            [ $dv->valid('zs_fields') ]
        ) if $dv->valid('zs_fields');

        return $rv;
    }

    sub _make_validation_profile {
        my ($self, $validated, $fields) = @_;

        my $validation_profile = {
            success     => 1,
            missing     => [],
            invalid     => [],
            unknown     => [],
            valid       => [],
            msgs        => {},
        };

        for my $param (@{ $fields }) {
            # Security, only test.bla[.bla.bla]
            next unless $param  =~ /^[\w\d\_]+\.[\w\d\_\.]+$/;

            my @tree            = split(/\./, $param);
            my $method          = pop(@tree);

            my $eval = '$validated->{';
            $eval   .= join('}->{', @tree) . '}';

            if (eval($eval . '->valid(\'' . $method . '\');')) {
                push(
                    @{ $validation_profile->{valid} },
                    $param
                );
            } elsif (eval($eval . '->invalid(\'' . $method . '\');')) {
                push(
                    @{ $validation_profile->{invalid} },
                    $param
                );
                $validation_profile->{success} = 0;
            } elsif (eval($eval . '->missing(\'' . $method . '\');')) {
                push(
                    @{ $validation_profile->{missing} },
                    $param
                );
                $validation_profile->{success} = 0;
            }

            my $msgs    = eval($eval . '->msgs');

            #warn Dumper($msgs);
            $validation_profile->{msgs}->{$param} = $msgs->{$method}
                if $msgs->{$method};

        }

        return $validation_profile;
    }
}



{
    Params::Profile->register_profile(
        method  => 'commit_session',
        profile => {
            required        => [ qw/
                session
            /],
            'optional'      => [ qw/
            /],
            'constraint_methods'    => {
            },
        }
    );

    sub commit_session {
        my ($self, %opts) = @_;
        my ($rv);

        my $dv = Params::Profile->check(
            params  => \%opts
        );

        do {
            $self->log->error(
                'Zaaktype->retrieve: invalid options'
            );
            return;
        } unless $dv->success;

        my $relaties        = ZAAKTYPEN_RELATIES;
        my $relatieprefix   = ZAAKTYPEN_PREFIX;

        ### Validate session
        return unless $self->is_valid_session(
            $dv->valid('session')
        );

        ### Transaction
        my ($zaaktype_node);
        $self->dbic->txn_do(sub {
            eval {
                ### Create zaaktype, unless it's an edit ;)
                my $zaaktype        = $self->_commit_zaaktype($dv->valid('session'))
                    or return;
                $zaaktype_node   = $self->_commit_zaaktype_node($dv->valid('session'), $zaaktype)
                    or return;

                $self->_commit_zaaktype_definitie($dv->valid('session'), $zaaktype_node)
                    or return;

                for my $relatie (@{ $relaties }) {
                    my $relatie_info    = $self->dbic->resultset('ZaaktypeNode')
                                            ->result_source->relationship_info($relatie);

                    next unless $relatie_info && $relatie_info->{source};
                    my $relatie_object  = $self->dbic->resultset($relatie_info->{source});

                    next unless $relatie_object->can('_commit_session');

                    ### Remove prefix,
                    ### eg: $rv->{kenmerken} ipv $rv->{zaaktype_kenmerken}
                    my $key         = $relatie;
                    $key            =~ s/^$relatieprefix//;
                    $rv->{$key}     = $relatie_object->_commit_session(
                        $zaaktype_node,
                        $dv->valid('session')->{$key}
                    );
                }

                ### Fase update
                if ($dv->valid('session')->{definitie}->{oud_zaaktype}) {
                    ### Oud zaaktype, duplicate definitie
                    if (
                        $dv->valid('session')->{definitie}->{oud_zaaktype} &&
                        $zaaktype_node->zaaktype_id
                    ) {
                        $self->log->info('Zaaktypen->commit: OLD ZAAKTYPE');
                        my $old_nodes = $self->dbic->resultset('ZaaktypeNode')->search(
                            {
                                zaaktype_id => $zaaktype->id
                            }
                        );

                        my $current_fases = $self->dbic->resultset('ZaaktypeStatus')->search(
                            {
                                 zaaktype_node_id   => $zaaktype_node->id,
                            }
                        );

                        my %definitie = $zaaktype_node->zaaktype_definitie_id->get_columns;
                        delete($definitie{id});

                        $self->log->info('Zaaktypen->commit: OLD ZAAKTYPE: UPDATE OLD NODES');
                        while (my $old_node = $old_nodes->next) {
                            ### UPDATE DEFINITIE
                            my $copy = $self->dbic->resultset('ZaaktypeDefinitie')->create(
                                \%definitie
                            );

                            $old_node->zaaktype_definitie_id($copy->id);
                            $self->log->info('Zaaktypen->commit: OLD ZAAKTYPE: UPDATE DEFINITIE');
                            $old_node->update;

                            ### UPDATE FASES
                            $current_fases->reset;
                            $self->log->info('Zaaktypen->commit: OLD ZAAKTYPE: UPDATE FASES');
                            if ($current_fases->count) {
                                while (my $current_fase = $current_fases->next) {
                                    my $old_fase = $old_node->zaaktype_statussen->search(
                                        {
                                            status  => $current_fase->status
                                        }
                                    );

                                    $self->log->info('Zaaktypen->commit: OLD ZAAKTYPE: TRY UPDATE FASE');
                                    next unless $old_fase->count == 1;
                                    $old_fase = $old_fase->first;

                                    $self->log->info('Zaaktypen->commit: OLD ZAAKTYPE: UPDATE FASE');
                                    $old_fase->naam( $current_fase->naam );
                                    $old_fase->fase( $current_fase->fase );

                                    $old_fase->update;
                                }

                            }
                        }
                    }
                }

                ### Create RT
                if ($self->rt) {
                    $self->_commit_rt($zaaktype_node);
                }
            };

            if ($@) {
                $self->log->error('Error: ' . $@);
                die('Rollback');
            } else {
                $self->log->info('Zaaktype aangemaakt');
            }

        });

        return $zaaktype_node;
    }

    sub _commit_rt {
        my ($self, $zaaktype_node)  = @_;

        ### XXX Remove RT functionality, for now: return true, skip RT
        return 1;

        my $rtq = $self->_commit_rt_queue   ($zaaktype_node);
        $self->_commit_rt_cf                ($zaaktype_node, $rtq);
    }

    sub _commit_rt_queue {
        my ($self, $zaaktype_node)  = @_;

        my $rtq         = $self->rt->create_object('RT::Queue');

        my $queuenaam   = $zaaktype_node->id . '-'
            . $zaaktype_node->zaaktype_id->id . '-'
            . $zaaktype_node->titel;

        my ($ok) = $rtq->Create(
            'Name'          => $queuenaam,
            'Description'   => $queuenaam . ' / Versie: ' .
                $zaaktype_node->version
        );

        if (!$ok) {
            die('Failed adding RT queue');
        }

        $zaaktype_node->zaaktype_rt_queue($queuenaam);
        $zaaktype_node->update;

        return $rtq;
    }


    sub _commit_rt_cf {
        my ($self, $zaaktype_node, $rtq)  = @_;

        #### XXX NEW STYLE
        my $kenmerken = $zaaktype_node->zaaktype_kenmerkens;

        while (my $kenmerk = $kenmerken->next) {
            my $kenmerkdb   = $kenmerk->bibliotheek_kenmerken_id;
            next unless $kenmerk->bibliotheek_kenmerken_id;
            my $rtcf        = $self->rt->create_object('RT::CustomField');
            my $rtcftype    = ZAAKSYSTEEM_CONSTANTS->{veld_opties}->{
                $kenmerkdb->value_type
            }->{'rt'};

            my ($bynameok)  = $rtcf->Load('kenmerk_id_' . $kenmerkdb->id);
            $self->log->debug('Load by id result: ' . $bynameok);

            if (!$bynameok) {
                $rtcf->Create(
                    'Name'          => 'kenmerk_id_' . $kenmerkdb->id,
                    'TypeComposite' => $rtcftype,
                    'Description'   => $kenmerkdb->label,
                    'LookupType'    => 'RT::Queue-RT::Ticket',
                    'ObjectType'    => 'RT::Queue',
                );
            }

            my ($ok, $msg) = $rtcf->AddToObject($rtq);
        }
    }

    sub _commit_zaaktype {
        my ($self, $session)        = @_;
        my $params = {};

        $params->{ $_ } = $session->{zaaktype}->{ $_ }
            for $self->dbic->resultset('Zaaktype')->result_source
                ->columns;

        if ($params->{id}) {

            my $zaaktype = $self->dbic->resultset('Zaaktype')->find(
                $session->{zaaktype}->{id}
            );

            return $zaaktype unless
                $session->{zaaktype}->{bibliotheek_categorie_id};

            $zaaktype->bibliotheek_categorie_id(
                $session->{zaaktype}->{bibliotheek_categorie_id}
            );
            $zaaktype->update;

            return $zaaktype;
        }

        return $self->dbic->resultset('Zaaktype')->create(
            $session->{zaaktype}
        );
    }

    sub _commit_zaaktype_node {
        my ($self, $session, $zaaktype)        = @_;
        my $params = {};

        $params->{ $_ } = $session->{node}->{ $_ }
            for $self->dbic->resultset('ZaaktypeNode')->result_source
                ->columns;

        if ($params->{id}) {
            ### Bump version
            $params->{version}++;
        }

        ### Make sure we delete id
        delete($params->{id});

        ### Add zaaktype id
        $params->{zaaktype_id} = $zaaktype->id;

        my $node    = $self->dbic->resultset('ZaaktypeNode')->create(
            $params
        );

        $zaaktype->zaaktype_node_id($node->id);
        $zaaktype->update;

        return $node;
    }

    sub _commit_zaaktype_definitie {
        my ($self, $session, $node)   = @_;
        my ($rv, $params) = (undef, {});

        ### Centen en euro's
        if (defined($session->{definitie}->{heeft_pdc_tarief})) {
            if ($session->{definitie}->{heeft_pdc_tarief}) {

                $session->{definitie}->{pdc_tarief} = undef;
                if (
                    $session->{definitie}->{pdc_tarief_eur} &&
                    $session->{definitie}->{pdc_tarief_eur} =~ /^\d+$/
                ) {
                    $session->{definitie}->{pdc_tarief} =
                        $session->{definitie}->{pdc_tarief_eur};
                }
                if (
                    $session->{definitie}->{pdc_tarief_cnt} &&
                    $session->{definitie}->{pdc_tarief_cnt} =~ /^\d+$/
                ) {
                    if ($session->{definitie}->{pdc_tarief}) {
                        $session->{definitie}->{pdc_tarief} .= '.'
                    } else {
                        $session->{definitie}->{pdc_tarief} .= '0.';
                    }
                    $session->{definitie}->{pdc_tarief} .=
                        $session->{definitie}->{pdc_tarief_cnt};
                }
            } else {
                $session->{definitie}->{pdc_tarief} = undef;
            }
        }

        $params->{ $_ } = $session->{definitie}->{ $_ }
            for $self->dbic->resultset('ZaaktypeDefinitie')->result_source
                ->columns;

        delete($params->{id});
        $rv = $self->dbic->resultset('ZaaktypeDefinitie')->create(
            $params
        );

        if ($rv) {
            $node->zaaktype_definitie_id($rv->id);
            $node->update;

        }

        return $rv;
    }

    sub is_valid_session { 1; }
}

{
    Params::Profile->register_profile(
        method  => 'verwijder',
        profile => {
            required        => [ qw/
            /],
            'optional'      => [ qw/
                as_session
                as_clone
            /],
            'require_some'  => {
                'zaaktype_id_or_node_id' => [
                    1,
                    'id',
                    'nid'
                ],
            },
            'constraint_methods'    => {
                'id'    => qr/^\d+$/,
                'nid'   => qr/^\d+$/,
            },
        }
    );

    sub verwijder {
        my ($self, %opts) = @_;
        my ($nid);

        my $dv = Params::Profile->check(
            params  => \%opts
        );

        do {
            $self->log->error(
                'Zaaktype->retrieve: invalid options'
            );
            return;
        } unless $dv->success;

        ### Retrieve resultset
        my ($zt_node);
        if ($opts{id}) {
            $zt_node = $self->_retrieve_node_by_zaaktype_id($opts{id});
        } else {
            $zt_node = $self->_retrieve_node_by_zaaktype_node_id($opts{nid});
        }

        $zt_node->active(undef);
        $zt_node->deleted(DateTime->now);

        my $zt = $zt_node->zaaktype_id;

        $zt->active(undef);
        $zt->deleted(DateTime->now);

        $zt->update;
        $zt_node->update;

        return 1;

    }
}


{
    Params::Profile->register_profile(
        method  => 'export',
        profile => {
            required        => [ qw/
                id
            /],
            'constraint_methods'    => {
                'id'    => qr/^\d+$/,
            },
        }
    );

    sub export {
        my ($self, %opts) = @_;
        my $dv = Params::Profile->check(
            params  => \%opts
        );
#warn Dumper \%opts;
#warn Dumper $dv;

        do {
            $self->log->error(
                'Zaaktype->export: invalid options'
            );
            return;
        } unless $dv->success;

        my $zt_node = $self->_retrieve_node_by_zaaktype_id($opts{id});
        my $session = $self->_retrieve_as_session($zt_node);
        ### Delete id and version
        delete($session->{zaaktype}->{id});
        $session->{node}->{version} = 1;

        return $session;
        
        
        return "dsdfdf";

    }
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

