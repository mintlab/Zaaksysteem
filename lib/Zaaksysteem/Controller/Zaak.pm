package Zaaksysteem::Controller::Zaak;

use strict;
use warnings;

use Moose;

use Data::Dumper;
use HTML::TagFilter;
use File::stat;
use Time::localtime;
use File::Basename;

BEGIN { extends 'Catalyst::Controller'; }

use Zaaksysteem::Constants qw/
    ZAAKSYSTEEM_CONSTANTS
    ZAAKSYSTEEM_GM_AUTHENTICATEDBY_BEHANDELAAR
    LDAP_DIV_MEDEWERKER
    ZAAKSYSTEEM_AUTHORIZATION_ROLES

    ZAAKSYSTEEM_CONTACTKANAAL_WEBFORM
    ZAAKSYSTEEM_CONTACTKANAAL_BALIE

    ZAAK_CREATE_PROFILE

/;




sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Zaaksysteem::Controller::Zaak in Zaak.');
}



sub base : Chained('/') : PathPart('zaak'): CaptureArgs(1) {
    my ($self, $c, $id) = @_;

    #$c->assert_permission('zaak_view');
    $c->log->debug('Opening zaak?' . $id);
    return unless $id =~ /^\d+$/;

    $c->add_trail(
        {
            uri     => $c->uri_for('/zaak/' . $id . '#zaak-elements-checklist'),
            label   => 'Zaak (' . $id . ')',
        }
    );

    $c->stash->{'template'}     = 'zaak/view.tt';
    $c->log->debug('Opening zaak');

    ### Retrieve zaak
    $c->stash->{'zaak'}         = $c->model('DB::Zaak')->find($id);

    if (!$c->stash->{zaak}) {
        $c->flash->{'result'} = 'Geen zaak gevonden met dit nummer';
        $c->response->redirect($c->uri_for('/'));
        $c->detach;
    }

    if ($c->user_exists) {
        $c->assert_any_zaak_permission('zaak_read','zaak_beheer','zaak_edit');
    }


    my $params = $c->req->params;

    ### Find fase
    my $fase;
    if (($fase = $params->{fase}) && $fase =~ /^\d+$/) {
        my $fases = $c->stash->{zaak}
            ->zaaktype_node_id
            ->zaaktype_statussen
            ->search({ status  => $fase });

        $c->stash->{requested_fase} = $fases->first if $fases->count;
    } else {
        $c->stash->{requested_fase} = (
            $c->stash->{zaak}->volgende_fase ||
            $c->stash->{zaak}->huidige_fase
        );
    }

    if ($c->req->action ne '/zaak/update') {
        $c->forward('_execute_regels');
    }
}



my $SPIFFY_SPINNER_DEFINITION = {
    'mode'      => 'timer',
    'title'     => 'Een moment geduld a.u.b. ...',
    'checks'    => [
        {
            'naam'  => 'kenmerk',
            'label' => 'Verzenden van formulier',
            'timer' => 2000,
        },
        {
            'naam'  => 'sjabloon',
            'label' => 'Aanmaken van documenten',
            'timer' => 2000,
        },
        {
            'naam'  => 'notificatie',
            'label' => 'Verzenden van notificatie',
            'timer' => 2000,
        },
        {
            'naam'  => 'vervolgzaak',
            'label' => 'Aanmaken van zaak',
            'timer' => 2000,
        },
    ],
};

sub create_redirect : Chained('/') : PathPart('zaak/create'): Args(0) {
    my ($self, $c, $wizard_stap) = @_;

    my $url = '/zaak/create/balie';
    if ($c->is_externe_aanvraag) {
        $url = '/zaak/create/webformulier';
    } else {
        $c->session->{_zaak_create}                 = {};
    }

    $c->res->redirect($c->uri_for($url, $c->req->params));
}


