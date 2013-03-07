package Zaaksysteem::Controller::Zaaktype::Auth;

use strict;
use warnings;
use Data::Dumper;
use parent 'Catalyst::Controller';




sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Zaaksysteem::Controller::Zaaktype::Auth in Zaaktype::Auth.');
}

{
    Zaaksysteem->register_profile(
        method  => 'edit',
        profile => {
            required => [ qw/
            /],
            optional            => [ qw/
            /],
            constraint_methods  => {
            },
        }
    );

    sub edit : Chained('/zaaktype/base'): PathPart('auth/edit'): Args(0) {
        my ($self, $c) = @_;

        $c->stash->{params} = $c->session->{zaaktype_edit};
        $c->stash->{template} = 'zaaktype/auth/edit.tt';

        if ($c->req->params->{update}) {
            ### LOAD parameters
            $c->forward('load_parameters');

            $c->response->redirect($c->uri_for('/zaaktype/finish'));
            $c->detach;
        }
    }
}

sub load_parameters : Private {
    my ($self, $c) = @_;
    my (%role_args);

    ### Drop zaaktype_edit auth
    $c->session->{zaaktype_edit}->{auth} = {};


    $role_args{ $_ } = $c->req->params->{ $_ } for
        grep(/ou_.*?_\d+$/, keys %{ $c->req->params });

    ### Loop over variables
    for my $group (grep(
            /ou_id_(\d+)$/,
            keys %role_args
    )) {
        my $count   = $group;
        $count      =~ s/.*?(\d+)$/$1/g;

        my (@rechten, %recht);

        #if (!defined($c->req->params->{'ou_id_' . $count})) { next; }

        if (
            UNIVERSAL::isa($c->req->params->{'role_recht_' . $count}, 'ARRAY')
        ) {
            @rechten = @{
                $c->req->params->{'role_recht_' . $count}
            };
        } elsif ($c->req->params->{'role_recht_' . $count}) {
            push(
                @rechten,
                $c->req->params->{'role_recht_' . $count}
            );
        } else {
            next;
        }

        $recht{
            $c->req->params->{'ou_id_' . $count}
        } = {};

        my %selected;
        for my $auth (@rechten) {
            $selected{$auth} = 1;
        }

        # Update hash:
        $c->session->{zaaktype_edit}->{auth}->{$count}
            = {
                id      => $c->req->params->{'ou_id_' . $count},
                ou_id   => $c->req->params->{'ou_id_' . $count},
                role_id => $c->req->params->{'role_id_' . $count},
                rechten => \%selected,
            };
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

