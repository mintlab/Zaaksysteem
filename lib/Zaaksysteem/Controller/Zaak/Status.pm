package Zaaksysteem::Controller::Zaak::Status;

use strict;
use warnings;
use Data::Dumper;
use parent 'Catalyst::Controller';




sub index :Chained('/zaak/base') : PathPart('status'): Args(0) {
    my ( $self, $c ) = @_;

    # This will get the first zaak

    ### TODO, depending on reuqest, show notes wrapper
    $c->stash->{nowrapper} = 1;
    $c->stash->{template} = 'zaak/elements/status.tt';
}

sub _status_check_possibility : Private {
    my ( $self, $c ) = @_;

$c->log->debug("check possibly");
    $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');

    ### Little bit dirty, but we always check first status too when we check
    ### the seconde fase. Because we are able to skip required kenmerken in
    ### the first fase
    my ($regels_result, $incompleet_fase);
    if ($c->stash->{zaak}->milestone == 1) {
        $incompleet_fase = $c->stash->{zaak}->huidige_fase->status;
        $regels_result = $c->model('Regels')->required_kenmerken_complete(
            $c,
            $c->stash->{zaak},
            $c->stash->{zaak}->huidige_fase
        );
    }

    ### Als de registratiefase niet van toepassing is OF deze had een succes
    ### status, check de huidige fase
    if (!$regels_result || $regels_result->{succes}) {
        $incompleet_fase = $c->stash->{zaak}->volgende_fase->status
            if $c->stash->{zaak}->volgende_fase;

        $regels_result = $c->model('Regels')->required_kenmerken_complete(
            $c,
            $c->stash->{zaak},
            $c->stash->{zaak}->volgende_fase
        );
    }


    $c->log->debug('Regels result: ' . Dumper($regels_result));

    unless ($regels_result->{succes}) {
        my $errmsg = 'Volgende fase niet mogelijk: ';

        if ($regels_result->{pauze}) {
            $errmsg .= 'aanvraag gepauzeerd "'
                . $regels_result->{pauze} . '"';
        } elsif ($regels_result->{required}) {
            $errmsg .= 'niet alle verplichte kenmerken zijn ingevuld';
        }

        $c->stash->{status_kenmerken_incompleet}        = $errmsg;
        $c->stash->{status_kenmerken_fase_incompleet}   = $incompleet_fase;
        $c->stash->{status_next_stop}                   = 1;
    }


    if (!$c->can_change) {
        $c->res->redirect(
            $c->uri_for(
                '/zaak/' . $c->stash->{zaak}->id
            )
        );
        $c->detach;
    }

    if ($c->stash->{zaak}->is_afgehandeld) {
        my $errmsg = 'Deze zaak is afgehandeld, '
            .'extra wijzigingen zijn niet meer mogelijk';

        $c->log->warn($c->flash->{result} = $errmsg);

        $c->response->redirect(
            $c->uri_for('/zaak/' . $c->stash->{zaak}->nr)
        );

        $c->detach;
    }
}

sub status_base : Chained('/zaak/base') : PathPart('status'): CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->forward('_status_check_possibility');

    $c->add_trail(
        {
            uri     => $c->uri_for(
                '/zaak/' . $c->stash->{zaak}->nr .
                '/status/next'
            ),
            label   => 'Volgende fase',
        }
    );
}

