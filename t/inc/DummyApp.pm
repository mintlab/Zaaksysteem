package DummyApp;

use Moose;

has [qw/log models/] => (
    'is'    => 'rw',
);

sub model {
    my $self = shift;
    my $req  = shift;

    if ($self->models && $self->models->{$req}) {
        return $self->models->{$req};
    }

    return;
}

1;
