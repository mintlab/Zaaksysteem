package Zaaksysteem::DB::Component::ZaaktypeSjablonen;

use strict;
use warnings;

use base qw/DBIx::Class/;

sub added_columns {
    return [qw/
        naam
    /];
}

sub naam {
    my $self    = shift;

    if ($self->bibliotheek_sjablonen_id) {
        return $self->bibliotheek_sjablonen_id->naam;
    }
}

1;
