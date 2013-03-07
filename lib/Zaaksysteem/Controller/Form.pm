package Zaaksysteem::Controller::Form;

use strict;
use warnings;

use HTML::TagFilter;
use HTML::Entities;
use JSON;


use Data::Dumper;
use parent 'Catalyst::Controller';

use Zaaksysteem::Constants;




sub form : Chained('/'): PathPart('form'): Args(0) {
    my ($self, $c) = @_;
    $c->detach('list');
}

sub form_with_id : Chained('/'): PathPart('form'): Args() {
    my ($self, $c, $id) = @_;

    $c->res->redirect(
        $c->uri_for(
            '/zaak/create/webformulier/',
            {
                zaaktype            => $id,
                sessreset           => 1,
                #ztc_aanvrager_type  => $c->req->params->{ztc_aanvrager_type},
                #authenticatie_methode => $c->req->params->{authenticatie_methode},
            }
        )
    );

    $c->detach;
}


sub cancel : Local {
    my ($self, $c) = @_;

    delete($c->session->{_zaak_create});

    $c->res->redirect($c->config->{gemeente}->{gemeente_portal});
    $c->detach;
}


sub form_by_zaaktype_afronden : Chained('/') : PathPart('aanvraag'): Args(3) {
    my ($self, $c, $zaaktype_naam, $type_aanvrager, $afronden) = @_;

    $c->stash->{afronden} = $afronden;

    $c->forward('form_by_zaaktype', [$zaaktype_naam, $type_aanvrager]);
}




sub form_by_zaaktype : Chained('/') : PathPart('aanvraag'): Args(2) {
    my ($self, $c, $zaaktype_naam, $type_aanvrager) = @_;

    my $afronden = $c->stash->{afronden} ? 1 : 0;

    $c->log->info("FORM-FORM_BY_ZAAKTYPE: Doorgekregen variabelen: $zaaktype_naam, $type_aanvrager, $afronden");

    # Ophalen van het zaaktype-id aan de hand van de zaak-naam
    return unless ($type_aanvrager =~ m/^(natuurlijk_persoon|niet_natuurlijk_persoon)$/);

    $zaaktype_naam =~ s/-/ /g;

    my $zaaktype = $c->model('DB::ZaaktypeNode')->search(
        { 'LOWER(me.titel)' => $zaaktype_naam },
        {'order_by' => { -desc => 'id' }, 'rows' => 1}
    );

    if ($type_aanvrager eq 'natuurlijk_persoon') {
        $c->res->redirect($c->uri_for(
            '/zaak/create/webformulier',
            {
                'ztc_aanvrager_type'    => 'natuurlijk_persoon',
                'sessreset'             => '1',
                'authenticatie_methode' => 'digid',
                zaaktype_id           => $zaaktype->first()->zaaktype_id->id,
                'afronden'              => $afronden
            }
        ));
    } else {
        $c->res->redirect($c->uri_for(
            '/zaak/create/webformulier',
            {
                zaaktype_id            => $zaaktype->first()->zaaktype_id->id,
                'ztc_aanvrager_type'    => 'niet_natuurlijk_persoon',
                'sessreset'             => '1',
                'authenticatie_methode' => 'bedrijfid',
                'afronden'              => $afronden
            }
        ));
    }
}


sub list : Private {
    my ($self, $c) = @_;

    $c->stash->{zaaktypen}  = $c->model('DB::Zaaktype')->search(
        {
            'me.deleted'                        => undef,
            'zaaktype_node_id.trigger'          => 'extern',
            'zaaktype_node_id.webform_toegang'  => 1,
        },
        {
            'prefetch'      => 'zaaktype_node_id',
        }
    );

    $c->stash->{template}   = 'form/list.tt';
}


sub aanvrager_type : Private {
    my ($self, $c)          = @_;

    $c->stash->{template}   = 'form/aanvrager_type.tt';
}


