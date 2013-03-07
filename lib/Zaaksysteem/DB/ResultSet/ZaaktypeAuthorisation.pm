package Zaaksysteem::DB::ResultSet::ZaaktypeAuthorisation;

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

    $self->__validate_session(
        @_,
        $profile,
    );
}

sub _commit_session {
    my $self            = shift;
    my $profile         = PROFILE;
    my $rv              = {};

    ### Remove old authorisations
    my ($node)          = @_;

    if ($node->zaaktype_id) {
        my $old_authorisations  = $self->search(
            {
                zaaktype_id     => $node->zaaktype_id->id
            }
        );

        if ($old_authorisations->count) {
            $old_authorisations->delete;
        }
    }

    $self->next::method( @_ );
}

1;
