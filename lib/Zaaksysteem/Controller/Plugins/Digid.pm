package Zaaksysteem::Controller::Plugins::Digid;

use strict;
use warnings;
use Data::Dumper;

use Moose;
use Moose::Util qw/apply_all_roles does_role/;

BEGIN { extends 'Catalyst::Controller'; }

use Zaaksysteem::Constants qw/
    ZAAKSYSTEEM_GM_AUTHENTICATEDBY_DIGID
    ZAAKSYSTEEM_GM_AUTHENTICATEDBY_BEDRIJFID

    VALIDATION_CONTACT_DATA
/;

#use Moose::Util qw/apply_all_roles/;

#around 'register_actions'  => sub {
#    my $orig    = shift;
#    my $class   = shift;
#
#    apply_all_roles( Zaaksysteem->controller('Zaak'), 'Zaaksysteem::Auth::Digid::WebformAuth');
#
#    warn('Applied ROLES: ' . does_role(Zaaksysteem->controller('Zaak'),
#            'Zaaksysteem::Auth::Digid::WebformAuth'));
#
#    my $rv      = $class->$orig(@_);
#};

#sub register_actions {
#    my $self    = shift;
#
#    $self->next::method(@_);
#
#    die(Dumper(shift->controller('Zaak')));
#    return $self;
#
#
#};

#apply_all_roles(Zaaksysteem->controller('Zaak'), 'Zaaksysteem::Auth::Digid::WebformAuth');



sub login : Chained('/') : PathPart('auth/digid'): Args() {
    my ($self, $c, $do_auth) = @_;

    if ($c->model('Plugins::Digid')->succes) {
        # Expire session
        if ($c->model('Plugins::Digid')->verified_url) {
            $c->res->redirect(
                $c->model('Plugins::Digid')->verified_url
            );
        } else {
            $c->res->redirect($c->uri_for('/pip'));
        }

        $c->detach;
    }

    if ($do_auth && uc($c->req->method) eq 'POST') {
        my $redir = $c->model('Plugins::Digid')->authenticate(
            verified_url    => $c->req->params->{verified_url}
        );

        if ($redir) {
            $c->res->redirect(
                $redir
            );
            $c->detach;
        }
    }

    if ($c->model('Plugins::Digid')->cancel) {
        $c->stash->{digid_error} = 'Inloggen geannuleerd.';
    } elsif ($c->model('Plugins::Digid')->error) {
        $c->stash->{digid_error} =
            'Er is een fout opgetreden in de communicatie met DigiD.'
            . ' Probeert u het later nogmaals.';
    }

    if ($c->flash->{digid_error}) {
        $c->stash->{digid_error} = $c->flash->{digid_error};
    }

    if ($c->user_exists) {
        $c->delete_session;
    }

    $c->stash->{template} = 'plugins/digid/login.tt';
}


sub logout : Chained('/') : PathPart('auth/digid/logout'): Args() {
    my ($self, $c) = @_;

    $c->model('Plugins::Digid')->logout;

    $c->stash->{template}   = 'plugins/digid/login.tt';
    $c->stash->{logged_out} = 1;
    $c->detach;
}


sub _zaak_create_secure_digid : Private {
    my ($self, $c) = @_;

    if (
        $c->req->params->{authenticatie_methode} eq 'digid' ||
        $c->session->{_zaak_create}->{extern}->{verified} eq 'digid'
    ) {
        if ($c->model('Plugins::Digid')->succes) {
            $c->session->{_zaak_create}->{extern} = {};

            ### Check if we are allowed to crate this zaaktype
            $c->session->{_zaak_create}->{extern}->{aanvrager_type}
                = 'natuurlijk_persoon';
            $c->session->{_zaak_create}->{extern}->{verified}
                = 'digid';
            $c->session->{_zaak_create}->{extern}->{id}
                = $c->model('Plugins::Digid')->uid;

            $c->stash->{aanvrager_type} = 'natuurlijk_persoon'
        } else {
            my $arguments = {};
            $arguments->{'authenticatie_methode'} = $c->req->params->{authenticatie_methode} if ($c->req->params->{authenticatie_methode});
            $arguments->{'ztc_aanvrager_type'} = $c->req->params->{ztc_aanvrager_type} if ($c->req->params->{ztc_aanvrager_type});
            $arguments->{'sessreset'} = $c->req->params->{sessreset} if ($c->req->params->{sessreset});
            $arguments->{'zaaktype_id'} = $c->req->params->{zaaktype_id} if ($c->req->params->{zaaktype_id});

            $c->res->redirect(
                $c->uri_for(
                    '/auth/digid',
                    {
                        verified_url    => $c->uri_for(
                            '/zaak/create/webformulier/',
                            $arguments,
                        )
                    }
                )
            );

            ### Wipe out externe authenticatie
            if (
                $c->session->{_zaak_create}->{extern} &&
                $c->session->{_zaak_create}->{verified} eq 'digid'
            ) {
                delete($c->session->{_zaak_create}->{extern});
            }

            $c->detach;
        }
    } else {

        ### Geen digiid, stop here
        return;
    }

    ### Save aanvrager data
    $c->forward('_zaak_create_aanvrager');
}

