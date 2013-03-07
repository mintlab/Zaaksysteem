package Zaaksysteem::Controller::Zaaktype::Status;

use strict;
use warnings;
use Data::Dumper;
use parent 'Catalyst::Controller';




sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Zaaksysteem::Controller::Zaaktype::Status in Zaaktype::Status.');
}

sub edit : Chained('/zaaktype/base'): PathPart('status/edit'): Args(0) {
    my ($self, $c) = @_;

    if (%{ $c->req->params }) {
        $c->forward('load_status_data');
        $c->response->redirect($c->uri_for('/zaaktype/specifiek/edit'));
    } elsif (
        $c->session->{zaaktype_edit}->{edit} &&
        $c->session->{zaaktype_edit}->{status} &&
        %{
            $c->session->{zaaktype_edit}->{status}
        }
    ) {
        ### Loop over all statusses
        ### Drop the tmp
        $c->session->{zaaktype_edit}->{tmp}->{kenmerken} = {};
        $c->session->{zaaktype_edit}->{tmp}->{checklist_antwoorden} = {};
        $c->session->{zaaktype_edit}->{tmp}->{document_kenmerken} = {};
        $c->session->{zaaktype_edit}->{tmp}->{sjablonen} = {};
        $c->session->{zaaktype_edit}->{tmp}->{notificaties} = {};
        $c->session->{zaaktype_edit}->{tmp}->{zaaktype_kenmerken} = {};

        while (my ($statusnr, $statusdata) = each %{
                $c->session->{zaaktype_edit}->{status}
            }
        ) {
            if (
                $c->session->{zaaktype_edit}->{status}->{$statusnr}
                    ->{checklist} &&
                %{
                    $c->session->{zaaktype_edit}->{status}->{$statusnr}
                        ->{checklist}
                }
            ) {
                while (my ($i, $checklist) = each %{
                        $c->session->{zaaktype_edit}->{status}->{$statusnr}
                            ->{checklist}
                    }
                ) {
                    my $destination =
                        'status_checklist_vraag_' . $statusnr . '_' .  $i;

                    $c->session->{zaaktype_edit}->{tmp}->{checklist_antwoorden}
                        ->{$destination} = {
                            type            => $checklist->{antwoorden}->{type},
                            mogelijkheden   => (
                                UNIVERSAL::isa(
                                    $checklist->{antwoorden}->{mogelijkheden},
                                    'ARRAY'
                                ) ?  join("\n", @{
                                        $checklist->{antwoorden}->{mogelijkheden}
                                    })
                                    : ''
                            ),
                        };
                }
            }

            if (
                $c->session->{zaaktype_edit}->{status}->{$statusnr}
                    ->{subzaken} &&
                %{
                    $c->session->{zaaktype_edit}->{status}->{$statusnr}
                        ->{subzaken}
                }
            ) {
                while (my ($i, $subzaak) = each %{
                        $c->session->{zaaktype_edit}->{status}->{$statusnr}
                            ->{subzaken}
                    }
                ) {
                    my $destination =
                        'status_zaaktype_id_' . $statusnr . '_' .  $i;

                    $c->session->{zaaktype_edit}->{tmp}->{zaaktype_kenmerken}
                        ->{$destination} = {
                            eigenaar    => $subzaak->{eigenaar_type},
                            kopieren_kenmerken    => $subzaak->{kopieren_kenmerken},
                            status    => $subzaak->{status},
                        };
                }
            }
            if (
                $c->session->{zaaktype_edit}->{status}->{$statusnr}
                    ->{documenten} &&
                %{
                    $c->session->{zaaktype_edit}->{status}->{$statusnr}
                        ->{documenten}
                }
            ) {
                while (my ($i, $document) = each %{
                        $c->session->{zaaktype_edit}->{status}->{$statusnr}
                            ->{documenten}
                    }
                ) {
                    my $destination =
                        'status_document_name_' . $statusnr . '_' .  $i;

                    $c->session->{zaaktype_edit}->{tmp}->{document_kenmerken}
                        ->{$destination} =
                            $document->{kenmerken};

                }
            }
            if (
                $c->session->{zaaktype_edit}->{status}->{$statusnr}
                    ->{kenmerken} &&
                %{
                    $c->session->{zaaktype_edit}->{status}->{$statusnr}
                        ->{kenmerken}
                }
            ) {
                while (my ($i, $kenmerk) = each %{
                        $c->session->{zaaktype_edit}->{status}->{$statusnr}
                            ->{kenmerken}
                    }
                ) {
                    my $destination =
                        'status_kenmerk_id_' . $statusnr . '_' .  $i;

                    $c->session->{zaaktype_edit}->{tmp}->{kenmerken}
                        ->{$destination} = $kenmerk;

                    $c->log->debug('Ruua...Rurrrr...rRUAUAUAURARR');
                }
            }

            if (
                $c->session->{zaaktype_edit}->{status}->{$statusnr}
                    ->{sjablonen} &&
                %{
                    $c->session->{zaaktype_edit}->{status}->{$statusnr}
                        ->{sjablonen}
                }
            ) {
                while (my ($i, $sjabloon) = each %{
                        $c->session->{zaaktype_edit}->{status}->{$statusnr}
                            ->{sjablonen}
                    }
                ) {
                    my $destination =
                        'status_sjabloon_id_' . $statusnr . '_' .  $i;

                    $c->session->{zaaktype_edit}->{tmp}->{sjablonen}
                        ->{$destination} = $sjabloon;
                }
            }

            if (
                $c->session->{zaaktype_edit}->{status}->{$statusnr}
                    ->{notificaties} &&
                %{
                    $c->session->{zaaktype_edit}->{status}->{$statusnr}
                        ->{notificaties}
                }
            ) {
                while (my ($i, $notificatie) = each %{
                        $c->session->{zaaktype_edit}->{status}->{$statusnr}
                            ->{notificaties}
                    }
                ) {
                    my $destination =
                        'status_notificatie_id_' . $statusnr . '_' .  $i;

                    $c->session->{zaaktype_edit}->{tmp}->{notificaties}
                        ->{$destination} = $notificatie;
                }
            }
        }
    }

    $c->stash->{params} = $c->session->{zaaktype_edit};
    $c->stash->{template} = 'zaaktype/status/edit.tt';

}

