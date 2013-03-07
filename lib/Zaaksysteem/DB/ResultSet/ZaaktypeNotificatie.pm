package Zaaksysteem::DB::ResultSet::ZaaktypeNotificatie;

use strict;
use warnings;

use Moose;

extends 'DBIx::Class::ResultSet', 'Zaaksysteem::Zaaktypen::BaseResultSet';

use constant    PROFILE => {
    required        => [qw/
        label
        rcpt
        onderwerp
        bericht
    /],
    optional        => [qw/
        intern_block
    /],
};

sub _validate_session {
    my $self            = shift;
    my $profile         = PROFILE;
    my $rv              = {};

    $self->__validate_session(@_, $profile);
}

1;
