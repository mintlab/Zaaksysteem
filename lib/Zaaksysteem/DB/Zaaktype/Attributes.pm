package Zaaksysteem::DB::Zaaktype::Attributes;

use strict;
use warnings;

use base qw(DBIx::Class);

sub insert {
    my $self = shift;

    use Data::Dumper;
    #die(Dumper($self));

    #return;
    return $self->next::method( @_ );
}

sub delete {
    my $self = shift;
    return $self->next::method( @_ );
}

sub update {
    my $self = shift;

    ### Dirty bastards

    return $self->next::method( @_ );
}

sub search {
    my $self = shift;
    die($self->{c});
}

sub find {
    my $self = shift;
    die($self->{c});
}

sub get {
    my $self = shift;
    die($self->{c});
}
1;