sub antwoorden : Chained('/zaaktype/base'): PathPart('status/antwoorden'): Args(0) {
    my ($self, $c) = @_;

    if (%{ $c->req->params } && $c->req->params->{update}) {
        $c->session->{zaaktype_edit}->{tmp}->{checklist_antwoorden}
            ->{ $c->req->params->{destination} } = {
                'type'          => $c->req->params->{antwoord_type},
                'mogelijkheden' => $c->req->params->{antwoord_mogelijkheden}
            };
        $c->res->body('OK');
        return;
    }

    if (
        $c->session->{zaaktype_edit}->{tmp}->{checklist_antwoorden}
            ->{ $c->req->params->{destination} }
        ) {
        $c->stash->{history} =
                $c->session->{zaaktype_edit}->{tmp}->{checklist_antwoorden}
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
    $c->stash->{template}  = 'zaaktype/status/antwoorden.tt';
}

sub zaaktype_kenmerken : Chained('/zaaktype/base'): PathPart('status/zaaktype'): Args(0) {
    my ($self, $c) = @_;

    if (%{ $c->req->params } && $c->req->params->{update}) {
        $c->session->{zaaktype_edit}->{tmp}->{zaaktype_kenmerken}
            ->{ $c->req->params->{destination} } = {
                'eigenaar'              => $c->req->params->{deelvervolg_eigenaar},
                'kopieren_kenmerken'    => $c->req->params->{deelvervolg_kopieren_kenmerken},
                'status'                => $c->req->params->{deelvervolg_status},
            };
        $c->res->body('OK');
        return;
    }

    if (
        $c->session->{zaaktype_edit}->{tmp}->{zaaktype_kenmerken}
            ->{ $c->req->params->{destination} }
        ) {
        $c->stash->{history} =
                $c->session->{zaaktype_edit}->{tmp}->{zaaktype_kenmerken}
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
    $c->stash->{template}  = 'zaaktype/status/vervolgzaken.tt';
}

sub document_kenmerken : Chained('/zaaktype/base'): PathPart('status/document_kenmerken'): Args(0) {
    my ($self, $c) = @_;

    if (%{ $c->req->params } && $c->req->params->{update}) {
        $c->session->{zaaktype_edit}->{tmp}->{document_kenmerken}
            ->{ $c->req->params->{destination} } = {
                map {
                    my $label   = $_;
                    $label      =~ s/^kenmerk_//g;
                    $label      => $c->req->params->{ $_ }
                } grep(/^kenmerk_/, keys %{ $c->req->params })
            };
        $c->res->body('OK');
        return;
    }

    if (
        $c->session->{zaaktype_edit}->{tmp}->{document_kenmerken}
            ->{ $c->req->params->{destination} }
    ) {
        ### History should overwrite edit parameters
        $c->stash->{history} =
                $c->session->{zaaktype_edit}->{tmp}->{document_kenmerken}
                    ->{ $c->req->params->{destination} };
        $c->log->debug('Found history' . Dumper($c->stash->{history}));
    }

    $c->stash->{nowrapper} = 1;
    $c->stash->{template}  = 'zaaktype/status/document_kenmerken.tt';
}

sub kenmerken : Chained('/zaaktype/base'): PathPart('status/kenmerken'): Args(0) {
    my ($self, $c) = @_;

    if (%{ $c->req->params } && $c->req->params->{update}) {
        $c->session->{zaaktype_edit}->{tmp}->{kenmerken}
            ->{ $c->req->params->{destination} } = {
                map {
                    my $label   = $_;
                    $label      =~ s/^kenmerk_//g;
                    $label      => $c->req->params->{ $_ }
                } grep(/^kenmerk_/, keys %{ $c->req->params })
            };
        $c->res->body('OK');
        return;
    }

    if (
        $c->session->{zaaktype_edit}->{tmp}->{kenmerken}
            ->{ $c->req->params->{destination} }
    ) {
        ### History should overwrite edit parameters
        $c->stash->{history} =
                $c->session->{zaaktype_edit}->{tmp}->{kenmerken}
                    ->{ $c->req->params->{destination} };
        $c->log->debug('Found history' . Dumper($c->stash->{history}));
    }

    $c->stash->{nowrapper} = 1;
    $c->stash->{template}  = 'zaaktype/status/vervolgzaken.tt';
}

sub sjablonen : Chained('/zaaktype/base'): PathPart('status/sjablonen'): Args(0) {
    my ($self, $c) = @_;

    if (%{ $c->req->params } && $c->req->params->{update}) {
        $c->session->{zaaktype_edit}->{tmp}->{sjablonen}
            ->{ $c->req->params->{destination} } = {
                map {
                    my $label   = $_;
                    $label      =~ s/^sjabloon_//g;
                    $label      => $c->req->params->{ $_ }
                } grep(/^sjabloon_/, keys %{ $c->req->params })
            };
        $c->res->body('OK');
        return;
    }

    if (
        $c->session->{zaaktype_edit}->{tmp}->{sjablonen}
            ->{ $c->req->params->{destination} }
    ) {
        ### History should overwrite edit parameters
        $c->stash->{history} =
                $c->session->{zaaktype_edit}->{tmp}->{sjablonen}
                    ->{ $c->req->params->{destination} };
        $c->log->debug('Found history' . Dumper($c->stash->{history}));
    }

    $c->stash->{nowrapper} = 1;
    $c->stash->{template}  = 'zaaktype/status/sjablonen.tt';
}

sub notificaties : Chained('/zaaktype/base'): PathPart('status/notificaties'): Args(0) {
    my ($self, $c) = @_;

    if (%{ $c->req->params } && $c->req->params->{update}) {
        $c->session->{zaaktype_edit}->{tmp}->{notificaties}
            ->{ $c->req->params->{destination} } = {
                map {
                    my $label   = $_;
                    $label      =~ s/^notificatie_//g;
                    $label      => $c->req->params->{ $_ }
                } grep(/^notificatie_/, keys %{ $c->req->params })
            };
        $c->res->body('OK');
        return;
    }

    if (
        $c->session->{zaaktype_edit}->{tmp}->{notificaties}
            ->{ $c->req->params->{destination} }
    ) {
        ### History should overwrite edit parameters
        $c->stash->{history} =
                $c->session->{zaaktype_edit}->{tmp}->{notificaties}
                    ->{ $c->req->params->{destination} };
        $c->log->debug('Found history' . Dumper($c->stash->{history}));
    }

    $c->stash->{nowrapper} = 1;
    $c->stash->{template}  = 'zaaktype/status/notificaties.tt';
}

sub load_status_data : Private {
    my ($self, $c) = @_;
    my ($status);

    my $opts = $c->req->params;

    ### Make sure we have valid data
    my $args = {
        map {
            $_ => $opts->{ $_ }
        } grep(/status_.*?_\d+$/, keys %{ $opts })
    };

    ### Count statussen
    my (@statusses) = grep { $opts->{$_} }
        grep(/status_naam_\d+/, keys %{ $opts });

    my $statuscount = scalar(@statusses);
    for (my $i = 0; $i < @statusses; $i++) {
        $statusses[$i] =~ s/.*?(\d+)$/$1/g;
    }

    ### Sort it
    @statusses = sort { $a <=> $b } @statusses;

    ### Work it, by grouping
    my $count = 1;
    for my $rawnr (@statusses) {
        ### General data
        my $statusinfo = {
            'afhandeltijd'  => $args->{'status_afhandeltijd_' . $rawnr},
            'naam'          => $args->{'status_naam_' . $rawnr},
            #'org_eenheid_id' => $args->{'status_org_eenheid_id_' . $rawnr},
            'ou_id'         => $args->{'status_ou_id_' . $rawnr},
            'role_id'       => $args->{'status_role_id_' . $rawnr},
            'status'        => $count,
            'type'          => $args->{'status_type_' . $rawnr},
            'mail'          => {
                'onderwerp'     => $args->{
                    'status_communicatie_subject_' . $rawnr
                },
                'message'     => $args->{
                    'status_communicatie_message_' . $rawnr
                }
            },
            'has_checklist' => $args->{'status_has_checklist_' . $rawnr} || undef,
            'documenten'    => {},
            'checklist'     => {},
            'kenmerken'     => {},
        };

        ### Documents

        my @docs = grep(/status_document_name_${rawnr}_.*?/, keys %{ $args });

        for my $doc (@docs) {
            my $count = $doc;
            $count =~ s/status_document_name_.*?_//g;

            next unless (
                $count &&
                $args->{'status_document_name_' . $rawnr . '_' . $count}
            );

            my $name = lc($args->{
                'status_document_name_' . $rawnr . '_' . $count
            });
            $name =~ s/ /_/g;

            $statusinfo->{documenten}->{$count} = { 'name' => $name };

            if (
                $c->session->{zaaktype_edit}->{tmp}->{document_kenmerken}
                    ->{ 'status_document_name_' . $rawnr . '_' . $count }
            ) {
                $statusinfo->{documenten}->{$count}->{kenmerken} =
                    $c->session->{zaaktype_edit}->{tmp}
                            ->{document_kenmerken}->{
                                'status_document_name_' . $rawnr . '_' . $count
                            };
            }
        }


        ### Checklist
        my @checklist_data = grep(
            /status_checklist_vraag_${rawnr}_.*?/,
            keys %{ $args }
        );
        ### Sort it
        @checklist_data = sort { $a <=> $b } @checklist_data;

        my $checklist;
        for my $checkvraag (@checklist_data) {
            my $count = $checkvraag;
            $count =~ s/status_checklist_vraag_.*?_//g;

            next unless (
                $count &&
                $args->{'status_checklist_vraag_' . $rawnr . '_' . $count}
            );

            $checklist->{$count} = {
                'vraag'     => $args->{
                    'status_checklist_vraag_' . $rawnr . '_' . $count
                },
                'antwoord'  => {
                    'type'              => 'yesno',
                    'mogelijkheden'     => "Ja\nNee",
                },
            }
        }

        $statusinfo->{checklist} = $checklist;

        ### Subzaken
        my @subzaken_data = grep(
            /status_zaaktype_id_${rawnr}_.*?/,
            keys %{ $args }
        );
        ### Sort it
        @subzaken_data = sort { $a <=> $b } @subzaken_data;

        my $subzaken;
        for my $subzaak (@subzaken_data) {
            my $count = $subzaak;
            $count =~ s/status_zaaktype_id_.*?_//g;

            next unless (
                $count &&
                $args->{'status_zaaktype_id_' . $rawnr . '_' . $count}
            );

            ### Find this subzaak, and retrieve title
            my $dbsubzaak = $c->model('DB::ZaaktypeNode')->find(
                $args->{'status_zaaktype_id_' . $rawnr . '_' . $count}
            );

            next unless $dbsubzaak;

            $subzaken->{$count} = {
                'zaaktype_id'     => $args->{
                    'status_zaaktype_id_' . $rawnr . '_' . $count
                },
                'deelzaak'  => (
                    $args->{'status_zaaktype_deelgerelateerd_' . $rawnr . '_' . $count}
                        eq 'deel'
                        ? 1
                        : undef
                ),
                'gerelateerd'   => (
                    $args->{'status_zaaktype_deelgerelateerd_' . $rawnr . '_' . $count}
                        eq 'gerelateerd'
                        ? 1
                        : undef
                ),
                'mandatory'   => (
                    $args->{'status_zaaktype_mandatory_' . $rawnr . '_' .  $count}
                        ? 1
                        : undef
                ),
                'description'     => $dbsubzaak->titel,
                'eigenaar_type'   =>
                    $c->session->{zaaktype_edit}->{tmp}->{zaaktype_kenmerken}
                        ->{'status_zaaktype_id_' . $rawnr . '_' . $count}
                            ->{eigenaar},
                'kopieren_kenmerken'   =>
                    $c->session->{zaaktype_edit}->{tmp}->{zaaktype_kenmerken}
                        ->{'status_zaaktype_id_' . $rawnr . '_' . $count}
                            ->{kopieren_kenmerken},
                'status'   =>
                    $c->session->{zaaktype_edit}->{tmp}->{zaaktype_kenmerken}
                        ->{'status_zaaktype_id_' . $rawnr . '_' . $count}
                            ->{status},
                'start_delay'     =>
                    $args->{'status_zaaktype_start_' . $rawnr . '_'
                        . $count}
            }

        }

        $statusinfo->{subzaken} = $subzaken;

        ### Resultaatmogelijkheden
        my @resultaat_data = grep(
            /status_bewaren_resultaat_${rawnr}_.*?/,
            keys %{ $args }
        );
        ### Sort it
        @resultaat_data = sort { $a <=> $b } @resultaat_data;

        my $resultaten;
        for my $resultaat (@resultaat_data) {
            my $count = $resultaat;
            $count =~ s/status_bewaren_resultaat_.*?_//g;

            next unless (
                $count &&
                $args->{'status_bewaren_resultaat_' . $rawnr . '_' . $count}
            );

            $resultaten->{$count} = {
                'resultaat'    => $args->{
                    'status_bewaren_resultaat_' . $rawnr . '_' . $count
                },
                'bewaartermijn'    => $args->{
                    'status_bewaren_bewaartermijn_' . $rawnr . '_' . $count
                },
                'vtermijn'    => $args->{
                    'status_bewaren_vtermijn_' . $rawnr . '_' . $count
                },
                'dossiertype'    => $args->{
                    'status_bewaren_dossiertype_' . $rawnr . '_' . $count
                },
                'ingang'    => $args->{
                    'status_bewaren_ingang_' . $rawnr . '_' . $count
                },
            }
        }

        $statusinfo->{resultaten} = $resultaten;

        $statusinfo->{kenmerken} = $self->_load_kenmerken($c, $args, $rawnr);
        $statusinfo->{sjablonen} = $self->_load_sjablonen($c, $args, $rawnr);
        $statusinfo->{notificaties} = $self->_load_notificaties($c, $args, $rawnr);

        ### Save status
        $status->{$args->{'status_nr_' . $rawnr}} = $statusinfo;
        $count++;
    }

    $c->session->{zaaktype_edit}->{status} = $status;
}

sub _load_notificaties {
    my ($self, $c, $args, $rawnr) = @_;
    my (@notificaties_data);

    my @notificaties_data_raw  = grep(
        /status_notificatie_id_${rawnr}_.*/,
        keys %{ $args }
    );

    for (@notificaties_data_raw) {
        $_ =~ s/status_notificatie_id_.*?_//g;

        push(
            @notificaties_data,
            $_
        );
    }

    ### Sort it
    @notificaties_data = sort { $a <=> $b } @notificaties_data;

    my $notificaties;
    my $realcount = 0;
    for my $count (@notificaties_data) {
        $c->log->debug('Loop over notificatie nr: ' . $count);

        next unless (
            $count &&
            $args->{'status_notificatie_id_' . $rawnr . '_' . $count}
        );

        $c->log->debug('Loop continue over notificatie nr: ' . $count);

        $realcount++;
        $notificaties->{$realcount} = {
            'label'             => $args->{
                'status_notificatie_id_' . $rawnr . '_' . $count
            },
        };

        if (
            $c->session->{zaaktype_edit}->{tmp}->{notificaties}->{
                'status_notificatie_id_' . $rawnr . '_' . $count
            }
        ) {
            $notificaties->{$realcount}->{'rcpt'}
                =   $c->session->{zaaktype_edit}->{tmp}->{notificaties}->{
                        'status_notificatie_id_' . $rawnr . '_' . $count
                    }->{rcpt};
            if ($notificaties->{$realcount}->{'rcpt'} eq 'behandelaar') {
                $notificaties->{$realcount}->{'email'}
                    =   $c->session->{zaaktype_edit}->{tmp}->{notificaties}->{
                            'status_notificatie_id_' . $rawnr . '_' . $count
                        }->{ztc_aanvrager_id};
            } elsif ($notificaties->{$realcount}->{'rcpt'} eq 'overig') {
                $notificaties->{$realcount}->{'email'}
                    =   $c->session->{zaaktype_edit}->{tmp}->{notificaties}->{
                            'status_notificatie_id_' . $rawnr . '_' . $count
                        }->{email};
            }
            $notificaties->{$realcount}->{'onderwerp'}
                =   $c->session->{zaaktype_edit}->{tmp}->{notificaties}->{
                        'status_notificatie_id_' . $rawnr . '_' . $count
                    }->{onderwerp};
            $notificaties->{$realcount}->{'bericht'}
                =   $c->session->{zaaktype_edit}->{tmp}->{notificaties}->{
                        'status_notificatie_id_' . $rawnr . '_' . $count
                    }->{bericht};
            $notificaties->{$realcount}->{'intern_block'}
                =   $c->session->{zaaktype_edit}->{tmp}->{notificaties}->{
                        'status_notificatie_id_' . $rawnr . '_' . $count
                    }->{intern_block};
        };
    }

    return $notificaties if $notificaties;
    return {};
}

sub _load_sjablonen {
    my ($self, $c, $args, $rawnr) = @_;
    my (@sjablonen_data);

    my @sjablonen_data_raw  = grep(
        /status_sjabloon_id_${rawnr}_.*/,
        keys %{ $args }
    );

    for (@sjablonen_data_raw) {
        $_ =~ s/status_sjabloon_id_.*?_//g;

        push(
            @sjablonen_data,
            $_
        );
    }

    ### Sort it
    @sjablonen_data = sort { $a <=> $b } @sjablonen_data;

    my $sjablonen;
    my $realcount = 0;
    for my $count (@sjablonen_data) {
        $c->log->debug('Loop over sjabloon nr: ' . $count);

        next unless (
            $count &&
            $args->{'status_sjabloon_id_' . $rawnr . '_' . $count}
        );

        ### Find this sjabloon, and retrieve title
        my $dbsjabloon = $c->model('DB::BibliotheekSjablonen')->find(
            $args->{'status_sjabloon_id_' . $rawnr . '_' . $count}
        );
        next unless $dbsjabloon;     # Should be impossible
        $c->log->debug('Loop continue over sjabloon nr: ' . $count);

        $realcount++;
        $sjablonen->{$realcount} = {
            'id'                => $args->{
                'status_sjabloon_id_' . $rawnr . '_' . $count
            },
            'bibliotheek_id'    => $args->{
                'status_sjabloon_id_' . $rawnr . '_' . $count
            },
            'naam'              => $dbsjabloon->naam,
        };

        if (
            $c->session->{zaaktype_edit}->{tmp}->{sjablonen}->{
                'status_sjabloon_id_' . $rawnr . '_' . $count
            }
        ) {
            $sjablonen->{$realcount}->{'help'}
                =   $c->session->{zaaktype_edit}->{tmp}->{sjablonen}->{
                        'status_sjabloon_id_' . $rawnr . '_' . $count
                    }->{help};
            $sjablonen->{$realcount}->{'verplicht'}
                =   $c->session->{zaaktype_edit}->{tmp}->{sjablonen}->{
                        'status_sjabloon_id_' . $rawnr . '_' . $count
                    }->{verplicht};
            $sjablonen->{$realcount}->{'automatisch_genereren'}
                =   $c->session->{zaaktype_edit}->{tmp}->{sjablonen}->{
                        'status_sjabloon_id_' . $rawnr . '_' . $count
                    }->{automatisch_genereren};
        };
    }

    return $sjablonen if $sjablonen;
    return {};
}

sub _load_kenmerken {
    my ($self, $c, $args, $rawnr) = @_;
    my (@kenmerken_data);

    my @kenmerken_data_raw  = grep(
        /status_kenmerk_id_${rawnr}_.*/,
        keys %{ $args }
    );

    $c->log->debug('Loading kenmerken: ' . Dumper(@kenmerken_data_raw));
    for (@kenmerken_data_raw) {
        $_ =~ s/status_kenmerk_id_.*?_//g;

        push(
            @kenmerken_data,
            $_
        );
    }

    ### Sort it
    @kenmerken_data = sort { $a <=> $b } @kenmerken_data;

    my $kenmerken;
    my $realcount = 0;
    for my $count (@kenmerken_data) {
        $c->log->debug('Loop over kenmerk nr: ' . $count);

        next unless (
            $count &&
            $args->{'status_kenmerk_id_' . $rawnr . '_' . $count}
        );

        ### Find this kenmerk, and retrieve title
        my $dbkenmerk = $c->model('DB::BibliotheekKenmerken')->find(
            $args->{'status_kenmerk_id_' . $rawnr . '_' . $count}
        );
        next unless $dbkenmerk;     # Should be impossible
        $c->log->debug('Loop continue over kenmerk nr: ' . $count);

        $realcount++;
        $kenmerken->{$realcount} = {
            'id'                    => $args->{
                'status_kenmerk_id_' . $rawnr . '_' . $count
            },
            'bibliotheek_id'        => $args->{
                'status_kenmerk_id_' . $rawnr . '_' . $count
            },
            'naam'                  => $dbkenmerk->naam,
            'zaakinformatie_view'   => (
                $dbkenmerk->value_type eq 'file'
                    ? 0
                    : 1
            ),
        };

        if (
            $c->session->{zaaktype_edit}->{tmp}->{kenmerken}->{
                'status_kenmerk_id_' . $rawnr . '_' . $count
            }
        ) {
            $kenmerken->{$realcount}->{'label'}
                =   $c->session->{zaaktype_edit}->{tmp}->{kenmerken}->{
                        'status_kenmerk_id_' . $rawnr . '_' . $count
                    }->{label};
            $kenmerken->{$realcount}->{'help'}
                =   $c->session->{zaaktype_edit}->{tmp}->{kenmerken}->{
                        'status_kenmerk_id_' . $rawnr . '_' . $count
                    }->{help};
            $kenmerken->{$realcount}->{'verplicht'}
                =   $c->session->{zaaktype_edit}->{tmp}->{kenmerken}->{
                        'status_kenmerk_id_' . $rawnr . '_' . $count
                    }->{verplicht};
            $kenmerken->{$realcount}->{'pip'}
                =   $c->session->{zaaktype_edit}->{tmp}->{kenmerken}->{
                        'status_kenmerk_id_' . $rawnr . '_' . $count
                    }->{pip};
            $kenmerken->{$realcount}->{'document_categorie'}
                =   $c->session->{zaaktype_edit}->{tmp}->{kenmerken}->{
                        'status_kenmerk_id_' . $rawnr . '_' . $count
                    }->{document_categorie};
            $kenmerken->{$realcount}->{'zaakinformatie_view'}
                =   $c->session->{zaaktype_edit}->{tmp}->{kenmerken}->{
                        'status_kenmerk_id_' . $rawnr . '_' . $count
                    }->{zaakinformatie_view};
        };
    }

    return $kenmerken;
}

sub kenmerken_definitie : Chained('/zaaktype/base'): PathPart('status/kenmerken_definitie'): Args() {
    my ($self, $c, $statusid, $kenmerkid) = @_;

    if (%{ $c->req->params } && $c->req->params->{update}) {
        $c->session->{zaaktype_edit}->{tmp}->{kenmerken}
            ->{ $c->req->params->{uniqueidr} } = {
                map {
                    my $label   = $_;
                    $label      =~ s/^kenmerk_//g;
                    $label      => $c->req->params->{ $_ }
                } grep(/^kenmerk_/, keys %{ $c->req->params })
            };
        $c->res->body('OK');
        return;
    } elsif (
        !$c->session->{zaaktype_edit}->{tmp}->{kenmerken} ->{
                $c->req->params->{uniqueidr}
            }
    ) {
        my $kenmerk = $c->model('Bibliotheek::Kenmerken')->get(
            'id'    => $c->req->params->{uniqueidrval}
        );

        if ($kenmerk) {
            $c->session->{zaaktype_edit}->{tmp}->{kenmerken}->{
                $c->req->params->{uniqueidr}
            }->{help} = $kenmerk->{kenmerk_help};
            $c->session->{zaaktype_edit}->{tmp}->{kenmerken}->{
                $c->req->params->{uniqueidr}
            }->{type} = $kenmerk->{kenmerk_type};
            $c->session->{zaaktype_edit}->{tmp}->{kenmerken}->{
                $c->req->params->{uniqueidr}
            }->{document_categorie} = $kenmerk->{kenmerk_document_categorie};
            $c->session->{zaaktype_edit}->{tmp}->{kenmerken}->{
                $c->req->params->{uniqueidr}
            }->{zaakinformatie_view} = $kenmerk->{kenmerk_zaakinformatie_view};
        }
    }

    if (
        $c->session->{zaaktype_edit}->{tmp}->{kenmerken}
            ->{ $c->req->params->{uniqueidr} }
    ) {
        ### History should overwrite edit parameters
        $c->stash->{history} =
                $c->session->{zaaktype_edit}->{tmp}->{kenmerken}
                    ->{ $c->req->params->{uniqueidr} };
    }

    $c->log->debug('la history: ' . Dumper($c->stash->{history}));

    $c->stash->{nowrapper} = 1;

    ## Check for uniqueidrvalue
    $c->stash->{template}  = 'zaaktype/status/kenmerken_definitie.tt';
}

sub sjablonen_definitie : Chained('/zaaktype/base'): PathPart('status/sjablonen_definitie'): Args() {
    my ($self, $c, $statusid) = @_;

    if (%{ $c->req->params } && $c->req->params->{update}) {
        $c->session->{zaaktype_edit}->{tmp}->{sjablonen}
            ->{ $c->req->params->{uniqueidr} } = {
                map {
                    my $label   = $_;
                    $label      =~ s/^sjabloon_//g;
                    $label      => $c->req->params->{ $_ }
                } grep(/^sjabloon_/, keys %{ $c->req->params })
            };
        $c->res->body('OK');
        return;
    }

    if (
        $c->session->{zaaktype_edit}->{tmp}->{sjablonen}
            ->{ $c->req->params->{uniqueidr} }
    ) {
        ### History should overwrite edit parameters
        $c->stash->{history} =
                $c->session->{zaaktype_edit}->{tmp}->{sjablonen}
                    ->{ $c->req->params->{uniqueidr} };
    }

    $c->stash->{nowrapper} = 1;
    $c->stash->{template}  = 'zaaktype/status/sjablonen_definitie.tt';
}

sub notificatie_definitie : Chained('/zaaktype/base'): PathPart('status/notificatie_definitie'): Args() {
    my ($self, $c, $statusid) = @_;

    if (%{ $c->req->params } && $c->req->params->{update}) {
        $c->session->{zaaktype_edit}->{tmp}->{notificaties}
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

    if (
        $c->session->{zaaktype_edit}->{tmp}->{notificaties}
            ->{ $c->req->params->{uniqueidr} }
    ) {
        ### History should overwrite edit parameters
        $c->stash->{history} =
                $c->session->{zaaktype_edit}->{tmp}->{notificaties}
                    ->{ $c->req->params->{uniqueidr} };
    }

    ### Behandelaar of overig
    if ($c->stash->{history}->{rcpt} eq 'behandelaar') {
        if (
            !$c->session->{zaaktype_edit}->{tmp}->{notificaties}
                ->{ $c->req->params->{uniqueidr} }->{ztc_aanvrager_id} &&
            $c->session->{zaaktype_edit}->{tmp}->{notificaties}
                ->{ $c->req->params->{uniqueidr} }->{email}
        ) {
            $c->session->{zaaktype_edit}->{tmp}->{notificaties}
                ->{ $c->req->params->{uniqueidr} }->{ztc_aanvrager_id}
                = $c->session->{zaaktype_edit}->{tmp}->{notificaties}
                    ->{ $c->req->params->{uniqueidr} }->{email};
        }

        if (
            ! $c->session->{zaaktype_edit}->{tmp}->{notificaties}
                ->{ $c->req->params->{uniqueidr} }->{ztc_aanvrager} &&
            $c->session->{zaaktype_edit}->{tmp}->{notificaties}
                ->{ $c->req->params->{uniqueidr} }->{ztc_aanvrager_id}
        ) {
            my $beh = $c->model('Betrokkene')->get(
                {},
                $c->session->{zaaktype_edit}->{tmp}->{notificaties}
                    ->{ $c->req->params->{uniqueidr} }->{ztc_aanvrager_id}
            );

            if ($beh) {
                $c->session->{zaaktype_edit}->{tmp}->{notificaties}
                    ->{ $c->req->params->{uniqueidr} }->{ztc_aanvrager}
                        = $beh->naam;
            }
        }
    }

    $c->stash->{nowrapper} = 1;
    $c->stash->{template}  = 'zaaktype/status/notificatie_definitie.tt';
}

#sub get_role_by_organisation
#    : Chained('/zaaktype/base'):
#    : PathPart('status/get_role_by_organisation')
#    : Args() {
#{
#    my ( $self, $c )        = @_;
#
#    my $suggestion = $c->model('Beheer::Bibliotheek::Kenmerken')
#       ->generate_magic_string($c->req->params->{naam});
#    $c->res->body($suggestion);
#}



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