{

    Zaaksysteem->register_profile(
        'method'    => 'create',
        'profile'   => ZAAK_CREATE_PROFILE
    );



    sub create_base : Chained('/') : PathPart('zaak/create'): CaptureArgs(1) {
        my ($self, $c, $aangevraagd_via) = @_;

		use Time::HiRes qw(gettimeofday tv_interval);
		
		my $t0 = [gettimeofday];
		$c->log->debug("start create zaak");

        $c->forward('_spiffy_spinner', [ $SPIFFY_SPINNER_DEFINITION ]);

        if ($c->user_exists) {
            if ($c->req->params->{tooltip}) {
                #$c->log->debug(Dumper($c->session->{remember_zaaktype}));
                $c->stash->{'template'} = 'widgets/zaak/create.tt';
                $c->stash->{'nowrapper'} = 1;
            } else {
                $c->stash->{'template'} = 'zaak/annuleer.tt';
            }
        } else {
            $c->stash->{'template'} = 'forbidden.tt';
        }

        if ($c->req->params->{sessreset}) {
            $c->log->debug('Wiping zaak create session, session reset asked');
            $c->session->{_zaak_create} = {};
        }

        ### Start van aanvraag, delete create session
        if ($c->user_exists && !scalar(keys %{ $c->req->params })) {
            $c->forward('_zaak_create_aanmaak_meldingen');

            $c->log->debug('Wiping zaak create session, no params');
            $c->session->{_zaak_create}                 = {};
            $c->detach;
        }

        ### POST
        $c->session->{_zaak_create}->{aangevraagd_via}  = $aangevraagd_via;

        ### Remember zaaktype
        {
            if ($c->req->params->{remember}) {
                $c->session->{remember_zaaktype}->{
                   $c->req->params->{ztc_trigger}
                } = {
                    'id'    => $c->req->params->{zaaktype_id},
                    'naam'  => $c->req->params->{zaaktype_name},
                };
            }
        }

#        $c->log->debug(Dumper($c->session->{_zaak_create}));

        $c->forward('_create_verify_security');

        $c->forward('_create_verify_externe_data');

        $c->forward('_create_validation');

        $c->forward('_create_load_stash');

        $c->forward('_create_zaaktype_validation');

        $c->forward('_create_load_externe_data');


        # Kijken of er een zaak moet worden afgerond
        if ($c->req->params->{afronden}) {
            $c->session->{afronden} = 1;
            $c->session->{afronden_gezet} = 0;
        }


		if (
            $c->req->header("x-requested-with") &&
            $c->req->header("x-requested-with") eq 'XMLHttpRequest'
        ) {
	        $c->stash->{nowrapper} = 1;
        }
    	my  $elapsed = tv_interval ( $t0, [gettimeofday]);
		$c->log->debug("executed zaak/create, time taken: " . $elapsed);

    }


    sub _create_zaaktype_validation : Private {
        my ($self, $c) = @_;

        my $registratie_fase    = $c->stash->{zaak_status};

        unless ($registratie_fase) {
            $c->stash->{template}   = 'form/aanvraag_error.tt';
            $c->stash->{error}      = {
                titel   => 'Helaas, deze zaak kan niet worden aangevraagd',
                bericht => 'Wij kunnen uw aanvraag helaas niet uitvoeren, '
                    .'omdat dit zaaktype niet gevonden kan worden'
                    . '. [invalid]'
            };
            $c->detach;
        }

        if ($c->stash->{zaaktype}->deleted) {
            $c->stash->{template}   = 'form/aanvraag_error.tt';
            $c->stash->{error}      = {
                titel   => 'Helaas, deze zaak kan niet worden aangevraagd',
                bericht => 'Wij kunnen uw aanvraag helaas niet uitvoeren, '
                    .'omdat dit zaaktype niet gevonden kan worden'
                    . '. [deleted]'
            };
            $c->detach;
        }
    }

    sub _zaak_create_aanmaak_meldingen : Private {
        my ($self, $c) = @_;

        if ($c->req->params->{actie} && $c->req->params->{actie} eq 'doc_intake') {
            $c->stash->{flash} = 'Document toevoegen aan zaak';
        }

    }

    sub _create_load_externe_data : Private {
        my ($self, $c) = @_;

        ### Only for externe aanvragen
        return 1 if $c->user_exists;

        unless (
            $c->session->{_zaak_create}->{extern} &&
            $c->session->{_zaak_create}->{extern}->{aanvrager_type}
        ) {
            $c->detach('/form/aanvrager_type');
        }

        $c->forward('_create_secure_aanvrager_bekend');

        ### Fallback, NOT AUTHORIZED
        unless (
            $c->session->{_zaak_create}->{extern} &&
            $c->session->{_zaak_create}->{extern}->{verified}
        ) {
            $c->detach('/form/aanvrager_type');
        }

        $c->session->{_zaak_create}->{aanvraag_trigger} = 'extern';

        ### Verify bussumid or digid
        $c->forward('/plugins/digid/_zaak_create_load_externe_data');
        $c->forward('/plugins/bedrijfid/_zaak_create_load_externe_data');
    }


    sub _create_secure_aanvrager_bekend : Private {
        my ($self, $c) = @_;

        ### Not logged in, in any way
        unless ($c->session->{_zaak_create}->{extern}->{verified}) {
            $c->detach;
        }

    }

    sub _create_verify_externe_data : Private {
        my ($self, $c) = @_;

        ### Only for externe aanvragen
        return 1 if $c->user_exists;

        ### Verify bussumid or digid
        $c->forward('/plugins/digid/_zaak_create_secure_digid');
        $c->forward('/plugins/bedrijfid/_zaak_create_security');
    }

    sub create : Chained('create_base') : PathPart(''): Args() {
        my ($self, $c, $wizard_stap) = @_;

        ### Dispatch to form
        if ($c->user_exists) {
            $wizard_stap ||= 'zaakcontrole';
        } else {
            $wizard_stap ||= 'aanvrager';
        }

        $c->forward('/form/' . $wizard_stap);

        $c->detach unless $c->stash->{publish_zaak};

        ### Publish zaak
        $c->forward('_create_zaak', [ $c->session->{_zaak_create} ]);
    }

    sub _create_handle_finish : Private {
        my ($self, $c, $params)  = @_;

        ### NOTIFICATIE
        if (
            $c->session->{_zaak_create} &&
            $c->stash->{zaak}->zaaktype_node_id->online_betaling &&
            (
                !$c->user_exists ||
                exists($c->session->{behandelaar_form})
            )
        ) {
            $c->stash->{zaak}->status('stalled');
            $c->stash->{zaak}->update;

            $c->stash->{zaak}->reden_opschorten(
                'Wachten op betaling'
            );

            $c->detach('/plugins/ogone/betaling');
        } else {
            $c->stash->{notificatie}    = {
                'status'        => 1
            };

            $c->forward('/zaak/mail/notificatie');
        }


        if ($c->session->{_zaak_create}) {
            ### Logged in
            if ($c->user_exists) {
                if (!$c->stash->{zaak}) {
                    my $errmsg  = 'Er is iets misgegaan bij het aanmaken '
                        . 'van de zaak.';
                    $c->log->error($c->flash->{result} = $errmsg);

                    $c->res->redirect(
                        $c->uri_for('/')
                    );
                    $c->detach;
                }
            }

            # Check of de klant een onafgeronde zaak heeft staan
            my $onafgeronde_zaak = $c->model('DB::ZaakOnafgerond')->find(
                $c->session->{_zaak_create}->{zaaktype_id}, 
                $c->session->{_zaak_create}->{ztc_aanvrager_id}
            );

            if ($onafgeronde_zaak) {
                $onafgeronde_zaak->delete; 
                $c->log->debug('ONAFGERONDE ZAAK UIT TABEL GEHAALD!');
            }

            my $redirect = '/';
            if ($c->user_exists && !exists($c->session->{behandelaar_form})) {
                if ($c->req->params->{actie_automatisch_behandelen}) {
                    $redirect = '/zaak/' . $c->stash->{zaak}->nr;
                } else {
                    $c->flash->{result} = 'Uw zaak is geregistreerd onder <a href="/zaak/'.$c->stash->{zaak}->nr.'">zaaknummer '.$c->stash->{zaak}->nr.'</a>';
                    $redirect = '/';
                }

                $c->response->redirect($redirect);
                $c->detach;
            } elsif (!$c->user_exists) {
                ### External user
                $c->stash->{template} = 'form/finish.tt';
            } else {
                return 1;
            }

            delete($c->session->{_zaak_create});
        }
    }

    sub _create_zaak : Private {
        my ($self, $c, $params)  = @_;

        ### Fix kenmerken
        {
            $params->{kenmerken} = [];

            unless($params->{raw_kenmerken} && %{ $params->{raw_kenmerken} }) {
                $params->{raw_kenmerken} = $params->{form}->{kenmerken};
            }

            for my $kenmerk (keys %{ $params->{raw_kenmerken} }) {
                ### Normal kenmerk
                push( @{ $params->{kenmerken} },
                    { $kenmerk    => $params->{raw_kenmerken}->{$kenmerk} }
                )
            }
        }

        ### Fix betrokkene
        if ($params->{ztc_aanvrager_id} && $params->{ztc_aanvrager_id} =~ /betrokkene-.*?-.*/) {
            $params->{aanvragers} = [{
                'betrokkene'        => $params->{ztc_aanvrager_id},
                'verificatie'       => (
                    (
                        $c->session->{_zaak_create}->{aangevraagd_via} eq
                            ZAAKSYSTEEM_CONTACTKANAAL_WEBFORM
                    )
                        ? $c->session->{_zaak_create}->{extern}->{verified}
                        : 'medewerker'
                )
            }];
        }

        ### REMOVE DUMMY
        if ($params->{aanvragers}) {
            for (my $i=0; $i < scalar(@{ $params->{aanvragers} }); $i++) {
                if ($params->{aanvragers}->[$i]->{betrokkene} =~ /dummy/) {
                    delete($params->{aanvragers}->[$i]);
                }
            }
        }

        $c->log->debug('Create zaak with: ' . Dumper($params));

        my $zaak            = $c->model('DB::Zaak')->create_zaak($params) or return;

        $c->stash->{zaak}   = $zaak;

        $c->forward('/zaak/handle_fase_acties', [ $params ]);

        return $zaak;
    }

    sub handle_fase_acties : Private {
        my ($self, $c, $params) = @_;

        $c->forward('_create_zaak_handle_uploads', [ $params ]);
        $c->forward('_create_zaak_handle_contact', [ $params ]);
        $c->forward('_create_zaak_handle_acties', [ $params ]);
        $c->forward('_create_zaak_handle_sjablonen', [ $params ]);
        $c->forward('_create_zaak_handle_deelzaken', [ $params ]);

        $c->model('Bibliotheek::Sjablonen')->touch_zaak($c->stash->{zaak});

        $c->forward('_create_handle_finish');
    }

    sub _create_zaak_handle_deelzaken : Private {
        my ($self, $c, $params)  = @_;

        ### This is here, because we can call this method from status/next,
        ### and then we do not want to run this routine.
        return unless ($c->session->{_zaak_create});

        my $status    = $c->stash->{zaak}
            ->zaaktype_node_id->zaaktype_statussen->search(
                {
                    status  => 1,
                }
            )->first;

        return unless $status;

        my $relaties    = $status->zaaktype_relaties->search;

        return unless $relaties->count;

        $c->log->debug('Starting zaaktype relaties');

        while (my $relatie = $relaties->next) {
            my $start_options   = {
                zaaktype_id             => $relatie->relatie_zaaktype_id->id,
                add_days                => $relatie->start_delay,
                actie_kopieren_kenmerken => $relatie->kopieren_kenmerken,
                aanvrager_type          => $relatie->eigenaar_type,
                behandelaar_type        => 'behandelaar',
                type_zaak               => $relatie->relatie_type,
            };

            $start_options->{ $_ } = $relatie->$_ for
                qw/ou_id role_id/;

            my $extra_zaak = $c->model('DB::Zaak')->create_relatie(
                $c->stash->{zaak},
                %{ $start_options }
            );
        }
    }

    sub _create_zaak_handle_sjablonen : Private {
        my ($self, $c, $params)  = @_;

        my $sjablonen  = $c->stash->{zaak}
            ->huidige_fase
            ->zaaktype_sjablonen
            ->search(
                {
                    automatisch_genereren => '1',
                },
                {
                    prefetch    => 'bibliotheek_sjablonen_id',
                }
            );

        while (my $sjabloon = $sjablonen->next) {
            my $args    = {
                'documenttype'      => 'sjabloon',
                'filename'          => $sjabloon->bibliotheek_sjablonen_id->naam . '.odt',
                'zaak_id'           => $c->stash->{zaak}->id,
                'sjabloon_id'       => $sjabloon->bibliotheek_sjablonen_id->id,
                'zaakstatus'        => $c->stash->{zaak}->milestone,
                actie_rename_when_exists    => 1,
            };
            $self->_create_zaak_genereer_sjabloon($c, $args);
        }
        
        $self->_add_regel_sjablonen($c);
    }


    sub _create_zaak_handle_acties : Private {
        my ($self, $c, $params)  = @_;

        ### This is here, because we can call this method from status/next,
        ### and then we do not want to run this routine.
        return unless ($c->session->{_zaak_create});

        if ($c->session->{_zaak_create}->{acties}->{doc_intake}) {
            my $doc_intake  = $c->session->{_zaak_create}
                                ->{acties}
                                ->{doc_intake};

            $c->forward(
                '/zaak/intake/add_to_zaak',
                [
                    {
                        document_type   => 'file',
                        id              => $doc_intake->{component_id},
                        category        => $doc_intake->{document_category},
                        catalogus       => $doc_intake->{document_catalogus},
                        help            => $doc_intake->{document_help},
                        zaaknr          => $c->stash->{zaak}->id,
                        noqueue         => 1,
                    }
                ],
            );
        }

        if ($c->req->params->{actie_automatisch_behandelen}) {
            $c->stash->{zaak}->open_zaak;

            $c->flash->{result} = 'Zaak is door u in behandeling genomen';
        }

        if ($c->req->params->{actie_ou_id}) {
            $c->stash->{zaak}->route_ou(
                $c->req->params->{actie_ou_id}
            );
            $c->stash->{zaak}->route_role(
                $c->req->params->{actie_role_id}
            );
            $c->stash->{zaak}->update;
        }
    }


    sub _create_zaak_handle_contact : Private {
        my ($self, $c, $params)  = @_;

        ### This is here, because we can call this method from status/next,
        ### and then we do not want to run this routine.
        return unless ($c->session->{_zaak_create});

        for (qw/npc-email npc-telefoonnummer npc-mobiel/) {
            my $value;
            if (defined($c->req->params->{ $_ })) {
                $value = $c->req->params->{ $_ };
            } elsif (defined($params->{ $_ })) {
                $value = $params->{$_};
            } else {
                next;
            }

            my $key     = $_;
            $key =~ s/^npc-//g;

            $c->log->debug('Add aanvrager: ' . $key . ':' . $value);
            $c->stash->{zaak}->aanvrager_object->$key($value)
        }

    }

    sub _create_zaak_handle_uploads : Private {
        my ($self, $c, $params)  = @_;

        ### This is here, because we can call this method from status/next,
        ### and then we do not want to run this routine.
 #       return unless ($c->session->{_zaak_create});

        return 1 unless ($params && $params->{uploads});

        while (my ($kenmerk_id,$upload_info) = each %{ $params->{uploads} }) {
            
            next unless($upload_info->{upload});

            my $bibkenmerk = $c->stash->{zaak}
                ->zaaktype_node_id
                ->zaaktype_kenmerken
                ->search(
                    {
                        'bibliotheek_kenmerken_id.id'           => $kenmerk_id,
                        'bibliotheek_kenmerken_id.value_type'   => 'file',
                    },
                    {
                        join    => 'bibliotheek_kenmerken_id'
                    }
                );

            next unless $bibkenmerk->count;

            $bibkenmerk = $bibkenmerk->first;

            if ($c->clamscan('kenmerk_id_' . $kenmerk_id)) {
                next;
            }

            ### IE Quirk: filenames contain full path
            my $filename = $upload_info->{upload}->basename;

            my %extra_doc_args = (
                verplicht       => $bibkenmerk->value_mandatory,
                category        => $bibkenmerk->bibliotheek_kenmerken_id
                                    ->document_categorie,
                pip             => $bibkenmerk->pip,
                catalogus       => $bibkenmerk->id,
                zaak_id         => $c->stash->{zaak}->id,
                filename        => $filename,
                documenttype    => 'file',
                actie_rename_when_exists => '1',
            );

            if (defined $upload_info->{filestore_id}) {
                $extra_doc_args{filestore_id} = $upload_info->{filestore_id};
            }

            {
                if ($c->user_exists) {
                    $extra_doc_args{betrokkene_id} = 'betrokkene-medewerker-'
                        . $c->user->uidnumber;
                } elsif ( $c->req->params->{'ztc_aanvrager_id'} ) {
                    $extra_doc_args{betrokkene_id} =
                        $c->req->params->{'ztc_aanvrager_id'};
                } else {
                    $extra_doc_args{betrokkene_id} =
                        $c->stash->{zaak}->aanvrager_object->rt_setup_identifier;
                }

                if (!$extra_doc_args{zaakstatus}) {
                    $extra_doc_args{zaakstatus} = $c->stash->{zaak}->milestone;
                }
            }

            my $document = $c->model('Documents')->add(
                \%extra_doc_args,
                $upload_info->{upload},
            );
        }

        ### Delete uploads from session
        delete($c->session->{_zaak_create}->{uploads});
    }

    sub _create_load_stash : Private {
        my ($self, $c)  = @_;

        $c->forward('_create_load_zaaktype');

        my $first_status       = $c->stash->{zaaktype}
            ->zaaktype_statussen
            ->search(
                {
                    status  => 1,
                }
            )->first;

        $c->stash->{zaak_status}    = $first_status;

        $c->stash->{fields}         = $c->stash->{zaaktype}
            ->zaaktype_kenmerken
            ->search(
                {
                    zaak_status_id  => $first_status->id,
                },
                {
                    prefetch    => ['bibliotheek_kenmerken_id', 'zaak_status_id'],
                    order_by    => 'me.id'
                }
            );

        ### Load aanvrager gegevens
        my $betrokkene_id = $c->req->params->{ztc_aanvrager_id};

        if (!$betrokkene_id && $c->session->{_zaak_create}->{aanvragers}) {
            $betrokkene_id  =
                $c->session->{_zaak_create}->{aanvragers}->[0]->{betrokkene};

            $betrokkene_id  = undef if $betrokkene_id =~ /dummy/;
        } elsif (!$betrokkene_id) {
            $betrokkene_id  = $c->session->{_zaak_create}->{ztc_aanvrager_id};
        }

        if ($betrokkene_id) {
            $c->stash->{aanvrager} = $c->model('Betrokkene')->get(
                {},
                $betrokkene_id
            );
        }

        if ($c->stash->{aanvrager}) {
            $c->stash->{aanvrager_naam} = $c->stash->{aanvrager}->naam;
        } elsif (
            $c->session->{_zaak_create}->{aanvrager_update} &&
            $c->session->{_zaak_create}->{aanvrager_update}->{'np-geslachtsnaam'}
        ) {
            my $aanvrager_sess =
                $c->session->{_zaak_create}->{aanvrager_update};

            $c->stash->{aanvrager_naam} = $aanvrager_sess->{'np-voornamen'}
                . ($aanvrager_sess->{'np-voorvoegsel'} ?
                    ' ' . $aanvrager_sess->{'np-voorvoegsel'} : ''
                ) . ' ' . $aanvrager_sess->{'np-geslachtsnaam'};
        }

        if ($c->session->{_zaak_create}->{vorige_zaak}) {
            $c->stash->{vorige_zaak} = $c->model('DB::Zaak')->find(
                $c->session->{_zaak_create}->{vorige_zaak}
            );

            $c->log->debug('Loaded vorige zaak: ' .
                $c->stash->{vorige_zaak}->id
            ) if $c->stash->{vorige_zaak};
        }

        ### Load aangevraagd via
        $c->stash->{aangevraagd_via} =
            $c->session->{_zaak_create}->{aangevraagd_via};

        $c->stash->{zaak_acties} =
            $c->session->{_zaak_create}->{acties}
                if $c->session->{_zaak_create}->{acties};

        $c->stash->{aanvraag_trigger} =
            $c->session->{_zaak_create}->{aanvraag_trigger}
                if $c->session->{_zaak_create}->{aanvraag_trigger};

        $c->stash->{aanvrager_type} =
            $c->session->{_zaak_create}->{extern}->{aanvrager_type};

        $c->stash->{logged_in_by} =
            $c->session->{_zaak_create}->{extern}->{verified};

        if (
            $c->session->{_zaak_create}->{acties}->{doc_intake}
        ) {
            $c->stash->{doc_intake} = $c->session
                ->{_zaak_create}
                ->{acties}
                ->{doc_intake};
        }

    }

    sub _create_load_zaaktype : Private {
        my ($self, $c)  = @_;

        ### Geen zaaktype? detach to list
        if (
            !$c->user_exists &&
            !$c->session->{_zaak_create}->{zaaktype_id}
        ) {
            $c->detach('/form/list');
        }

        my $zaaktype_node;

        if($c->session->{_zaak_create}->{zaaktype_id}) {
            $zaaktype_node = $c->model('DB::Zaaktype')->find(
                $c->session->{_zaak_create}->{zaaktype_id},
                {
                    prefetch    => [
                    'zaaktype_node_id', { zaaktype_node_id =>
                        'zaaktype_definitie_id' }
                    ],
                }
            )->zaaktype_node_id;
        }

        unless (
            $zaaktype_node
        ) {
            $c->log->debug('Z::C::Zaak->_create_load_zaaktype: '
                . ' zaaktype not found by id: '
                . $c->session->{_zaak_create}->{zaaktype_id}
            );

            delete($c->session->{_zaak_create}->{zaaktype_id});
            $c->detach;
        }

        $c->stash->{zaaktype_node}      = $c->stash->{zaaktype}
                                        = $c->stash->{definitie}
                                        = $zaaktype_node;

        $c->stash->{zaaktype_node_id}   = $c->stash->{zaaktype_node}->id;

        my $aanvragers                  = $c->stash->{zaaktype_node}
                                            ->zaaktype_betrokkenen
                                            ->search;

        $c->stash->{type_aanvragers}    = [];
        while (my $aanvrager = $aanvragers->next) {
            push(
                @{ $c->stash->{type_aanvragers} },
                $aanvrager->betrokkene_type
            );
        }
    }

    sub _create_validation_aanvragers : Private {
        my ($self, $c, $params) = @_;

        ### FIX: Make sure aanvrager validatie werkt, alleen voor interne
        ### aanvraag

        if ($c->req->params->{ztc_aanvrager_id}) {
            $params->{aanvragers} = [{
                'betrokkene'        => $params->{aanvrager_id},
                'verificatie'       => (
                    (
                        $c->session->{_zaak_create}->{aangevraagd_via} eq
                            ZAAKSYSTEEM_CONTACTKANAAL_WEBFORM
                    )
                        ? $c->session->{_zaak_create}->{extern}->{verified}
                        : 'medewerker'
                )
            }];
        } elsif (
            $c->session->{_zaak_create}->{aanvrager_update} &&
            $c->session->{_zaak_create}->{aanvrager_update}->{create} &&
            $c->session->{_zaak_create}->{extern}->{verified}
        ) {
            $params->{aanvragers} = [{
                'create'            =>
                    $c->session->{_zaak_create}->{aanvrager_update},
                'betrokkene_type'   =>
                    $c->session->{_zaak_create}->{extern}->{aanvrager_type},
                'verificatie'       =>
                        $c->session->{_zaak_create}->{extern}->{verified},
            }];

            $c->session->{_zaak_create}->{aanvragers} =
                $params->{aanvragers};

        } elsif ($c->session->{_zaak_create}->{aanvrager_update}) {
            ### XXXX !!!!!!DUMMY!!!!!!
            $params->{aanvragers} = [{
                'betrokkene'        => 'betrokkene-dummy-99999',
                'verificatie'       => (
                    (
                        $c->session->{_zaak_create}->{aangevraagd_via} eq
                            ZAAKSYSTEEM_CONTACTKANAAL_WEBFORM
                    )
                        ? $c->session->{_zaak_create}->{extern}->{verified}
                        : 'medewerker'
                )
            }];
        }

    }

    sub _create_validation_acties : Private {
        my ($self, $c, $params) = @_;

        ### If doc_intake session, check for extra parameters
        if (
            $c->req->params->{doc_intake_update} &&
            $c->session->{_zaak_create}->{acties}->{doc_intake}
        ) {
            $c->session->{_zaak_create}->{acties}->{doc_intake}->{document_category}
                    = $c->req->params->{intake_document_category};

            $c->session->{_zaak_create}->{acties}->{doc_intake}->{document_catalogus}
                    = $c->req->params->{intake_document_catalogus};

            $c->session->{_zaak_create}->{acties}->{doc_intake}->{document_help}
                    = $c->req->params->{intake_document_help};
        }


        ### Fill from params
        if ($c->req->params->{actie}) {
            $c->session->{_zaak_create}->{acties} = {};

            $c->session->{_zaak_create}->{acties}->{
                $c->req->params->{actie}
            } = {
                    component       => $c->req->params->{actie},
                    onderwerp       => $c->req->params->{actie_description},
                    component_id    => $c->req->params->{actie_value},
            };
        }
    }

    my $_create_validation_deprecation_map = {
        ztc_trigger         => 'aanvraag_trigger',
        betrokkene_type     => 'betrokkene_type',
        zaaktype            => 'zaaktype_node_id',
        ztc_aanvrager_id    => 'aanvrager_id',
        ztc_contactkanaal   => 'contactkanaal'
    };

    sub _create_validation : Private {
        my ($self, $c)  = @_;
        my $params      = {};

        ### Keys to validate?
        if (scalar(keys( %{ $c->req->params }))) {
            $params        = { %{ $c->req->params } };

            ### Translation
            for my $key (keys %{ $_create_validation_deprecation_map }) {
                $params->{ $_create_validation_deprecation_map->{ $key } }
                    = $params->{$key};

                delete($params->{$key});
            }
        }

        $c->forward('_create_validation_aanvragers', [ $params ]);
        $c->forward('_create_validation_acties', [ $params ]);

        ### Merge session data into params:
        $params->{ $_ } = $c->session->{_zaak_create}->{ $_ }
            for keys %{ $c->session->{_zaak_create} };

        ### Fix registratiedatum
        $params->{registratiedatum} = DateTime->now()
            unless $params->{registratiedatum};

        my $dv          = Params::Profile->check(
            params  => $params,
            method  => 'Zaaksysteem::Controller::Zaak::create'
        );

        my $validated_options   = $dv->valid;

        ### Depending on xml request (do_validation) or create, we detach
        if (
            $c->req->header("x-requested-with") &&
            $c->req->header("x-requested-with") eq 'XMLHttpRequest' &&
            $c->req->params->{do_validation} &&
            $c->req->params->{create_entry}
        ) {
            $c->zvalidate($dv);
            $c->detach;
        }

        ### Because we need extra variabled in session, we loop
        ### over the params keys.
        for my $key (keys %{ $validated_options }) {
            $c->session->{_zaak_create}->{ $key } =
            $validated_options->{ $key }
        }

        ###
        ### Betrokkenen
        ###
        for (qw/npc-email npc-telefoonnummer npc-mobiel/) {
            next unless $params->{$_};

            $c->session->{_zaak_create}->{$_} = $params->{$_};
        }

        ### Plugin structure
        my $reqparams  = $c->req->params;

        ### Plugins
        if ($reqparams->{plugin}) {
            foreach my $controller ($c->controllers) {
                next unless (
                    $controller eq
                        'Plugins::' .  ucfirst($reqparams->{plugin})
                        &&
                    $c->controller($controller)->can('prepare_zaak_create')
                );

                $c->log->debug(
                    'Z:C:Zaak->create[prepare_zaak_create]: Running plugin: '
                    .  ucfirst($params->{plugin})
                );

                $c->controller($controller)->prepare_zaak_create($c, $reqparams);
            }
        }


        ### Add kenmerken
        $c->session->{_zaak_create}->{raw_kenmerken}
            = $c->session->{_zaak_create}->{form}->{kenmerken};
    }

    sub _create_verify_security : Private {
        my ($self, $c) = @_;

        $c->forward('_create_verify_security_how_we_got_here');

        if ($c->is_externe_aanvraag) {
            $c->forward('_create_verify_externe_aanvraag');
        }
    }

    sub _create_verify_externe_aanvraag : Private {
        my ($self, $c) = @_;


    }

    sub _create_verify_security_how_we_got_here : Private {
        my ($self, $c) = @_;

        ### Aangevraagd via correct
        {
            unless (
                grep (
                    { $c->session->{_zaak_create}->{aangevraagd_via} eq $_ }
                    ZAAKSYSTEEM_CONTACTKANAAL_WEBFORM,
                    ZAAKSYSTEEM_CONTACTKANAAL_BALIE
                )
            ) {
                $c->log->error('Aangevraagd_via not one of: ' .
                    join (',',
                        ZAAKSYSTEEM_CONTACTKANAAL_WEBFORM,
                        ZAAKSYSTEEM_CONTACTKANAAL_BALIE
                    )
                );
                $c->detach;
            }

            unless (
                (
                    $c->session->{_zaak_create}->{aangevraagd_via} eq
                        ZAAKSYSTEEM_CONTACTKANAAL_WEBFORM &&
                    !$c->user_exists
                ) ||
                (
                    $c->session->{_zaak_create}->{aangevraagd_via} ne
                        ZAAKSYSTEEM_CONTACTKANAAL_WEBFORM &&
                    $c->user_exists
                )
            ) {
                $c->log->error(
                    $c->session->{_zaak_create}->{aangevraagd_via}
                    . ' aanvraag niet via logged in user, impossible.'
                );
                $c->detach;
            }

            if ($c->is_externe_aanvraag) {
                $c->session->{_zaak_create}->{aangevraagd_via} =
                    $c->session->{_zaak_create}->{contactkanaal} =
                        ZAAKSYSTEEM_CONTACTKANAAL_WEBFORM;
            }
        }
    }
}




