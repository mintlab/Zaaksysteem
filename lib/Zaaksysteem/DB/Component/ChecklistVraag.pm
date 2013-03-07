package Zaaksysteem::DB::Component::ChecklistVraag;

use strict;
use warnings;

use Data::Dumper;

use base qw/DBIx::Class/;

sub added_columns {
    return [qw/
        mogelijkheden
    /];
}

sub mogelijkheden {
    my $self    = shift;

    if ($self->checklist_mogelijkhedens) {
        return $self->checklist_mogelijkhedens->_retrieve_as_session;
    }
}

1;
