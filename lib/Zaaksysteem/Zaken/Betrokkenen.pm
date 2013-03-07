package Zaaksysteem::Zaken::Betrokkenen;

use Moose::Role;

sub betrokkene_set {
    my ($self, $opts, $betrokkene_target, $betrokkene_info) = @_;

    if (UNIVERSAL::isa($betrokkene_info, 'HASH') && $betrokkene_info->{betrokkene}) {
        my $target;
        eval {
            $target = $self->_betrokkene_get_handle($betrokkene_info);
        };

        if ($@) {
            if ($betrokkene_target ne 'aanvrager') {
                die('Abort zaak, behandelaar of coordinator bestaat niet: ' . $@);
            } else {
                $target = $self->_betrokkene_get_handle(
                    {
                        betrokkene  =>  'betrokkene-bedrijf-'
                            . '7780'
                    }
                );
            }
        }

        $opts->{$betrokkene_target} = $target;
        if ($opts->{$betrokkene_target}) {
            my ($gmid)  = $betrokkene_info->{betrokkene} =~ /(\d+)$/;
            $opts->{$betrokkene_target . '_gm_id'} = $gmid;
        }

        return $opts->{$betrokkene_target};
    } elsif (
        UNIVERSAL::isa($betrokkene_info, 'HASH') &&
        $betrokkene_info->{gegevens_magazijn_id} &&
        $betrokkene_info->{betrokkene_id} &&
        $betrokkene_info->{betrokkene_type} &&
        $betrokkene_info->{verificatie}
    ) {
        $opts->{$betrokkene_target} =
            $self->_manual_betrokkene_create($betrokkene_info);

        if ($opts->{$betrokkene_target}) {
            $opts->{$betrokkene_target . '_gm_id'} =
                $betrokkene_info->{gegevens_magazijn_id};
        }

        return $opts->{$betrokkene_target};
    } elsif (
        UNIVERSAL::isa($betrokkene_info, 'HASH') &&
        $betrokkene_info->{betrokkene_type} &&
        $betrokkene_info->{verificatie} &&
        UNIVERSAL::isa($betrokkene_info->{create}, 'HASH')
    ) {
        unless ($self->_betrokkene_create_nieuw($betrokkene_info)) {
            die('Abort zaak, target betrokkene kan niet worden aangemaakt');
        }

        my $target;
        eval {
            $target = $self->_betrokkene_get_handle($betrokkene_info);
        };

        if ($@) {
            if ($betrokkene_target ne 'aanvrager') {
                die('Abort zaak, behandelaar of coordinator bestaat niet: ' . $@);
            } else {
                $target = $self->_betrokkene_get_handle(
                    {
                        betrokkene  =>  'betrokkene-bedrijf-'
                            . '7780'
                    }
                );
            }
        }

        $opts->{$betrokkene_target} = $target;
        if ($opts->{$betrokkene_target}) {
            my ($gmid)  = $betrokkene_info->{betrokkene} =~ /(\d+)$/;
            $opts->{$betrokkene_target . '_gm_id'} = $gmid;
        }

        return $opts->{$betrokkene_target};
    } else {
        die(
            'Only implementing structure: '
            . ' { betrokkene    => "betrokkene-TYPE-ID" }'
        );
    }
}

# OLD BTYPE MAP:
my $OLD_BTYPE_MAP = {
    natuurlijk_persoon  => 'gm_natuurlijk_persoon_id',
    medewerker          => 'medewerker_id',
    bedrijf             => 'gm_bedrijf_id',
    org_eenheid         => 'org_eenheid_id',
};

sub _betrokkene_create_nieuw {
    my ($self, $betrokkene_info) = @_;

    my $gmid = $self->z_betrokkene->create(
        $betrokkene_info->{betrokkene_type},
        {
            %{ $betrokkene_info->{create} },
            authenticated_by => $betrokkene_info->{verificatie}
        }
    );

    $betrokkene_info->{betrokkene} = 'betrokkene-'
        . $betrokkene_info->{betrokkene_type} . '-' . $gmid;

    return $gmid;
}

sub _manual_betrokkene_create {
    my ($self, $betrokkene_info) = @_;

    my ($raw_betrokkene,$old_betrokkene);
    
    my $colname = $OLD_BTYPE_MAP->{ $betrokkene_info->{betrokkene_type} };

    if ($self->can('dbic')) {
        $old_betrokkene = $self->dbic->resultset('Betrokkene')->find(
            $betrokkene_info->{betrokkene_id},
        );

        return unless $old_betrokkene;

        if (
            $betrokkene_info->{betrokkene_type} eq 'medewerker' ||
            $betrokkene_info->{betrokkene_type} eq 'org_eenheid'
        ) {
            $betrokkene_info->{betrokkene_id} =
                $betrokkene_info->{gegevens_magazijn_id}
        } else {
            $betrokkene_info->{betrokkene_id} =
                $old_betrokkene->$colname->id
        }

        $raw_betrokkene = $self->dbic->resultset('ZaakBetrokkenen')->create(
            $betrokkene_info
        );
    } else {
        $old_betrokkene = $self->result_source->schema->resultset('Betrokkene')->find(
            $betrokkene_info->{betrokkene_id},
        );

        return unless $old_betrokkene;

        if (
            $betrokkene_info->{betrokkene_type} eq 'medewerker' ||
            $betrokkene_info->{betrokkene_type} eq 'org_eenheid'
        ) {
            $betrokkene_info->{betrokkene_id} =
                $betrokkene_info->{gegevens_magazijn_id}
        } else {
            $betrokkene_info->{betrokkene_id} =
                $old_betrokkene->$colname->id
        }

        $raw_betrokkene = $self->result_source->schema->resultset('ZaakBetrokkenen')->create(
            $betrokkene_info
        );
    }

    return unless $raw_betrokkene;

    my ($internextern, $search_id) = (1, $raw_betrokkene->id);

    if (
        my $betrokkene = $self->z_betrokkene->get(
            {
                intern => 1,
                type    => $betrokkene_info->{betrokkene_type},
            }, $raw_betrokkene->id
        )
    ) {
        $raw_betrokkene->naam( $betrokkene->naam );
        $raw_betrokkene->update;
    }

    return $raw_betrokkene->id;
}

sub _betrokkene_get_handle {
    my ($self, $betrokkene_info) = @_;

    ## Set betrokkene-TYPE-ID
    my $betrokkene_ident  = $self->z_betrokkene->set($betrokkene_info->{betrokkene});

    die('Betrokkene not found [' . $betrokkene_info->{betrokkene} . ']')
        unless $betrokkene_ident;

    ### Retrieve TYPE
    my ($betrokkene_type) = $betrokkene_info->{betrokkene}
        =~ /betrokkene-([\w_]+)-/;

    ### Retrieve betrokkene ID from ident (GMID-ID)
    my ($betrokkene_id) = $betrokkene_ident =~ /-(\d+)$/;

    ### Retrieve just created betrokkene
    if (
        my $betrokkene = $self->z_betrokkene->get(
            {
                intern => 1,
                type    => $betrokkene_type,
            }, $betrokkene_id
        )
    ) {
        return $betrokkene_id;
    }

    die('ERROR: Cannot retrieve found betrokkene: ' .
        $betrokkene_info->{betrokkene}
    );

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

