package Zaaksysteem::DB::ResultSet::Zaaktype;

use strict;
use warnings;

use Moose;
use Zaaksysteem::Constants;

extends 'DBIx::Class::ResultSet', 'Zaaksysteem::Zaaktypen::BaseResultSet';

__PACKAGE__->load_components(qw/Helper::ResultSet::SetOperations/);

# COMPLETE: 100%
use constant    PROFILE => {
    required        => [qw/
        bibliotheek_categorie_id
    /],
    optional        => [qw/
    /],
    msgs            => PARAMS_PROFILE_DEFAULT_MSGS,
};

sub _validate_session {
    my $self            = shift;
    my $profile         = PROFILE;
    my $rv              = {};

    $self->__validate_session(@_, $profile, 1);
}

1;
