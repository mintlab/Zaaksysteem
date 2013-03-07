package Zaaksysteem::SBUS::Logging::Object;

use Moose;
use Data::Serializer;

use constant TO_DB_MAPPING => {
    mutatie_type        => 'mutatie_type',
    object_type         => 'object',
    kerngegeven         => 'kerngegeven',
    label               => 'label',
    error               => 'error_message',
    created             => 'created',
};

has [qw/
    mutatie_type
    object_type
    params
    error
    kerngegeven
    label

    parent_object
    traffic_object
    is_flushed
/] => (
    'is'    => 'rw'
);

has 'changes'   => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $self = shift;

        return [];
    }
);

has 'created'   => (
    'is'        => 'rw',
    'default'   => sub {
        DateTime->now('time_zone'   => 'Europe/Amsterdam');
    }
);


sub record_has_changed {
    my $self    = shift;

    if (scalar(@{ $self->changes })) {
        return 1;
    }

    if (uc($self->mutatie_type) ne 'W') {
        return 1;
    }

    return;
}

sub change {
    my $self    = shift;
    my $opt     = shift;

    die('Invalid options for change') unless(
        exists($opt->{column}) &&
        exists($opt->{old}) &&
        exists($opt->{new})
    );

    push(
        @{ $self->changes },
        $opt
    );

    return 1;
}

sub success {
    return 1 unless shift->error;
    return;
}

sub flush {
    my ($self, $dbic) = @_;

    return if $self->is_flushed;

    my $TO_DB_MAPPING   = TO_DB_MAPPING;

    my $obj = Data::Serializer->new(
        'serializer'    => 'Storable',
    );

    my $create = {
        modified    => $self->created,
    };

    while (my ($key, $mapping) = each %{ $TO_DB_MAPPING }) {
        $create->{$mapping} = $self->$key;
    }

    if ($self->error) {
        $create->{error} = 1;
    }

    $create->{params}   = $obj->serialize($self->params)
        if $self->params;

    $create->{changes}  = $obj->serialize($self->changes)
        if $self->changes;

    if ($self->parent_object) {
        $create->{pid} = $self->parent_object->id;
    }

    if ($self->traffic_object) {
        $create->{sbus_traffic_id} = $self->traffic_object->id;
    }

    if (my $logobject = $dbic->resultset('SbusLogging')->create($create)) {
        $self->is_flushed(1);
        return $logobject;
    }

    return;
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

