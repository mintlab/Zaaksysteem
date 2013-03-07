package Zaaksysteem::Controller::Beheer::Zaaktypen;
use Moose;
use namespace::autoclean;

use Hash::Merge::Simple qw( clone_merge );

use Data::Dumper;

BEGIN {extends 'Catalyst::Controller'; }

use constant ZAAKTYPEN              => 'zaaktypen';
use constant ZAAKTYPEN_MODEL        => 'DB::Zaaktype';
use constant CATEGORIES_DB          => 'DB::BibliotheekCategorie';




sub base : Chained('/') : PathPart('beheer/zaaktypen'): CaptureArgs(1) {
    my ( $self, $c, $zaaktype_id ) = @_;


    $c->response->headers->header('Cache-Control', 'No-store');

    if($zaaktype_id) {
        my $zaaktype = $c->model('DB::Zaaktype')->search({
            'id' => $zaaktype_id,
        });
        my $zaaktype_row = $zaaktype->single;
        my $zaaktype_node_id = $zaaktype_row->zaaktype_node_id->id;
        $c->stash->{zaaktype_id}        = $zaaktype_id;    
        $c->stash->{zaaktype_node_id}   = $zaaktype_node_id;
        $c->stash->{zaaktype_node_title} = $zaaktype_row->zaaktype_node_id->titel;
    } else {
        $c->stash->{zaaktype_id}        = 0;    
        $c->stash->{zaaktype_node_id}   = 0;
    }

    if($zaaktype_id) {
        # Aanvraag voor het bewerken van een zaaktype opslaan
        my $gegevens_magazijn_id = $c->user->uidnumber;
        my $session_id           = $c->get_session_id();
        my $current_unixtime     = time();
        my $usage_seconds        = 600; # 10 minuten!
        my $update_or_create     = 1;

        my $zaaktype_lock = $c->model('DB::UserAppLock')->search({type => 'zaaktypen', type_id => $zaaktype_id});
        $zaaktype_lock    = $zaaktype_lock->first;


        if (defined $zaaktype_lock) {
            my $bid     = $zaaktype_lock->get_column('uidnumber');
            my $bo      = $c->model('Betrokkene')->get(
                {
                    extern  => 1,
                    type    => 'medewerker',
                },
                $bid
            );

            my $lastlog_unixtime                           = $zaaktype_lock->create_unixtime;
            my $seconds_between_inactivity                 = $current_unixtime - $lastlog_unixtime;
            my ($days, $hours, $minutes, $seconds)         = (gmtime $seconds_between_inactivity)[7,2,1,0];
            my ($days_t, $hours_t, $minutes_t, $seconds_t) = (gmtime $usage_seconds)[7,2,1,0];

            if ($zaaktype_lock->uidnumber ne $gegevens_magazijn_id) {
                # Na $usage_seconds seconden mag degene verder anders moet ie wachten
                if ($seconds_between_inactivity <= $usage_seconds) {

                    my $melding = 'Onder andere gebruiker \''.$bo->naam.'\' (vanaf ip-adres: "'.$c->engine->env->{REMOTE_ADDR}.'") ziet momenteel het zaaktype '.$c->stash->{zaaktype_node_title}.' in. <br/>'.
                                  "De laatste activiteit was $minutes minuten en $seconds seconden geleden.<br/>".
                                  "HOU ER DUS REKENING MEE DAT IEMAND ANDERS TEGELIJKERTIJD HET ZAAKTYPE KAN PUBLICEREN!<br/>".
                                  'Deze melding verdwijnt weer nadat de andere gebruiker het zaaktype heeft gepubliceerd of wanneer er binnen '.$minutes_t.' minuten geen activiteit heeft plaatsgevonden.';

                    $c->flash->{result} = $melding;
                    #$c->res->redirect($c->uri_for('/beheer/zaaktype_catalogus/'));
                } else {
                    # Het kan zijn dat er andere gebruikers bezig waren met dit zaaktype
                    # Deze gebruikers waren echter meer dan x seconden inactief dus worden verwijdert
                    $c->model('DB::UserAppLock')->search({type => 'zaaktypen', type_id => $zaaktype_id})->delete;
                }
            } elsif ($zaaktype_lock->uidnumber eq $gegevens_magazijn_id) {
                if ($seconds_between_inactivity <= $usage_seconds) {
                    # In geval het dezelfde gebruiker is maar !een andere sessie!
                    if ($zaaktype_lock->session_id ne $session_id) {
                    my $melding = 'Onder andere gebruiker \''.$bo->naam.'\' (vanaf ip-adres: "'.$c->engine->env->{REMOTE_ADDR}.'") ziet momenteel het zaaktype '.$c->stash->{zaaktype_node_title}.' in. <br/>'.
                                  "De laatste activiteit was $minutes minuten en $seconds seconden geleden.<br/>".
                                  "HOU ER DUS REKENING MEE DAT IEMAND ANDERS TEGELIJKERTIJD HET ZAAKTYPE KAN PUBLICEREN!<br/>".
                                  'Deze melding verdwijnt weer nadat de andere gebruiker het zaaktype heeft gepubliceerd of wanneer er binnen '.$minutes_t.' minuten geen activiteit heeft plaatsgevonden.';

                        # Omdat de "PK" uid, type en type_id is en we dezelfde gebruiker hebben die wil bewerken
                        # moet niet het session_id worden ge-update (Het is namelijk een (ander) persoon onder dezelfde login!)
                        $update_or_create = 0;

                        $c->flash->{result} = $melding;
                        #$c->res->redirect($c->uri_for('/beheer/zaaktype_catalogus/'));
                    }
                }
            }
        }

        if ($update_or_create) {
            my $update = $c->model('DB::UserAppLock')->update_or_create({
                                        'uidnumber'       => $gegevens_magazijn_id,
                                        'type'            => 'zaaktypen',
                                        'type_id'         => $zaaktype_id,
                                        'create_unixtime' => $current_unixtime,
                                        'session_id'      => $session_id,
                                        });
        }
    }

#    $c->stash->{categorie_id}       = 49; #useless, but keeps everybody happy
}




sub list : Chained('/'): PathPart('beheer/zaaktypen'): Args() {
    my ( $self, $c, $categorie_id ) = @_;

    $c->stash->{bib_type}   = ZAAKTYPEN;
    $c->stash->{dest_type}   = ZAAKTYPEN;
    $c->stash->{'list_table'} = ZAAKTYPEN_MODEL;
    $c->stash->{'apply_text_filter_function'} = \&_apply_text_filter;

    $c->forward('/beheer/bibliotheek/list');
    
    $c->stash->{'entries'} = $c->stash->{'entries'}->search({'deleted' => undef}); 
}