sub _add_regel_sjablonen {
    my ($self, $c) = @_;

    # sjablonen gegenereerd nav een regel
    my $regel_sjablonen = $c->session->{regel_sjablonen};
    foreach my $sjabloon_id (@$regel_sjablonen) {
        my $sjabloon = $c->model('DB::ZaaktypeSjablonen')->find($sjabloon_id);
        my $args = {
            documenttype             => 'sjabloon',
            filename                 => $sjabloon->bibliotheek_sjablonen_id->naam . '.odt',
            actie_rename_when_exists => 0,
            sjabloon_id              => $sjabloon->bibliotheek_sjablonen_id->id,
            zaak_id                  => $c->stash->{zaak}->id,
            zaakstatus               => $c->stash->{zaak}->milestone,
        };

        $self->_create_zaak_genereer_sjabloon($c, $args);
    }
    $c->session->{regel_sjablonen} = [];
}


sub _create_zaak_genereer_sjabloon : Private {
    my ($self, $c, $args) = @_;

    if ($c->user_exists) {
        $args->{betrokkene_id} = 'betrokkene-medewerker-'
            . $c->user->uidnumber;
    } else {
        $args->{betrokkene_id} =
            $c->stash->{zaak}->aanvrager_object->betrokkene_identifier;
    }
    
#    $c->log->debug('_create_zaak_genereer_sjabloon: ' . Dumper $args);

    my $document = $c->model('Documents')->add(
        $args,
    );
}




