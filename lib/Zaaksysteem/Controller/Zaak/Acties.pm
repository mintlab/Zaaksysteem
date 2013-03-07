package Zaaksysteem::Controller::Zaak::Acties;

use strict;
use warnings;
use Data::Dumper;
use DateTime;
use parent 'Catalyst::Controller';

use Zaaksysteem::Constants;




sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Zaaksysteem::Controller::Zaak::Acties in Zaak::Acties.');
}

#### ACTIES VOOR OVERZICHT
{
    Zaaksysteem->register_profile(
        method  => 'verplaats',
        profile => {
            required => [ qw/
                betrokkene_type
                ztc_behandelaar_id
            /],
        }
    );

    sub verplaats : Chained('/zaak/base'): PathPart('actie/verplaats'): Args(0) {
        my ($self, $c) = @_;

        die('HIGHLY DEPRECATED, REMOVE AFTER 2.0 RELEASE');
        return unless $c->req->params->{betrokkene_type};

        $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');

        ### Validation
        if (
            $c->req->header("x-requested-with") eq 'XMLHttpRequest' &&
            $c->req->params->{do_validation}
        ) {
            $c->zvalidate;
            $c->detach;
        }

        ### Post
        if (
            %{ $c->req->params } &&
            $c->req->params->{'ztc_behandelaar_id'}
        ) {
            $c->res->redirect(
                $c->uri_for('/')
            );

            my $dv;
            return unless ($dv = $c->zvalidate);


            $c->stash->{zaak}->set_behandelaar(
                $c->req->params->{'ztc_behandelaar_id'}
            );

            $c->detach;
        }

        if ($c->req->params->{betrokkene_type} eq 'medewerker') {
            $c->stash->{betrokkene_type} = 'medewerker';
            $c->stash->{template} = 'zaak/widgets/set_behandelaar.tt';
        } else {
            $c->stash->{betrokkene_type} = 'org_eenheid';
            $c->stash->{template} = 'zaak/widgets/set_org_eenheid.tt';
        }
    }
}

#### ACTIES VOOR OVERZICHT
{
    Zaaksysteem->register_profile(
        method  => 'weiger',
        profile => {
        }
    );

    sub weiger : Chained('/zaak/base'): PathPart('actie/weiger'): Args(0) {
        my ($self, $c) = @_;

        $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');

        ### VAlidation
        if (
            $c->req->header("x-requested-with") eq 'XMLHttpRequest' &&
            $c->req->params->{do_validation}
        ) {
            $c->zvalidate;
            $c->detach;
        }

        ### Post
        if (
            %{ $c->req->params } &&
            $c->req->params->{confirmed}
        ) {
            $c->res->redirect(
                $c->uri_for('/')
            );

            ### Confirmed
            #my $dv;
            #return unless $dv = $c->zvalidate;

            if ($c->stash->{zaak}->behandelaar) {
                $c->log->info(
                    'Zaak::Acties->weiger ['
                    . $c->stash->{zaak}->nr . ']: behandelaar removed'
                );
                $c->stash->{zaak}->behandelaar(undef);
            }

            $c->stash->{zaak}->route_ou(10007);
            $c->stash->{zaak}->route_role(20004);
            $c->stash->{zaak}->update;

            $c->log->info(
                'Zaak::Acties->weiger ['
                . $c->stash->{zaak}->nr . ']: route_ou_role removed'
            );

            $c->detach;

        }

        $c->stash->{confirmation}->{message}    =
            'Weet u zeker dat u deze zaak wilt weigeren?';

        $c->stash->{confirmation}->{type}       = 'yesno';
        $c->stash->{confirmation}->{uri}        =
            $c->uri_for(
                '/zaak/'
                . $c->stash->{zaak}->nr
                . '/actie/weiger'
            );


        $c->forward('/page/confirmation');
        $c->detach;
    }
}


