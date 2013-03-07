package Zaaksysteem::DB::Component::BagNummeraanduiding;

use strict;
use warnings;

use base qw/Zaaksysteem::DB::Component::BagGeneral/;

sub nummeraanduiding {
    my $self    = shift;

    return $self->huisnummer . $self->huisletter .
        ($self->huisnummertoevoeging
            ? '-' . $self->huisnummertoevoeging
            : ''
        );

}

1;
