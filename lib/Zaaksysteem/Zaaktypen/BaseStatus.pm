package Zaaksysteem::Zaaktypen::BaseStatus;

use strict;
use warnings;

use Data::Dumper;
use Params::Profile;

use Moose;

extends 'DBIx::Class::ResultSet';

use constant STATUS_PREFIX  => 'zaaktype_';
use constant STATUS_RELATIES => [qw/
    zaaktype_kenmerken
    zaaktype_sjablonen
    zaaktype_relaties
    zaaktype_notificaties
    zaaktype_resultaten
    zaaktype_checklists
    zaaktype_regels
/];

#    zaaktype_regels

use constant PARAMS_PROFILE_STATUS  => {
    'required'      =>  [qw/
        status
        naam
    /],
    'optional'      => [qw/
        status_type
        omschrijving
        help
        ou_id
        role_id
        afhandeltijd
        zaaktype_node_id
    /],
    constraint_methods  => {
        'status'        => qr/^\d+$/,
        'naam'          => qr/^[\w\d ]+$/,
        'status'        => qr/^\d+$/,
    },
    defaults            => {
        status_type     => 'behandelen',
    },
};

### XXX MOVE LOWER CLASS
sub _retrieve_columns {
    my ($self)  = @_;

    my @columns     = $self->result_source->columns;

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

### XXX MOVE LOWER CLASS
sub _get_session_template {
    my ($self) = @_;

    my $relaties        = STATUS_RELATIES;
    my $relatieprefix   = STATUS_PREFIX;


    my $template = {
        'definitie' => {},
        'elementen' => {},
    };

    for my $key ($self->_retrieve_columns) {
        $template->{definitie}->{$key} = undef;
    }

    for my $relatie (@{ $relaties }) {
        my $relatie_info    =
            $self->result_source->relationship_info($relatie);

        my $relatie_object  = $self->result_source->schema->resultset($relatie_info->{source});

        next unless $relatie_object->can('_get_session_template');

        $relatie    =~ s/$relatieprefix//g;

        $template->{elementen}->{$relatie} =
            $relatie_object->_get_session_template;

        #$dv_error = 1 unless ($rv->{$status}->{elementen}->{$element}->success
    }

    return $template;
}

sub _validate_session_self {
    my ($self, $status_info)    = @_;

    my $rv                      = {};

    ### Get profile from Model
    my $profile = PARAMS_PROFILE_STATUS;

    Params::Profile->register_profile(
        method => '_validate_session_self',
        profile => $profile,
    );

    my $dv      = Params::Profile->check(
        params  => $status_info->{definitie} || {},
    );

    return $dv;
}

sub _validate_session {
    my ($self, $session)    = @_;

    my $rv                  = {};

    my $relatieprefix       = STATUS_PREFIX;

    ### Validate self
    while (my ($status, $status_info) = each %{ $session }) {
        my $dv_error = 0;

        $rv->{$status}              = {
            'definitie'     => {},
            'elementen'     => {},
            'success'       => 0,
        };

        ### Eigen status definitie
        $rv->{$status}->{definitie} = $self->_validate_session_self($status_info);

        $dv_error = 1 unless $rv->{$status}->{definitie}->success;

        ### Alle elementen, zoals notificatie / resultaten / relaties
        ### (subzaken) etc
        while (
            my ($element, $element_data) =
                each %{ $session->{$status}->{elementen} }
        ) {
            my $relatie_info    =
                $self->result_source->relationship_info($relatieprefix . $element);


            next unless ($relatie_info || $relatie_info->{source});

            my $relatie_object  = $self->result_source->schema->resultset($relatie_info->{source});

            next unless $relatie_object->can('_validate_session');

            $rv->{$status}->{elementen}->{$element} =
                $relatie_object->_validate_session($element_data);

            #$dv_error = 1 unless ($rv->{$status}->{elementen}->{$element}->success
        }

        $rv->{$status}->{success} = 1 unless $dv_error;
    }

    return $rv;
}

sub _retrieve_as_session {
    my $self        = shift;
    my $extraopts   = shift;

    my @columns     = $self->_retrieve_columns;

    my $counter     = 0;

    my $rv          = {};

    my $rows        = $self->search(
        {},
        {
            order_by    => 'id'
        }
    );


    my $relaties        = STATUS_RELATIES;
    my $relatieprefix   = STATUS_PREFIX;

    while (my $row  = $rows->next) {
        $rv->{$row->status} = {
            definitie   => {},
            elementen   => {},
        };
        for my $column (@columns) {
            ### When this is a reference to another table, just
            ### retrieve the id
            if (!ref($row->$column)) {
                $rv->{$row->status}->{definitie}->{$column} = $row->$column;
            }
        }

        for my $relatie (@{ $relaties }) {
            next unless $row->$relatie->can('_retrieve_as_session');

            ### Remove prefix,
            ### eg: $rv->{kenmerken} ipv $rv->{zaaktype_kenmerken}
            my $key         = $relatie;
            $key            =~ s/^$relatieprefix//;

            $rv->{$row->status}->{elementen}->{$key}     = $row->$relatie->_retrieve_as_session($extraopts);
        }
    }

    return $rv;
}

sub _commit_session_self {
    my ($self, $node, $status_params)   = @_;

    my $rv                              = {};
    my $status_info                     = {};

    my @columns                         = $self->_retrieve_columns;
    $status_info->{ $_ }                = $status_params->{ $_ } for @columns;


    ### Get profile from Model
    delete($status_info->{id});

    my $data = {
        %{ $status_info },
        'zaaktype_node_id'  => $node->id,
    };

    $self->create($data);
}

sub _commit_session {
    my ($self, $node, $session)    = @_;

    my $rv                  = {};

    my $relatieprefix       = STATUS_PREFIX;

    ### Validate self
    while (my ($status, $status_info) = each %{ $session }) {
        my $dv_error = 0;

        $rv->{$status}              = {
            'definitie'     => {},
            'elementen'     => {},
            'success'       => 0,
        };

        ### Eigen status definitie
        my $db_status               = $self->_commit_session_self(
            $node,
            $status_info->{definitie}
        );

        $rv->{$status}->{definitie} = $db_status;

        ### Alle elementen, zoals notificatie / resultaten / relaties
        ### (subzaken) etc
        while (
            my ($element, $element_data) =
                each %{ $session->{$status}->{elementen} }
        ) {
            my $relatie_info    =
                $self->result_source->relationship_info($relatieprefix . $element);

            next unless ($relatie_info && $relatie_info->{source});

            my $relatie_object  = $self->result_source->schema->resultset($relatie_info->{source});

            next unless $relatie_object->can('_commit_session');
            #next unless $element eq 'notificaties';

            $rv->{$status}->{elementen}->{$element} =
                $relatie_object->_commit_session($db_status, $element_data);

            #$dv_error = 1 unless ($rv->{$status}->{elementen}->{$element}->success
        }

        $rv->{$status}->{success} = 1 unless $dv_error;
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

