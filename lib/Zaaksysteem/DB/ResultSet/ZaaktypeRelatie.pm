package Zaaksysteem::DB::ResultSet::ZaaktypeRelatie;

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
    my $self                    = shift;

    ### Remove old authorisations
    my $node                    = shift;
    my $element_session_data    = shift;

    use Data::Dumper;
    while (my ($key, $data) = each %{ $element_session_data }) {
        if ($data->{start_delay} =~ /^\d+\-\d+\-\d+$/) {
            $data->{delay_type}     = 'datum';
        } else {
            $data->{delay_type}     = 'dagen';
        }
    }

    $self->next::method(
        $node,
        $element_session_data,
        {
            status_id_column_name   => 'zaaktype_status_id',
        }
    );
}

1;
