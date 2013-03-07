package Zaaksysteem::Controller::Zaak::Checklist;

use strict;
use warnings;
use Data::Dumper;
use parent 'Catalyst::Controller';




sub index :Chained('/zaak/base') : PathPart('checklist'): Args(0) {
    my ( $self, $c ) = @_;

    # This will get the first zaak

    ### TODO, depending on reuqest, show notes wrapper
    $c->stash->{nowrapper} = 1;
    $c->stash->{template} = 'zaak/elements/checklist.tt';
}

sub update :Chained('/zaak/base') : PathPart('checklist/update'): Args(0) {
    my ( $self, $c ) = @_;
    my $options = {};

    $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');

    do {
        $c->res->redirect(
            $c->uri_for(
                '/zaak/' . $c->stash->{zaak}->nr . '#zaak-elements-checklist'
            )
        );
        $c->detach;
    } unless $c->can_change;

    #| Parameter                           | Value                                |
    #+-------------------------------------+--------------------------------------+
    #| optie_1                      | 1                                    |
    #| submit                              | Wijzigingen opslaan                  |
    #| vraag_5                             | mogelijkheid_9                       |

    foreach my $checklist (keys %{ $c->req->params }) {
        next unless $c->req->params->{$checklist};

        if (my ($vraag_id, $option) = $checklist =~ /^checklist_(\d+)_([janee]+)$/) {
            $options->{$vraag_id} = $option;
        }
    }

    ### Update values
    $c->stash->{zaak}->checklist->update_checklist(
        $options,
        { fase_id => $c->req->params->{update_fase} },
        $c->stash->{zaak},
    );

    $c->flash->{'result'} = 'Wijzigingen opgeslagen';

    $c->res->redirect($c->uri_for('/zaak/' . $c->stash->{zaak}->nr));
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