sub next :Chained('status_base') : PathPart('next'): Args(0) {
    my ( $self, $c ) = @_;

    if (
        $c->req->header("x-requested-with") eq 'XMLHttpRequest' &&
        $c->req->params->{do_validation}
    ) {
        $c->zcvalidate({ success => 1});
        $c->detach;
    }

    $c->stash->{template} = 'zaak/status/next.tt';

    ### NO Post
    unless ($c->req->params->{update}) {
        delete($c->session->{status_tmp});

        $c->detach;
    }

    ### CHECKS
    if (
        ! $c->stash->{zaak}->can_volgende_fase ||
        $c->stash->{status_next_stop}
    ) {
        my $errmsg      = 'Checklist, documenten of kenmerken niet compleet, '
            .'kan status niet verhogen.';

        $c->log->warn           ( $c->flash->{result} = $errmsg );
        $c->response->redirect  ( $c->uri_for('/' . $c->req->path));
        $c->detach;
    }


    ### SET FASE
    if (!$c->stash->{zaak}->set_volgende_fase) {
        my $errmsg      = 'Fase werd niet verhoogd, contact systeembeheer.';

        $c->log->error          ( $c->flash->{'result'} = $errmsg );
        $c->response->redirect  (
            $c->uri_for('/zaak/' . $c->stash->{zaak}->nr)
        );
        $c->detach;
    }

    $c->forward('_handle_toewijzing');

    # voor regels uit
    my $status = $c->req->param('fase') || 1;

    my $regels = $c->model('Regels');
    $regels->_execute_regels(
        $c, 
        $c->stash->{zaak}->zaaktype_node_id->id, 
        $status,
        $c->stash->{zaak}->zaak_kenmerken->search_all_kenmerken({ fase => $status})
    );



    ### XXX TODO ZS2 kenmerk resultaat
    if (defined($c->req->params->{system_kenmerk_resultaat})) {
        $c->stash->{zaak}->kenmerk->resultaat(
            $c->req->params->{system_kenmerk_resultaat}
        );
    }

    $c->flash->{'result'} = 'Fase van zaak succesvol verhoogd';

    ## Start vervolg/deelzaken
    my $open_zaak = $self->start_subzaken($c);

    $c->forward('notificatie_send');
    $c->forward('/zaak/_create_zaak_handle_sjablonen');

    my $response_uri;
    if (exists($c->stash->{behandelaar_changed})) {
        $c->flash->{'result'} = 'Fase van zaak succesvol verhoogd en behandelaar gewijzigd.';
        $response_uri = $c->uri_for('/');
    } elsif (
        $c->stash->{zaak}->is_afhandel_fase
    ) {
        if ($open_zaak) {
            $c->flash->{'result'} = 'Fase van zaak succesvol afgehandeld'
                . ' en vervolgzaak geopend.';
            ### Override any of the above when we want to start a subzaak
            ### immediatly
            $response_uri = '/zaak/' . $open_zaak->nr;
        } else {
            $c->flash->{'result'} = 'Fase van zaak succesvol afgehandeld.';
            $response_uri = $c->uri_for('/');
        }
    } else {
        if ($c->stash->{zaak}->behandelaar) {
            $response_uri = $c->uri_for('/zaak/' . (
                    $open_zaak ? $open_zaak->nr :
                    $c->stash->{zaak}->nr
                )
            );
        } else {
            $response_uri = $c->uri_for('/');
        }
    }

    $c->model('Bibliotheek::Sjablonen')->touch_zaak($c->stash->{zaak});

    $c->response->redirect(
        $response_uri
    );

    return;

}

sub _handle_toewijzing : Private {
    my ($self, $c) = @_;

    if ($c->req->params->{toewijzing_type} eq 'route') {
        $c->log->debug('Wijzig toewijzing naar: ' .
            $c->req->params->{ou_id} . ':' . $c->req->params->{role_id}
        );
        $c->stash->{zaak}->wijzig_route(
            $c->req->params->{ou_id},
            $c->req->params->{role_id},
        );
    } elsif ($c->req->params->{toewijzing_type} eq 'behandelaar') {
        if ($c->req->params->{ztc_behandelaar_id}) {
            $c->stash->{zaak}->set_behandelaar(
                $c->req->params->{ztc_behandelaar_id}
            );

            $c->stash->{zaak}->status('new');
            $c->stash->{zaak}->update;

            $c->stash->{behandelaar_changed} = 1;
        }
    }

    return 1;
}

