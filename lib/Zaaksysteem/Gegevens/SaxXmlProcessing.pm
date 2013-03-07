package Zaaksysteem::Gegevens::SaxXmlProcessing;

use base qw(XML::SAX::Base);

use strict;
use warnings;

use Params::Profile;
use Data::Dumper;
use Zaaksysteem::Constants;

use Moose;
use namespace::autoclean;

has [qw/prod log dbicg db_cols active_group active_sub_group active_element group_node go_sub_node counter processing_unique table_name/] => (
    'is'    => 'rw',
);

has 'active_record' => (
    is      => 'rw',
    lazy    => 1,
    default => sub { {} },
);

has 'unique_record' => (
    is      => 'rw',
    lazy    => 1,
    default => sub { {} },
);

has 'bool_read_chars' => (
    is      => 'rw',
    default => 0,
);




sub start_document {
    my ($self, $doc) = @_;

    # Zetten van vars
    #$self->counter(0);
    $self->processing_unique(0);
}





sub start_element {
    my ($self, $el) = @_;

    my $cur_element = $el->{Name};

    # Zet het xpath_group element
    $self->active_group ($cur_element) if (exists $self->db_cols->{'xpath_group'}->{$el->{Name}});

    # Als een xpath_group is begonnen de elementen uitzoeken en in de terug-array zetten
    if ($cur_element =~ /^[\-:\w]+$/) {
        if (defined $self->active_group) {
            $self->group_node($self->db_cols->{'xpath_group'}->{$self->active_group}) if (!$self->go_sub_node) ;

            if (exists $self->group_node->{$cur_element}) {
                # Check of er een waarde uit een child moet worden gehaald
                if (ref($self->group_node->{$cur_element}) eq 'HASH') {
                    $self->active_sub_group ($cur_element);
                    $self->go_sub_node(1);
                    $self->group_node($self->group_node->{$cur_element});
                } else {
                    my $db_column_name = $self->group_node->{$cur_element};

                    $self->bool_read_chars(1);
                    $self->active_element($db_column_name);
                }
            }
        } else {
            if (exists $self->db_cols->{'xpath_unique'}->{$cur_element}) {
                $self->processing_unique(1);
                my $db_column_name = $self->db_cols->{'xpath_unique'}->{$cur_element};
                $self->bool_read_chars(1);
                $self->active_element($db_column_name);
            }
        }
    }
}





sub characters {
    my ($self, $characters) = @_;

    if ($self->bool_read_chars) {
        if ($self->processing_unique) {
            $self->unique_record->{$self->active_element} = $characters->{Data};
        } else {
            $self->active_record->{$self->active_element} = $characters->{Data};
        }
    }

    $self->bool_read_chars(0);
    $self->processing_unique(0);
}





sub end_element {
    my ($self, $el) = @_;

    if (defined $self->active_group) {
#        if ($el->{Name} eq $self->active_group) {
#            $self->counter($self->counter+1);
#        }

        # Voeg alle uniek gevonden waarden toe!
        my %uniques = %{ $self->unique_record };
        while (my ($key, $val) = each (%uniques)) {
            $self->active_record->{$key} = $val;
        }

        # Legen van het active_record voor een eventuele nieuwe opvulling
        if ($el->{Name} eq $self->active_group) {
            # Wegschrijven van de active_record naar de DB-Table
            #print $self->table_name.' - '.$self->counter."\n";#.Dumper($self->active_record);
            $self->dbicg->resultset($self->table_name)->update_or_create($self->active_record);

            #print Dumper($self->active_record);
            $self->active_record({});
        }
    }

    if (defined $self->active_sub_group) {
        if ($self->active_sub_group eq $el->{Name}) {
            if ($self->go_sub_node) {
                $self->go_sub_node(0);
            }
        }
    }
}

1;

=head1 PROJECT FOUNDER

Mintlab B.V. <info@mintlab.nl>

=head1 CONTRIBUTORS

Arne de Boer

Nicolette Koedam

Marjolein Bryant

Peter Moen

Michiel Ootjers

Jonas Paarlberg

Jan-Willem Buitenhuis

Martin Kip

Gemeente Bussum

=head1 COPYRIGHT

Copyright (c) 2009, the above named PROJECT FOUNDER and CONTRIBUTORS.

=head1 LICENSE

The contents of this file and the complete zaaksysteem.nl distribution
are subject to the EUPL, Version 1.1 or - as soon they will be approved by the
European Commission - subsequent versions of the EUPL (the "Licence"); you may
not use this file except in compliance with the License. You may obtain a copy
of the License at
L<http://joinup.ec.europa.eu/software/page/eupl>

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

=cut