sub aanvrager :Private {
    my ($self, $c)      = @_;
    my (%betrokkene_opts, %searchopts, $searchcolumn);

    $c->stash->{template} = 'form/aanvrager.tt';

    if ($c->session->{_zaak_create}->{extern}->{verified} eq 'digid') {
        $searchopts{burgerservicenummer}    = $c->session
            ->{_zaak_create}->{extern}->{id};

        %betrokkene_opts                    = (
            type    => 'natuurlijk_persoon',
            intern  => 0,
        );

        $searchcolumn   = 'gm_natuurlijk_persoon_id';
    } else {
        $searchopts{dossiernummer}    = $c->session
            ->{_zaak_create}->{extern}->{id};
        %betrokkene_opts                    = (
            type    => 'bedrijf',
            intern  => 0,
        );

        $searchcolumn   = 'gm_bedrijf_id';
    }

    my $res = $c->model('Betrokkene')
                    ->search(\%betrokkene_opts, \%searchopts);

    ### LOGGING
    if (
        $c->session->{form}->{authenticatie_methode} eq
        ZAAKSYSTEEM_GM_AUTHENTICATEDBY_DIGID
    ) {
        $c->log->debug('Checking burgerservicenumber: ' .
            $c->model('Plugins::Digid')->uid
        );
    } elsif (
        $c->session->{form}->{authenticatie_methode} eq
            ZAAKSYSTEEM_GM_AUTHENTICATEDBY_BEDRIJFID
    ) {
        $c->log->debug('Checking dossiernummer: ' .
            $c->model('Plugins::Bedrijfid')->login
        );
    }

    $res                    = $res->next if $res;

    ### Aanvrager update AND aanvrager has put in his correct credentials:
    if (
        $c->session->{_zaak_create}->{aanvrager_update} &&
        scalar(keys(%{
            $c->session->{_zaak_create}->{aanvrager_update}
        }))
    ) {
        $c->forward('webform');
    }

    ### person not found? Well...show form, it's impossible
    ### for bedrijven to not be found, they wouldn't have a login
    ### and password anyway.
    $self->_check_mogelijke_aanvragers($c, $res);

    if (
        !$res ||
        (
            $res->btype eq 'natuurlijk_persoon' &&
            !$res->authenticated && $res->authenticated_by ne
                ZAAKSYSTEEM_GM_AUTHENTICATEDBY_DIGID
        )
    ) {
        $c->stash->{aanvrager_edit} = 1;
        $c->stash->{aanvrager_bsn}  = $c->session
            ->{_zaak_create}->{extern}->{id};

        ### Mark as editable aanvrager
        $c->session->{_zaak_create}->{aanvrager_update} = {};

        $c->detach;
    }

    $c->stash->{aanvrager}  = $res;

    ### Set ztc_aanvrager_id
    $c->session->{_zaak_create}->{ztc_aanvrager_id} =
        $res->betrokkene_identifier;

    ### Zoek laatste zaak
    #$c->model('DB::Zaak')->search({
    #    'betrokkene.betrokkene_id'  => 
    if ($c->req->params->{aanvrager_update}) {
        $c->forward('zaakcontrole');
    }
}

sub _check_mogelijke_aanvragers {
    my $self                = shift;
    my $c                   = shift;
    my $res                 = shift;

    $c->log->debug('Welke type aanvragers mogen dit zaaktype aanvragen:'
        . Dumper($c->stash->{type_aanvragers})
    );

    my $ztc_aanvrager_type  = $c->stash->{aanvrager_type};

    if ($ztc_aanvrager_type =~ /^natuurlijk_persoon/) {
        $self->_check_mogelijke_aanvragers_personen($c, $res);
    } else {
        $self->_check_mogelijke_aanvragers_bedrijven($c, $res);
    }
}