sub nextnot :Chained('/zaak/base') : PathPart('status/nextnot'): Args(0) {
    my ( $self, $c ) = @_;


    ### Submit
    if (
        exists($c->req->params->{'update'}) &&
        $c->req->params->{'update'}
    ) {

#        if (
#            $c->stash->{zaak}->fase->is_volgende_einde &&
#            !$c->req->params->{system_kenmerk_resultaat}
#        ) {
#            $c->log->debug('Resultaat is niet ingevuld');
#            $c->flash->{'result'} = 'Resultaat van deze zaak is verplicht';
#            $c->response->redirect( $c->uri_for('/' . $c->req->path));
#            $c->detach;
#        }


        ### 1) Update checklist
        $c->log->debug(
            'Status change for ' . $c->stash->{zaak}->nr . ' => next'
        );
        my $options = {};

        ### XXX What is this doing here.
        foreach my $checklist (keys %{ $c->req->params }) {
            if (my ($option) = $checklist =~ /^checklist\[(.*?)\]/) {
                $c->stash->{zaak}->checklist->set(
                    $option,
                    $c->req->params->{$checklist}
                );
            }
        }

        ### 2) Raise status
        if (! $c->stash->{zaak}->zaakstatus->can_next ) {
            $c->log->debug('Checklist, documenten of kenmerken niet compleet, kan status niet verhogen.');
            $c->flash->{'result'} = 'Checklist, documenten of kenmerken voor huidige fase niet compleet, kan fase niet verhogen';
            $c->response->redirect( $c->uri_for('/' . $c->req->path));
            $c->detach;
        }

        if (! $c->stash->{zaak}->zaakstatus->next_status) {
            $c->flash->{'result'} = 'Fase werd niet verhoogd, contact systeembeheer';
            $c->log->error(
                'Zaak kon niet worden verhoogd (zaak: ' .
                $c->stash->{zaak}->nr . ')'
            );
            $c->response->redirect(
                $c->uri_for('/zaak/' . $c->stash->{zaak}->nr)
            );
            $c->detach;
        }

        ### 3) Change behandelaar
        if ($c->req->params->{ztc_behandelaar_id}) {
            $c->stash->{zaak}->behandelaar(
                $c->req->params->{ztc_behandelaar_id}
            );

            $c->stash->{zaak}->status('new');
            $c->stash->{behandelaar_changed} = 1;
        }

        if (defined($c->req->params->{system_kenmerk_resultaat})) {
            $c->stash->{zaak}->kenmerk->resultaat(
                $c->req->params->{system_kenmerk_resultaat}
            );
        }

        if (
            $c->stash->{zaak}->zaakstatus->nextnode->status eq
            $c->stash->{zaak}->zaakstatus->afhandel->status
        ) {
            $c->stash->{zaak}->sluit(time);
        }

        $c->flash->{'result'} = 'Fase van zaak succesvol verhoogd';

        ## Start vervolg/deelzaken
        my $open_zaak = $self->start_subzaken($c);

#        if ($c->req->params->{zaaktype}) {
#            # Start vervolgzaak
#
#            $c->forward('/zaak/vervolg');
#
#            $c->flash->{result} .= ' en vervolgzaak is aangemaakt onder nummer:
#            ' . $c->stash->{vervolg_zaak}->nr if $c->stash->{vervolg_zaak};
#        }

        $c->stash->{zaak}->notes->add({
            'commenttype'   => 'status',
            'value'         => 'Fase verhoogd door '
                . $c->user->displayname,
        });

        $c->forward('notificatie_send');

        my $response_uri;
        if (exists($c->stash->{behandelaar_changed})) {
            $c->flash->{'result'} = 'Fase van zaak succesvol verhoogd en behandelaar gewijzigd.';
            $response_uri = $c->uri_for('/');
        } elsif (
            $c->stash->{zaak}->zaakstatus->nextnode->status eq
            $c->stash->{zaak}->zaakstatus->afhandel->status
        ) {
            if ($open_zaak) {
                $c->flash->{'result'} = 'Fase van zaak succesvol afgehandeld'
                    . ' en vervolgzaak geopend.';
                ### Override any of the above when we want to start a subzaak
                ### immediatly
                $response_uri = '/zaak/' . $open_zaak->nr;
            } else {
                $c->flash->{'result'} = 'Fase van zaak succesvol afgehandeld.';
                $response_uri = $c->uri_for('/');
            }
        } else {
            $response_uri = $c->uri_for('/zaak/' . (
                    $open_zaak ? $open_zaak->nr :
                    $c->stash->{zaak}->nr
                )
            );
        }


        $c->response->redirect(
            $response_uri
        );

        return;
    }

    #$c->forward('/zaak/mail/preview');

}

sub notificatie_send : Private {
    my ($self, $c) = @_;

    ### Make sure mail is fully loaded
    $c->forward('load_notificatie_definitie', [ { huidige_fase => 1 } ]);
    #$c->forward('notificatie_definitie');

    $c->log->debug(
        'Z::S->notificatie_send: sending notifications'
    );

    ### Now have fun
    while (
        my ($uniqueidr, $notificatie) = each %{
            $c->session->{status_tmp}->{notificaties}
        }
    ) {
        $uniqueidr =~ s/_id_/_run_/g;

        $c->log->debug(
            'Z::S->notificatie_send: try sending onderwerp: '
            . $notificatie->{onderwerp}
        );

        next unless $c->req->params->{$uniqueidr};

        $c->log->debug(
            'Z::S->notificatie_send: sending onderwerp: '
            . $notificatie->{onderwerp}
        );
        $c->stash->{notificatie} = {
           message => $notificatie
        };

        ### Find behandelaar
        if ($notificatie->{rcpt} eq 'behandelaar') {
            if (!$notificatie->{ztc_aanvrager_id}) {
                if (
                    $c->stash->{zaak}->behandelaar &&
                    $c->stash->{zaak}->behandelaar_object->email
                ) {
                    $notificatie->{ztc_aanvrager_id} =
                        $c->stash->{zaak}->behandelaar_object->rt_setup_identifier
                } else {
                    $c->log->error(
                        'No proper rcpt found'
                    );
                }
            }
        }


        $c->forward('/zaak/mail/notificatie');
    }
}