#### ACTIES 
{
    Zaaksysteem->register_profile(
        method  => 'wijzig_route',
        profile => {
        }
    );

    sub wijzig_route : Chained('/zaak/base'): PathPart('update/afdeling'): Args(0) {
        my ($self, $c) = @_;

        $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');

        if (
            $c->req->params->{'ou_id'} &&
            $c->req->params->{'role_id'} &&
            $c->req->params->{confirmed} &&
            $c->model('Users')
                ->get_role_by_id(
                    $c->req->params->{'role_id'}
                ) &&
            $c->model('Users')
                ->get_ou_by_id(
                    $c->req->params->{'ou_id'}
                )
        ) {
            my $route = $c->stash->{zaak}->wijzig_route(
                $c->req->params->{ou_id},
                $c->req->params->{role_id}
            );

            if ($route) {
                $c->flash->{result} =
                    'Zaak ' . $c->stash->{zaak}->nr
                    . ' gewijzigd naar afdeling: '
                    . $c->model('Users')
                        ->get_ou_by_id(
                            $c->req->params->{'ou_id'}
                        )->get_value('description')
                        . ' - '
                    . $c->model('Users')
                        ->get_role_by_id(
                            $c->req->params->{'role_id'}
                        )->get_value('cn');

                $c->stash->{zaak}->logging->add(
                    {
                        component   => 'zaak',
                        onderwerp   => $c->flash->{result}
                    }
                );

                $c->res->redirect('/zaak/' . $c->stash->{zaak}->nr);
            }
            $c->detach;
        } else {
            $c->stash->{nowrapper} = 1;
            $c->stash->{template} = 'zaak/widgets/wijzig_route.tt';
            $c->detach;
        }
    }
}

{
    sub set_betrokkene_suggestion : Chained('/zaak/base'): PathPart('update/betrokkene/suggestion'): Args(0) {
        my ($self, $c) = @_;

        my $suggestion = $c->stash
            ->{zaak}
            ->betrokkenen_relateren_magic_string_suggestion(
                $c->req->params
            );

        unless ($suggestion) {
            $c->res->body('NOK');
            return;
        }

        $c->res->body($suggestion);
    }


    sub set_betrokkene : Chained('/zaak/base'): PathPart('update/betrokkene'): Args(0) {
        my ($self, $c) = @_;

        if (
            my $dv = $c->forward('/page/dialog', [{
                validatie       => BETROKKENE_RELATEREN_PROFILE,
                permissions     => [qw/zaak_beheer zaak_edit/],
                template        => 'widgets/betrokkene/create_relatie.tt',
                complete_url    => $c->uri_for('/zaak/'. $c->stash->{zaak}->id)
            }])
        ) {
            my $params  = $dv->valid;

            if (
                $c->stash->{zaak}->betrokkene_relateren(
                    $params
                )
            ) {
                my $logmsg = 'Betrokkene: "' .
                    $c->req->params->{betrokkene_naam} . '"'
                    .' toegevoegd aan zaak, relatie: ' .
                    $c->req->params->{rol};

                $c->stash->{zaak}->logging->add(
                    {
                        component   => 'zaak',
                        onderwerp   => $logmsg,
                    }
                );

                $c->flash->{result} = $logmsg;

                $c->log->info(
                    'Zaak[' . $c->stash->{zaak}->id . ']: ' . $logmsg
                );
            }
        }
    }
}

sub wijzig_vernietigingsdatum : Chained('/zaak/base'): PathPart('update/vernietigingsdatum'): Args(0) {
    my ($self, $c) = @_;

    if (
        my $dv = $c->forward('/page/dialog', [{
            validatie       => ZAAK_WIJZIG_VERNIETIGINGSDATUM_PROFILE,
            permissions     => [qw/zaak_beheer/],
            template        => 'zaak/widgets/wijzig_vernietigingsdatum.tt',
            complete_url    => $c->uri_for('/zaak/'. $c->stash->{zaak}->id)
        }])
    ) {
        my $params  = $dv->valid;

        if (
            $c->stash->{zaak}->wijzig_vernietigingsdatum(
                $params
            )
        ) {
            my $logmsg = 'Vernietigingsdatum voor zaak: "' .
                $c->stash->{zaak}->id . '"'
                .' gewijzigd naar: ' .
                $params->{vernietigingsdatum}->dmy;

            $c->flash->{result} = $logmsg;

            $c->log->info(
                'Zaak[' . $c->stash->{zaak}->id . ']: ' . $logmsg
            );
        }
    }
}

