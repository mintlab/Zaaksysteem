package Zaaksysteem::DB::ResultSet::ZaaktypeKenmerken;

use strict;
use warnings;

use Moose;

extends 'DBIx::Class::ResultSet', 'Zaaksysteem::Zaaktypen::BaseResultSet';

use Zaaksysteem::Constants qw/
    DEFAULT_KENMERKEN_GROUP_DATA
/;

use constant    PROFILE => {
    required        => [qw/
        bibliotheek_kenmerken_id
        label
    /],
    optional        => [qw/
        description
        help
        created
        pip
        zaakinformatie_view
        document_categorie
        value_mandatory
        value_default
    /],
};





sub _validate_session {
    my $self            = shift;
    my $profile         = PROFILE;
    my $rv              = {};

    $self->__validate_session(@_, $profile);
}

sub search {
    my $self            = shift;
    my $search          = shift;

    unless ($search) {
        $search         = {};
    }


    my $remove = $self->next::method($search, @_);

    return $remove;
}

sub _commit_session {
    my $self                    = shift;

    ### Remove old authorisations
    my $node                    = shift;
    my $element_session_data    = shift;

    use Data::Dumper;
    while (my ($key, $data) = each %{ $element_session_data }) {
        unless (
            (
                $data->{naam} &&
                $data->{bibliotheek_kenmerken_id}
            ) ||
            $data->{is_group}
        ) {
            delete($element_session_data->{$key});
        }
    }

    $self->next::method( $node, $element_session_data );
}


sub _retrieve_as_session {
    my $self            = shift;

    my $rv              = $self->next::method({
        search  => {
            is_group    => [ 1, undef ],
        }
    });

    return $rv unless UNIVERSAL::isa($rv, 'HASH');

    ### Detect groupen, when not found, create one
    ### BACKWARDS 1.1.9 COMPATIBILITY {
    if (scalar(keys %{ $rv }) && !$rv->{1}->{is_group}) {
        my $group_info  = DEFAULT_KENMERKEN_GROUP_DATA;

        my $newrv       = {};

        $newrv->{1} = $self->_get_session_template;
        $newrv->{1}->{zaaktype_node_id} = $rv->{1}->{zaaktype_node_id};
        $newrv->{1}->{zaak_status_id}   = $rv->{1}->{zaak_status_id};

        $newrv->{1}->{is_group}         = 1;
        $newrv->{1}->{help}             = $group_info->{help};
        $newrv->{1}->{label}            = $group_info->{label};

        for (my $counter = 2; $counter <= (scalar( keys %{ $rv }) + 1); $counter++) {
            $newrv->{ $counter } = $rv->{($counter - 1)};
        }

        $rv = $newrv;
    }
    ### } END BACKWARDS 1.1.9 COMPATIBILITY

    return $rv;
}

sub search_fase_kenmerken {
    my $self        = shift;
    my $fase        = shift;

    my $kenmerken   = $self->search(
        {
            zaak_status_id     => $fase->id,
        },
        {
            'order_by'  => { '-asc' => 'me.id' },
            'prefetch'  => 'bibliotheek_kenmerken_id'
        }
    );

    $kenmerken->count;

    if (scalar(@_)) {
        return $kenmerken->search(@_);
    }

    return $kenmerken;
}


1;