sub start_subzaken : Private {
    my ($self, $c) = @_;
    my (%subzaken_args, $open_zaak);

    ### Of course some authentication
    $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');

    ### And make sure we got all the information we need
    $c->forward('load_zaaktype_kenmerken', [ { huidige_fase => 1 } ]);

    $c->log->debug('1. Start subzaak');

    $subzaken_args{ $_ } = $c->req->params->{ $_ } for
        grep(/status_zaaktype_.*?_\d+$/, keys %{ $c->req->params });

    for my $subzaak (grep(
            /status_zaaktype_id_(\d+)$/,
            keys %subzaken_args
    )) {
        my $count   = $subzaak;
        $count      =~ s/.*(\d+)$/$1/g;

        if (!$c->req->params->{'status_zaaktype_id_' . $count}) { next; }

        ### Is vinke 'Starten' aangevinkt?
        if (!$c->req->params->{'status_zaaktype_run_' . $count}) { next; }

        ### Now let's go...
        my $aanvrager_type = $c->session->{status_tmp}->{zaaktype_kenmerken}->{
            'status_zaaktype_id_' . $count
        }->{eigenaar};

        my %zaakopts = (
            'zaaktype_id'  =>
                $c->req->params->{'status_zaaktype_id_' . $count},
            'add_days'          =>
                $c->req->params->{'status_zaaktype_start_' . $count},
            'actie_kopieren_kenmerken' =>
                (
                    $c->req->params->{
                        'status_zaaktype_kopieren_kenmerken_' .  $count
                    } ||
                    $c->session->{status_tmp}->{zaaktype_kenmerken}->{
                        'status_zaaktype_id_' . $count
                    }->{kopieren_kenmerken}
                ),
            'role_id' => (
                    $c->session->{status_tmp}->{zaaktype_kenmerken}->{
                        'status_zaaktype_id_' . $count
                    }->{role_id} || undef
                ),
            'ou_id' => (
                    $c->session->{status_tmp}->{zaaktype_kenmerken}->{
                        'status_zaaktype_id_' . $count
                    }->{ou_id} || undef
                ),
            'aanvrager_type'    => ($aanvrager_type ?
                $aanvrager_type : 'aanvrager'
            ),
            'actie_automatisch_behandelen'    => (
                $c->session->{status_tmp}->{zaaktype_kenmerken}->{
                    'status_zaaktype_id_' . $count
                }->{automatisch_behandelen} || undef
            ),

        );

        $zaakopts{type_zaak} =
            $c->req->params->{'status_zaaktype_deelrelatie_' . $count};

        # Logging for subzaak:
        $c->log->debug(
            'C::Zaak::Status->start_subzaken: ' .
            Dumper(\%zaakopts)
        );

        $c->log->debug('5. Daadwerkelijk starten');

        my $extra_zaak = $c->model('DB::Zaak')->create_relatie(
            $c->stash->{zaak},
            %zaakopts
        );

        $c->log->debug(
            'Req: ' . $c->req->params->{'status_zaaktype_open'} . "\n" .
            'zaaktype_id: ' . $zaakopts{zaaktype_id} .
            'extra epoch: ' . $extra_zaak->registratiedatum->epoch .
            'nu epoch: ' . DateTime->now()->epoch
        );

        if (
            $c->req->params->{'status_zaaktype_open'} eq
                $zaakopts{zaaktype_id} &&
            $extra_zaak->registratiedatum->epoch < DateTime->now()->epoch
        ) {
            $c->log->debug('OOOPEN: ' . $extra_zaak->id);
            $open_zaak = $extra_zaak;
        }

        ### Make sure we do not have a 'create_zaak' session open
        my $current_zaak    = $c->stash->{zaak};
        $c->stash->{zaak}   = $extra_zaak;

        delete($c->session->{_zaak_create});
        $c->forward('/zaak/handle_fase_acties');

        $c->stash->{zaak}   = $current_zaak;
    }

    return $open_zaak;
}