{
    Zaaksysteem->register_profile(
        method  => 'wijzig_zaaktype',
        profile => {
        }
    );

    sub wijzig_zaaktype : Chained('/zaak/base'): PathPart('update/zaaktype'): Args(0) {
        my ($self, $c) = @_;

        $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');

        if ($c->req->params->{zaaktype_id} && $c->req->params->{confirmed}) {
            my $zaak = $c->stash->{zaak}->wijzig_zaaktype({
                zaaktype_id    => $c->req->params->{zaaktype_id}
            });

            if ($zaak) {
                $c->flash->{result} =
                    'Zaaktype ' . $c->stash->{zaak}->nr . ' succesvol '
                    . 'gewijzigd, nieuw zaaknummer: ' . $zaak->id;

                $c->res->redirect('/zaak/' . $zaak->nr);
            } else {
                $c->res->redirect('/zaak/' . $c->stash->{zaak}->nr);
            }
            $c->detach;
        } else {
            $c->stash->{nowrapper} = 1;
            $c->stash->{template} = 'zaak/widgets/wijzig_zaaktype.tt';
            $c->detach;
        }
    }
}

sub set_behandelaar : Chained('/zaak/base'): PathPart('update/behandelaar'): Args(0) {
    my ($self, $c) = @_;

    $c->stash->{betrokkene_type} = 'medewerker';

    $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');

    if ($c->req->params->{'ztc_behandelaar_id'}) {
        my ($betrokkene_type, $uidnumber) =
            $c->req->params->{'ztc_behandelaar_id'} =~ /betrokkene-(\w+)-(\d+)$/;

        $c->stash->{zaak}->set_behandelaar($c->req->params->{'ztc_behandelaar_id'});

        if (
            $betrokkene_type eq 'medewerker' &&
            $uidnumber eq $c->user->uidnumber
        ) {
            $c->stash->{zaak}->status('open');
            $c->stash->{zaak}->update;

            $c->res->redirect(
                $c->uri_for('/zaak/' . $c->stash->{zaak}->id)
            );
        } else {
            $c->stash->{zaak}->status('new');
            $c->stash->{zaak}->update;

            $c->res->redirect(
                $c->uri_for('/')
            );
        }

        $c->detach;
    } else {
        $c->stash->{nowrapper} = 1;
        $c->stash->{template} = 'zaak/widgets/set_behandelaar.tt';
        $c->detach;
    }

    $c->forward('/zaak/view');
}

sub set_aanvrager : Chained('/zaak/base'): PathPart('update/aanvrager'): Args(0) {
    my ($self, $c) = @_;

    $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');
    # Get aanvrager type
    if ($c->stash->{zaak}->aanvrager) {
        $c->stash->{betrokkene_type} = $c->stash->{zaak}->aanvrager_object->btype;
    } else {
        $c->stash->{betrokkene_type} = 'natuurlijk_persoon';
    }

    if (!%{ $c->req->params }) {
        $c->stash->{nowrapper} = 1;
        $c->stash->{template} = 'zaak/widgets/set_aanvrager.tt';
        $c->detach;
    } elsif ($c->req->params->{'ztc_behandelaar_id'}) {
        $c->stash->{zaak}->set_aanvrager($c->req->params->{'ztc_behandelaar_id'});
    }
}

sub set_eigenaar : Chained('/zaak/base'): PathPart('update/eigenaar'): Args(0) {
    my ($self, $c) = @_;

    $c->stash->{betrokkene_type} = 'medewerker';
    $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');
    if (!%{ $c->req->params }) {
        $c->stash->{nowrapper} = 1;
        $c->stash->{template} = 'zaak/widgets/set_eigenaar.tt';
#        $c->stash->{url} = $c->uri_for('/zaak/' . $c->stash->{zaak}->nr .
#            '/update/behandelaar');
        $c->detach;
    } elsif ($c->req->params->{'ztc_behandelaar_id'}) {
        $c->stash->{zaak}->set_coordinator($c->req->params->{'ztc_behandelaar_id'});
#        $c->stash->{zaak}->notes->add({
#            'commenttype'   => 'actie',
#            'value'         => 'Zaakcoordinator voor zaak gewijzigd naar '
#                . $c->stash->{zaak}->behandelaar->naam
#        });
    }
}