sub _apply_text_filter {
    my ($c, $resultset, $textfilter) = @_;

    my $zaaktypen = $c->model('DB::ZaaktypeNode')->search({
        'titel' => {'ilike' => '%'. $textfilter. '%' },
    });

    return $resultset->search({ 'zaaktype_node_id' => { -in => $zaaktypen->get_column('id')->as_query }});
}





{
    sub zaaktypen_flush : Chained('/'): PathPart('beheer/zaaktypen/flush'): Args(1) {
        my ($self, $c, $zaaktype_id) = @_;

        $zaaktype_id = $c->stash->{'zaaktype_id'};

        # Verwijder gegevens uit de user_app_lock tabel
        my $gegevens_magazijn_id = $c->user->uidnumber;

        my $zaaktype_lock = $c->model('DB::UserAppLock')->find($gegevens_magazijn_id, 'zaaktypen', $zaaktype_id);
        if($zaaktype_lock) {
            $zaaktype_lock->delete;
        }

        delete($c->session->{zaaktypen});
        delete($c->session->{zaaktypen_tmp});

        $c->res->redirect(
            $c->uri_for('/beheer/zaaktype_catalogus')
        );
        $c->detach;
    }
}



{
    sub zaaktypen_clone : Chained('base'): PathPart('clone'): Args(0) {
        my ($self, $c)   = @_;

        $c->forward('_zaaktype_bewerken', [ { as_clone => 1 } ]);

        $c->res->redirect(
            $c->uri_for(
                '/beheer/zaaktypen/'
                . $c->stash->{zaaktype_id} . '/bewerken'
            )
        );
    }
}



{
    sub zaaktypen_verwijder : Chained('base'): PathPart('verwijder'): Args(0) {
        my ($self, $c)   = @_;

        ### Post
        if ( $c->req->params->{confirmed}) {
            my $zaaktype = $c->model('DB::Zaaktype')->search(
                zaaktype_node_id             => $c->stash->{zaaktype_node_id}
            );
    
            my $categorie_id = $zaaktype->first->bibliotheek_categorie_id->id || '';

            if (
                $c->model('Zaaktypen')->verwijder(
                    nid             => $c->stash->{zaaktype_node_id},
                )
            ) {
                $c->flash->{result} = 'Zaaktype succesvol verwijderd';
            }

            $c->res->redirect(
                $c->uri_for(
                    '/beheer/zaaktype_catalogus'
                    . ($categorie_id ? '/'. $categorie_id : '')
                )
            );
            $c->detach;
        }

        my $zt_node = $c->model('Zaaktypen')->retrieve(
            nid             => $c->stash->{zaaktype_node_id},
        );

        if (!$zt_node) {
            $c->res->redirect(
                $c->uri_for(
                    '/beheer/zaaktype_catalogus'
                )
            );

            $c->flash->{result} = 'Zaaktype kon niet worden gevonden';
            $c->detach;
        }

        $c->stash->{confirmation}->{message}    =
            'Weet u zeker dat u zaaktype "'
            . $zt_node->titel . '"  wilt verwijderen?'
            . ' Deze actie kan niet ongedaan gemaakt worden';

        $c->stash->{confirmation}->{type}       = 'yesno';

        $c->stash->{confirmation}->{uri}     = $c->req->uri;

        $c->forward('/page/confirmation');
        $c->detach;

    }
}

{
    sub zaaktypen_bewerken : Chained('base'): PathPart('bewerken'): CaptureArgs(0) {
        my ($self, $c)   = @_;
        my ($ztnode);

        $c->forward('_zaaktype_bewerken', [ { as_clone => undef } ]);

        ### Check session params
        $c->forward('_load_session_and_params');

    }
}

sub _zaaktype_bewerken : Private {
    my $self    = shift;
    my $c       = shift;
    my %opts;

    if (UNIVERSAL::isa($_[0], 'HASH')) {
        %opts = %{ $_[0] };
    }

    ### We would like to know if this is an existing zaaktype
    if ($c->stash->{zaaktype_node_id}) {

        ### Reset session when requested node id is different from
        ### the one in session
        unless (
            !$opts{as_clone} &&
            $c->session->{zaaktypen} &&
            $c->session->{zaaktypen}->{node}->{id} eq
                $c->stash->{zaaktype_node_id}
        ) {
            $c->session->{zaaktypen} = $c->model('Zaaktypen')->retrieve(
                nid             => $c->stash->{zaaktype_node_id},
                as_session      => 1,
                as_clone        => $opts{as_clone}
            );
            $c->session->{zaaktypen_tmp} = {};
        }
    } elsif (
        !$c->session->{zaaktypen} ||
        !$c->session->{zaaktypen}->{create}
    ) {
        ### New zaaktype
        $c->session->{zaaktypen} = {
            'create'    => 1,
            'node'      => {
                'id'        => 0,
                'version'   => 1,
            }
        };
    }


    ### HACK, REMOVE NOW
    if (!$c->session->{zaaktypen}->{node}->{id}) {
        $c->session->{zaaktypen}->{node}->{id} = 0;
    }

    $c->stash->{baseaction} = $c->stash->{formaction}   = $c->uri_for(
        '/beheer/zaaktypen/' .
        ( $c->stash->{zaaktype_id} || 0)
        . '/bewerken'
    );

    $c->stash->{zaaktype}   = $c->session->{zaaktypen};

    $c->stash->{'categorie_id'} = $c->stash->{'zaaktype'}->{'zaaktype'}->{'bibliotheek_categorie_id'};

    if (not defined $c->stash->{'categorie_id'}) {
        $c->stash('categorie_id', $c->session->{'categorie_id'});
    }

    $c->stash->{params}     = $c->session->{zaaktypen};

    if ($c->stash->{params}->{definitie}->{oud_zaaktype}) {
        $c->stash->{flash} = 'LET OP: Dit is een oud zaaktype uit versie 1.1.'
            . ' Bij publicatie worden alle oude zaaktypen bijgewerkt met de'
            . ' nieuwe fasenamen';
    }
}


{
    sub zaaktypen_start : Chained('zaaktypen_bewerken'): PathPart(''): Args(0) {
        my ($self, $c)              = @_;

        $c->forward('algemeen');
    }
}

