package Zaaksysteem::DB::Component::ZaaktypeNode;

use strict;
use warnings;

use base qw/DBIx::Class/;

sub is_huidige_versie {
    my $self    = shift;

    if (
        $self->zaaktype_id &&
        $self->zaaktype_id->zaaktype_node_id->id eq $self->id
    ) {
        return 1;
    }

    return;
}


1;
