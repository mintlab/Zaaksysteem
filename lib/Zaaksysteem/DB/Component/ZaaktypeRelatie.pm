package Zaaksysteem::DB::Component::ZaaktypeRelatie;

use strict;
use warnings;

use base qw/DBIx::Class/;

sub added_columns {
    return [qw/
        relatie_naam
    /];
}

sub relatie_naam {
    my $self    = shift;

    if ($self->relatie_zaaktype_id) {
        return $self->relatie_zaaktype_id->zaaktype_node_id->titel;
    }
}

1;