{
    sub zaaktypen_view : Chained('base'): PathPart('view'): Args(0) {
        my ($self, $c)              = @_;

        $c->stash->{catalogus} = $c->model('Zaaktype')->retrieve(
            nid => $c->stash->{zaaktype_node_id}
        );

        $c->stash->{template} = 'beheer/zaaktypen/view.tt';

    }
}


my $STAPPEN_PLAN = [
    {
        naam        => 'algemeen',
        required    => [qw/
        /],
        #node.code
        #   node.titel
    },
    {
        naam        => 'relaties',
        required    => [qw/
        /],
    },
    {
        naam        => 'acties',
        required    => [qw/
        /],
    },
    {
        naam        => 'milestone_definitie',
        required    => [qw/
        /],
    },
    {
        naam        => 'milestones',
        required    => [qw/
        /],
    },
    {
        naam        => 'auth',
        required    => [qw/
        /],
    },
    {
        naam        => 'finish',
        required    => [qw/
        /],
    },
];

sub _controleer_complete_stap : Private {
    my ($self, $c)              = @_;
    my ($huidige_stap, @required_fields);

    my $stapnaam                = $c->stash->{huidige_stapnaam};
    my @stappen_plan            = @{ $STAPPEN_PLAN };

    my $vorige_stap;
    while (@stappen_plan && !$huidige_stap) {
        my $stap_data   = shift(@stappen_plan);

        if ($stapnaam eq $stap_data->{naam}) {
            if ($vorige_stap) {
                $c->stash->{vorige_stap}    = $vorige_stap;
            } elsif ($c->req->params->{goback}) {
                $c->forward('zaaktypen_flush', []);
            }

            $huidige_stap = $stap_data;

            $c->stash->{volgende_stap}  = shift(@stappen_plan);
            $c->stash->{volgende_stapnaam} =
                $c->stash->{volgende_stap}->{naam};
        } else {
            push(
                @required_fields,
                @{ $stap_data->{required} }
            );
        }

        $vorige_stap    = $stap_data->{naam};
    }

    if ($c->req->params->{goback}) {
        if ($c->stash->{vorige_stapurl}) {
            $c->res->redirect(
                $c->stash->{vorige_stapurl}
            );
        } else {
            $c->res->redirect(
                $c->stash->{baseaction} . '/' .
                     $c->stash->{vorige_stap}
            );
        }
        $c->detach;


    }

    ### Niks te controleren
    return 1 unless @required_fields;

    ### Validate required fields
    my $validation_profile = $c->model('Zaaktypen')->validate_session(
        'session'       => $c->session->{zaaktype},
        'zs_fields'     => \@required_fields,
    );

    if (!$validation_profile->{validation_profile}->{success}) {
        $c->log->debug('Missing fields to continue: ' . Dumper(
                $validation_profile->{validation_profile}
            )
        );

        return;
    }

    return 1;
}

sub _valideer_part : Private {
    my ($self, $c)   = @_;

    ### Check if we even can go to this part
    if (!$c->forward('_controleer_complete_stap')) {
        $c->res->redirect(
            $c->uri_for(
                '/beheer/zaaktypen/bewerken/'
                . $c->stash->{zaaktype_id} . '/algemeen'
            )
        );
        $c->detach;
    }

    ###
    ###
    ### SUBMIT!!!
    ###
    ###
    if (
        $c->req->params && $c->req->params->{zaaktype_update} &&
        $c->stash->{validation}->{validation_profile}->{success} &&
        !(
            $c->req->header("x-requested-with") &&
            $c->req->header("x-requested-with") eq 'XMLHttpRequest' &&
            $c->req->params->{do_validation}
        )
    ) {
        $self->merge_stash_into_session($c);

        if ($c->req->params->{direct_finish}) {
            $c->res->redirect(
                $c->uri_for(
                    '/beheer/zaaktypen/'
                    . $c->stash->{zaaktype_id} . '/bewerken/'
                    . 'finish'
                )
            );
        } else {
            $c->res->redirect(
                (
                    $c->stash->{volgende_stapurl} ||
                    $c->uri_for(
                        '/beheer/zaaktypen/'
                        . $c->stash->{zaaktype_id} . '/bewerken/'
                        . $c->stash->{volgende_stapnaam}
                    )
                )
            );
        }
        $c->detach;
    }

}

sub merge_stash_into_session {
    my ($self, $c) = @_;

    delete($c->session->{params});

    my $tomerge = {};
    if ($c->stash->{params}->{params}) {
        $tomerge = $c->stash->{params}->{params};
    } else {
        $tomerge = $c->stash->{params};
    }
    
    # clean up temporary
    # should they be here in the first place?
    my $milestone_number = $c->stash->{milestone_number};
    if($milestone_number) {
        if(exists $tomerge->{statussen}->{ $c->stash->{milestone_number} }->{elementen}->{regels}) {
            my $regels = $tomerge->{statussen}->{ $c->stash->{milestone_number} }->{elementen}->{regels};
            foreach my $regel (values %$regels) {
                foreach my $key (keys %$regel) {    
                    delete $regel->{$key} if($key =~ m|_previous|);
                }
            }
        }
    }

    my $sessionmerged = clone_merge(
        $c->session->{zaaktypen},
        $tomerge
    );

    ### Delete tmp session data
    delete($c->session->{zaaktypen_tmp});
    $c->session->{zaaktypen} = $sessionmerged;
}