sub _spiffy_spinner : Private {
    my ($self, $c, $definition) = @_;

    return 1 unless (
        $c->req->header("x-requested-with") &&
        $c->req->header("x-requested-with") eq 'XMLHttpRequest' &&
        $c->req->params->{spiffy_spinner}
    );

    $c->stash->{json} = {
        'spinner'    => $definition,
    };
    $c->forward('Zaaksysteem::View::JSON');
    $c->detach;
}



sub duplicate : Local {
    my ($self, $c, $zaakid) = @_;

    unless ($c->req->param('confirmed')) {

		$c->stash->{confirmation}->{message}    =
			'Weet u zeker dat u deze zaak met zaaknummer '
		   . $zaakid .  ' wilt kopieren?';
	
		$c->stash->{confirmation}->{type}       = 'yesno';
		$c->stash->{confirmation}->{uri}        =
			$c->uri_for(
				'/zaak/duplicate/' . $zaakid
			);
	
		$c->forward('/page/confirmation');

	} else {
        my $zaak = $c->model('DB::Zaak')->duplicate(
            $zaakid,
            {
                simpel  => 1
            }
        );

        if (!$zaak) {
            $c->flash->{result} =
                'ERROR: Helaas kon de zaak niet worden '
                .'gedupliceerd';

            $c->response->redirect($c->req->referer);
            $c->detach;
        }

        $c->flash->{result} = 'Zaak ' . $zaakid . ' succesvol gekopieerd';
        $c->response->redirect('/zaak/' . $zaak->nr . '#zaak-elements-case');
    }
	$c->detach;
}



