package Zaaksysteem::SBUS::Response;

use Moose::Role;

use Zaaksysteem::SBUS::Constants;

use Zaaksysteem::SBUS::Objecten::R03;
use Zaaksysteem::SBUS::Objecten::R02;
use Zaaksysteem::SBUS::Objecten::ADR;
use Zaaksysteem::SBUS::Objecten::PRS;

use Data::Dumper;


Params::Profile->register_profile(
    method  => 'response',
    profile => {
        required        => [qw/
            sbus_type
            object
            input
        /],
        optional        => [qw/
            input_raw
            operation
        /],
        constraint_methods  => {
            'object'    => sub {
                my ($dfv, $val)     = @_;

                my $SBUS_OBJECTS = SBUS_OBJECTS;
                if (grep { $_ eq $val } @{ $SBUS_OBJECTS }) {
                    return 1;
                }

                return;
            },
            'sbus_type'    => sub {
                my ($dfv, $val)     = @_;

                my $SBUS_TYPES = SBUS_TYPES;
                if (grep { $_ eq $val } @{ $SBUS_TYPES }) {
                    return 1;
                }

                return;
            }
        }
    }
);

sub response {
    my ($self, $c, $raw_params) = @_;
    my $response;

    ### VALIDATION
    my $params;
    {
        my $dv = Params::Profile->check(
            params  => $raw_params,
        );

        die('Invalid call to response: ' . Dumper($dv))
            unless $dv->success;

        $params = $dv->valid;
    }

    my $to  = $self->_register_traffic($c, $params);

    return $self->_response(
        $params,
        $c,
        $to
    );
}

sub _response {
    my ($self, $params, $c, $to)    = @_;
    my $response;

    eval {
        my $package = 'Zaaksysteem::SBUS::Objecten::'
            . $params->{object};

        $c->log->info(
            'ServiceBus request dispatching to object: ' . $params->{object}
            . ' / TYPE: ' . $params->{sbus_type}
        );

        my $object  = $package->new(app => $c);

        $response   = $object->handle_response(
            $params,
            {
                traffic_object  => $to,
            }
        );
    };

    if ($@) {
        $to->error(1);
        $to->error_message('SBUS Failure: ' . $@);
        $c->log->error($to->error_message);
    }

    $to->update;

    return $response;
}

sub response_from_id {
    my ($self, $c, $response_id) = @_;

    my $to      = $c->model('DB')->resultset('SbusTraffic')->find(
        $response_id
    );

    my $input   = $self->_deserialize($to->input);

    $c->log->info('ServiceBus request by id: ' . $response_id);

    return $self->_response(
        {
            input       => $input,
            object      => $to->object,
            sbus_type   => $to->sbus_type,
            input_raw   => $to->input_raw,
            operation   => $to->operation,
        },
        $c,
        $to
    );
}

1;