sub _load_params_status_update : Private {
    my ($self, $c)  = @_;

    ### We need to reshake the params a bit, just to make it easy for
    ### javascript to work with the dynamic tables

    my $mnumber             = $c->req->params->{milestone_number};

    ### Load all data according to template
    #my $zaaktype_template   = $c->model('Zaaktypen')->session_template;

    ### Session parameters
    $c->stash->{milestone_number}   = $mnumber;
    $c->forward('load_session_tmp');

    #### Default parameters
    my %found_elementdata   = ();
    my $newreqparams        = {};
    for my $paramkey (keys %{ $c->stash->{req_params} }) {
        my $paramvalue          = $c->stash->{req_params}->{$paramkey};

        next unless $paramkey   =~ /^params\.status\./;

        my $paramkeyoriginal = $paramkey;

        ### Are we able to work with this param?
        if (
            $paramkey !~ /^params\.status\.[\w\d_]+\.[\w\d_]+\.\d+$/
        ) {
            ### Remove bogus keys
            next;
        }

        ### Make param zaaksysteem readable
        {
            ### CHANGE: params.status.notificatie.label.1
            ### INTO: params.statussen.notificatie.1.label
            $paramkey   =~
            s/^params\.status(\.[\w\d_]+)(\.[\w\d_]+)(\.\d+)$/params\.statussen\.$mnumber\.elementen$1$3$2/g;

            ### Delete deprecated entry and set new one
            $newreqparams->{$paramkey} = (
                $paramvalue ? $paramvalue : undef
            );
        }


        ### Load kenmerk dialog data into params
        {
            my ($element, $elementnumber)   = $paramkey =~
                /^params\.statussen\.$mnumber\.elementen\.([\w\d_]+)\.(\d+)/;

            if (! defined($found_elementdata{$element . $elementnumber}) ) {
                my $elementdata = $c->session->{zaaktypen_tmp}
                    ->{ 'milestones' }
                    ->{ $mnumber }
                    ->{ $element }
                    ->{ $elementnumber };

                if ($elementdata) {
                    for my $key (keys %{ $elementdata }) {
                        next if $newreqparams->{
                            'params.statussen.' . $mnumber
                            . '.elementen.' . $element
                            . '.' . $elementnumber . '.' . $key
                        };
                        $newreqparams->{
                            'params.statussen.' . $mnumber
                            . '.elementen.' . $element
                            . '.' . $elementnumber . '.' . $key
                        } = $elementdata->{$key};
                    }
                }

                ### Remove tmp data
                delete(
                    $c->session->{zaaktypen_tmp}
                        ->{ 'milestones' }
                        ->{ $mnumber }
                        ->{ $element }
                        ->{ $elementnumber }
                );

                $found_elementdata{$element . $elementnumber} = 1;
            }
        }
    }

    $c->stash->{req_params} = $newreqparams;
}

sub _handle_deleted_entries {
    my ($self, $c) = @_;

    ### Only for milestone handling
    return unless $c->stash->{milestone_number};

    my $old_params  = $c->session
        ->{zaaktypen}
        ->{params}
        ->{statussen}
        ->{ $c->stash->{milestone_number} }
        ->{ elementen };

    my $new_params  = $c->stash
        ->{new_params}
        ->{params}
        ->{statussen}
        ->{ $c->stash->{milestone_number} }
        ->{ elementen };

    for my $element ( keys %{ $old_params }) {
        unless ($new_params->{ $element }) {
            delete($c->session
                ->{zaaktypen}
                ->{params}
                ->{statussen}
                ->{ $c->stash->{milestone_number} }
                ->{ elementen }
                ->{ $element }
            );
            next;
        }
        for my $i (keys %{ $old_params->{ $element } }) {
            unless ($new_params->{ $element }->{ $i }) {
                delete($c->session
                    ->{zaaktypen}
                    ->{params}
                    ->{statussen}
                    ->{ $c->stash->{milestone_number} }
                    ->{ elementen }
                    ->{ $element }
                    ->{ $i }
                );
            }
        }
    }

}

{
    sub _load_session_and_params : Private {
        my ($self, $c)   = @_;

        return unless $c->req->params && $c->req->params->{zaaktype_update};

        ### Clone parameters
        $c->stash->{req_params} = { %{ $c->req->params } };

        ### Let's make sure we got all the checkboxes
        if ($c->stash->{req_params}->{ezra_checkboxes}) {
            my @given_checkboxes = ();
            if (UNIVERSAL::isa($c->stash->{req_params}->{ezra_checkboxes}, 'ARRAY')) {
                @given_checkboxes = @{ $c->stash->{req_params}->{ezra_checkboxes} };
            } else {
                push(@given_checkboxes,
                    $c->stash->{req_params}->{ezra_checkboxes}
                );
            }

            for my $given_checkbox (@given_checkboxes) {
                if (!$c->stash->{req_params}->{$given_checkbox}) {
                    $c->stash->{req_params}->{$given_checkbox} = undef;

                    $c->log->debug('FOUND GIVEN CHECKBOX: ' .  $given_checkbox);
                }
            }

            delete($c->stash->{req_params}->{ezra_checkboxes});
        }

        ### Reorden 'special' params status update
        if ($c->req->params->{status_update}) {
            $c->forward('_load_params_status_update');
        }

        ### Update params
        $c->stash->{new_params} = {};
        for my $param (keys %{ $c->stash->{req_params} }) {
            # Security, only test.bla[.bla.bla]
            next unless $param  =~ /^[\w\d\_]+\.[\w\d\_\.]+$/;

            my $eval = '$c->stash->{new_params}->{';
            $eval   .= join('}->{', split(/\./, $param)) . '}';

            $eval   .= ' = $c->stash->{params}->{';
            $eval   .= join('}->{', split(/\./, $param)) . '}';

            $eval   .= ' = $c->stash->{req_params}->{\'' . $param . '\'}';

            eval($eval);
        }

        $self->_handle_deleted_entries($c);

        ### Resort params
        if ($c->req->params->{status_update}) {
            foreach my $elementnaam (
                keys %{ $c->stash->{params}->{params}->{statussen}->{
                        $c->stash->{milestone_number}
                    }->{elementen}
                }
            ) {
                my $sorted_params = {
                    map {
                        $_->{mijlsort} => $_
                    } values %{
                        $c->stash->{params}->{params}->{statussen}->{
                            $c->stash->{milestone_number}
                        }->{elementen}->{$elementnaam}
                    }
                };

                $c->stash->{params}->{params}->{statussen}->{
                    $c->stash->{milestone_number}
                }->{elementen}->{$elementnaam} = $sorted_params;
            }

            ### OK...finalize
            $c->session->{zaaktypen}->{statussen}->{
                $c->stash->{milestone_number}
            }->{elementen} = $c->stash->{params}->{params}->{statussen}->{
                $c->stash->{milestone_number}
            }->{elementen};
        }

        if (exists($c->stash->{req_params}->{'zaaktype_betrokkenen.betrokkene_type'})) {
            my @betrokkenen = ();
            if (
                UNIVERSAL::isa(
                    $c->req->params->{'zaaktype_betrokkenen.betrokkene_type'},
                    'ARRAY'
                )
            ) {
                push(@betrokkenen,
                    @{ $c->req->params->{'zaaktype_betrokkenen.betrokkene_type'} }
                );
            } elsif ($c->req->params->{'zaaktype_betrokkenen.betrokkene_type'}) {
                push(@betrokkenen,
                    $c->req->params->{'zaaktype_betrokkenen.betrokkene_type'}
                );
            }

            my $counter = 0;
            $c->stash->{params}->{betrokkenen} = {};
            for my $betrokkene (@betrokkenen) {
                $c->stash->{params}->{betrokkenen}->{
                    ++$counter
                }   = {
                    betrokkene_type => $betrokkene,
                }
            }
        }

        ### Validate params
        $c->stash->{validation} = $c->model('Zaaktypen')->validate_session(
            'session'       => $c->stash->{params},
            'zs_fields'     => [ keys %{ $c->req->params } ],
        );

        ### Give JSON some feedback
        if (
            $c->req->header("x-requested-with") &&
            $c->req->header("x-requested-with") eq 'XMLHttpRequest' &&
            $c->req->params->{do_validation}
        ) {
                $c->zcvalidate($c->stash->{validation}->{validation_profile});
                $c->detach;
        }
    }
}


