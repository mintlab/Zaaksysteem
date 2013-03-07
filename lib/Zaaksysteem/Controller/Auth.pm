package Zaaksysteem::Controller::Auth;

use strict;
use warnings;
use Data::Dumper;
use parent 'Catalyst::Controller';

#BEGIN {
#    Zaaksysteem::Controller::Page::add_menu_item({
#            'quick'   => {
#                'Uitloggen' => {
#                    'url'   => __PA
#
#
#                },
#
#
#            },
#            'main'  => {
#
#            }
#        
#        );
#}



sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Zaaksysteem::Controller::Auth in Auth.');
}

sub login : Local {
    my ($self, $c) = @_;

    if ($c->flash->{referer}) {
        $c->stash->{'referer'} = $c->flash->{referer};
    } elsif ($c->req->params->{referer}) {
        $c->stash->{'referer'} = $c->req->params->{referer};
    }

    if ($c->user_exists) {
        $c->res->redirect(
            ($c->stash->{'referer'} ||
            $c->uri_for( '/')),
        );
        $c->detach;
    } else {
        $c->stash->{template} = 'auth/login.tt';
    }


    if (exists($c->req->params->{'username'})) {

        ### Some input checking
        if ($c->req->params->{'username'} !~ /^[\w\d_\-]+$/) {
            $c->detach;
        }

        if (
            $c->authenticate(
                {
                    'username'  => $c->req->params->{'username'},
                    'password'  => $c->req->params->{'password'},
                }
            )
        ) {
            ### User sucessfully authenticated
            if ($c->req->params->{referer}) {
                $c->response->redirect($c->req->params->{referer});
            } else {
                $c->response->redirect($c->uri_for('/'));
            }
            $c->detach;
            return;
        } else {
            $c->flash->{result} = 'Invalid login.';
        }
    }

}

sub logout : Local {
    my ($self, $c) = @_;

    #$c->stash->{template} = 'auth/login.tt';
    $c->logout();
    $c->delete_session();
    #$c->request->cookies->{'ui-tabs-23'}->value(undef);

    $c->stash->{message} = 'You have been logged out';
    $c->response->redirect($c->uri_for('/auth/login'));

}


sub retrieve_roles : Local {
    my ($self, $c, $ouid) = @_;

    #$c->assert_any_user_role('admin');

    return unless $c->req->header("x-requested-with") eq 'XMLHttpRequest';

    my $ldaproles = $c->model('Groups')->search;
    my $ldapous   = $c->model('Groups')->search_ou;

    my %ldapousmap = map {
        $_->{id}  => $_->{ou}
    } @{ $ldapous };

    my $json = {
        'roles' => []
    };

    for my $ldaprole (@{ $ldaproles }) {
        if (
            $ldaprole->{ou} && $ldaprole->{ou} ne $ldapousmap{$ouid}
        ) { next; }

        ### Remove special case admin
        if ($ouid && $ldaprole->{short_name} eq 'Admin') { next; }

        push(@{ $json->{roles} },
            {
                role_id     => $ldaprole->{id},
                ou_id       => $ldaprole->{ou},
                label       => $ldaprole->{short_name}
            }
        );
    }

    $c->stash->{json} = $json;
    $c->forward('Zaaksysteem::View::JSON');
}



sub prepare_page : Private {
    my ($self, $c) = @_;

    if ($c->user_exists) {
        $c->forward('/page/add_menu_item', [
            {
                'quick' => [
                    {
                        'name'  => 'Uitloggen',
                        'href'  => $c->uri_for('/auth/logout'),
                    },
                    {
                        'name'  => 'Ingelogd als "' . $c->user->displayname . '"',
                        'href'  => $c->uri_for(
                            '/betrokkene/' . $c->user->uidnumber, {
                                gm => 1,
                                type => 'medewerker'
                            }
                        ),
                    },
                ],
            }
        ]);
    } else {
        $c->forward('/page/add_menu_item', [
            {
                'quick' => [
                    {
                        'name'  => 'Inloggen',
                        'href'  => $c->uri_for('/auth/login'),
                    }
                ],
            }
        ]);

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

