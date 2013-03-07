package Zaaksysteem::Zaken::Roles::BetrokkenenObjecten;

use Moose::Role;
use Data::Dumper;

with 'Zaaksysteem::Zaken::Betrokkenen';

use Zaaksysteem::Constants;

use Zaaksysteem::Betrokkene;

has 'aanvrager_object' => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return unless $self->aanvrager;

        return $self->_load_betrokkene_object(
            $self->aanvrager
        );
    }
);

has 'ontvanger_object' => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my $self        = shift;
        my $ontvanger   = $self->zaak_betrokkenen->ontvanger;

        return unless $ontvanger;

        return $self->_load_betrokkene_object(
            $ontvanger
        );
    }
);

has 'behandelaar_object' => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return unless $self->behandelaar;

        return $self->_load_betrokkene_object(
            $self->behandelaar
        );
    }
);

has 'coordinator_object' => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return unless $self->coordinator;

        return $self->_load_betrokkene_object(
            $self->coordinator
        );
    }
);

has 'ou_object' => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return unless $self->route_ou;

        return $self->result_source->schema->resultset('Zaak')->betrokkene_model->get(
            {
                'intern'    => 0,
                'type'      => 'org_eenheid'
            }, $self->route_ou
        );
    }
);

Params::Profile->register_profile(
    'method'    => 'betrokkene_object',
    'profile'   => {
        'optional'      => [qw/
        /],
        'require_some'  => {
            'magic_string_or_rol'   => [
                1,
                'magic_string_prefix',
                'rol',
                'betrokkene_id'
            ],
        },
    }
);

sub betrokkene_object {
    my ($self, $opts)   = @_;
    my $dv              = Params::Profile->check(params => $opts);
    my $search          = {};

    die('Parameters incorrect:' . Dumper($opts)) unless $dv->success;

    if ($opts->{magic_string_prefix}) {
        $search->{magic_string_prefix}  = $opts->{magic_string_prefix};
    } elsif ($opts->{rol}) {
        $search->{rol}                  = $opts->{rol};
    } else {
        $search->{id}                   = $opts->{betrokkene_id};
    }

    my $betrokkene = $self->zaak_betrokkenen->search(
        $search
    );

    return unless $betrokkene->count == 1;

    $betrokkene     = $betrokkene->first;

    if (
        $self->{_betrokkene_object_cache} &&
        $self->{_betrokkene_object_cache}->{$betrokkene->id}
    ) {
        return $self->{_betrokkene_object_cache}->{$betrokkene->id};
    }

    $self->{_betrokkene_object_cache} = {} unless
        $self->{_betrokkene_object_cache};


    return $self->{_betrokkene_object_cache}->{ $betrokkene->id }
        = $self->_load_betrokkene_object(
            $betrokkene
        );
}

sub set_coordinator {
    my $self        = shift;
    my $identifier  = shift;

    my $bo          = $self->result_source
        ->schema
        ->resultset('Zaak')
        ->betrokkene_model;

    ## Set betrokkene-TYPE-ID
    my $betrokkene_ident  = $bo->set($identifier);

    ### Retrieve betrokkene ID from ident (GMID-ID)
    my ($gm_id, $betrokkene_id) = $betrokkene_ident =~ /(\d+)-(\d+)$/;

    $self->_betrokkene_delete($self->coordinator);

    $self->coordinator($betrokkene_id);
    $self->coordinator_gm_id($gm_id);
    $self->update;
};

sub set_behandelaar {
    my $self        = shift;
    my $identifier  = shift;

    my $bo          = $self->result_source
        ->schema
        ->resultset('Zaak')
        ->betrokkene_model;

    ## Set betrokkene-TYPE-ID
    my $betrokkene_ident  = $bo->set($identifier);

    ### Retrieve betrokkene ID from ident (GMID-ID)
    my ($gm_id, $betrokkene_id) = $betrokkene_ident =~ /(\d+)-(\d+)$/;

    $self->_betrokkene_delete($self->behandelaar);

    $self->behandelaar($betrokkene_id);
    $self->behandelaar_gm_id($gm_id);
    $self->update;
};

sub set_aanvrager {
    my $self        = shift;
    my $identifier  = shift;

    my $bo          = $self->result_source
        ->schema
        ->resultset('Zaak')
        ->betrokkene_model;

    ## Set betrokkene-TYPE-ID
    my $betrokkene_ident  = $bo->set($identifier);

    ### Retrieve betrokkene ID from ident (GMID-ID)
    my ($gm_id, $betrokkene_id) = $betrokkene_ident =~ /(\d+)-(\d+)$/;

    ### Delete current betrokkene
    $self->_betrokkene_delete($self->aanvrager);

    $self->aanvrager($betrokkene_id);
    $self->aanvrager_gm_id($gm_id);
    $self->update;
};

sub _betrokkene_delete {
    my $self        = shift;
    my $betrokkene  = shift;

    return unless $betrokkene;

    $betrokkene->deleted(DateTime->now());
    $betrokkene->update;
}

