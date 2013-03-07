package Zaaksysteem::SBUS::Request;

use Moose::Role;

use Zaaksysteem::SBUS::Constants;
use Clone qw/clone/;

=head1 NAME

Zaaksysteem::SBUS::Request - Zaaksysteem ServiceBus Request object, requesting
information from external resources, e.g. by calling a SOAP server.

=head1 SYNOPSIS

    my $sbus            = $c->model('SBUS');

    my $xml_response    = $sbus->request
        $c
        {
            operation   => 'kennisgeving',
            sbus_type   => 'StUF',
            object      => 'PRS',
            input       => {
                body        => {
                    PRS         => {
                        burgerservicenummer => 1,
                    }
                }
            },
            input_raw   => $c->stash->{soap}->envelope(),
        }
    );

    $c->stash->{soap}->compile_return(
        $xml_response
    )

=head1 DESCRIPTION

=cut

=head2 request

Arguments: $context_object, \%request_parameters

Return value: $lib_xml object

=cut

Params::Profile->register_profile(
    method  => 'request',
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

sub request {
    my ($self, $c, $raw_params) = @_;
    my $request;

    ### VALIDATION
    my $params;
    {
        my $dv = Params::Profile->check(
            params  => $raw_params,
        );

        die('Invalid call to request: ' . Dumper($dv))
            unless $dv->success;

        $params = $dv->valid;
    }

    my $to  = $self->_register_traffic($c, $params);

    return $self->_request(
        $params,
        $c,
        $to
    );
}

sub _request {
    my ($self, $request_params, $c, $to)    = @_;
    my $request;

    my $params = clone($request_params);


    eval {
        my $package = 'Zaaksysteem::SBUS::Objecten::'
            . $params->{object};

        $c->log->info(
            'ServiceBus request dispatching to object: ' . $params->{object}
            . ' / TYPE: ' . $params->{sbus_type}
        );

        my $object  = $package->new(app => $c);

        $request    = $object->handle_request(
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

    return $request;
}

1;