sub meta_info : Chained('/'): PathPart('zaak/get_meta'): Args(1) {
    my ($self, $c, $id) = @_;

    return unless $id =~ /^\d+$/;

    ### Retrieve zaak
    $c->stash->{nowrapper} = 1;
    $c->stash->{'zaak'} = $c->model('DB::Zaak')->find($id);

    $c->stash->{template} = 'zaak/metainfo.tt';
}



sub start_nieuwe_zaak : Chained('/'): PathPart('zaak/start_nieuwe_zaak'): Args(1) {
    my ($self, $c, $zaaktype_node_id) = @_;

    my $zaaktype_node_rs = $c->model('DB::ZaaktypeNode')->search({
        'id' => $zaaktype_node_id,
    });
    my $zaaktype_node = $zaaktype_node_rs->single;

    my $new_params = {
        'create'            => '1',
        'create_entry'      => '1',
        'sessreset'         => 1,
        'zaaktype_id'       => $zaaktype_node->zaaktype_id->id,
        'zaaktype_name'     => $zaaktype_node->titel,
        'ztc_contactkanaal' => $c->session->{_zaak_create}->{contactkanaal},
        'jstrigger'         => $c->session->{_zaak_create}->{aanvraag_trigger},
        'ztc_trigger'       => $c->session->{_zaak_create}->{aanvraag_trigger},
        'ztc_aanvrager_id'  => $c->session->{_zaak_create}->{aanvragers}->[0]->{betrokkene},
        'betrokkene_type'   => $c->session->{_zaak_create}->{aanvragers}->[0]->{verificatie},
    };

    my $contactkanaal = $c->session->{_zaak_create}->{contactkanaal};

    $c->res->redirect($c->uri_for('/zaak/create/' . $contactkanaal, $new_params));
    $c->detach;
}