sub algemeen : Chained('zaaktypen_bewerken'): PathPart('algemeen') {
    my ($self, $c) = @_;

    $c->stash->{bib_cat}        = $c->model(CATEGORIES_DB)->search(
        {  
            'system'    => { 'is' => undef },
            'pid'       => undef,
        },
        {  
            order_by    => ['pid','naam']
        }
    );

    $c->stash->{huidige_stapnaam}   = 'algemeen';

    $c->stash->{formaction}         .= '/algemeen';

    $c->forward('_valideer_part');

    ### Speciale webformulieren
    {
        $c->stash->{speciale_webformulieren} = [];
        if (-d $c->config->{root} . '/tpl/zaak_v1/nl_NL/form/custom') {
            opendir(my $DIR, $c->config->{root} . '/tpl/zaak_v1/nl_NL/form/custom');
            while (my $file = readdir($DIR)) {
                next unless $file =~ /\.tt$/;

                $file =~ s/\.tt$//;

                push(@{ $c->stash->{speciale_webformulieren} },
                    $file
                );
            }
        }
    }

    $c->stash->{template}   = 'beheer/zaaktypen/algemeen/edit.tt';
}

sub relaties : Chained('zaaktypen_bewerken'): PathPart('relaties') {
    my ($self, $c) = @_;

    $c->stash->{huidige_stapnaam}   = 'relaties';

    $c->stash->{formaction}         .= '/relaties';

    ## Custom
    {
        $c->stash->{zaaktype_betrokkenen} = {};

        while (
            my ($bid, $betrokkene) = each %{
                $c->stash->{zaaktype}->{betrokkenen}
            }
        ) {
            $c->stash->{zaaktype_betrokkenen}->{
                $betrokkene->{betrokkene_type}
            } = 1;
        }
    }

    if ($c->req->method =~ /POST/i) {
        if (!$c->stash->{params}->{definitie}->{heeft_pdc_tarief}) {
            $c->stash->{params}->{definitie}->{ $_ } = undef
                for qw/pdc_tarief_cnt pdc_tarief pdc_tarief_eur/;
        }
    }

    $c->forward('_valideer_part');

    $c->stash->{template}   = 'beheer/zaaktypen/relaties/edit.tt';
}

sub acties : Chained('zaaktypen_bewerken'): PathPart('acties') {
    my ($self, $c) = @_;

    $c->stash->{huidige_stapnaam}   = 'acties';

    $c->stash->{formaction}         .= '/acties';

    $c->forward('_valideer_part');

    $c->stash->{template}   = 'beheer/zaaktypen/acties/edit.tt';
}

sub auth : Chained('zaaktypen_bewerken'): PathPart('auth') {
    my ($self, $c) = @_;

    $c->stash->{huidige_stapnaam}   = 'auth';

    $c->stash->{formaction}         .= '/auth';

    ### Combine params
    {
        $c->stash->{pauthorisaties} = {};
        while (my ($authid, $authdata) = each %{
            $c->stash->{zaaktype}->{authorisaties}
        }) {
            if (
                $c->stash->{pauthorisaties}->{
                    $authdata->{ou_id} . '-' . $authdata->{role_id}
                }
            ) {
                $c->stash->{pauthorisaties}->{
                        $authdata->{ou_id} . '-' . $authdata->{role_id}
                }->{recht}->{ $authdata->{recht} } = 1;
                next;
            }

            ### Place authdata
            $c->stash->{pauthorisaties}->{
                $authdata->{ou_id} . '-' . $authdata->{role_id}
            } = $authdata;

            ### Replace recht
            $c->stash->{pauthorisaties}->{
                $authdata->{ou_id} . '-' . $authdata->{role_id}
            }->{recht} = {
                $authdata->{recht}  => 1,
            };
        }

        my $sorted_auth;
        my $counter = 0;
        while (my ($authident, $authdata) = each %{
                $c->stash->{pauthorisaties}
        }) {
            $sorted_auth->{++$counter} = $authdata;
        }

        $c->stash->{pauthorisaties} = $sorted_auth;
    }

    $c->forward('_verify_auth');
    $c->forward('_valideer_part');

    $c->stash->{template}   = 'beheer/zaaktypen/auth/edit.tt';
}

sub _verify_auth : Private {
    my ($self, $c) = @_;
    my $auth = {};

    if ($c->req->params->{auth_update}) {
        {
            my $maxauth = 0;
            for my $key ( grep { /^aparams\.authorisaties\..*?.\d+$/ } keys %{ $c->req->params } ) {
                my ($paramkey, $authid) = $key =~ /aparams\.authorisaties\.(.*?)\.(\d+)/;

                $auth->{$authid} = {} unless $auth->{$authid};
                $auth->{$authid}->{$paramkey}   = $c->req->params->{$key};

                $maxauth = $authid if $maxauth < $authid;
            }

            ### Now do something with deletion
            while (my ($id, $data) = each %{ $auth }) {
                ## Delete when no recht
                if (!$data->{recht}) {
                    delete($auth->{$id});
                    next;
                }
            }

            ### Now do something with more than 1 right
            while (my ($id, $data) = each %{ $auth }) {
                if (UNIVERSAL::isa($data->{recht}, 'ARRAY')) {
                    my @rechten = @{ $data->{recht} };
                    # first:
                    my $firstright = shift(@rechten);

                    $auth->{$id}->{recht} = $firstright;

                    for my $right (@rechten) {
                        my %newdata = %{ $data };
                        $newdata{'recht'} = $right;

                        $auth->{++$maxauth} = { %newdata };
                    }
                }
            }
        }

        $c->stash->{zaaktype}->{authorisaties} = $auth;
    }

}

