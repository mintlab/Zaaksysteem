package Zaaksysteem::SBUS;

use strict;
use warnings;

use Zaaksysteem::Constants;
use Zaaksysteem::SBUS::Constants;

use Data::Serializer;

use Params::Profile;
use Data::Dumper;

use Moose;
use namespace::autoclean;

with
    'Zaaksysteem::SBUS::StoreRole',
    'Zaaksysteem::SBUS::Response',
    'Zaaksysteem::SBUS::Request',
    'Zaaksysteem::SBUS::Dispatcher::Soap';


=head1 NAME

Zaaksysteem::SBUS - Zaaksysteem ServiceBus, for importing and querying
different koppelingen.

=head1 SYNOPSIS

    my $sbus            = $c->model('SBUS');

    my $xml_response    = $sbus->response(
        $c
        {
            operation   => 'kennisgeving',
            sbus_type   => 'StUF',
            object      => 'PRS',
            input       => $XmlCompileReader_object,
            input_raw   => $c->stash->{soap}->envelope(),
        }
    )

    $c->stash->{soap}->compile_return(
        $xml_response
    )

=head1 DESCRIPTION

The ServiceBus is able to parse external requests and dispatch them to the
necessary 'gegevensmagazijn' tables.

It is able to retrieve information from other companies by requesting
information with soap calls, or it can parse incoming information.

See L<Zaaksysteem::SBUS::Response> for information about processing INCOMING data
See L<Zaaksysteem::SBUS::Request> for requesting data from other companies

=cut

has [qw/config customer dbic dbicg app/] => (
    'is'        => 'rw',
);

has 'log'   => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        my $app     = $self->app;

        return $app->log;
    }
);



=head2 dispatch

Arguments: $dispatcher_name, \%options

Dispatch Service Bus call to dispatcher, e.g. Soap, see
L<Zaaksysteem::SBUS::Dispatcher::Soap>

=cut

sub dispatch {
    my $self        = shift;
    my $dispatcher  = shift;

    die('Dispatcher: ' . $dispatcher . ' not found, make sure '
        . __PACKAGE__ . '::Dispatcher::'
        . ucfirst($dispatcher) . ' exists'
    ) unless $self->can('_dispatch_' . $dispatcher);

    my $sub         = '_dispatch_' . $dispatcher;

    $self->$sub(@_);
}

=head1 PRIVATE METHODS

=head2 _serialize

Arguments: $value

Return value: $serialized_value

Serializes a value (like a hashref) with Storable and returns serialized
object

=cut

sub _serialize {
    my ($self, $value) = @_;

    my $obj = Data::Serializer->new(
        serializer  => 'Storable',
    );

    return $obj->serialize($value);
}

=head2 _deserialize

Arguments: $serialized_value

Return value: $value

Returns the raw value which is serialized by Storable

=cut

sub _deserialize {
    my ($self, $value) = @_;

    my $obj = Data::Serializer->new(
        serializer  => 'Storable',
    );

    return $obj->deserialize($value);
}

=head2 _register_traffic

Arguments: \%create_parameters

Return value: $new_row

Returns the traffic_row from table SbusTraffic, serializes any params which
are a reference to like a HASH or ARRAY

=cut


sub _register_traffic {
    my ($self, $c, $params) = @_;

    my $SBUS_TRAFFIC_PARAMS = SBUS_TRAFFIC_PARAMS;

    my $create  = {};
    for my $param (@{ $SBUS_TRAFFIC_PARAMS }) {
        if (ref($params->{$param})) {
            $create->{$param} = $self->_serialize($params->{$param});
            next;
        }
        $create->{$param} = $params->{$param};
    }

    return $c->model('DB')->resultset('SbusTraffic')->create($create);
}

__PACKAGE__->meta->make_immutable;


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

