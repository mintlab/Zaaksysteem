package Zaaksysteem::Betrokkene::Object;

use strict;
use warnings;
use Data::Dumper;

use Zaaksysteem::Betrokkene::Object::Notes;
use Zaaksysteem::Betrokkene::ResultSet;

use Moose;


my $BETROKKENE_TYPES = {
    'medewerker'            => 'Medewerker',
    'natuurlijk_persoon'    => 'NatuurlijkPersoon',
    'org_eenheid'           => 'OrgEenheid',
};

has 'types'     => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        return $BETROKKENE_TYPES;
    },
);

### Direct catalyst access
#has 'c'         => (
#    'is'        => 'rw',
#    'weak_ref'  => 1,
#);

has [qw/prod log dbic dbicg stash config customer/] => (
    'weak_ref'  => 1,
    'is'        => 'ro',
);

has '_dispatch_options' => (
    'is'    => 'ro',
    'lazy'  => 1,
    'default'   => sub {
        my $self    = shift;

        my $dispatch = {
            prod        => $self->prod,
            log         => $self->log,
            dbic        => $self->dbic,
            dbicg       => $self->dbicg,
            stash       => $self->stash,
            config      => $self->config,
            customer    => $self->customer,
        };

        Scalar::Util::weaken($dispatch->{stash});

        return $dispatch;
    }
);


### What was the trigger of the call, get, search etc
has 'trigger'      => (
    'is'    => 'rw'
);

### Type, well, should always be 'natuurlijk_persoon'
has 'type'      => (
    'is'    => 'rw'
);

### TODO ah why not, see other TODO
has 'bo'      => (
    'is'    => 'rw'
);

### There is always a betrokkene id
has 'id'        => (
    'is'    => 'rw',
);

### There is always a betrokkene_type
has 'btype'        => (
    'is'    => 'rw',
);

### And the identifier, when internal
has 'identifier' => (
    'is'    => 'rw',
);

### Authenticated by: can be: medewerker, kvk, gba
### or UNDEF (webform)
has 'authenticated_by' => (
    'is'    => 'rw',
);

### Only with GBA or KVK
has 'authenticated'    => (
    'is'    => 'rw',
);

has 'can_verwijderen'    => (
    'is'    => 'rw',
);

### BAG koppeling, dynamic
has 'verblijfsobject'   => (
    'is'    => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        return unless $self->can('verblijfsobject_id');

        return $self->verblijfsobject_id if $self->verblijfsobject_id;

        ### AAPJE, GEEN VERBLIJFSOBJECT? Find it using BAG postcode
        $self->log->debug(Dumper({
            'postcode'              => uc($self->postcode),
            'huisnummer'            => $self->huisnummer,
            'huisletter'            => (uc($self->huisletter) || undef),
            'huisnummertoevoeging'  => (uc($self->huisnummertoevoeging) || undef),
            'einddatum'             => undef,
        }));


        my $na = $self->dbicg->resultset('BagNummeraanduiding')->search({
            'postcode'              => uc($self->postcode),
            'huisnummer'            => $self->huisnummer,
            'huisletter'            => (uc($self->huisletter) || undef),
            'huisnummertoevoeging'  => (uc($self->huisnummertoevoeging) || undef),
            'einddatum'             => undef,
        });

        if ($na->count && $na->count == 1) {
            $na     = $na->first;

            my $vbo = $na->verblijfsobjecten->search({
                'einddatum' => undef,
            });

            if ($vbo->count) {
                return $vbo->first;
            }
        }

        return;
    }
);

has 'verblijfsobject_koppeling' => (
    'is'    => 'rw',
    'lazy'  => 1,
    'default'   => sub {
        my ($self) = @_;

        return unless $self->can('verblijfsobject_id');

        return unless $self->verblijfsobject_id;

        return 1;
    }
);

sub rt_identifier {
    my ($self) = @_;

    return $self->btype . '-'
        . $self->identifier;
}

sub rt_setup_identifier {
    my ($self) = @_;

    return 'betrokkene-' . $self->btype
        . '-' . $self->ex_id;
}

has 'betrokkene_identifier' => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        return shift->rt_setup_identifier;
    }
);

has 'ex_id' => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        if ($self->can('ldapid')) {
            return $self->ldapid;
        } elsif ($self->can('gmid')) {
            return $self->gmid;
        }
    }
);

has 'human_type' => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        if( $self->btype eq 'natuurlijk_persoon' ) {
            return 'Natuurlijk persoon';
        }

        if( $self->btype eq 'bedrijf' ) {
            return 'Niet natuurlijk persoon';
        }

        if( $self->btype eq 'medewerker' ) {
            return 'Behandelaar';
        }
    }
);

has 'notes'   => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        my $att_class           = __PACKAGE__ . '::Notes';

        return $att_class->new(
            'betrokkene'    => $self,
            %{ $self->_dispatch_options }
        )
    },
);

has [qw/is_overleden is_briefadres in_onderzoek/]  => (
    'is'    => 'ro',
);

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