sub finish : Chained('zaaktypen_bewerken'): PathPart('finish') {
    my ($self, $c) = @_;

    $c->stash->{huidige_stapnaam}   = 'finish';

    $c->stash->{formaction}         .= '/finish';

    $c->forward('_valideer_part');

    if ($c->req->params->{commit}) {
        ### Commit the shizzle
        $c->model('Zaaktypen')->commit_session(
            session     => $c->stash->{zaaktype}
        );

        $c->forward('zaaktypen_flush');
        $c->res->redirect('/beheer/zaaktypen');

        $c->flash->{result} = 'Zaaktype succesvol bijgewerkt';

        $c->detach;
    }

    $c->stash->{template}   = 'beheer/zaaktypen/finish/view.tt';
}

sub _add_milestone : Private {
    my ($self, $c) = @_;

    my @statusnums  = sort { $a <=> $b } keys %{ $c->stash->{zaaktype}->{statussen} };
    my $laststatus  = pop @statusnums;

    ### Reroute
    $c->stash->{zaaktype}->{statussen}->{ $laststatus }->{definitie}->{status} =
        ($laststatus + 1);

    $c->stash->{zaaktype}->{statussen}->{ ($laststatus + 1) } =
        $c->stash->{zaaktype}->{statussen}->{ $laststatus };

    $c->stash->{zaaktype}->{statussen}->{ $laststatus } = {
        'elementen' => {},
        'definitie' => {
            status  => $laststatus,
            create  => 1,
            ou_id   => $c->stash->{zaaktype}->{statussen}->{ $laststatus }
                ->{definitie}->{ou_id},
            role_id => $c->stash->{zaaktype}->{statussen}->{ $laststatus }
                ->{definitie}->{role_id}
        }
    };
}

sub _verify_milestone_definitie : Private {
    my ($self, $c) = @_;

    if ($c->req->params->{definitie_update}) {
        {
            my %availablestatussen = ();
            my $statussen;
            for my $key ( grep { /statussen\./ } keys %{ $c->req->params } ) {
                my ($statusid) = $key =~ /statussen\.(\d+)\./;

                if (! $availablestatussen{$statusid} ) {
                    if (
                        $c->req->params->{
                            'statussen.' . $statusid . '.definitie.naam'
                        }
                    ) {
                        $statussen->{$statusid} = $c->stash->{zaaktype}
                            ->{statussen}->{ $statusid };
                    }
                }

                $availablestatussen{$statusid} = 1;
            }

            $c->stash->{zaaktype}->{statussen} = $statussen;
        }

        ### Update data
        {
            my @statusnums     = sort { $a <=> $b } keys %{ $c->stash->{zaaktype}->{statussen} };
            my ($role_id,$ou_id);
            for my $statusnr (@statusnums) {
                # Naam
                $c->stash->{zaaktype}->{statussen}->{ $statusnr }
                    ->{definitie}->{naam}   = $c->req->params->{
                        'statussen.' . $statusnr . '.definitie.naam'
                    };


                # Fase
                $c->stash->{zaaktype}->{statussen}->{ $statusnr }
                    ->{definitie}->{fase}   = $c->req->params->{
                        'statussen.' . $statusnr . '.definitie.fase'
                    };

                # ou_id
                if (
                    $c->req->params->{
                        'statussen.' . $statusnr .  '.definitie.role_set'
                    } || $statusnr == 1
                ) {
                    $ou_id      = $c->req->params->{
                        'statussen.' . $statusnr . '.definitie.ou_id'
                    };

                    $role_id    = $c->req->params->{
                        'statussen.' . $statusnr . '.definitie.role_id'
                    };
                }


                $c->stash->{zaaktype}->{statussen}->{ $statusnr }
                    ->{definitie}->{ou_id}   = $ou_id;

                # scope_id
                $c->stash->{zaaktype}->{statussen}->{ $statusnr }
                    ->{definitie}->{role_id}   = $role_id;
            }
        }
    }

    ### Resort data
    {
        my @statusnums     = sort { $a <=> $b } keys %{ $c->stash->{zaaktype}->{statussen} };
        my ($statussen, $counter) = ({}, 0);
        my ($role_id, $ou_id) = @_;
        for my $statusnr (@statusnums) {
            ++$counter;
            my $statusdata  = $c->stash->{zaaktype}->{statussen}->{$statusnr};

            ### Make DAMN sure counter is the same as status
            $statusdata->{definitie}->{status} = $counter;

            $statussen->{$counter} = $statusdata;

            ### XXX Dit is pre-2.1 code, wat alleen gebruikt wordt bij
            ### bestaande zaaktypen van voor 2.1 die bewerkt worden. Het vinkje:
            ### toewijziging activeren staat standaard uit, en moet even aangezet
            ### worden voor afwijkende roles/ou's
            ### {
            if (
                !$c->req->params->{definitie_update} &&
                (
                    $statusdata->{definitie}->{ou_id} ne $ou_id ||
                    $statusdata->{definitie}->{role_id} ne $role_id
                )
            ) {
                $ou_id      = $statusdata->{definitie}->{ou_id};
                $role_id    = $statusdata->{definitie}->{role_id};
                $statusdata->{definitie}->{role_set} = 1;
            }
            ### }
        }

        $c->stash->{zaaktype}->{statussen} = $statussen;
    }
}

sub milestone_definitie : Chained('zaaktypen_bewerken'): PathPart('milestone_definitie') {
    my ($self, $c) = @_;

    $c->stash->{huidige_stapnaam}   = 'milestone_definitie';

    $c->stash->{formaction}         .= '/milestone_definitie';

    $c->forward('_verify_milestone_definitie');
    ### Ajax action
    if (
        $c->req->header("x-requested-with") &&
        $c->req->header("x-requested-with") eq 'XMLHttpRequest' &&
        $c->req->params->{action}
    ) {
        $c->forward('_add_milestone');

        $c->stash->{nowrapper} = 1;
        $c->stash->{template} =
            'beheer/zaaktypen/milestone_definitie/ajax_table.tt';
        $c->detach;
    }

    $c->forward('_valideer_part');

    if (
        !$c->stash->{zaaktype}->{statussen} ||
        scalar(keys %{ $c->stash->{zaaktype}->{statussen} }) < 2
    ) {
        $c->stash->{zaaktype}->{statussen} = {
            1   => {
                'definitie' => {
                    'naam'      => 'Geregistreerd',
                    'fase'      => 'Registratie',
                    'status'    => 1,
                },
            },
            2   => {
                'definitie' => {
                    'naam'      => 'Afgehandeld',
                    'fase'      => 'Afhandeling',
                    'status'    => 2,
                }
            },
        };
    }

    if ($c->stash->{zaaktype}->{definitie}->{oud_zaaktype}) {
        my $laatste_status = scalar(
            keys(%{ $c->stash->{zaaktype}->{statussen} })
        );

        $c->stash->{zaaktype}->{statussen}->{1}
            ->{definitie}->{fase} = 'Registratie';
        $c->stash->{zaaktype}->{statussen}->{$laatste_status}
            ->{definitie}->{fase} = 'Afhandeling';
    }

    $c->stash->{template}   = 'beheer/zaaktypen/milestone_definitie/edit.tt';
}


