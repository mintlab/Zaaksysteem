package Zaaksysteem::DB::Component::BibliotheekCategorie;

use strict;
use warnings;
use Data::Dumper;

use base qw/DBIx::Class/;

sub list_of_children {
    my $self        = shift;
    my $rv          = [];

    my $children    = $self->categorien->search;
    while (my $child = $children->next) {
        push(@{ $rv }, @{ $child->list_of_children });
        push(@{ $rv }, $child->id);
    }

    return $rv;
}


1;