sub _check_mogelijke_aanvragers_bedrijven {
    my $self                = shift;
    my $c                   = shift;
    my $res                 = shift;

    if (
        (
            !$res ||
            !$res->authenticated
        ) &&
        !grep(
         /^niet_natuurlijk_persoon_na$/,
         @{ $c->stash->{type_aanvragers} }
        )
    ) {
        $c->log->debug('U bent niet gevonden in onze KVK. Deze aanvraag is niet op u van toepassing.');
        $c->stash->{template} = 'form/aanvraag_nvt.tt';
        $c->detach;
    }

    if (
        (
         $res &&
         $res->authenticated
        ) &&
        !grep(
         /^niet_natuurlijk_persoon$/,
         @{ $c->stash->{type_aanvragers} }
        )
    ) {
        $c->log->debug('U bent gevonden in de KVK binnen de gemeente. Deze aanvraag is
            alleen van toepassing op bedrijven buiten onze gemeente.');
        $c->stash->{template} = 'form/aanvraag_nvt.tt';
        $c->detach;
    }
}

sub _check_mogelijke_aanvragers_personen {
    my $self                = shift;
    my $c                   = shift;
    my $res                 = shift;

    if (
        (
            !$res ||
            !$res->authenticated
        ) &&
        !grep(
         /^natuurlijk_persoon_na$/,
         @{ $c->stash->{type_aanvragers} }
        )
    ) {
        $c->log->debug('U bent geen inwoner van de gemeente. Deze aanvraag is niet op u van toepassing.');
        $c->stash->{template} = 'form/aanvraag_nvt.tt';
        $c->detach;
    }

    if (
        (
         $res &&
         $res->authenticated
        ) &&
        !grep(
         /^natuurlijk_persoon$/,
         @{ $c->stash->{type_aanvragers} }
        )
    ) {
        $c->log->debug('U bent inwoner van de gemeente. Deze aanvraag is
            alleen van toepassing op personen buiten de gemeente.');
        $c->stash->{template} = 'form/aanvraag_nvt.tt';
        $c->detach;
    }
}



sub _afronden_get_zaak {
    my ($self, $c) = @_;

    my $json             = new JSON;
    my $betrokkene       = $c->session->{_zaak_create}->{ztc_aanvrager_id};
    my $zaak_create      = $c->session->{_zaak_create};

    my ($zaaktype_id);

    if ($zaak_create->{'zaaktype_id'}) {
        my $zaaktype    = $c->model('DB::Zaaktype')->find($zaak_create->{'zaaktype_id'}) or return;

        $zaaktype_id    = $zaaktype->id;
    } elsif ($zaak_create->{'zaaktype_node_id'}) {
        my $zaaktype_node = $c->model('DB::ZaaktypeNode')->find($zaak_create->{'zaaktype_node_id'}) or return;

        return unless $zaaktype_node->zaaktype_id;

        $zaaktype_id    = $zaaktype_node->zaaktype_id->id;
    }

    # Check of de klant een onafgeronde zaak heeft staan
    my $onafgeronde_zaak = $c->model('DB::ZaakOnafgerond')->find($zaaktype_id, $betrokkene);

    return $onafgeronde_zaak;
}


sub _afronden_zaak {
    my ($self, $c) = @_;

    # Check of de sessie op afronden staat
    if ($c->session->{afronden}) {
        my $json             = new JSON;
        my $onafgeronde_zaak = $self->_afronden_get_zaak($c) or return;

        # In geval er een zaak is gevonden die nog niet is afgerond dan wordt de data er van gezet
        if ($onafgeronde_zaak) {
            $c->session->{_zaak_create} = $json->decode($onafgeronde_zaak->json_string);
            $c->stash->{'afronden_goto_step'} = $c->session->{_zaak_create}->{'afronden_goto_step'};
        }

        # Omdat we alleen maar eenmaal deze stap willen zetten we de sessie-afronden op false
        $c->session->{afronden} = 0;
    }

    # In alle gevallen zet onafgeronde zaak op true zodat nieuwe data van de zaak weer wordt opgeslagen in een niet afgeronde zaak
    $c->session->{afronden_gezet} = 1;
}


sub zaakcontrole : Private {
    my ($self, $c) = @_;

    ### Geen controle bij aanvrager onbekend
    $c->detach('webform') unless $c->stash->{aanvrager};

    # Check of de sessie op afronden staat
    $c->detach('webform') if ($c->session->{afronden});

    ### Of geen zaakcontrole
    $c->detach('webform') unless $c->stash->{zaaktype}->aanvrager_hergebruik;

    ### Check zaken
    my $zaken   = $c->model('DB::Zaak')->search(
        {
            'me.aanvrager_gm_id'                    => $c->stash->{aanvrager}->ex_id,
            'me.zaaktype_id'                        => $c->stash->{zaaktype}->zaaktype_id->id
        },
        {
            order_by    => { -desc => 'me.id' },
            rows        => 1,
        }
    );

    unless ($zaken->count) {
        $c->detach('webform');
    }

    $c->detach('webform') if (defined $c->session->{afronden});

    if (
        $c->req->params->{vorige_zaak}
    ) {
        if ($c->req->params->{copy_gegevens}) {
            $c->session->{_zaak_create}->{vorige_zaak} =
                $c->req->params->{vorige_zaak};

            $c->stash->{vorige_zaak}    = $zaken->first;
        }

        $c->detach('webform');
    }

    $c->stash->{vorige_zaak}    = $zaken->first;

    $c->stash->{template}       = 'form/zaakcontrole.tt'
}


    sub _afronden_zaak_opslaan : Private {
        my ($self, $c) = @_;

        # Zetten van de betrokkene
        my $betrokkene = $c->session->{_zaak_create}->{ztc_aanvrager_id};

        # Tijdelijk opslaan en laden van de data
        my $zaak_create = $c->session->{_zaak_create};
        
        # Opslaan van de stap waarin we zitten
        my $process_step_index = $c->req->param('process_step_index') || 0;
        my $steps = $c->stash->{kenmerken_groups_keep_sort};

        die "illegal step index" unless($process_step_index < scalar @$steps && $process_step_index >= 0);

        if (!$c->req->params->{submit_to_pip}) {
            if($c->req->param('submit_to_previous')) {
                $process_step_index--;
            } elsif($c->req->param('submit_to_next')) {
                $process_step_index++;
            }
        }

        $zaak_create->{'afronden_goto_step'} = $process_step_index;

        # Zetten van het zaaktype_id
        my $zaaktype_id = $zaak_create->{'zaaktype_id'};
        my $zaaktype_node    = $c->stash->{zaaktype} || $c->model('DB::Zaaktype')->find($zaaktype_id)->zaaktype_node_id;

        my $json = new JSON;

        if (defined $c->session->{_zaak_create}->{ztc_aanvrager_id}) {

            # Zetten van de data in een JSON-string
            $json = $json->allow_blessed([1]); # Nodig om een HASH in JSON om te zetten :-S
            my $json_string = $json->encode($zaak_create);

            # Opslaan of updaten van de tijdelijk opgeslagen data
            my $cd = $c->model('DB::ZaakOnafgerond')->update_or_create(
                {
                    'zaaktype_id'     => $zaaktype_node->get_column('zaaktype_id'),
                    'betrokkene'      => $betrokkene,
                    'json_string'     => $json_string,
                    'afronden'        => 0,
                    'create_unixtime' => time()
                }
            );
        }
    }



sub webform : Private {
    my ($self, $c) = @_;

    $c->stash->{template} = $c->forward('_preprocess_webform');

    $c->forward('_process_stap');

    my $status = $c->req->param('fase') || 1;
	my $regels = $c->model('Regels');
    $regels->_execute_regels(
        $c, 
        $c->stash->{zaaktype_node_id}, 
        $c->req->params->{fase} || 1, 
        $c->session->{_zaak_create}->{form}->{kenmerken}
    );


    unless ($c->stash->{template}) {
        $c->stash->{template} = 'foutmelding.tt';
    }

    # last step
    my $steps = $c->stash->{kenmerken_groups_keep_sort};

    # Sla bij elke stap de gegevens op in de onafgeronde zaken tabel
    if ($c->req->params->{update_kenmerken}) {
        # Bij elke stap slaan we data op de in onafgeronde zaken tabel
        if ($c->session->{afronden_gezet}) {
            $c->forward('_afronden_zaak_opslaan');
        }

        if ( $c->req->params->{submit_to_pip} ) {
            $c->stash->{template} = 'form/boodschap_onafgeronde_zaak.tt';
            $c->detach;
        }
    }

    # Bij de laatste stap zet publish_zaak
    if ($c->req->params->{update_kenmerken} && 
        ($c->req->param('process_step_index')+1) == @$steps && 
        $c->req->param('submit_to_next')) {
        $c->stash->{publish_zaak} = 1;
    } else {
        $c->detach();
    }
}


sub _process_stap : Private {
    my ($self, $c)          = @_;


    ### Onafronden zaak?
#    $c->log->info('FORM->_process_stap: SESSION AFRONDEN?: '.$c->session->{afronden});
    $self->_afronden_zaak($c);


    ### Wizard
    $c->forward('_process_stap_wizard');
    $c->forward('_process_stap_load_values');
    $c->forward('_process_stap_handle_post');


    $c->stash->{form} = $c->session->{_zaak_create}->{form};

    my $uploads = $c->session->{_zaak_create}->{uploads};
    foreach my $kenmerk_id (keys %$uploads) {
        $c->stash->{uploads}->{$kenmerk_id} = $uploads->{$kenmerk_id}->{upload};
    }

    $self->_get_default_values($c);
    
	# allow cheat - in certain situations, required fields may be bypassed. inform
	# browser that the cheat option may be presented.
    #warn Dumper $c->session->{_zaak_create};

	my $zaak_create = $c->session->{_zaak_create};
	my $extra_auth_info = {
		aangevraagd_via => $zaak_create->{aangevraagd_via},
	};

	if(
#		$zaak_create->{contactkanaal} eq 'post' &&
		$zaak_create->{milestone} eq '1' &&
		$c->check_any_user_permission('zaak_beheer')
#		&& $self->required_fields_in_fase($c)
	) {
	    $c->stash->{allow_cheat} = 1;
	}
}


sub _get_default_values {
    my ($self, $c) = @_;

    # only once please
    return if $c->session->{_zaak_create}->{default_values_set}++;

    my $zaaktype_id         = $c->session->{_zaak_create}->{zaaktype_id};
    
    my $zaaktype_kenmerkens;
    if ($c->stash->{zaaktype}) {
        $zaaktype_kenmerkens    = $c->stash->{zaaktype}
            ->zaaktype_kenmerkens;
    } else {
        my $zaaktype_node_id    = $c->model("DB::Zaaktype")->find($zaaktype_id)->zaaktype_node_id->id;

        $zaaktype_kenmerkens  = $c->model('DB::ZaaktypeNode')->
            find($zaaktype_node_id)->
            zaaktype_kenmerkens;
    }

    my $zaaktype_kenmerken = $zaaktype_kenmerkens->search(
        {
            is_group => undef, 
        },
        {
            prefetch    => 'bibliotheek_kenmerken_id'
        }
    );
	my $mandatory_fields = 0;
    
    while(my $zaaktype_kenmerk = $zaaktype_kenmerken->next) {


        my $value_default = $zaaktype_kenmerk->bibliotheek_kenmerken_id->value_default;
        next unless($value_default);

        my $bibliotheek_kenmerken_id = $zaaktype_kenmerk->bibliotheek_kenmerken_id->id;
        $c->session->{_zaak_create}->{form}->{kenmerken}->{$bibliotheek_kenmerken_id} ||= $value_default;
    }
}


# sub required_fields_in_fase {
# 	my ($self, $c) = @_;
# 
#     my $zaaktype_id = $c->session->{_zaak_create}->{zaaktype_id};
#     my $zaaktype_node_id = $c->model("DB::Zaaktype")->find($zaaktype_id)->zaaktype_node_id->id;
# 
#     my $registratie_fase    = $c->stash->{zaaktype}
#         ->zaaktype_statussen
#         ->search({status => 1 })->first->id;
# 
# $c->log->debug("registratie fase status id: " . $registratie_fase); 
#     my $required_field_count = $c->model('DB::ZaaktypeNode')->
#         find($zaaktype_node_id)->
#         zaaktype_kenmerkens->
#         search({
#             is_group 		=> undef, 
#             value_mandatory => 1,
#             zaak_status_id 	=> $registratie_fase,
#         })->count;
# $c->log->debug("required fields: " . $required_field_count);
# 
# 	return $required_field_count;
# }


sub _process_stap_handle_post : Private {
    my ($self, $c)          = @_;

    return 1 unless $c->req->params->{update_kenmerken};

    ### Validation
    my $registratie_fase;
    if ($c->stash->{zaak_status}) {
        $registratie_fase    = $c->stash->{zaak_status};
    } else {
        $registratie_fase    = $c->stash->{zaaktype}
            ->zaaktype_statussen
            ->search({status => 1 });

        die('WUT? Geen registratiefase?') unless (
            $registratie_fase = $registratie_fase->first
        );
    }


    my $params = $c->req->params();

# put files in the params just before validating, otherwise the validator doesn't know 
# files have been uploaded.
    my $session_uploads = $c->session->{_zaak_create}->{uploads} || {};
    foreach my $upload_kenmerk_id (keys %$session_uploads) {
        my $kenmerk = 'kenmerk_id_' . $upload_kenmerk_id;
        $params->{$kenmerk} ||= $session_uploads->{$upload_kenmerk_id}->{upload}->filename;
    }

# hack - to make checkboxes and options defined, to enable search for required fields
    my @defined_kenmerken = ($c->req->param('defined_kenmerk'));
    foreach my $defined_kenmerk (@defined_kenmerken) {
        $params->{$defined_kenmerk} ||= '';
    }


    if (
        $c->req->header("x-requested-with") &&
        $c->req->header("x-requested-with") eq 'XMLHttpRequest' &&
        $c->req->params->{do_validation}
    ) {
        $c->zvalidate(
            $registratie_fase->validate_kenmerken(
                $params,
                {
                    ignore_undefined => 1,
                    with_prefix     => 1
                }
            )
        );
        $c->detach;
    }

    $self->uploadfile($c);

    my $session_kenmerken = $c->session->{_zaak_create}->{form}->{kenmerken} ||= {};
    my %req_kenmerken   = map {
            my $key = $_;
            $key    =~ s/kenmerk_id_//g;
            $key    => $c->req->params->{ $_ }
        } grep(/^kenmerk_id_(\d+)$/, keys %{ $c->req->params });

    for my $kenmerk (keys %req_kenmerken) {
        
        if (UNIVERSAL::isa($req_kenmerken{$kenmerk}, 'ARRAY')) {
            $session_kenmerken->{ $kenmerk } = [];

            foreach my $kenmerk_id (@{ $req_kenmerken{$kenmerk} }) {
                push @{$session_kenmerken->{ $kenmerk }}, $self->_make_value_secure($kenmerk_id);
            }
        } else {
            $session_kenmerken->{ $kenmerk } = $self->_make_value_secure($req_kenmerken{$kenmerk});
        }
    }


    # remove kenmerken that are in the current step but not in cgi params 
    # - to get rid of the last checkbox
    # first find out which step the post is about - which data are we replacing here
    my $submitted_step_index = $c->req->param('process_step_index');
    my $steps = $c->stash->{kenmerken_groups_keep_sort};
    my $submitted_step = $steps->[$submitted_step_index];

    # then get a list of kenmerken for this submitted step. for each of them, if there's
    # no information for one of them, delete it.
    my $current_stap_kenmerken = $c->stash->{kenmerken_groups}->{$submitted_step};
    foreach my $current_stap_kenmerk (@$current_stap_kenmerken) {
        my $kenmerk_id = $current_stap_kenmerk->bibliotheek_kenmerken_id->id;
        unless(exists $req_kenmerken{$kenmerk_id}) {
            delete $session_kenmerken->{$kenmerk_id};
        }        
    }
}

sub _make_value_secure {
    my ($self, $value) = @_;

    my $tf  = HTML::TagFilter->new(allow => {});

    ### HTML::TagFilter has the annoying problem that it returns en empty
    ### string when given a 0. So we make sure we do not run tagfilter when
    ### string is empty or contains a 0 (when it tests 'false').
    ### Also, we recode entities to Unicode
    unless (defined($value) && !$value) {
        $value = $tf->filter($value);
        decode_entities($value);
    }

    return $value;
}


sub uploadfile {
    my ($self, $c) = @_;

    my $uploaded_files = {};
    foreach my $upload_param (keys %{$c->req->uploads}) {
        my $upload = $c->req->upload($upload_param);

        my $options = {
          'filename' => $upload->filename,
          'id' => '0',
          'naam' => $upload->filename,
        };

        my $file_id = $c->req->param('file_id');

        # For oldschool uploading (IE)        
        unless($file_id) {
            ($file_id) = $upload->headers()->header('content-disposition') =~ m|name="(.*?)"|;
        }

        die "need file id" unless($file_id);

        my ($kenmerk) = $file_id =~ m|(\d+)$|;

        my $params = {
            uploads => {
                $kenmerk => {'upload' => $upload}
            }
        };

        my $filestore_id = $c->model('Filestore')->_store_file($c, $upload, %$options);
        $c->session->{_zaak_create}->{uploads}->{ $kenmerk } = {
            upload => $c->req->upload($upload_param),
            filestore_id => $filestore_id 
        };
        $uploaded_files->{$filestore_id} = $upload;
    }

    return $uploaded_files;
}


sub _process_stap_load_values : Private {
    my ($self, $c)          = @_;

    return 1 if (
        $c->session->{_zaak_create}->{form} &&
        scalar(keys %{ $c->session->{_zaak_create}->{form} })
    );

    $c->session->{_zaak_create}->{form} = {
        kenmerken   => {}
    };

    if ($c->stash->{vorige_zaak}) {
        my $kenmerken   = $c->stash
            ->{vorige_zaak}
            ->zaak_kenmerken
            ->search_all_kenmerken({ fase =>
                $c->stash->{vorige_zaak}->registratie_fase
            });

        $c->session->{_zaak_create}->{form}->{kenmerken} = $kenmerken;
    }    
}


#
# determine the screenflow of the webform.
# the webform can be submitted through a submit button - in which case there's a variable
# present in $c->req->params(), or through AJAX. default behaviour is to stay on the same 
# step
#
# input:
# - current step index (process_step_index)
# - CGI param submit to next
# - CGI param submit to prev
#
# output:
# - new current step
#
sub _process_stap_wizard : Private {
    my ($self, $c)          = @_;
    $c->stash->{process}    = {};

    if ($c->user_exists && $c->stash->{aanvraag_trigger} eq 'extern') {
        push(@{ $c->stash->{kenmerken_groups_keep_sort} }, 'contactgegevens');
    }

    my $steps = $c->stash->{kenmerken_groups_keep_sort};
    my $process_step_index = $c->req->param('process_step_index') || 0;

    die "illegal step index" unless($process_step_index < scalar @$steps && $process_step_index >= 0);
    
    if($c->req->param('submit_to_previous')) {
        $process_step_index--;
    } elsif($c->req->param('submit_to_next')) {
        $process_step_index++;
    }

    # In geval we uit een onafgehandelde zaak komen check naar welke stap we toe moeten waar de gebruiker gebleven was
    if ($c->stash->{'afronden_goto_step'}) {
        $c->log->info('FORM->_process_stap_wizard: GOTO STEP '.$c->stash->{'afronden_goto_step'}.' IVM afronden zaak!!!');
        $process_step_index = $c->stash->{'afronden_goto_step'} || 0;

        # Dit doen we maar eenmaal!
        $c->stash->{'afronden_goto_step'} = undef;
    }

#    $c->log->debug('process step: ' . $process_step_index);
    $c->stash->{process_step_index} = $process_step_index;
    my $process = {
        current_stap => $steps->[$process_step_index],        
        step         => $process_step_index,
    };
    if($process_step_index > 0) {
        $process->{'previous_stap'} = 3;
    }

    if(scalar @$steps > $process_step_index+1) {
        $process->{'next_stap'} = $process_step_index + 1;
    }

    $c->stash->{process} = $process; 
}



sub finish : Private {
    my ($self, $c) = @_;

    ### Delete form
    delete($c->session->{form});

    ### Set finish template
    $c->stash->{template} = 'form/finish.tt';
}

sub _preprocess_webform : Private {
    my ($self, $c) = @_;
    my ($plugin_error);

    my $template = 'form/webform.tt';

    ### Speciale webformulieren
    {
        my $zaaktype;
        if ($c->stash->{zaaktype}) {
            $zaaktype = $c->stash->{zaaktype};
        } else {
            $zaaktype = $c->model('Zaaktypen')->retrieve(
                nid => $c->stash->{zaaktype_node_id}
            );
        }

        if ($zaaktype && $zaaktype->zaaktype_definitie_id->custom_webform) {
            my $plugin = $zaaktype->zaaktype_definitie_id->custom_webform;

            foreach my $controller ($c->controllers) {
                $plugin = ucfirst($plugin);

                next unless (
                    $controller eq
                        'Plugins::' . $plugin
                        &&
                    $c->controller($controller)->can('prepare_zaak_form')
                );



                $c->log->debug(
                    'Z:C:Form->webform[prepare_zaak_form]: Running plugin: '
                    .  ucfirst($plugin)
                );

                unless($c->controller($controller)->prepare_zaak_form($c)) {
                    $plugin_error = 1;
                }
            }

            $template = 'form/custom/'
                . $zaaktype->zaaktype_definitie_id->custom_webform
                . '.tt';
        }
    }

    ### Form fields
    {
        $c->stash->{kenmerken_groups}           = {};
        $c->stash->{kenmerken_groups_keep_sort} = [];
        $c->stash->{kenmerken_groups_only}      = {};
        my $fields                              = $c->stash->{fields};

        my $current_group;
        $fields->reset;
        while (my $kenmerk = $fields->next) {
            if ($kenmerk->is_group) {
                $current_group = $kenmerk->label;
                push(
                    @{ $c->stash->{kenmerken_groups_keep_sort} },
                    $kenmerk->label
                );

                $c->stash->{kenmerken_groups_only}->{$kenmerk->label} = $kenmerk;
                next;
            } else {
                ### Geen group, show default
                if (!scalar(@{ $c->stash->{kenmerken_groups_keep_sort} })) {
                    $current_group = 'Benodigde gegevens';
                    $c->stash->{kenmerken_groups_keep_sort}->[0]
                        = 'Benodigde gegevens';
                    $c->stash->{kenmerken_groups_only}->{'Benodigde gegevens'}
                        = {
                            label   => 'Benodigde gegevens',
                            help    => undef,
                        };
                }
            }

            $c->stash->{kenmerken_groups}->{$current_group} ||= [];

            push(
                @{ $c->stash->{kenmerken_groups}->{$current_group} },
                $kenmerk
            );
        }
    }

     return $template unless $plugin_error;
     return;
}
  

sub fileupload : Chained('/') : PathPart('fileupload'): Args(1) {
    my ($self, $c, $zaak_id) = @_;

    if($zaak_id && $zaak_id =~ m|^\d+$| && $zaak_id > 0) {
        $c->stash->{'zaak'} = $c->model('DB::Zaak')->find($zaak_id);
    }

    my $uploaded_files = {};
    foreach my $upload_param (keys %{$c->req->uploads}) {
        my $upload = $c->req->upload($upload_param);

        my $options = {
          'filename' => $upload->filename,
          'id' => '0',
          'naam' => $upload->filename,
        };

    
        my $kenmerk;
        my $params;
        my $file_id = $c->req->param('file_id') || '';
        if($file_id && $file_id =~ m|(\d+)$|) {
            $kenmerk = $1;
            $params = {
                uploads => {
                    $kenmerk => {'upload' => $upload}
                }
            };
        }



        my $filestore_id;
        if($c->stash->{zaak}) {
            $c->forward("/zaak/_create_zaak_handle_uploads", [$params]);
        } else {
            $filestore_id = $c->stash->{filestore_id} = $c->model('Filestore')->_store_file($c, $upload, %$options);
            
            $c->session->{last_fileupload} = {
                upload        => $c->req->upload($upload_param),
                filestore_id  => $filestore_id 
            };
            
            if($kenmerk) {
                $c->session->{_zaak_create}->{uploads}->{ $kenmerk } = $c->session->{last_fileupload};
            }
        }
        $uploaded_files->{$filestore_id} = $upload;
    }

    $c->stash->{template} = 'uploadresponse.tt';
    $c->stash->{result} = 1;
    $c->stash->{nowrapper} = 1;
    $c->stash->{uploaded_files} = $uploaded_files;
}




#
# todo move this to a proper generic situation
#
use Digest::MD5::File qw/-nofatals file_md5_hex/;
use constant FILESTORE_DB           => 'DB::Filestore';

sub _store_file {
    my ($self, $c, $upload, %options) = @_;

    # store in DB
    my $options     = {
        'filename'      => $options{filename},
        'filesize'      => $upload->size,
        'mimetype'      => $upload->type,
    };

    my $filestore   = $c->model(FILESTORE_DB)->create($options);

    if (!$filestore) {
        $c->log->error(
            'Bib::S->_parse_file: Hm, kan filestore entry niet aanmaken: '
            . $options{filename}
        );
        $c->flash->{result} = 'ERROR: Kan bestand niet aanmaken op omgeving';
        return;
    }

    # Store on system
    my $files_dir   = $c->config->{files} . '/filestore';
$c->log->debug("moving to: " . $files_dir . '/' . $filestore->id);
    if (!$upload->copy_to($files_dir . '/' . $filestore->id)) {
        $filestore->delete;
        $c->log->error(
            'Bib::S->_parse_file: Hm, kan bestand niet aanmaken: '
            . $options{filename}
        );
        $c->flash->{result} = 'ERROR: Kan bestand niet kopieren naar omgeving';
        return;
    }

    # Stored on system and database, now fill in other fields

    # md5sum
    {
        my $md5sum = file_md5_hex($files_dir . '/' .  $filestore->id);
        $filestore->md5sum($md5sum);
    }

    $filestore->update;

    return $filestore->id
}

sub register_relaties_in_session_suggestion : Chained('/') : PathPart('form/register_relaties/suggestion'): Args(0) {
    my ($self, $c) = @_;

    my @columns;
    my $suggestion = BETROKKENE_RELATEREN_MAGIC_STRING_SUGGESTION->(
        \@columns,
        $c->req->params->{magic_string_prefix},
        $c->req->params->{rol}
    );

    unless ($suggestion) {
        $c->res->body('NOK');
        return;
    }

    $c->res->body($suggestion);
}

Params::Profile->register_profile(
    'method'    => 'register_relaties_in_session',
    'profile'   => BETROKKENE_RELATEREN_PROFILE,
);

sub register_relaties_in_session : Chained('/') : PathPart('form/register_relaties'): Args(0) {
    my ($self, $c)          = @_;
    $c->stash->{nowrapper}  = 1;

    if ($c->req->header("x-requested-with") eq 'XMLHttpRequest') {
        if ($c->req->params->{do_validation}) {
            $c->zvalidate;
        }
    }

    if ($c->req->params->{add}) {
        $c->stash->{template}   = 'widgets/betrokkene/create_relatie.tt';
        $c->detach;
    }

    if ($c->req->params->{remove}) {
        if ($c->session->{_zaak_create}->{betrokkene_relaties}) {
            $c->log->debug('Removing');
            my @relaties;
            for my $relatie (
                @{ $c->session->{_zaak_create}->{betrokkene_relaties} }
            ) {
                if (
                    $relatie->{betrokkene_identifier} eq
                        $c->req->params->{remove}
                ) {
                    next;
                }

                push(@relaties, $relatie);
            }

            $c->session->{_zaak_create}->{betrokkene_relaties} = \@relaties;
        }
    }

    $c->stash->{table_config}   = {
        'header'    => [
            {
                label   => 'Relatietype',
                mapping => 'type',
            },
            {
                label   => 'Naam',
                mapping => 'betrokkene_naam',
            },
            {
                label   => 'Rol',
                mapping => 'rol'
            },
        ],
        'options'   => {
            action              => '/form/register_relaties',
            row_identifier      => 'betrokkene_identifier',
            has_delete_button   => 1,
        }
    };

    $c->stash->{template}       = 'widgets/general/simple_table.tt';

    if (uc($c->req->method) eq 'POST') {
        $c->session->{_zaak_create}->{betrokkene_relaties} = []
            unless $c->session->{_zaak_create}->{betrokkene_relaties};

        my $relatie_profile     = BETROKKENE_RELATEREN_PROFILE;

        my $params = {};
        $params->{ $_ } = $c->req->params->{ $_ } for (
            qw/
                type
                betrokkene_naam
            /,
            @{ $relatie_profile->{required} },
            @{ $relatie_profile->{optional} }
        );

        push(
            @{ $c->session->{_zaak_create}->{betrokkene_relaties} },
            $params
        );
    };

    $c->stash->{table_config}->{rows} =
        $c->session->{_zaak_create}->{betrokkene_relaties};
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

