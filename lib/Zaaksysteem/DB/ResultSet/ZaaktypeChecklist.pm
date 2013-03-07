package Zaaksysteem::DB::ResultSet::ZaaktypeChecklist;

use strict;
use warnings;

use Moose;

extends 'DBIx::Class::ResultSet', 'Zaaksysteem::Zaaktypen::BaseResultSet';

use constant    PROFILE => {
    required        => [qw/
    /],
    optional        => [qw/
    /],
};

sub _validate_session {
    my $self            = shift;
    my $profile         = PROFILE;
    my $rv              = {};

    $self->__validate_session(@_, $profile);
}

sub _commit_session {
    my $self            = shift;
    my $profile         = PROFILE;
    my $rv              = {};

    $self->next::method(
        @_,
        {  
            status_id_column_name   => 'zaaktype_status_id',
        }
    );
}


1;
