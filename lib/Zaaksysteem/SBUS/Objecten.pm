package Zaaksysteem::SBUS::Objecten;

use Moose;
use Data::Dumper;

has [qw/app/]   => (
    'is'    => 'rw',
);

### options contains
### {
###     traffic_object
### }
sub handle_response {
    my ($self, $params, $options) = @_;

    $self->_verify_capability;

    my $operation   = $params->{operation};
    my $stufxml     = $params->{input};

    my ($return_value);
    eval {
        ### Do stuff
        my $prepared_params;

        ### Check if we need to use an adapter to get the required arguments
        ### from the parameters
        my ($adapter);
        if ($params->{sbus_type}) {
            my $adapter_package = 'Zaaksysteem::SBUS::Types::'
                . $params->{sbus_type} . '::'
                . $params->{object};

            $adapter            = $adapter_package->new(
                app => $self->app
            );

            $prepared_params    = $adapter->prepare_response_parameters(
                $params,
                $options
            );

            die(
                'Servicebus requested object: ' . $params->{object}
                . ', but the sbus_type did not return any parameters: '
                . $params->{sbus_type}
            ) unless $prepared_params;
        } else {
            $prepared_params    = $params->{input};
        }

        ### options to options
        $options->{mutatie_type}    = $prepared_params->{mutatie_type};
        delete($prepared_params->{mutatie_type});

        my $result                  = $self->_commit_to_database(
            $prepared_params,
            $options
        );

        $self->_flush_logobject(
            $result, $options->{traffic_object}
        ) if $result;

        if ($adapter) {
            $return_value           = $adapter->generate_response_return(
                $params,
                $prepared_params,
                $options,
                $result
            );
        }
    };

    if ($@) {
        $options->{traffic_object}->error(1);
        $options->{traffic_object}->error_message(
            'Error handling stuf XML: ' . $@
        );
        $self->app->log->error('Error handling stuf XML: ' . $@);
    }

    return $return_value;
}

sub handle_request {
    my ($self, $params, $options) = @_;

    $self->_verify_capability;

    my $operation   = $params->{operation};
    my $stufxml     = $params->{input};

    my ($return_value);
    eval {
        ### Do stuff
        my $prepared_params;

        ### Check if we need to use an adapter to get the required arguments
        ### from the parameters
        my ($adapter);
        if ($params->{sbus_type}) {
            my $adapter_package = 'Zaaksysteem::SBUS::Types::'
                . $params->{sbus_type} . '::'
                . $params->{object};

            $adapter            = $adapter_package->new(
                app => $self->app
            );

            $prepared_params    = $adapter->prepare_request_parameters(
                $params,
                $options
            );

            die(
                'Servicebus requested object: ' . $params->{object}
                . ', but the sbus_type did not return any parameters: '
                . $params->{sbus_type}
            ) unless $prepared_params;
        } else {
            $prepared_params    = $params->{input};
        }

        ### options to options
        $options->{mutatie_type}    = $prepared_params->{mutatie_type};
        delete($prepared_params->{mutatie_type});

        if ($options->{dispatch_type} && $adapter) {
            my $dispatcher  = '_dispatch_' . $options->{dispatch_type};

            if (my $coderef = $adapter->can($dispatcher)) {
                $return_value = $coderef->(
                    $adapter,
                    $options->{dispatch_method},
                    $prepared_params,
                    $options
                );
            }
        }
    };

    if ($@) {
        $options->{traffic_object}->error(1);
        $options->{traffic_object}->error_message(
            'Error handling stuf XML: ' . $@
        );
        $self->app->log->error('Error handling stuf XML: ' . $@);
    }

    return $return_value;
}

sub _flush_logobject {
    my ($self, $logobject, $to) = @_;

    ### Got log object, flush to DB after given traffic object
    if ($logobject) {
        $logobject->traffic_object($to);
        $logobject->flush($self->app->model('DB'));
    }
}


sub _verify_capability {
    my ($self, $params) = @_;

    return 1 unless $params->{sbus_type};

    unless ($self->_capability->{ $params->{sbus_type} }) {
        die(
            'Servicebus requested object: ' . $params->{object}
            . ', but the sbus_type given not exist: ' . $params->{sbus_type}
        );
    }

    return 1;
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