sub _execute_regels : Private {
    my ($self, $c) = @_;

    my $status = $c->stash->{requested_fase}->status;

    my $regels = $c->model('Regels');
    $regels->_execute_regels(
        $c, 
        $c->stash->{zaak}->zaaktype_node_id->id, 
        $status,
        $c->stash->{zaak}->zaak_kenmerken->search_all_kenmerken({ fase => $status })
    );
}

sub update : Chained('base'): PathPart('update'): Args(0) {
    my ($self, $c) = @_;

    if (
        $c->req->header("x-requested-with") &&
        $c->req->header("x-requested-with") eq 'XMLHttpRequest'
    ) {
        $c->stash->{template} = 'zaak/elements/view_kenmerken.tt';
    }

    if (
        defined($c->req->params->{system_kenmerk_resultaat}) &&
        $c->can_change({ ignore_afgehandeld => 1 })
    ) {
        $c->stash->{zaak}->resultaat(
            $c->req->params->{system_kenmerk_resultaat}
        );
        $c->stash->{zaak}->update;
    }

    unless ($c->can_change) {
        $c->model('Bibliotheek::Sjablonen')->touch_zaak($c->stash->{zaak});
        $c->forward('_execute_regels');
        $c->response->redirect('/zaak/' . $c->stash->{zaak}->nr.'/?fase='.$c->req->params->{fase});
        $c->detach;
    }


    my $params  = $c->req->params;
    my $fase    = $c->stash->{requested_fase}->status;


    # Get the newly submitted values    
    my $new_values = {};
    foreach my $key (keys %$params) {
        if($key =~ m/^kenmerk_id_(\d+)$/) {
            my $bibliotheek_kenmerken_id = $1;
            my $values = $params->{$key};
            $values = UNIVERSAL::isa($values, 'ARRAY') ? $values : [$values];
            $new_values->{$bibliotheek_kenmerken_id} = $values;

            # Afhandelen van bestanden die eventueel worden mee ge-upload
            if ($c->req->upload($key)) {
                my $upload_params = {
                    uploads => {
                        $bibliotheek_kenmerken_id => {'upload' => $c->req->upload($key)}
                    }
                };

                $self->_create_zaak_handle_uploads($c, $upload_params);
            }
        }
    }
    $c->log->debug("new_values: " . Dumper $new_values);

    # Get all bibliotheek_kenmerken_ids and matching values
    # that need updating from the zaaktype_kenmerken
    my $zaaktype_kenmerken = $c->stash->{zaak}
        ->zaaktype_node_id
        ->zaaktype_kenmerken
        ->search({ 
            'zaak_status_id.status' => $fase 
        },
        { 
            join => ['bibliotheek_kenmerken_id', 'zaak_status_id']
        });


    # Loop through the kenmerken for this fase
    while(my $zaaktype_kenmerk = $zaaktype_kenmerken->next) {

        next unless($zaaktype_kenmerk->bibliotheek_kenmerken_id);

        my $value_type                  = $zaaktype_kenmerk->type;
        my $bibliotheek_kenmerken_id    = $zaaktype_kenmerk->bibliotheek_kenmerken_id->id;

        next if($value_type eq 'file');
        next if($zaaktype_kenmerk->is_group());
        
        #$c->log->debug("bibliotheek_kenmerken_id: $bibliotheek_kenmerken_id, zaak_id: " . $c->stash->{zaak}->id);

# TODO check
#         unless (defined(my $value = $self->_update_verify_value(
#             $c, 
#             $bibliotheek_kenmerken_id, 
#             $new_values->{bibliotheek_kenmerken_id}))) {
#             next;
#         }

        $c->model("DB")->txn_do(sub {
            eval {
                # Remove existing values for this bibliotheek_kenmerken_id
                $c->stash->{zaak}->zaak_kenmerken->search({
                    bibliotheek_kenmerken_id    => $bibliotheek_kenmerken_id, 
                    zaak_id                     => $c->stash->{zaak}->id,
                })->delete;

                if(defined $new_values->{$bibliotheek_kenmerken_id}) {
                    # Re-create this kenmerk with new values
                    $c->stash->{zaak}->zaak_kenmerken->create_kenmerk({
                        zaak_id                     => $c->stash->{zaak}->id,
                        bibliotheek_kenmerken_id    => $bibliotheek_kenmerken_id,
                        values                      => $new_values->{$bibliotheek_kenmerken_id},
                    });
                }
          #      $c->stash->{zaak}->set_value();
            };
        
            if ($@) {
                die("Error in Controller/Zaak.pm: " . $@);
            } 
        });
    }


    $c->model('Bibliotheek::Sjablonen')->touch_zaak($c->stash->{zaak});

    $c->forward('_execute_regels');

    # used for going to the next phase while saving the latest changes
    if(my $redirect = $c->req->param('redirect')) {
        $c->response->redirect($redirect);
        $c->detach;        
    }

    # Redirect naar de juiste page en fase
    # Below is not needed, speeeeed
    #$c->response->redirect('/zaak/' . $c->stash->{zaak}->nr.'/?fase='.$c->req->params->{fase});
    $c->detach;

    return 1;
}


sub _update_verify_value {
    my ($self, $c, $id, $value) = @_;
    my $return_as_scalar    = 0;

    my $dbkenmerk   = $c->model('DB::BibliotheekKenmerken')->find(
        $id
    );

    unless (UNIVERSAL::isa($value, 'ARRAY')) {
        $return_as_scalar++;
        $value  = [ $value ];
    }

    for (my $i = 0; $i < scalar(@{ $value }); $i++) {
        my $valuepart   = $value->[$i];

        if (
            defined(
                ZAAKSYSTEEM_CONSTANTS->{veld_opties}->{
                    $dbkenmerk->value_type
                }->{constraint}
            )
        ) {
            if (
                $valuepart !~
                    ZAAKSYSTEEM_CONSTANTS->{veld_opties}->{
                        $dbkenmerk->value_type
                    }->{constraint}
            ) {
                $c->log->warn('Value with key: ' . $id . ' does not match'
                    . ' constraint defined in veld_opties'
                );
                return;
            }
        }

        if ($dbkenmerk->value_type eq 'valuta') {
            $valuepart =~ s/,/./g;
        }

        $value->[$i] = $valuepart;
    }

    return $value->[0] if $return_as_scalar;
    return $value;
}


sub open : Chained('base'): PathPart('open'): Args(0) {
    my ($self, $c) = @_;

    $c->assert_any_zaak_permission('zaak_edit');
    #$c->assert_user_role(qw/behandelaar/);

    $c->stash->{zaak}->open_zaak;

    $c->flash->{result} = 'Zaak is door u in behandeling genomen';

    $c->model('Bibliotheek::Sjablonen')->touch_zaak($c->stash->{zaak});

    $c->response->redirect('/zaak/' . $c->stash->{zaak}->nr);
    $c->detach;
}





