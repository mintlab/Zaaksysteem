package Zaaksysteem::Controller::Betrokkene::Notes;

use strict;
use warnings;
use parent 'Catalyst::Controller';




sub add : Chained('/betrokkene/view_base'): PathPart('notes/add'): Args(0) {
    my ($self, $c) = @_;

    $c->check_any_user_permission(qw/contact_search contact_nieuw/);

    # Prepare redirection
    if ($c->req->header("x-requested-with") eq 'XMLHttpRequest') {
        $c->stash->{nowrapper} = 1;
        $c->stash->{template} = 'widgets/betrokkene/notes.tt';
    } else {
        $c->response->redirect(
            $c->uri_for(
                '/betrokkene/' .
                $c->req->params->{requested_bid} .
                '/',
                {
                    gm      => $c->req->params->{gm},
                    type    => $c->req->params->{type},
                }
            )
        );
    }

    my $bid     = $c->user->uidnumber;

    my $bo      = $c->model('Betrokkene')->get(
        {
            extern  => 1,
            type    => 'medewerker',
        },
        $bid
    );

    return unless $c->req->params->{message};

    # Add notes
    $c->stash->{'betrokkene'}->notes->add({
        'message'           => $c->req->params->{'message'},
        'betrokkene_from'     => $bo->betrokkene_identifier,
        'betrokkene_exid'   => $c->stash->{requested_bid},
        'betrokkene_type'   => $c->req->params->{type},
    });

    if ($c->req->header("x-requested-with") ne 'XMLHttpRequest') {
        $c->flash->{result} = 'Notitie succesvol toegevoegd';
    }
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

