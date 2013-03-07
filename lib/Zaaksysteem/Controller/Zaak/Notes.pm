package Zaaksysteem::Controller::Zaak::Notes;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use Zaaksysteem::Constants qw/LOGGING_COMPONENT_NOTITIE/;




sub index :Chained('/zaak/base') : PathPart('notes'): Args(0) {
    my ( $self, $c ) = @_;

    ### TODO, depending on reuqest, show notes wrapper
    $c->stash->{nowrapper} = 1;
    $c->stash->{template} = 'zaak/elements/notes.tt';
}

sub base : Chained('/zaak/base'): PathPart('notes'): CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub add : Chained('base'): PathPart('add'): Args(0) {
    my ($self, $c) = @_;

    return unless $c->check_any_zaak_permission('zaak_edit');

    if (
        !exists($c->req->params->{'update_element'}) ||
        $c->req->params->{'update_element'} ne 'notes'
    ) { return; }

    $c->stash->{'zaak'}->logging->add({
        'component' => LOGGING_COMPONENT_NOTITIE,
        'bericht'   => $c->req->params->{'content'},
        'onderwerp' => 'Notitie toegevoegd',
    });

    $c->flash->{result} = 'Notitie succesvol toegevoegd';

    #$c->log->debug('Adding notitie: ' . $c->stash->{zaak}->touch('Notitie
    #       toegevoegd'));
    if ($c->req->header("x-requested-with") eq 'XMLHttpRequest') {
        $c->detach('index');
    }

    $c->response->redirect(
        $c->uri_for(
            '/zaak/' . $c->stash->{zaak}->nr . '#zaak-elements-notes'
        )
    );

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