sub milestones_base : Chained('zaaktypen_bewerken'): PathPart('milestones'): CaptureArgs(1) {
    my ($self, $c, $milestone_number) = @_;

    $c->stash->{milestone_number}   = $milestone_number;
    $c->stash->{page_title} = "Fase $milestone_number";

    if ($c->stash->{milestone_number} < 2) {
        $c->stash->{milestone_first} = 1;
    }

    if (
        $c->stash->{zaaktype}->{statussen} &&
        scalar(keys %{ 
            $c->stash->{zaaktype}->{statussen}
            }
        ) == $c->stash->{milestone_number}
    ) {
        $c->stash->{milestone_last} = 1;
    }

    $c->stash->{milestone}          = $c->stash->{zaaktype}
                            ->{statussen}->{ $c->stash->{milestone_number} };

    $c->stash->{milestoneurl}       .= $c->stash->{formaction} . '/milestones';
    $c->stash->{formaction}         .= '/milestones/'
        . $c->stash->{milestone_number};

    ### Define volgende stap bypass:
    if ($c->stash->{milestone_number} > 1) {
        $c->stash->{vorige_stapurl} =
            $c->stash->{milestoneurl} . '/' .
            ($c->stash->{milestone_number} - 1)
    }


    if ($c->req->params->{status_update}) {
        if (
            $c->stash->{zaaktype}->{statussen}->{
                ($c->stash->{milestone_number} + 1)
            }
        ) {
            $c->stash->{volgende_stapurl} =
                $c->stash->{milestoneurl} . '/' .
                ($c->stash->{milestone_number} + 1)
        }
    }

    $c->stash->{huidige_stapnaam}   = 'milestones';

    $c->forward('_valideer_part');
}

sub milestones_start : Chained('zaaktypen_bewerken'): PathPart('milestones'): Args(0) {
    my ($self, $c) = @_;

    ### Forward to milestone number 1
    $c->forward('milestones_base', [1]);
    $c->forward('milestones');
}


sub milestones : Chained('milestones_base'): PathPart(''): Args(0) {
    my ($self, $c) = @_;

    $c->stash->{template}           = 'beheer/zaaktypen/milestones/edit.tt';
}



sub load_session_tmp : Private {
    my ($self, $c) = @_;

    ### Define some incoming attributes
    if ($c->req->params) {
        $c->stash->{row_id}     = $c->req->params->{row_id};    # row identifier in page
        $c->stash->{rownumber}  = $c->req->params->{rownumber}; # row number in page
        $c->stash->{edit_id}    = $c->req->params->{edit_id};   # what to edit
    }

    my $store              = 'milestones';
    my $milestonenumber    = $c->stash->{milestone_number};

    return unless ($store && $milestonenumber);

    ### First, check if we already updated some values
    if (
        !exists(
            $c->session->{zaaktypen_tmp}->{
                $store
            }->{ $milestonenumber }
        ) &&
        $c->session->{zaaktypen}->{statussen}->{ $milestonenumber }
    ) {
        for my $element (
            keys %{
                $c->session->{zaaktypen}->{statussen}->{ $milestonenumber }
                    ->{ elementen }
            }
        ) {
            next if ($element eq 'definitie');

            $c->session->{zaaktypen_tmp}
                ->{ $store }
                ->{ $milestonenumber }
                ->{ $element }
                    = $c->session->{zaaktypen}->{statussen}
                            ->{ $milestonenumber }
                            ->{'elementen'}
                            ->{ $element };
        }
    }


    ### Is this a post? update values in session
    if ($c->req->params->{update}) {
        my $element = $c->stash->{zaaktypen_tmp_store_element};

        my $elemdata = { map {
            my $key = $_;
            $key    =~ s/^${element}_//;
            $key    => $c->req->params->{ $_ }
        } grep {
            $_ =~ /^${element}_/
        } %{ $c->req->params } };

        if($c->req->param('update_regel_editor')) {
            $elemdata = $self->pre_process_regel_info($c, $elemdata);
        }

        $c->session->{zaaktypen_tmp}
            ->{ $store }
            ->{ $milestonenumber }
            ->{ $element }
            ->{ $c->stash->{rownumber} }
                = $elemdata;
    }

}



#
# if a different kenmerk is chosen, the form is re-submitted to have the template render a
# new page. the input fields change. however, the value should not be kept since there are different
# datatypes.
# first recognize the situation, this happens when a kenmerk property is different. a extra hidden
# input field is use for this purpose, to keep track. alternatively,we could look in the session
# no idea where to find that though -- maybe next week :)
# for now, compare stash with req->params
# solution is to delete all value fields from the stash that are linked to the kenmerk property.
#
sub pre_process_regel_info {
    my ($self, $c, $elemdata) = @_;

    foreach my $param (keys %{$c->req->params}) {
        my $current = $c->req->param($param);
#        $c->log->debug('param: '. $param . ', current: ' . $current);
        my $previous = $c->req->param($param . '_previous');

        if($param =~ m|\_kenmerk| && $previous) {
            if($previous ne $current) {
                $param =~ s|kenmerk|value|;
                $param =~ s|^regels_||;
                $c->log->debug('param chopped: ' . $param);
                foreach my $key (keys %$elemdata) {
                    if($key eq $param) {
                        $c->log->debug('deleting ' . $key);
                        delete $elemdata->{$key};
                    }
                }
            }
        }
    }

    return $elemdata;
}