sub view : Chained('base'): PathPart(''): Args(0) {
    my ($self, $c) = @_;

    if ($c->stash->{zaak}->status eq 'deleted') {
        $c->flash->{'result'} = 'Zaak "' . $c->stash->{zaak}->id . '" is vernietigd';
        $c->response->redirect($c->uri_for('/'));
        $c->detach;
    }

    $c->stash->{page_title} = 'Zaak :: ' . $c->stash->{zaak}->id;

    ### TODO FROM HERE
#    if ($c->stash->{zaak}->zaakstatus->is_afgehandeld) {
#        $c->flash->{result} = 'Deze zaak is afgehandeld. Extra wijzigingen zijn niet meer mogelijk';
#    }

    ### Find fase
    {
        my $fase = $c->req->params->{fase} || '';
        if ($fase =~ /^\d+$/) {
            my $fases = $c->stash->{zaak}->fasen->search(
                {
                    status  => $fase
                }
            );

            $c->stash->{requested_fase} = $fases->first if $fases->count;
        }
    }

    #### XXX TODO overleden aanvrager
    if (
        $c->stash->{zaak}->aanvrager_object &&
        $c->stash->{zaak}->aanvrager_object->is_overleden
    ) {
        $c->flash->{'result'} = 'WAARSCHUWING: Aanvrager van deze zaak is'
            . ' overleden (' .
            $c->stash->{zaak}->aanvrager_object->gm_extern_np->datum_overlijden->dmy
            . ')';
    }
}

{
    my $ELEMENT_MAP = {
        'zaak-elements-notes'       =>
            'zaak/elements/notes.tt',
        'zaak-elements-betrokkenen' =>
            'zaak/elements/betrokkenen.tt',
        'zaak-elements-status'      =>
            'zaak/elements/status.tt',
        'load_algemene_zaakinformatie'      =>
            'zaak/elements/view_algemene_zaakinformatie.tt',
        'load_element_maps'      =>
            'zaak/elements/view_maps.tt',
    };

    sub view_element : Chained('base'): PathPart('view_element'): Args(1) {
        my ($self, $c, $element) = @_;

        unless ($ELEMENT_MAP->{$element}) {
            $c->res->redirect($c->uri_for(
                '/zaak/' . $c->stash->{zaak}->nr
            ));

            $c->detach;
        }

        $c->stash->{nowrapper}  = 1;
        $c->stash->{template}   = $ELEMENT_MAP->{$element};
    }
}


sub dashboard : Chained('/'): PathPart('zaak/dashboard'): Args(0) {
    my ($self, $c)  = @_;

    #my $myself      = $c->user_betrokkene;
    $c->user_roles_ids;
}



#
# home page, forwarded from Controller/Root.pm
#
sub list : Chained('/'): PathPart('zaak/list'): Args(0) {
    my ($self, $c) = @_;

	my $params = $c->req->params();
#	$c->log->debug('Params: ' . Dumper $params);
    my $view = $c->req->params->{view};

    unless ($c->req->params->{order}) {
        $c->stash->{order} = 'last_modified';
        $c->stash->{order_direction} = 'DESC';
    }


    ### Default descending (because order is by id)
    $c->stash->{order_direction} = 'DESC' unless
        ($c->stash->{order_direction} || $c->stash->{order});

    $c->stash->{paging_rows} = 5;

    $c->stash->{'show_more_search_queries'} = 1;
    $c->forward('/search/dashboard');
    ### Retrieve a list of zaken
    $c->stash->{'template'} = 'zaak/list.tt';


## zaken openstaand
    my $zaken_openstaand_resultset = $c->model('Zaken')->openstaande_zaken({ 
    	page        => ($params->{'page'} || 1), 
    	rows        => 5,
    	uidnumber   => $c->user->uidnumber,
        'sort_direction'        => $c->req->params->{sort_direction},
        'sort_field'            => $c->req->params->{sort_field},
    })->with_progress();

	# use the central filter code to handle the dropdown and textfilter limiting filter options    
    $zaken_openstaand_resultset = $c->model('Zaken')->filter({
    	resultset 	=> $zaken_openstaand_resultset,
    	textfilter  => $params->{'openstaand_textfilter'},
    });

    $c->stash->{'zaken_openstaand'} = $zaken_openstaand_resultset; 



### zaken intake
     my $zaken_intake_resultset = $c->model('Zaken')->intake_zaken({ 
     	page => ($params->{'page'} || 1), 
     	rows => 5 ,
    	user_roles_ids => [$c->user_roles_ids],
        user_ou_id     => $c->user_ou_id,
        user_roles     => [$c->user_roles],
    	uidnumber      => $c->user->uidnumber,
        'sort_direction'        => $c->req->params->{sort_direction},
        'sort_field'            => $c->req->params->{sort_field},
     })->with_progress();

	# use the central filter code to handle the dropdown and textfilter limiting filter options    
    $zaken_intake_resultset = $c->model('Zaken')->filter({
    	resultset 	   => $zaken_intake_resultset,
    	textfilter     => $params->{'intake_textfilter'},
    });

    $c->stash->{'zaken_intake'} = $zaken_intake_resultset; 




	# get the default zaak search output structure from the SearchQuery object    
    my $search_query = $c->model('SearchQuery');
    $c->stash->{'display_fields'} = $search_query->get_display_fields();	

    $c->stash->{ $_ }     = $c->req->params->{ $_ }
            for qw/sort_direction sort_field/;
}


my $FILTER_MAP = {
    'new'       => ' AND Status="new"',
    'open'      => ' AND Status="open"',
    'stalled'   => ' AND Status="stalled"',
    'resolved'  => ' AND Status="resolved"',
    'urgent'    => 1,
};
sub own : Chained('/'): PathPart('zaak/list/own'): Args(0) {
    my ($self, $c) = @_;

	my $params = $c->req->params();
#	$c->log->debug("Params: " . Dumper $params);
	
    my $view    = $c->req->params->{view} || '';

#    my $sql = {
#        'own'   => $self->_get_query_for_zaken($c)
#    };

	my $where = {'me.deleted' => undef};

	my $betrokkenen = $c->model('DB::ZaakBetrokkenen')->search({
		'gegevens_magazijn_id' => $c->user->uidnumber,		
	});

	$where->{'behandelaar'} = {-in => $betrokkenen->get_column('id')->as_query};

    my $sort_field = $params->{'sort_field'} || 'me.id';
    $c->stash->{'sort_field'} = $sort_field;
    
    my $sort_direction = $params->{'sort_direction'} || 'DESC';
    $c->stash->{'sort_direction'} = $sort_direction;
    my $order_by = { '-' . $sort_direction => $sort_field};

    $where->{'me.status'} = $c->req->params->{statusfilter} if
        $c->req->params->{statusfilter};
 

    ### Asked for a search view?
#    if (
#        $view || (
#            $c->session->{search_query}->{raw_sql} &&
#            $c->req->params->{paging_page}
#        )
#    ) {
#        $c->session->{search_query}->{raw_sql} = $sql->{own};
#        $c->forward('/search/load_search_results');
#        $c->detach;
#    }

    ### Default descending (because order is by id)
    $c->stash->{order_direction} = 'DESC' unless
        ($c->stash->{order_direction} || $c->stash->{order});


	my $ROWS_PER_PAGE = 10;
	my $page = $params->{'page'} || 1;

    $where->{'me.deleted'} = undef;

    
    my $resultset = $c->model('DB::Zaak')->search_extended($where, {
    	page     => $page,
    	rows	 => $ROWS_PER_PAGE,
    	order_by => $order_by,
    })->with_progress();

	# use the central filter code to handle the dropdown and textfilter limiting filter options    
    $resultset = $c->model('Zaken')->filter({
    	resultset 	=> $resultset,
    	dropdown    => $params->{'filter'}, 
    	textfilter  => $params->{'textfilter'},
    });

    $c->stash->{'results'} = $resultset;   

	# get the default zaak search output structure from the SearchQuery object    
    my $search_query = $c->model('SearchQuery');
    $c->stash->{'display_fields'} = $search_query->get_display_fields();	
    $c->stash->{'template'} = 'zaak/own.tt';
}


