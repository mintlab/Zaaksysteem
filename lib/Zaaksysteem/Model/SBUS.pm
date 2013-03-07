package Zaaksysteem::Model::SBUS;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model::Adaptor';

__PACKAGE__->config(
    class       => 'Zaaksysteem::SBUS',
    constructor => 'new',
);

sub prepare_arguments {
    my ($self, $app) = @_;

    return {
        'config'    => $app->config,
        'app'       => $app,
        #'log'       => $app->log,
        #'dbic'      => $app->model('DB'),
        #'dbicg'     => $app->model('DBG'),
    };
}

1;

__PACKAGE__->meta->make_immutable;

