package Zaaksysteem::DB::ResultSet::ZaaktypeAttributen;

use strict;
use warnings;
use Data::Dumper;

use Moose;
use Zaaksysteem::Constants qw/
    ZAAKTYPE_DB_MAP
    ZAAKTYPE_PREFIX_SPEC_KENMERK

    ZAAKTYPE_KENMERKEN_ZTC_DEFINITIE
/;

extends 'DBIx::Class::ResultSet', 'Zaaksysteem::Zaaktypen::BaseResultSet';

use constant ZTN_SEARCH => {};

has ['nid', 'nido']     => (
    'is'    => 'rw',
);

has ['_kenmerken']      => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub { {} }
);

has 'ztc_definitie'    => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        return ZAAKTYPE_KENMERKEN_ZTC_DEFINITIE;
    }
);

has 'get_raw'            => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return $self->_kenmerken->{kenmerken}
            if %{ $self->_kenmerken };

        return $self->_all_kenmerken->{kenmerken}
    }
);

has 'get_raw_ztc'        => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return $self->_kenmerken->{ztc}
            if %{ $self->_kenmerken };

        return $self->_all_kenmerken->{ztc};
    }
);

sub get {
    my ($self, $kenmerk_naam)   = @_;
    my ($kenmerk);

    if ($kenmerk_naam =~ /^\d+$/) {
        ($kenmerk) = grep {
                $_->{id} eq $kenmerk_naam
        } @{ $self->get_raw };
    } else {
        ($kenmerk) = grep {
                $_->{naam} eq $kenmerk_naam
        } @{ $self->get_raw };
    }

    return $kenmerk;
}

sub get_ztc {
    my ($self, $kenmerk_naam)   = @_;
    my ($kenmerk);

    if ($kenmerk_naam =~ /^\d+$/) {
        ($kenmerk) = grep {
                $_->{id} eq $kenmerk_naam
        } @{ $self->get_raw_ztc };
    } else {
        ($kenmerk) = grep {
                $_->{naam} eq $kenmerk_naam
        } @{ $self->get_raw_ztc };
    }

    return $kenmerk;
}


sub search {
    my $self    = shift;

    $self->next::method(@_);
}

sub _all_kenmerken {
    my $self    = shift;

    my $kenmerken = $self->search(
        ZTN_SEARCH,
        {
            order_by => [
                { -asc => 'id' },
            ],
        }
    );

    $self->_kenmerken({
        'kenmerken' => [],
        'ztc'       => [],
    });

    while (my $kenmerk = $kenmerken->next) {
        my $dbkenmerk = {};
        while (my ($key, $dbkey) = each %{ ZAAKTYPE_DB_MAP->{kenmerken} }) {
            ### Backwards compatibility...don't ask
            ### We need to remove the darn ztc_
            if (
                $kenmerk->attribute_type ne ZAAKTYPE_PREFIX_SPEC_KENMERK &&
                $dbkey eq 'key'
            ) {
                my $dbkeyvalue = $kenmerk->$dbkey;
                $dbkeyvalue =~ s/^ztc_//;
                $dbkenmerk->{$key} = $dbkeyvalue;
            } else {
                $dbkenmerk->{$key} = $kenmerk->$dbkey;
            }
        }

        if (my $options = $kenmerk->zaaktype_values) {
            $options->search(
                {},
                {
                    order_by => [
                        { -asc => 'id' },
                    ],
                }
            );

            if ($kenmerk->attribute_type eq ZAAKTYPE_PREFIX_SPEC_KENMERK) {
                $dbkenmerk->{options} = [];
                while (my $option = $options->next) {
                    push(
                        @{ $dbkenmerk->{options} },
                        $option->value
                    );
                }
            } else {
                $dbkenmerk->{value}  = $options->first->value;
            }
        }

        if ($kenmerk->attribute_type eq ZAAKTYPE_PREFIX_SPEC_KENMERK) {
            push(
                @{ $self->_kenmerken->{kenmerken} },
                $dbkenmerk
            );
        } else {
            push(
                @{ $self->_kenmerken->{ztc} },
                $dbkenmerk
            );
        }
    }

    return $self->_kenmerken;
}


sub clear_zt {
    my $self    = shift;

    $self->_kenmerken = {};
}

1;