sub load_zaaktype_kenmerken : Private {
    my ($self, $c, $opt) = @_;

    ### Retrieve subzaak information
    if (
        !$c->session->{status_tmp} &&
        !$c->session->{status_tmp}->{zaaktype_kenmerken}
    ) {

        my $relaties;
        if ($opt && UNIVERSAL::isa($opt, 'HASH') && $opt->{huidige_fase}) {
            $relaties =
                $c->stash->{zaak}->huidige_fase->zaaktype_relaties;
        } else {
            $relaties =
                $c->stash->{zaak}->volgende_fase->zaaktype_relaties;
        }

        $c->session->{status_tmp}                       = {};
        $c->session->{status_tmp}->{zaaktype_kenmerken} = {};

        my $count = 0;
        while (my $relatie = $relaties->next) {
            $c->session->{status_tmp}->{zaaktype_kenmerken}->{
                'status_zaaktype_id_' . ++$count
            }->{eigenaar} = $relatie->eigenaar_type;
            $c->session->{status_tmp}->{zaaktype_kenmerken}->{
                'status_zaaktype_id_' . $count
            }->{kopieren_kenmerken} = $relatie->kopieren_kenmerken;
            $c->session->{status_tmp}->{zaaktype_kenmerken}->{
                'status_zaaktype_id_' . $count
            }->{status} = $relatie->status;
            $c->session->{status_tmp}->{zaaktype_kenmerken}->{
                'status_zaaktype_id_' . $count
            }->{ou_id} = $relatie->ou_id;
            $c->session->{status_tmp}->{zaaktype_kenmerken}->{
                'status_zaaktype_id_' . $count
            }->{role_id} = $relatie->role_id;
            $c->session->{status_tmp}->{zaaktype_kenmerken}->{
                'status_zaaktype_id_' . $count
            }->{automatisch_behandelen} =
                $relatie->automatisch_behandelen;
        }

    }

}

sub zaaktype_kenmerken : Chained('/zaak/base'): PathPart('status/next/zaaktype_kenmerken'): Args(0) {
    my ($self, $c) = @_;

    $c->log->debug(Dumper($c->session->{status_tmp}));

    if (%{ $c->req->params } && $c->req->params->{update}) {
        $c->session->{status_tmp}->{zaaktype_kenmerken}
            ->{ $c->req->params->{destination} } = {
                'eigenaar'      => $c->req->params->{deelvervolg_eigenaar},
                'kopieren_kenmerken'    => $c->req->params->{deelvervolg_kopieren_kenmerken},
                'status'                => $c->req->params->{deelvervolg_status},
                'ou_id'                 => $c->req->params->{deelvervolg_ou_id},
                'role_id'               => $c->req->params->{deelvervolg_role_id},
                'automatisch_behandelen' =>
                                $c->req->params->{deelvervolg_automatisch_behandelen}
            };
        $c->res->body('OK');
        return;
    } else {
        $c->forward('load_zaaktype_kenmerken');
    }
    $c->log->debug(Dumper($c->session->{status_tmp}));

    if (
        $c->session->{status_tmp}->{zaaktype_kenmerken}
            ->{ $c->req->params->{destination} }
        ) {
        $c->stash->{history} =
                $c->session->{status_tmp}->{zaaktype_kenmerken}
                    ->{ $c->req->params->{destination} };
#    } else {
#        my ($status, $vraag) = $c->req->params->{destination} =~
#            /status_checklist_vraag_(\d+)_(\d+)/;
#
#        if (
#            $c->session->{zaaktype_edit}->{status}
#                    ->{$status}->{checklist}->{$vraag}->{antwoorden}
#        ) {
#            $c->log->debug('Found history');
#            $c->stash->{history} =
#                $c->session->{zaaktype_edit}->{status}
#                        ->{$status}->{checklist}->{$vraag}->{antwoorden};
#        }
    }

    $c->stash->{nowrapper} = 1;
    $c->stash->{nextstatus} = 1;
    $c->stash->{template}  = 'zaak/status/vervolgzaken.tt';
}