sub dialog_bewerken_base : Private {
    my ($self, $c) = @_;

    $c->forward('load_session_tmp');

    ### When data is new, load some credentials from database
    unless (
        $c->session->{zaaktypen_tmp}
            ->{ $c->stash->{zaaktypen_tmp_store} }
            ->{ $c->stash->{milestone_number} }
            ->{ $c->stash->{zaaktypen_tmp_store_element} }
            ->{ $c->stash->{rownumber} } ||
        !$c->req->params->{edit_id} ||
        $c->req->params->{edit_id} eq 'undefined'
    ) {
        my $bibliotheek_kenmerk =
            $c->model('DB::BibliotheekKenmerken')->find(
                $c->req->params->{edit_id}
            );

        if ($bibliotheek_kenmerk) {
            my @columns = $bibliotheek_kenmerk->result_source->columns;

            my %data;
            for my $column (@columns) {
                my $columnname      = $column;

                $columnname         = 'type'
                    if ($column eq 'value_type');

                $data{$columnname}  = $bibliotheek_kenmerk->$column;
            }

            $c->stash->{params} = \%data;
        }
    } else {
        $c->stash->{params}     =
            $c->session->{zaaktypen_tmp}
                ->{ $c->stash->{zaaktypen_tmp_store} }
                ->{ $c->stash->{milestone_number} }
                ->{ $c->stash->{zaaktypen_tmp_store_element} }
                ->{ $c->stash->{rownumber} };
    }

    $c->stash->{nowrapper}  = 1;
}



sub kenmerk_bewerken : Chained('milestones_base'): PathPart('kenmerk'): Args() {
    my ($self, $c) = @_;

    $c->stash->{zaaktypen_tmp_store}            = 'milestones';
    $c->stash->{zaaktypen_tmp_store_element}    = 'kenmerken';
    $c->stash->{bibiotheek_kenmerk}             = $c->model('DB::BibliotheekKenmerken')->find($c->req->params->{edit_id});

    $c->stash->{template}   = 'beheer/zaaktypen/milestones/edit_kenmerk.tt';

    if ($c->req->params->{update}) {
        if ($c->req->params->{kenmerken_value_default} eq $c->stash->{bibiotheek_kenmerk}->value_default) {
            #$c->req->params->{kenmerken_value_default} = undef;
        }
        
    }

    $c->forward('dialog_bewerken_base');
}

sub kenmerkgroup_bewerken : Chained('milestones_base'): PathPart('kenmerkgroup'): Args() {
    my ($self, $c) = @_;

    $c->stash->{zaaktypen_tmp_store}            = 'milestones';
    $c->stash->{zaaktypen_tmp_store_element}    = 'kenmerken';

    $c->stash->{template}   = 'beheer/zaaktypen/milestones/edit_kenmerk_group.tt';

    $c->forward('dialog_bewerken_base');
}


sub sjabloon_bewerken : Chained('milestones_base'): PathPart('sjabloon'): Args() {
    my ($self, $c) = @_;

    $c->stash->{zaaktypen_tmp_store}            = 'milestones';
    $c->stash->{zaaktypen_tmp_store_element}    = 'sjablonen';

    $c->stash->{template}   = 'beheer/zaaktypen/milestones/edit_sjabloon.tt';

    $c->forward('dialog_bewerken_base');
}


sub checklist_bewerken : Chained('milestones_base'): PathPart('checklist'): Args() {
    my ($self, $c) = @_;

    $c->stash->{zaaktypen_tmp_store}            = 'milestones';
    $c->stash->{zaaktypen_tmp_store_element}    = 'checklists';

    $c->stash->{template}   = 'beheer/zaaktypen/milestones/edit_checklist.tt';

    $c->forward('dialog_bewerken_base');
}


sub notificatie_bewerken : Chained('milestones_base'): PathPart('notificatie'): Args() {
    my ($self, $c) = @_;

    $c->stash->{zaaktypen_tmp_store}            = 'milestones';
    $c->stash->{zaaktypen_tmp_store_element}    = 'notificaties';

    $c->stash->{template}   = 'beheer/zaaktypen/milestones/edit_notificatie.tt';

    $c->forward('dialog_bewerken_base');
}



sub regel_bewerken : Chained('milestones_base'): PathPart('regel'): Args() {
    my ($self, $c) = @_;

    $c->stash->{zaaktypen_tmp_store}            = 'milestones';
    $c->stash->{zaaktypen_tmp_store_element}    = 'regels';

    my $params = $c->req->params();
    
    if($params->{'add_voorwaarde'}) {
        my $voorwaarden = $params->{'regels_voorwaarden'};
        $voorwaarden ||= '1';
        unless(ref $voorwaarden && ref $voorwaarden eq 'ARRAY') {
            $voorwaarden = [$voorwaarden];
        }
        # find a free slot
        my $lookup = {map {$_ => 1} @$voorwaarden};
        my $i = 0;
        while($lookup->{++$i}) {}
        $c->stash->{new_voorwaarde} = "$i";
    } elsif($params->{'add_actie'}) {
        my $acties = $params->{'regels_acties'};
        $acties ||= '1';
        unless(ref $acties && ref $acties eq 'ARRAY') {
            $acties = [$acties];
        }
        # find a free slot
        my $lookup = {map {$_ => 1} @$acties};
        my $i = 0;
        while($lookup->{++$i}) {}
        $c->stash->{new_actie} = "$i";
    } elsif($params->{'add_anders'}) {
        my $anders = $params->{'regels_anders'};
        $anders ||= '1';
        unless(ref $anders && ref $anders eq 'ARRAY') {
            $anders = [$anders];
        }
        # find a free slot
        my $lookup = {map {$_ => 1} @$anders};
        my $i = 0;
        while($lookup->{++$i}) {}
        $c->stash->{new_anders} = "$i";
    }

    $c->stash->{template}   = 'beheer/zaaktypen/milestones/edit_regel.tt';

    $c->forward('dialog_bewerken_base');
}


sub relatie_bewerken : Chained('milestones_base'): PathPart('relatie'): Args() {
    my ($self, $c) = @_;

    $c->stash->{zaaktypen_tmp_store}            = 'milestones';
    $c->stash->{zaaktypen_tmp_store_element}    = 'relaties';

    $c->stash->{template}   = 'beheer/zaaktypen/milestones/edit_relatie.tt';

    $c->forward('dialog_bewerken_base');
}



sub overzicht_milestones : Chained('milestones_base'): PathPart('overzicht') : Args() {
    my ($self, $c) = @_;

    $c->stash->{template} =
        'beheer/zaaktypen/milestones/overzicht_milestones.tt';
}



__PACKAGE__->meta->make_immutable;


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

