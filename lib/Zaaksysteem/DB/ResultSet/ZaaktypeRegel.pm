package Zaaksysteem::DB::ResultSet::ZaaktypeRegel;

use strict;
use warnings;

use Moose;
use Data::Dumper;
use Data::Serializer;

extends 'DBIx::Class::ResultSet', 'Zaaksysteem::Zaaktypen::BaseResultSet';


use constant    PROFILE => {
    optional        => [qw/
        naam
        settings
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

    foreach my $regel_id (keys %$element_session_data) {
        
        my $regel = $element_session_data->{$regel_id};
        delete $regel->{settings}; # settings is a json representation of the whole hash.
        $regel->{settings}= $self->_serializer->serialize($regel);        
    }

    $self->next::method( $node, $element_session_data );
}


sub _retrieve_as_session {
    my $self            = shift;

    my $rv              = $self->next::method();

    return $rv unless UNIVERSAL::isa($rv, 'HASH');

#    warn "retrieve as session ------------------------------";
#    warn Dumper $rv;

    foreach my $index (keys %$rv) {
        my $regel = $rv->{$index};
        
        eval {
            my $deserialized = $self->_serializer->deserialize($regel->{'settings'});
            foreach my $key (keys %$deserialized) {
                $regel->{$key} = $deserialized->{$key};
            }
        };
        if($@) {
            warn 'Could not deserialize regels: ' . $@;
        }
    }
#    warn Dumper $rv;

    return $rv;
}


#sub search_as_json {
#    my $self = shift;
#
#    my $resultset = $self->search({});
#    return $resultset;
#}


sub _retrieve {
    my $self            = shift;

    my $rv              = $self->next::method();

    return $rv unless UNIVERSAL::isa($rv, 'HASH');
#    warn "retrived lekker";
    return $rv;
}


sub _serializer {
	return Data::Serializer->new(
		serializer => 'JSON',
	);
}

1;


