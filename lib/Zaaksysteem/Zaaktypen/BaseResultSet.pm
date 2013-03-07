package Zaaksysteem::Zaaktypen::BaseResultSet;

use strict;
use warnings;

use Data::Dumper;

use Moose;

use constant ZAAKTYPE_PREFIX  => 'zaaktype_';


sub _retrieve_columns {
    my ($self, $no_extras)  = @_;

    my @columns     = $self->result_source->columns;
    return @columns if $no_extras;

    ### It is possible we ask a relation with extra information,
    ### when the component exports extra_columns, we can add
    ### these to the columns information
    if ($self->result_source->result_class->can('added_columns')) {
        push(
            @columns,
            @{ $self->result_source->result_class->added_columns }
        );
    }

    return @columns;
}

sub _get_session_template {
    my ($self) = @_;

    my $template = {};
    for my $key ($self->_retrieve_columns) {
        $template->{$key} = undef;
    }

    return $template;
}

sub __validate_session {
    my ($self, $element_session_data, $profile, $single)    = @_;

    my $rv                                                  = {};

    return unless UNIVERSAL::isa($element_session_data, 'HASH');

    Params::Profile->register_profile(
        method => '__validate_session',
        profile => $profile,
    );

    if ($single) {
        $rv = Params::Profile->check(
            params  => $element_session_data
        );
    } else {
        while (my ($counter, $data) = each %{ $element_session_data }) {
            $rv->{$counter} = Params::Profile->check(
                params  => $data
            );
        }
    }

    return $rv;
}


sub _retrieve_as_session {
    my $self            = shift;
    my $extra_options   = shift;

    my @columns     = $self->_retrieve_columns;

    my $counter     = 0;

    my $rv          = {};

    my $search      = {};
    if ($extra_options && $extra_options->{search}) {
        $search     = $extra_options->{search};
    }

    my $rows        = $self->search(
        $search,
        {
            order_by    => 'id'
        }
    );

    while (my $row  = $rows->next) {
        $rv->{++$counter} = {};
        for my $column (@columns) {
            ### When this is a reference to another table, just
            ### retrieve the id
            if (
                UNIVERSAL::can($row->$column, 'isa') &&
                $row->$column->can('id')
            ) {
                $rv->{$counter}->{$column}  = $row->$column->id;
            } elsif (
                !ref($row->$column) ||
                !UNIVERSAL::can($row->$column, 'isa')
            ) {
                $rv->{$counter}->{$column} = $row->$column;
            }
        }
    }

    return $rv;
}

sub _commit_session {
    my ($self, $node, $element_session_data, $options)    = @_;
    my $rv = {};

    return unless UNIVERSAL::isa($element_session_data, 'HASH');

    my @keys    = sort { $a <=> $b } keys %{$element_session_data};
    foreach my $counter (@keys) {
        my $data_params                     = $element_session_data->{$counter};

        my $data                            = {};

        my @columns                         = $self->_retrieve_columns(1);

        $data->{ $_ }                       = $data_params->{ $_ } for @columns;

        delete($data->{id});
        delete($data->{zaaktype_node_id});

        if ($node->can('status')) {
            if (
                $options && $options->{'status_id_column_name'}
            ) {
                $data->{ $options->{'status_id_column_name'} }     = $node->id;
            } else {
                $data->{ 'zaak_status_id' }     = $node->id;
            }

            $data->{zaaktype_node_id}   = $node->zaaktype_node_id->id,
        } elsif (grep({ $_ eq 'zaaktype_node_id' } @columns)) {
            $data->{zaaktype_node_id}   = $node->id,
        }

        if (grep({ $_ eq 'zaaktype_id' } @columns) && $node->can('zaaktype_id')) {
            $data->{zaaktype_id} = $node->zaaktype_id->id;
        }

        if ($options->{extra_data}) {
            while (my ($extracol, $extradata) = %{ $options->{extra_data} }) {
                $data->{$extracol} = $extradata;
            }
        }

        $rv->{$counter} = $self->create($data);
    }

    return $rv;
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

