package Zaaksysteem::DB::Component::Logging;

use strict;
use warnings;

use Data::Dumper;

use Zaaksysteem::Constants qw/
    ZAAKSYSTEEM_LOGGING_LEVELS
/;

use base qw/DBIx::Class/;


sub _set_effective_loglevel {
    my $self    = shift;

    my $levels  = ZAAKSYSTEEM_LOGGING_LEVELS;

    if ($self->loglevel) {
        $self->loglevel(
            $self->loglevel || 1
        );

        if ($self->loglevel !~ /^\d+$/) {
            $self->loglevel(
                $levels->{$self->loglevel} || 1
            );
        }
    }
}

sub insert {
    my $self    = shift;

    $self->_set_effective_loglevel;

    $self->next::method( @_ );
}

sub update {
    my $self    = shift;

    $self->_set_effective_loglevel;

    $self->next::method( @_ );
}

sub loglevel    {
    my $self    = shift;

    my $loglevel    = $self->next::method(@_);

    my $levels      = ZAAKSYSTEEM_LOGGING_LEVELS;

    return $levels->{ $loglevel };
}

1;