sub load_notificatie_definitie : Private {
    my ($self, $c, $opt) = @_;

    ### Retrieve subzaak information
    if (
        !$c->session->{status_tmp} ||
        !$c->session->{status_tmp}->{notificaties}
    ) {

        my $notificaties;
        if ($opt && UNIVERSAL::isa($opt, 'HASH') && $opt->{huidige_fase}) {
            $notificaties = $c->stash->{zaak}
                ->huidige_fase
                ->zaaktype_notificaties
                ->search;
        } else {
            $notificaties = $c->stash->{zaak}
                ->volgende_fase
                ->zaaktype_notificaties
                ->search;
        }

        $c->session->{status_tmp}                       = {};
        $c->session->{status_tmp}->{notificaties}       = {};

        my $count = 0;
        while (my $notificatie = $notificaties->next) {
            $c->session->{status_tmp}->{notificaties}->{
                'status_notificatie_id_' . ++$count
            }->{rcpt} = $notificatie->rcpt;
            if ($notificatie->rcpt eq 'behandelaar') {
                $c->session->{status_tmp}->{notificaties}->{
                    'status_notificatie_id_' . $count
                }->{ztc_aanvrager_id} = $notificatie->email;
                $c->session->{status_tmp}->{notificaties}->{
                    'status_notificatie_id_' . $count
                }->{email} = $notificatie->email;
            } elsif ($notificatie->rcpt eq 'overig') {
                $c->session->{status_tmp}->{notificaties}->{
                    'status_notificatie_id_' . $count
                }->{email} = $notificatie->email;
            }
            $c->session->{status_tmp}->{notificaties}->{
                'status_notificatie_id_' . $count
            }->{onderwerp} = $notificatie->onderwerp;
            $c->session->{status_tmp}->{notificaties}->{
                'status_notificatie_id_' . $count
            }->{bericht} = $notificatie->bericht;
            $c->session->{status_tmp}->{notificaties}->{
                'status_notificatie_id_' . $count
            }->{intern_block} = $notificatie->intern_block;
        }
    }
}

sub notificatie_definitie : Chained('/zaak/base'): PathPart('status/next/notificatie_definitie'): Args() {
    my ($self, $c, $statusid) = @_;

    if (%{ $c->req->params } && $c->req->params->{update}) {
        $c->session->{status_tmp}->{notificaties}
            ->{ $c->req->params->{uniqueidr} } = {
                map {
                    my $label   = $_;
                    $label      =~ s/^notificatie_//g;
                    $label      => $c->req->params->{ $_ }
                } grep(/^notificatie_/, keys %{ $c->req->params })
            };

        $c->res->body('OK');
        return;
    }

    $c->forward('load_notificatie_definitie');
    if (
        $c->session->{status_tmp}->{notificaties}
            ->{ $c->req->params->{uniqueidr} }
    ) {
        ### History should overwrite edit parameters
        $c->stash->{history} =
                $c->session->{status_tmp}->{notificaties}
                    ->{ $c->req->params->{uniqueidr} };
    }

    ### Behandelaar of overig
    if ($c->stash->{history}->{rcpt} eq 'behandelaar') {
        $c->session->{status_tmp}->{notificaties}
            ->{ $c->req->params->{uniqueidr} }->{ztc_aanvrager_id}
            = $c->session->{status_tmp}->{notificaties}
                ->{ $c->req->params->{uniqueidr} }->{email};

        if (
            ! $c->session->{status_tmp}->{notificaties}
                ->{ $c->req->params->{uniqueidr} }->{ztc_aanvrager} &&
            $c->session->{status_tmp}->{notificaties}
                ->{ $c->req->params->{uniqueidr} }->{ztc_aanvrager_id}
        ) {
            my $beh = $c->model('Betrokkene')->get(
                {},
                $c->session->{status_tmp}->{notificaties}
                    ->{ $c->req->params->{uniqueidr} }->{ztc_aanvrager_id}
            );

            if ($beh) {
                $c->session->{status_tmp}->{notificaties}
                    ->{ $c->req->params->{uniqueidr} }->{ztc_aanvrager}
                        = $beh->naam;
            }
        }
    }

    $c->log->debug('Definitie: ' . Dumper($c->session->{status_tmp}));
    $c->stash->{popupaction} = $c->uri_for(
        '/zaak/' . $c->stash->{zaak}->nr .
        '/status/next/notificatie_definitie'
    );
    $c->stash->{nowrapper} = 1;
    $c->stash->{ZAAKSTATUS} = 1;
    $c->stash->{template}  = 'zaaktype/status/notificatie_definitie.tt';
}


# XXX REMOVE AFTER 2010-08-01
sub prev :Chained('/zaak/base') : PathPart('status/prev'): Args(1) {
    my ($self, $c, $status) = @_;

    $c->stash->{'zaak'}->kenmerk->status($status);

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