### XXX
sub set_relatie : Chained('/zaak/base'): PathPart('update/relatie'): Args(0) {
    my ($self, $c) = @_;

    $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');
    if (!$c->req->params->{zaaknr}) {
        $c->stash->{nowrapper} = 1;
        $c->stash->{template} = 'zaak/widgets/set_relatie.tt';
        $c->detach;
    } else {
        $c->res->redirect('/zaak/' . $c->stash->{zaak}->nr);

        if ($c->req->params->{zaaknr} eq $c->stash->{zaak}->id) {
            $c->flash->{result} = 'Kan geen relatie aanmaken met hetzelfde'
                . ' zaaknummer als huidige zaak';
            $c->detach;
        }

        my $relatie_zaak    = $c->model('DB::Zaak')->find(
            $c->req->params->{zaaknr}
        ) or do {
            $c->flash->{result} = 'Zaak ' . $c->req->params->{zaaknr}
                . ' kan niet gevonden worden.';
            $c->detach;
        };

        if ($c->req->params->{zaaknr} eq $c->stash->{zaak}->id) {
            $c->flash->{result} = 'Kan geen relatie aanmaken met hetzelfde'
                . ' zaaknummer als huidige zaak';
            $c->detach;
        }

        $c->stash->{zaak}->set_relatie({
            relatie         => 'gerelateerd',
            relatie_zaak    => $relatie_zaak
        });
    }
}

sub set_jumbo : Chained('/zaak/base'): PathPart('update/set_jumbo'): Args(0) {
    my ($self, $c) = @_;

    $c->assert_any_user_permission('admin');

    if (!$c->req->params->{jumboupdate}) {
        $c->stash->{nowrapper} = 1;
        $c->stash->{template} = 'zaak/widgets/set_jumbo.tt';
        $c->detach;
    } else {
        $c->res->redirect('/zaak/' . $c->stash->{zaak}->nr);

        my %changes;

        if (
            $c->req->params->{status} && 
            $c->req->params->{status} ne $c->stash->{zaak}->status
        ) {
            $changes{status} = $c->req->params->{status};

            if ($c->req->params->{status} eq 'deleted') {
                $c->stash->{zaak}->deleted(DateTime->now());
            }

            $c->stash->{zaak}->status($c->req->params->{status});
        }


        $c->stash->{zaak}->update;

        if (scalar(keys %changes)) {
            $c->flash->{result} = 'Jumbo update, wijzigingen:<br />';
            while (my ($component, $value) = each %changes) {
                $c->flash->{result} .=  '<br />- ' . $component . ' gewijzigd naar: ' . $value;
            }
        }

        $c->detach;
    }
}

### XXX
{
    Zaaksysteem->register_profile(
        method  => 'verlengen',
        profile => {
            required => [ qw/
                reden
                datum
            /],
            constraint_methods => {
                datum_jaar  => sub {
                    my ($dfv) = @_;

                    my ($datum_dag, $datum_maand, $datum_jaar) = split (/-/,
                        $dfv->get_filtered_data->{datum}); 
                    my $givendate = DateTime->new(
                        year => $datum_jaar,
                        month => $datum_maand,
                        day => $datum_dag,
                    );

                    if ($givendate > DateTime->now()) {
                        return 1;
                    }

                    return;
                },
            }
        }
    );
    sub verlengen: Chained('/zaak/base'): PathPart('update/verlengen'): Args(0) {
        my ($self, $c) = @_;

        $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');
        if (
            $c->req->header("x-requested-with") eq 'XMLHttpRequest' &&
            $c->req->params->{do_validation}
        ) {
            $c->zvalidate;
            $c->detach;
        }

        if (%{ $c->req->params } && exists($c->req->params->{reden})) {
            return unless $c->zvalidate;


            my ($datum_dag, $datum_maand, $datum_jaar) = split (/-/,
                    $c->req->params->{datum}); 
            my $givendate = DateTime->new(
                year => $datum_jaar,
                month => $datum_maand,
                day => $datum_dag,
            );
            $c->stash->{zaak}->set_verlenging(
                $givendate
            );
            #$c->stash->{zaak}->setup_datums;

            $c->flash->{result} = 'Afhandeldatum gewijzigd naar: ' .
                $givendate->dmy;

            $c->stash->{zaak}->logging->add(
                {
                    component   => 'zaak',
                    onderwerp   => $c->flash->{result}
                        .', reden: ' . $c->req->params->{reden}
                }
            );
            $c->res->redirect('/zaak/' . $c->stash->{zaak}->nr);
            $c->detach;
        }

        $c->stash->{nowrapper} = 1;
        $c->stash->{template} = 'zaak/widgets/verlengen.tt';
        $c->detach;
    }
}