sub _zaak_create_aanvrager : Private {
    my ($self, $c) = @_;

    return unless (
        $c->req->params->{aanvrager_update}
    );

    $c->log->debug('_zaak_create_aanvrager: Aanvrager update');

    my $callerclass     = 'Zaaksysteem::Betrokkene::Object::NatuurlijkPersoon';


    ### Only validate contact, which are all optional
    my $profile;
    if ($c->req->params->{contact_edit}) {
        $profile = VALIDATION_CONTACT_DATA;
    } else {
        ### Get profile from Model
        $profile         = $c->get_profile(
            'method'    => 'create',
            'caller'    => 'Zaaksysteem::Controller::Betrokkene'
        ) or die('Terrible die here');

        ### MERGE
        my $contact_profile = VALIDATION_CONTACT_DATA;
        while (my ($key, $data) = each %{ $contact_profile }) {
            unless ($profile->{$key}) {
                warn('hm1?');
                $profile->{$key} = $data;
                next;
            }

            if (UNIVERSAL::isa($data, 'ARRAY')) {
                warn('hm2?');
                push(@{ $profile->{$key} }, @{ $data });
                next;
            }

            if (UNIVERSAL::isa($data, 'HASH')) {
                warn('hm3?:' . $key);
                while (my ($datakey, $dataval) = each %{ $data }) {
                    warn('hmz?:' . $datakey);
                    $profile->{$key}->{$datakey} = $dataval;
                }
                next;
            }
        }
    }

    Zaaksysteem->register_profile(
        method => '_zaak_create_aanvrager',
        profile => $profile,
    );

    if (
        $c->req->header("x-requested-with") eq 'XMLHttpRequest'
    ) {
        $c->zvalidate;
        $c->detach;
    }

    my $dv      = $c->zvalidate;
    return unless ref($dv);

    return unless $dv->success;

    ### Post
    $c->log->debug('_zaak_create_aanvrager: Updated aanvrager');
    if ($c->req->params->{aanvrager_edit}) {
        $c->session->{_zaak_create}->{aanvrager_update} = $dv->valid;
    } elsif ($c->req->params->{contact_edit}) {
        for (qw/npc-email npc-telefoonnummer npc-mobiel/) {
            if (defined($c->req->params->{ $_ })) {
                $c->session->{_zaak_create}->{ $_ } =
                    $c->req->params->{ $_ };
            }
        }

    }
}



sub _zaak_create_load_externe_data : Private {
    my ($self, $c) = @_;

    return unless (
        $c->req->params->{publish_zaak} &&
        $c->session->{_zaak_create}->{extern}->{verified} eq 'digid' &&
        $c->session->{_zaak_create}->{aanvrager_update}
    );

    my $id = $c->model('Betrokkene')->create(
        'natuurlijk_persoon',
        {
            %{ $c->session->{_zaak_create}->{aanvrager_update} },
            'np-authenticated'   => 0,
            'np-authenticatedby' => ZAAKSYSTEEM_GM_AUTHENTICATEDBY_DIGID,
        }
    );

    $c->session->{_zaak_create}->{ztc_aanvrager_id}
                                    = 'betrokkene-natuurlijk_persoon-' .  $id;
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

