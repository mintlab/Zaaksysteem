package Zaaksysteem::Controller::Plugins::Bedrijfid;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use Zaaksysteem::Constants qw/
    ZAAKSYSTEEM_GM_AUTHENTICATEDBY_DIGID
    ZAAKSYSTEEM_GM_AUTHENTICATEDBY_BEDRIJFID

    VALIDATION_CONTACT_DATA
/;





sub login : Chained('/') : PathPart('auth/bedrijfid'): Args() {
    my ($self, $c, $loginpage) = @_;

    if (!$loginpage) {
        $c->stash->{template} = 'plugins/bedrijfid/info.tt';
        $c->detach;
    }

    if ($c->model('Plugins::Bedrijfid')->succes) {
        if ($c->model('Plugins::Bedrijfid')->verified_url) {
            $c->res->redirect(
                $c->model('Plugins::Bedrijfid')->verified_url
            );
        } else {
            $c->res->redirect($c->uri_for('/pip'));
        }

        $c->detach;
    }

    if ($c->req->params->{do_auth} && uc($c->req->method) eq 'POST') {
        my $redir = $c->model('Plugins::Bedrijfid')->authenticate(
            login           => $c->req->params->{login},
            password        => $c->req->params->{password},
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
        $c->stash->{flash} = 'Inloggen geannuleerd.';
    } elsif ($c->model('Plugins::Digid')->error) {
        $c->stash->{flash} =
            'Er is een fout geconstateerd bij het inloggen bij uw gemeente.'
            .' Probeert u het nogmaals.';
    }

    $c->stash->{template} = 'plugins/bedrijfid/login.tt';
}


sub logout : Chained('/') : PathPart('auth/bedrijfid/logout'): Args() {
    my ($self, $c) = @_;

    $c->model('Plugins::Bedrijfid')->logout;

    $c->stash->{template}   = 'plugins/bedrijfid/login.tt';
    $c->stash->{logged_out} = 1;
    $c->detach;
}

sub wachtwoord : Chained('/zaak/base') : PathPart('update/bedrijfid'): CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->check_any_user_permission(qw/contact_nieuw contact_search/);

    return unless (
        $c->stash->{zaak} &&
        $c->stash->{zaak}->aanvrager &&
        $c->stash->{zaak}->aanvrager_object->btype eq 'bedrijf'
    );

    $c->stash->{betrokkene} = $c->stash->{zaak}->aanvrager_object;
}

sub randomPassword {
    my $self = shift;

    my $password;
    my $_rand;

    my $password_length = $_[0];
        if (!$password_length) {
            $password_length = 10;
        }

    my @chars = split(" ",
        '
        a b c d e f g h i j k l m n o
        p q r s t u v w x y z - _ % # |
        0 1 2 3 4 5 6 7 8 9
        '
    );

    srand;

    for (my $i=0; $i <= $password_length ;$i++) {
        $_rand = int(rand 41);
        $password .= $chars[$_rand];
    }
    return $password;
}


sub wachtwoord_wijzig : Chained('wachtwoord') : PathPart('wijzig'): Args(0) {
    my ($self, $c) = @_;

    ### Post
    if (
        %{ $c->req->params } &&
        $c->req->params->{confirmed}
    ) {
        #$c->res->redirect(
        #    $c->uri_for('/')
        #);

        ### Confirmed
        my $newpassword = $self->randomPassword(8);

        $c->stash->{betrokkene}->password($newpassword);

        $c->flash->{result} = 'Wachtwoord voor bedrijf "'
            . $c->stash->{betrokkene}->naam . '" succesvol gewijzigd';

        $c->res->redirect(
            $c->uri_for(
                '/zaak/' . $c->stash->{zaak}->nr
            )
        );
        $c->detach;
    }

    if ($c->stash->{betrokkene}->has_password) {
        $c->stash->{confirmation}->{message}    =
            'Dit bedrijf heeft eerder een wachtwoord overhandigd gekregen.'
            .' Hiermee zal het bestaande wachtwoord worden gewijzigd.'
    } else {
        $c->stash->{confirmation}->{message}    =
            'Er is nog niet eerder een wachtwoord overhandigd.'
            .' Dit zou niet mogen voorkomen'
            .'<b>Door op bevestigen te klikken geeft u aan de nodige'
            .' identificatie te hebben gecontroleerd.</b>';
    }


    $c->stash->{confirmation}->{type}       = 'yesno';
    $c->stash->{confirmation}->{uri}        =
        $c->uri_for(
            '/zaak/' . $c->stash->{zaak}->nr
            .'/update/bedrijfid/wijzig'
        );


    $c->forward('/page/confirmation');
    $c->detach;
}