### XXX
sub opschorten : Chained('/zaak/base'): PathPart('update/opschorten'): Args(0) {
    my ($self, $c) = @_;

    $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');

    my $url;

    if (!scalar(keys(%{ $c->req->params }))) {
        $c->stash->{nowrapper} = 1;
        if ($c->stash->{zaak}->status eq 'stalled') {
            $c->stash->{is_opgeschort} = 1;
        }
        $c->stash->{template} = 'zaak/widgets/opschorten.tt';
        $c->detach;
    } elsif (exists($c->req->params->{'reden'})) {
        if ($c->stash->{zaak}->status eq 'stalled') {
            $c->stash->{zaak}->status('new');
            $c->stash->{zaak}->update;

            $c->stash->{zaak}->logging->add(
                {
                    component   => 'zaak',
                    onderwerp   => 'Zaak is hervat: '
                    . $c->req->params->{reden}
                }
            );

            $url    = $c->uri_for('/zaak/' . $c->stash->{zaak}->id);
        } elsif ($c->stash->{zaak}->status eq 'resolved') {
            $c->flash->{result} =
                'Kan zaak niet opschorten, deze  zaak is afgehandeld';
        } else {
            $c->stash->{zaak}->status('stalled');
            $c->stash->{zaak}->update;
            $c->stash->{zaak}->reden_opschorten(
                $c->req->params->{'reden'}
            );

            $c->stash->{zaak}->logging->add(
                {
                    component   => 'zaak',
                    onderwerp   => 'Zaak is opgeschort: '
                    . $c->req->params->{reden}
                }
            );

            $url    = $c->req->referer;
        }
    }

    $c->res->redirect($url);
    $c->detach;
}

sub vorige_status : Chained('/zaak/base'): PathPart('update/vorige_status'): Args(0) {
    my ($self, $c) = @_;

    $c->assert_any_zaak_permission('zaak_beheer');

    if (!exists($c->req->params->{update})) {
        $c->stash->{nowrapper}  = 1;
        $c->stash->{template}   = 'zaak/widgets/vorige_status.tt';
        $c->detach;
    } elsif ($c->req->params->{'update'}) {
        if ($c->stash->{zaak}->set_vorige_fase) {
            $c->flash->{result} = 'Zaak succesvol omgezet naar vorige fase';
        }
    }

    $c->res->redirect('/zaak/' . $c->stash->{zaak}->nr
        . '#zaak-elements-status'
    );
    $c->detach;
}

### XXX
sub afhandelen : Chained('/zaak/base'): PathPart('update/afhandelen'): Args(0) {
    my ($self, $c) = @_;

    $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');
    if (!exists($c->req->params->{update})) {
        $c->stash->{nowrapper} = 1;
        $c->stash->{template} = 'zaak/widgets/afhandelen.tt';
        $c->detach;
    } elsif (exists($c->req->params->{'reden'})) {
        $c->stash->{zaak}->set_gesloten(DateTime->now());

        $c->stash->{zaak}->logging->add(
            {
                component   => 'zaak',
                onderwerp   => 'Zaak is vroegtijdig afgehandeld: '
                . $c->req->params->{reden}
            }
        );
        $c->res->redirect('/zaak/' . $c->stash->{zaak}->nr);
        $c->detach;
    }
}

sub deelzaak : Chained('/zaak/base'): PathPart('update/deelzaak'): Args(0) {
    my ($self, $c) = @_;

    $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');
    if (!exists($c->req->params->{update})) {
        $c->stash->{nowrapper} = 1;
        $c->stash->{template} = 'zaak/widgets/deelzaak.tt';
        $c->detach;
    } else {
        $c->forward('/zaak/status/start_subzaken');

        $c->res->redirect('/zaak/' . $c->stash->{zaak}->nr
            . '#zaak-elements-status'
        );
        $c->detach;
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