sub eenheid : Chained('/'): PathPart('zaak/list/eenheid'): Args() {
    my ($self, $c, $filter) = @_;

	my $params = $c->req->params();
    my $view    = $c->req->params->{view};


    my $sort_field = $params->{'sort_field'} || 'me.id';
    $c->stash->{'sort_field'} = $sort_field;
    
    my $sort_direction = $params->{'sort_direction'} || 'DESC';
    $c->stash->{'sort_direction'} = $sort_direction;
    my $order_by = { '-' . $sort_direction => $sort_field};


	my $where = {
		'route_ou' => $c->user_ou_id,
	};
    $where->{'me.status'} = $c->req->params->{statusfilter} if
        $c->req->params->{statusfilter};

	my $ROWS_PER_PAGE = 10;
	my $page = $params->{'page'} || 1;

    $where->{'me.deleted'} = undef;

    my $resultset = $c->model('DB::Zaak')->search_extended($where, {
    	page     => $page,
    	rows	 => $ROWS_PER_PAGE,
    	order_by => $order_by,
    })->with_progress();

	# use the central filter code to handle the dropdown and textfilter limiting filter options    
    $resultset = $c->model('Zaken')->filter({
    	resultset 	=> $resultset,
    	dropdown    => $params->{'filter'}, 
    	textfilter  => $params->{'textfilter'},
    });

    $c->stash->{'results'} = $resultset;   

	# get the default zaak search output structure from the SearchQuery object    
    my $search_query = $c->model('SearchQuery');
    $c->stash->{'display_fields'} = $search_query->get_display_fields();
    $c->stash->{'template'} = 'zaak/eenheid.tt';
}


sub change_filename : Chained('/'): PathPart('zaak/intake/changefilename'): Args(0) {
    my ($self, $c) = @_;

    my $params = $c->req->params();
#    $c->log->debug("Params: " . Dumper $params);
    
    my $old_filename = $params->{'old_filename'};
    my $new_filename = $params->{'new_filename'};
   
    my $old_record = $c->model('DB::DroppedDocuments')->find({'filename'=> $old_filename});
    if(!$old_record) {
        $self->_change_filename_response($c, 0, 'Bestand niet gevonden');
    }

    $old_record->filename($new_filename);
    $old_record->update;
    
    $self->_change_filename_response($c, 1, '');
}

sub _change_filename_response {
    my ($self, $c, $result, $message) = @_;

    $c->stash->{json} = {
        'result'    => $result,
        'message'   => $message,
    };
    $c->forward('Zaaksysteem::View::JSON');
    $c->detach;
}


sub intake : Chained('/'): PathPart('zaak/intake'): Args(0) {
    my ($self, $c) = @_;

    my $view    = $c->req->params->{view};

    $c->stash->{'template'} = 'zaak/intake.tt';

    my $bid     = $c->user->uidnumber;

    my $ou_id   = $c->user_ou_id;

    $c->stash->{'dropped_documents'} = $c->model('DB::DroppedDocuments')->search(
        {
            'betrokkene_id' => [
                undef,
                'betrokkene-org_eenheid-' . $ou_id,
                'betrokkene-medewerker-' . $bid,
            ],
        },
        {
            order_by    => 'filename',
        }
    );
}


sub preview : Chained('/'): PathPart('zaak/documentpreview'): Args(0) {
    my ($self, $c) = @_;

    my $params = $c->req->params();
#    $c->log->debug("Params: " . Dumper $params);

    my $document_id = $c->stash->{'document_id'} = $params->{'document_id'};   


    # check if an up-to-date thumbnail is available. this can be done by comparing the filedate for
    # the thumbnail to the last modified date for the original file
    my $document = $c->model('DB::DroppedDocuments')->find($document_id);
    my $filedir = '/drops/';

    unless($document) {
        $document = $c->model('DB::Documents')->find($document_id);
        $filedir = '/documents/';
    }

    if($document) {
        my $source_last_modified = $document->last_modified;
        
        my $thumbnail_filename = $c->config->{'files'} . '/thumbnails/' . $document_id . '.jpg';
#       $c->log->debug('thumbnail_filename: ' . $thumbnail_filename);
    
    
        my $thumbnail_last_modified;
        if(-e $thumbnail_filename) {
            $thumbnail_last_modified = DateTime->from_epoch(epoch => stat($thumbnail_filename)->mtime);        
#            $c->log->debug('source_last_modified: ' . $source_last_modified. ', thumbnail_last_modified: ' . $thumbnail_last_modified);
        }
    
        # if not up-to-date (or not existing) generate a thumbnail
        if(!-e $thumbnail_filename || $source_last_modified > $thumbnail_last_modified) {
            $self->_generate_thumbnail($c, $document_id, $document, $filedir);
        }
    } else {
        $c->stash->{'no_image'} = 1;
    }

    $c->stash->{nowrapper} = 1;
    $c->stash->{'template'} = 'zaak/documentpreview.tt';
}


sub preview_image : Chained('/'): PathPart('zaak/documentpreview'): Args() {
    my ($self, $c, $document_id) = @_;
    
    my $filename = $c->config->{'files'} . '/thumbnails/' . $document_id . '.jpg';
    $c->serve_static_file($filename);

    my $stat = stat($filename);
    $c->res->headers->content_length( $stat->size );
    $c->res->headers->content_type('image/jpeg');
    $c->res->content_type('image/jpeg');
}


sub _generate_thumbnail {
    my ($self, $c, $document_id, $document, $filedir) = @_;
    

#    $c->log->debug('document: ' . $document->filename);
#	$c->log->debug('jodconvertor lookup');
    
    my $working_dir = `pwd`;
    chomp $working_dir;

    my $filename = $c->config->{'files'} . $filedir . $document_id;
    my $pdf_filename = $c->config->{'files'} . '/thumbnails/' . $document_id . '.pdf'; 

    if($document->mimetype eq 'image/jpeg') {
        # no need to do anything pdf related, just use the jpg directly.       
    }
    elsif($document->mimetype eq 'application/pdf') {
        # don't have to convert pdf to pdf, just copy it to the thumbnail dir
        system("cp $filename $pdf_filename");
    } else {
        CORE::open FILE, $filename or die "couldnot open file [$filename]: $!";
        my $content = join "", <FILE>;
        close FILE;
    
        use HTTP::Request::Common;
        my $ua = LWP::UserAgent->new;
        my $result = $ua->request(POST 'http://localhost:8080/converter/service', 
            Content => $content,
            Content_Type => $document->mimetype,
            Accept => 'application/pdf',
        );
    
    
        my $pdf_content = $result->content();
        CORE::open FILE2, '>' . $pdf_filename or die "could not open file: $!";
        print FILE2 $pdf_content;
        close FILE2;
    }
#	$c->log->debug('magick conversion');
	
	use Image::Magick;
	my $magick = new Image::Magick();
	
	my $magick_input_filename = $pdf_filename.'[0]';  # get first page only
	if($document->mimetype eq 'image/jpeg') {
	    $magick_input_filename = $filename;
	}
    my $status = $magick->Read($magick_input_filename);
    $c->log->debug( "Read failed: $status" ) if $status; 

    $magick->Resize(geometry => '200x');
    $c->log->debug( "Resize failed: $status" ) if $status; 

    my $jpg_filename = $c->config->{'files'} . '/thumbnails/' . $document_id . '.jpg'; 

    $status = $magick->Write($jpg_filename); 
    $c->log->debug( "Write failed: $status") if $status;

	$c->log->debug('finito');

    # clean up pdf.
    system("rm $pdf_filename");
}


sub zaaktypeinfo : Chained('base'): PathPart('zaaktypeinfo'): Args(0) {
    my ($self, $c) = @_;

    $c->stash->{nowrapper} = 1;
    $c->stash->{template} = 'zaak/zaaktypeinfo.tt'
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