sub _load_betrokkene_object {
    my $self    = shift;
    my $object  = shift;

    my $searchid        = $object->id;
    my $searchintern    = 1;

    if (
        $object->betrokkene_type eq 'medewerker' ||
        $object->betrokkene_type eq 'org_eenheid'
    ) {
        $searchid = $object->gegevens_magazijn_id;
        $searchintern = 0;
    }

    return $self->result_source->schema->resultset('Zaak')->betrokkene_model->get(
        {
            'intern'    => $searchintern,
            'type'      => $object->betrokkene_type,
        }, $searchid
    );
}

after '_handle_logging' => sub {
    my $self            = shift;

    my $changed_data    = $self->_get_latest_changes;

    my @types           = qw/behandelaar coordinator aanvrager/;

    for my $type (@types) {
        if (exists($changed_data->{$type})) {
            if (!$changed_data->{$type} && $changed_data->{_is_insert}) {
                next;
            }

            $self->result_source->schema->resultset('Logging')->add({
                zaak_id         => $self->id,
                component       => 'betrokkene',
                onderwerp       => 'Betrokkene "'
                    . $type . '" gewijzigd naar: "'
                    . ($self->$type ? $self->$type->naam : '<Geen Betrokkene>')
                    . '"'
            });
        }
    }

    return $changed_data;

};


sub is_betrokkene_compleet {
    my $self    = shift;

    return 1 if $self->behandelaar;
    return;
}

around 'can_volgende_fase' => sub {
    my $orig    = shift;
    my $self    = shift;

    return unless $self->$orig(@_);

    if (!$self->is_betrokkene_compleet) {
        return;
    }

    return 1;
};

Params::Profile->register_profile(
    'method'    => 'betrokkene_relateren',
    'profile'   => BETROKKENE_RELATEREN_PROFILE
);

sub betrokkene_relateren {
    my $self        = shift;
    my $opts        = shift;

    my $identifier  = shift;

    my $dv          = Params::Profile->check(params => $opts);

    die('Parameters incorrect:' . Dumper($opts)) unless $dv->success;

    my $bo          = $self->result_source
        ->schema
        ->resultset('Zaak')
        ->betrokkene_model;

    my $magic_string_prefix =
        $self->betrokkenen_relateren_magic_string_suggestion(
            $opts
        ) or return;

    ### Don't add duplicated
    my $current_betrokkenen = $self->zaak_betrokkenen->search(
        {
            '-or'   => [
                { magic_string_prefix   => $magic_string_prefix },
                { rol                   => $opts->{rol} }
            ]
        }
    );

    return if $current_betrokkenen->count;

    eval {
        $self->result_source->schema->txn_do(sub {
            ## Set betrokkene-TYPE-ID
            my $betrokkene_ident  = $bo->set($opts->{betrokkene_identifier});

            ### Retrieve betrokkene ID from ident (GMID-ID)
            my ($gm_id, $betrokkene_id) = $betrokkene_ident =~ /(\d+)-(\d+)$/;

            ### Retrieve betrokkene_id from database and manipulate
            my $betrokkene              = $self->result_source
                ->schema
                ->resultset('ZaakBetrokkenen')
                ->find(
                    $betrokkene_id
                ) or return;

            $betrokkene->zaak_id($self->id);
            $betrokkene->verificatie('medewerker');
            $betrokkene->rol($opts->{rol});
            $betrokkene->magic_string_prefix($magic_string_prefix);
            $betrokkene->update;

            my $logmsg = 'Betrokkene: "' .
                $betrokkene->naam . '"'
                .' toegevoegd aan zaak, relatie: ' .
                $opts->{rol};

            $self->logging->add(
                {
                    component       => LOGGING_COMPONENT_ZAAK,
                    onderwerp       => $logmsg
                },
            );
        });
    };

    if ($@) {
        warn('There was a problem creating this betrokkene:' .
            $@
        );

        return;
    }

    return 1;
}

Params::Profile->register_profile(
    'method'    => 'betrokkenen_relateren_magic_string_suggestion',
    'profile'   => {
        'optional'      => [qw/
        /],
        'require_some'  => {
            'magic_string_or_rol'   => [
                1,
                'magic_string',
                'rol',
            ],
        },
        field_filters   => {
            magic_string_prefix    => sub {
                my $magic_string_prefix    = shift;
                $magic_string_prefix       =~ s/[^A-Za-z0-9]//;

                return lc($magic_string_prefix);
            },
            rol             => sub {
                my $rol             = shift;
                $rol                =~ s/[^A-Za-z0-9]//;

                return lc($rol);
            }
        }
    }
);

sub betrokkenen_relateren_magic_string_suggestion {
    my $self            = shift;
    my $opts            = shift;

    my $dv              = Params::Profile->check(params => $opts);

    die('Parameters incorrect:' . Dumper($opts)) unless $dv->success;

    ### Collect used columns in Zaaksysteem
    my @used_columns    = ();

    ### Collect used columns in this zaak
    my $betrokkenen = $self->zaak_betrokkenen->search(
        {
            'magic_string_prefix'   => { 'is not'   => undef }
        }
    );

    while (my $betrokkene = $betrokkenen->next) {
        push(@used_columns, $betrokkene->magic_string_prefix . '_naam');
    }

    return BETROKKENE_RELATEREN_MAGIC_STRING_SUGGESTION->(
        \@used_columns, $dv->valid('magic_string_prefix'), $dv->valid('rol')
    );
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

