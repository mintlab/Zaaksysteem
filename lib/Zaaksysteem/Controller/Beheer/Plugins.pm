package Zaaksysteem::Controller::Beheer::Plugins;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }




sub base : Chained('/') : PathPart('beheer/plugins'): CaptureArgs(1) {
    my ( $self, $c, $import_id ) = @_;

    $c->stash->{entry} = $c->model('DB::BeheerPlugins')->find($import_id);

    if (!$c->stash->{entry}) {
        $c->res->redirect($c->uri_for('/beheer/plugins'));
        $c->detach;
    }

    $c->add_trail(
        {
            uri     => $c->uri_for('/beheer/plugins/'),
            label   => 'Plugins'
        },
    );
    $c->add_trail(
        {
            uri     => $c->uri_for('/beheer/plugins/' . $c->stash->{entry}->id),
            label   => $c->stash->{entry}->label
        }
    );
}

sub index : Chained('/') : PathPart('beheer/plugins'): Args(0) {
    my ( $self, $c ) = @_;

    $c->add_trail(
        {
            uri     => $c->uri_for('/beheer/plugins/'),
            label   => 'Plugins'
        }
    );

    $c->stash->{plugin_list} = $c->model('DB::BeheerPlugins')->search(
        {
        },
        {
            order_by    => 'label'
        }
    );

    $c->stash->{template} = 'beheer/plugins/list.tt';
}

sub view : Chained('base') : PathPart(''): Args() {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'beheer/plugins/view.tt'
}

sub inschakelen : Chained('base') : PathPart('inschakelen'): Args() {
    my ( $self, $c ) = @_;

    if ($c->req->params->{confirmed}) {
        $c->log->debug(
            'Schakel plugin ' . $c->stash->{entry}->label . ' uit'
        );

        $c->stash->{entry}->actief(1);

        if ($c->stash->{entry}->update) {
            $c->flash->{result} =
                'Plugin "' . $c->stash->{entry}->label
                . '" succesvol ingeschakeld';
        } else {
            $c->flash->{result} =
                'ERROR:  Plugin "' . $c->stash->{entry}->label
                . '"  kon niet worden ingeschakeld';
        }

        $c->res->redirect($c->uri_for(
            '/beheer/plugins'
        ));
        $c->detach;
    }

    $c->stash->{confirmation}->{message}    =
        'Weet u zeker dat u de plugin "' . $c->stash->{entry}->label . '"'
        . ' wilt inschakelen?';

    $c->stash->{confirmation}->{type}       = 'yesno';
    $c->stash->{confirmation}->{uri}        = $c->uri_for(
        '/beheer/plugins/' . $c->stash->{entry}->id
        . '/inschakelen'
    );

    $c->forward('/page/confirmation');
    $c->detach;
}

sub uitschakelen : Chained('base') : PathPart('uitschakelen'): Args() {
    my ( $self, $c ) = @_;

    if ($c->req->params->{confirmed}) {
        $c->log->debug(
            'Schakel plugin ' . $c->stash->{entry}->label . ' uit'
        );

        $c->stash->{entry}->actief(0);

        if ($c->stash->{entry}->update) {
            $c->flash->{result} =
                'Plugin "' . $c->stash->{entry}->label
                . '" succesvol uitgeschakeld';
        } else {
            $c->flash->{result} =
                'ERROR:  Plugin "' . $c->stash->{entry}->label
                . '"  kon niet worden uitgeschakeld';
        }

        $c->res->redirect($c->uri_for(
            '/beheer/plugins'
        ));
        $c->detach;
    }

    $c->stash->{confirmation}->{message}    =
        'Weet u zeker dat u de plugin "' . $c->stash->{entry}->label . '"'
        . ' wilt uitschakelen?';

    $c->stash->{confirmation}->{type}       = 'yesno';
    $c->stash->{confirmation}->{uri}        = $c->uri_for(
        '/beheer/plugins/' . $c->stash->{entry}->id
        . '/uitschakelen'
    );

    $c->forward('/page/confirmation');
    $c->detach;
}

sub disabled : Private {
    my ($self, $c) = @_;

    $c->stash->{template} = 'beheer/plugins/disabled.tt';
}

sub prepare_page : Private {
    my ($self, $c) = @_;

    my $plugins = $c->model('DB::BeheerPlugins')->search(
        {
            'actief'    => 1
        },
    );

    $c->stash->{_plugins} = {};
    while (my $plugin = $plugins->next) {
        $c->stash->{_plugins}->{
            $plugin->naam
        } = 1;
    }
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

