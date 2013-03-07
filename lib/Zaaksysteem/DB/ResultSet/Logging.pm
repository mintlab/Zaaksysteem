package Zaaksysteem::DB::ResultSet::Logging;

use strict;
use warnings;

use Moose;

extends 'DBIx::Class::ResultSet';

sub is_alert {
    my $self    = shift;

    return $self->search(
        {
            is_bericht => 1,
        }
    )->count;
}

sub alerts {
    my $self    = shift;

    return $self->search(
        {
            is_bericht => 1,
        }
    );
}

sub add {
    my $self    = shift;
    my $opt     = shift;

    my $current_user        = $self->result_source
        ->schema
        ->resultset('Zaak')
        ->current_user;

    if ($current_user) {
        $opt->{betrokkene_id}   = $current_user->betrokkene_identifier;
    }

    $opt->{loglevel}      ||= 2;

    $opt->{onderwerp}       = substr($opt->{onderwerp},0,255);

    if ($opt && !$opt->{created}) {
        $opt->{created} = DateTime->now()->set_time_zone('Europe/Amsterdam');
    }

    $self->create($opt, @_);
}


1;