sub _zaak_create_security : Private {
    my ($self, $c) = @_;

    if (
        $c->req->params->{authenticatie_methode} eq 'bedrijfid' ||
        $c->session->{_zaak_create}->{extern}->{verified} eq 'bedrijfid'
    ) {
        if ($c->model('Plugins::Bedrijfid')->succes) {
            $c->session->{_zaak_create}->{extern} = {};

            ### Check if we are allowed to crate this zaaktype
            $c->session->{_zaak_create}->{extern}->{aanvrager_type}
                = 'niet_natuurlijk_persoon';
            $c->session->{_zaak_create}->{extern}->{verified}
                = 'bedrijfid';
            $c->session->{_zaak_create}->{extern}->{id}
                = $c->model('Plugins::Bedrijfid')->login;

            $c->stash->{aanvrager_type} = 'niet_natuurlijk_persoon'
        } else {
            my $arguments = {};
            $arguments->{'authenticatie_methode'} = $c->req->params->{authenticatie_methode} if ($c->req->params->{authenticatie_methode});
            $arguments->{'ztc_aanvrager_type'} = $c->req->params->{ztc_aanvrager_type} if ($c->req->params->{ztc_aanvrager_type});
            $arguments->{'sessreset'} = $c->req->params->{sessreset} if ($c->req->params->{sessreset});
            $arguments->{'zaaktype_id'} = $c->req->params->{zaaktype_id} if ($c->req->params->{zaaktype_id});

            $c->res->redirect(
                $c->uri_for(
                    '/auth/bedrijfid',
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
                $c->session->{_zaak_create}->{verified} eq 'bedrijfid'
            ) {
                delete($c->session->{_zaak_create}->{extern});
            }

            $c->detach;
        }
    } else {

        ### Geen bedrijfid, stop here
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

    my $callerclass     = 'Zaaksysteem::Betrokkene::Object::Bedrijf';

    ### Only validate contact, which are all optional
    my $profile;
    if ($c->req->params->{contact_edit}) {
        $profile = VALIDATION_CONTACT_DATA;
    } else {
        ### Get profile from Model
        $profile         = $c->get_profile(
            'method'=> 'create',
            'caller' => $callerclass
        ) or die('Terrible die here');

        my @required_fields = grep {
            $_ ne 'vestiging_postcodewoonplaats' ||
            $_ ne 'vestiging_adres'
        } @{ $profile->{required} };

        push(@required_fields, 'rechtsvorm');

        $profile->{required} = \@required_fields;

        ### MERGE
        my $contact_profile = VALIDATION_CONTACT_DATA;
        while (my ($key, $data) = each %{ $contact_profile }) {
            unless ($profile->{$key}) {
                $profile->{$key} = $data;
                next;
            }

            if (UNIVERSAL::isa($data, 'ARRAY')) {
                push(@{ $profile->{$key} }, @{ $data });
                next;
            }

            if (UNIVERSAL::isa($data, 'HASH')) {
                while (my ($datakey, $dataval) = each %{ $data }) {
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
        $c->session->{_zaak_create}->{extern}->{verified} eq 'bedrijfid' &&
        $c->session->{_zaak_create}->{aanvrager_update}
    );

    my $id = $c->model('Betrokkene')->create(
        'bedrijf',
        {
            %{ $c->session->{_zaak_create}->{aanvrager_update} },
            'authenticated'   => 0,
            'authenticatedby' => ZAAKSYSTEEM_GM_AUTHENTICATEDBY_BEDRIJFID,
        }
    );

    $c->session->{_zaak_create}->{ztc_aanvrager_id}
                                    = 'betrokkene-bedrijf-' .  $id;
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

