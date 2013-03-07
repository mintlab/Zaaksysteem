package Zaaksysteem::Controller::Zaak::Documents;

use strict;
use warnings;
use Data::Dumper;
use Zaaksysteem::Constants;

use parent 'Zaaksysteem::Controller::Documents';
use File::Basename;
use File::stat;
use Text::Wrap;
use Email::Valid;

use constant LOGGING_ZAAK_DOCUMENTS_QUEUE => 'zaak_documents_queue';

my $DOCUMENT_TYPES = {
    file        => {
        'modelargs' => [qw/
            category
            documenttype
            filename
            post_registratie
            verplicht
            catalogus
        /],
        'profile'   => {
            required    => [qw/
                documenttype
                category
                filename
            /],
            optional    => [qw/
                intern
                post_registratie
                verplicht
                catalogus
            /],
        },
    },
    sjabloon    => {
        'modelargs' => [qw/
            category
            documenttype
            filename
            post_registratie
            verplicht
            catalogus
            help
        /],
        'profile'   => {
            required    => [qw/
                documenttype
                category
                filename
            /],
            optional    => [qw/
                intern
                post_registratie
                verplicht
                catalogus
            /],
        },
    },
    mail        => {
        'modelargs' => [qw/
            documenttype
            subject
            message
            rcpt
        /],
        'profile'   => {
            required    => [qw/
                documenttype
                subject
                message
                rcpt_type
            /],
            optional    => [qw/
                rcpt
            /],
            constraint_methods => {
                'rcpt'      => sub {
                    my ($dfv, $val) = @_;

                    return 1 if
                        $val =~ /^betrokkene-/;

                    return 1 if !$val;

                    return;
                },
            }
        },
    },
};




{
    sub queue_action_accepteer: Chained('documents'): PathPart('accepteer'): Args(1) {
        my ( $self, $c, $id) = @_;

        $c->response->redirect(
            $c->uri_for(
                '/zaak/' . $c->stash->{zaak}->nr,
                undef,
                {
                    current_element     => 'documents',
                    documentdepth       => (
                        $c->stash->{document_depth}
                            ? $c->stash->{document_depth}
                            : 0
                    ),
                }
            )
        );

        $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');

        ### Post
        if ( $id ) {
            my $document;

            unless ($document = $c->stash->{zaak}->documents->find($id)) {
                $c->flash->{result} = 'Document niet onderdeel van deze zaak';
                $c->detach;
            }

            unless ($document->queue) {
                $c->flash->{result} = 'Document niet onderdeel van de wachtrij';
                $c->detach;
            }

            $document->queue(undef);
            $document->update;

            $c->flash->{result} = 'Document geaccepteerd.';
            $c->detach;

        }
    }
}

{
    sub queue_action_weiger: Chained('documents'): PathPart('weiger'): Args(1) {
        my ( $self, $c, $id) = @_;

        if ($id =~ /^\d+$/) {
            $c->stash->{document} = 
                $c->stash->{zaak}->documents->find(
                    $id
                );
        }

        if (
            my $dv = $c->forward('/page/dialog', [{
                validatie       => {
                    optional    => [qw/omschrijving/],
                    required    => [qw//],
                },
                permissions     => [qw/zaak_beheer zaak_edit/],
                template        => 'zaak/widgets/weiger_document.tt',
                complete_url    => $c->uri_for(
                    '/zaak/' . $c->stash->{zaak}->nr,
                    undef,
                    {
                        current_element     => 'documents',
                        documentdepth       => (
                            $c->stash->{document_depth}
                                ? $c->stash->{document_depth}
                                : 0
                        ),
                    }
                )
            }])
        ) {
            my $params  = $dv->valid;

            my $document;
            unless ($document   = $c->stash->{document}) {
                $c->flash->{result} = 'Document niet onderdeel van deze zaak';
                $c->detach;
            }

            unless ($document->queue) {
                $c->flash->{result} = 'Document niet onderdeel van de wachtrij';
                $c->detach;
            }

            if (
                $c->forward(
                    '/zaak/intake/redrop_document', 
                    [$id, { omschrijving => $dv->valid('omschrijving') } ]
                )
            ) {
                $document->delete;
            }

            my $logmsg = 'Document "' . $document->filename . '"'
                . ' geweigerd' . ( $dv->valid('omschrijving')
                    ? ': ' . $dv->valid('omschrijving')
                    : '.'
                );

            ### Make a note about it
            $c->stash->{zaak}->logging->add({
                component       => LOGGING_ZAAK_DOCUMENTS_QUEUE,
                component_id    => $id,
                onderwerp       => $logmsg,
            });

            $c->flash->{result} = $logmsg;

            $c->log->info(
                'Zaak[' . $c->stash->{zaak}->id . ']: ' . $logmsg
            );
        }

        ### VAlidation
#        if (
#            $c->req->header("x-requested-with") eq 'XMLHttpRequest' &&
#            $c->req->params->{do_validation}
#        ) {
#            $c->zvalidate;
#            $c->detach;
#        }
#
#        ### Post
#        if (
#            %{ $c->req->params } &&
#            $c->req->params->{confirmed}
#        ) {
#            $c->response->redirect(
#                $c->uri_for(
#                    '/zaak/' . $c->stash->{zaak}->nr,
#                    undef,
#                    {
#                        current_element     => 'documents',
#                        documentdepth       => (
#                            $c->stash->{document_depth}
#                                ? $c->stash->{document_depth}
#                                : 0
#                        ),
#                    }
#                )
#            );
#
#
#            my $document;
#            unless ($document = $c->stash->{zaak}->documents->find($id)) {
#                $c->flash->{result} = 'Document niet onderdeel van deze zaak';
#                $c->detach;
#            }
#
#            unless ($document->queue) {
#                $c->flash->{result} = 'Document niet onderdeel van de wachtrij';
#                $c->detach;
#            }
#
#            if ($c->forward('/zaak/intake/redrop_document/' . $id)) {
#                $document->delete;
#            }
#
#
#            #$document->queue(undef);
#            #$document->update;
#            ### Make a note about it
#            $c->stash->{zaak}->logging->add({
#                component       => LOGGING_ZAAK_DOCUMENTS_QUEUE,
#                component_id    => $id,
#                onderwerp       => 'Document "' . $document->filename . '"'
#                    . ' geweigerd.'
#            });
#
#            $c->flash->{result} = 'Document geweigerd.';
#            $c->detach;
#
#        }
#
#        $c->stash->{confirmation}->{message}    =
#            'Weet u zeker dat u dit document wilt weigeren?';
#
#        $c->stash->{confirmation}->{type}       = 'yesno';
#        $c->stash->{confirmation}->{uri}        =
#            $c->uri_for(
#                    '/zaak/' . $c->stash->{zaak}->nr . '/documents/'
#                    . (
#                            $c->stash->{document_depth}
#                                ? $c->stash->{document_depth}
#                                : 0
#                    ) . '/weiger/' . $id
#            );
#
#
#        $c->forward('/page/confirmation');
#        $c->detach;
    }
}


sub view :Chained('documents') : PathPart(''): Args(0) {
    my ( $self, $c, $id ) = @_;

    $c->stash->{current_element} = 'documents';
}

sub documents :Chained('/zaak/base') : PathPart('documents'): CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash->{current_element} = 'documents';


    ### Legacy?
    $c->stash->{document_depth} = $c->stash->{zaak}->documents->find($id);
}

sub get_meta :Chained('documents') : PathPart('get_meta'): Args(1) {
    my ( $self, $c, $id ) = @_;

    my $document = $c->stash->{zaak}->documents->find($id);

    $c->stash->{document} = $document;

    $c->stash->{template} = 'zaak/elements/dialog/documents_meta_view.tt';
}

sub show :Chained('documents') : PathPart('show'): Args(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash->{current_element} = 'documents';

    my $document = $c->stash->{zaak}->documents->find($id);

    my $mail = $document->documents_mails->first;

    if ($mail->rcpt =~ /betrokkene-/) {
        my $rcpto = $c->model('Betrokkene')->get(
            {},
            $mail->rcpt
        );

        $c->stash->{rcpt} = $rcpto->naam;
    } else {
        $c->stash->{rcpt} = $c->stash->{zaak}->aanvrager->naam;
    }

    $c->stash->{document} = $document;
    $c->stash->{mail} = $mail;

    $c->stash->{nowrapper}  = 1;
    $c->stash->{template}   = 'zaak/elements/dialog/documents_show.tt';
}

sub get_by_kenmerk_id : Chained('documents') : PathPart('get_by_kenmerk_id'): Args() {


}


sub get :Chained('documents') : PathPart('get'): Args() {
    my ( $self, $c, $id ) = @_;
    my ($stat);

$c->log->debug("id: " . $id);
    $c->stash->{current_element} = 'documents';

    my $search_opts = {
        all_documents       => 1,
        id                  => $id,
        search_recursive    => 1,
        zaak_id             => $c->stash->{zaak}->id,
    };

    ### PIP security
    $search_opts->{pip} = 1 if $c->stash->{pip};
    $search_opts->{pip} = 1 unless $c->user_exists;

    my $documents = $c->model('Documents')->list($search_opts);

    my $continue = $documents->first;

    (
        $c->log->debug('Geen document met dit ID gevonden onder deze zaak'),
        return
    ) unless $continue;

    my $filename = $c->config->{'files'} . '/documents/' . $id;

    (
        $c->log->debug('Geen bestand gevonden op disk'),
        return
    ) unless ($stat = stat($filename));

    $c->log->debug('mimetype: ' . $continue->mimetype . ' filetype: ' .
        $c->req->params->{filetype});

    if (
        $continue->mimetype eq 'application/vnd.oasis.opendocument.text' &&
        !$c->req->params->{filetype}
    ) {
        $c->stash->{nowrapper} = 1;
        $c->stash->{document} = $continue;
        $c->stash->{template}   = 'zaak/elements/dialog/view_sjabloon.tt';
        $c->detach;
    } elsif (
        $continue->mimetype eq 'application/vnd.oasis.opendocument.text'
    ) {
        $c->model('Bibliotheek::Sjablonen')->download_sjabloon(
            document_id     => $continue->id,
            output_filetype => $c->req->params->{filetype},
            filename        => $continue->filename,
            mimetype        => $continue->mimetype,
        );
        return;
    }

    $c->serve_static_file($c->config->{'files'} . '/documents/' . $id);

    $c->res->headers->content_length( $stat->size );
    $c->res->headers->content_type($continue->mimetype);
    $c->res->content_type($continue->mimetype);

    return;
}

sub del :Chained('documents') : PathPart('del'): Args(1) {
    my ( $self, $c, $id ) = @_;
    my ($pid);

    $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');
    #$c->assert_permission(qw/zaak_edit zaak_admin/);

    if ($c->req->params->{confirmed}) {
        return unless $c->can_change();
        if ($c->stash->{document_depth}) {
            $pid = $c->stash->{document_depth}->id;
        } else {
            $pid = undef;
        }

        my $document = $c->stash->{zaak}->documents->find($id)
            or return;

        $document->deleted_on(DateTime->now());
        if ($document->update) {
            $c->flash->{result} = 'Document succesvol verwijderd';

            $c->stash->{zaak}->logging->add({
                'component'     => LOGGING_COMPONENT_DOCUMENT,
                'component_id'  => $document->id,
                'onderwerp'     => 'Document "'
                    . $document->filename . '" ['
                    . $document->id . '] succesvol '
                    . 'verwijderd'
            });
        }

        $c->response->redirect(
            $c->uri_for(
                '/zaak/' . $c->stash->{zaak}->nr,
                undef,
                {
                    current_element     => 'documents',
                    documentdepth       => (
                        $c->stash->{document_depth}
                            ? $c->stash->{document_depth}
                            : 0
                    ),
                }
            )
        );
        $c->detach;
    }

    $c->stash->{confirmation}->{message}    =
        'Weet u zeker dat u dit document wilt verwijderen?'
        . ' Deze actie kan niet ongedaan gemaakt worden.';

    $c->stash->{confirmation}->{type}       = 'yesno';
    $c->stash->{confirmation}->{uri}        =
        '/zaak/' . $c->stash->{zaak}->nr . '/documents/'
        . ($c->stash->{document_depth} ? $c->stash->{document_depth}->id : 0)
        . '/del/' . $id;

    #$c->stash->{confirmation}->{params}     = {
    #    'document_id'   => $id
    #};

    $c->forward('/page/confirmation');
    $c->detach;
}

sub update :Chained('documents') : PathPart('update'): Args() {
    my ( $self, $c ) = @_;

    $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');

    return unless $c->can_change();
    $c->response->redirect(
        $c->uri_for(
            '/zaak/' . $c->stash->{zaak}->nr,
            undef,
            {
                current_element     => 'documents',
                documentdepth       => $c->stash->{document_depth},
            }
        )
    );

    unless (exists($c->req->params->{private})) {
        $c->detach;
    }

    $c->stash->{zaak}->documents->update(
        $c->req->params->{private},
        $c->stash->{document_depth}
    );


    $c->detach;
}

sub edit :Chained('documents') : PathPart('edit'): Args(1) {
    my ( $self, $c, $id ) = @_;

    $c->assert_any_zaak_permission('zaak_beheer','zaak_edit');

    ### Authorization ok?
    return unless $c->can_change();

    my $document = $c->model('DB::Documents')->find($id);

    $c->stash->{mappen} = $c->model('Documents')->list({
        search_recursive    => 1,
        alleen_mappen       => 1,
        zaak_id             => $c->stash->{zaak}->id
    });

    my $filename = $document->filename;

    my ($basename,$path,$suffix) = fileparse($filename, qr/\.[^.]*/);
    $c->stash->{'filename_without_extension'} = $basename;
    $c->stash->{'filename_extension'} = $suffix || '';
    
    $c->stash->{document} = $document;

    $c->stash->{template} = 'zaak/elements/dialog/documents_edit_file.tt';


    if (%{ $c->req->params } && $c->req->params->{documenttype}) {
        $c->forward('add_file');

        $c->response->redirect(
            $c->uri_for(
                '/zaak/' . $c->stash->{zaak}->nr,
                undef,
                {
                    current_element     => 'documents',
                    documentdepth       => (
                        $c->stash->{document_depth}
                            ? $c->stash->{document_depth}->id
                            : undef
                    )
                }
            )
        );

    }
}

sub sjabloon_suggestion :Chained('documents') : PathPart('suggest'): Args() {
    my ( $self, $c) = @_;

    ### Sjabloon:
    my $zaaktype_sjabloon = 
        $c->model('DB::ZaaktypeSjablonen')->find(
            $c->req->params->{naam}
        );

    my $sjabloon = $zaaktype_sjabloon->bibliotheek_sjablonen_id;
#    my $sjabloon        = $c->model('Bibliotheek::Sjablonen')->retrieve(
#        id => $c->req->params->{naam},
#    );

    if (!$sjabloon) {
        $c->res->body('');
        $c->detach;
    }

    my $sjabloon_naam   = $sjabloon->naam;

    my $sjabloon_ok         = 0;
    my $sjabloon_counter    = 0;
    while (!$sjabloon_ok) {
        my $rv = $c->model('DB::Documents')->search({
            filename        => $sjabloon_naam . '.odt',
            'zaak_id'       => $c->stash->{zaak}->nr,
            'deleted_on'    => undef
        });

        $c->log->debug('Sjabloon suggestion');

        if (!$rv->count) {
            $sjabloon_ok  = 1;
        } else {
            $c->log->debug('Sjabloon taken, new one');
            if ($sjabloon_counter > 0) {
                $sjabloon_naam =~ s/$sjabloon_counter$//;
            }
            $sjabloon_naam     .= ++$sjabloon_counter;
        }
    }

    $c->stash->{json} = {
        'suggestie'     => $sjabloon_naam,
        'toelichting'   => $zaaktype_sjabloon->help,
    };

    $c->forward('Zaaksysteem::View::JSON');
}

sub get_catalogus_waarden : Chained('/zaak/base') : PathPart('get_catalogus_waarden'): Args(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash->{json} = {
        catalogus   => {
            'id'        => undef,
            'pip'       => undef,
            'verplicht' => undef,
        }
    };

#    $c->detach('Zaaksysteem::View::JSON') unless (
#        $c->req->header("x-requested-with") eq 'XMLHttpRequest' &&
#        $c->req->params->{json_response}
#    );

    ### XML Request, get doc
    my $definitie;
    if (!$c->stash->{zaak}) {
        $c->detach unless $c->req->params->{zaakdefinitie};

        $definitie  = $c->model('DB::ZaaktypeNode')->find(
            $c->req->params->{zaakdefinitie}
        );
    } else {
        $definitie = $c->stash->{zaak}->zaaktype_node_id;
    }

    my $zaaktype_document   = $definitie->zaaktype_kenmerken->find($id)
        or $c->detach('Zaaksysteem::View::JSON');

    $c->stash->{json}->{catalogus} = {
        'id'        => $id,
        'pip'       => $zaaktype_document->pip,
        'verplicht' => $zaaktype_document->value_mandatory,
        'categorie' => $zaaktype_document->kenmerken_categorie
    };

    $c->forward('Zaaksysteem::View::JSON');
}

sub mapadd :Chained('documents') : PathPart('mapadd'): Args() {
    my ( $self, $c, $type ) = @_;

    $c->stash->{nowrapper} = 1;
    $c->stash->{template} = 'zaak/elements/dialog/map_add.tt'
}

sub add :Chained('documents') : PathPart('add'): Args() {
    my ( $self, $c, $type ) = @_;

    ### Authorization ok?
    return unless $c->can_change();

    ### No post? detach with type
    unless (%{ $c->req->params } && $c->req->params->{documenttype}) {
        (
            $c->log->debug(
                'DOC->add: No documenttype given, don\'t know what to show'
            ),
            $c->res->redirect($c->uri_for('/zaak/' . $c->stash->{zaak}->id)),
            $c->detach
        ) unless $type;

        (
            $c->log->debug(
                'DOC->add: Invalid DOCUMENT_TYPE given'
            ),
            $c->res->redirect($c->uri_for('/zaak/' . $c->stash->{zaak}->id)),
            $c->detach
        ) unless ( grep { $type eq $_ } keys %{ ZAAKSYSTEEM_CONSTANTS->{document}->{types} });

        ### XXX MAIL SPECIFIC
        {
            if ($type eq 'mail') {
                $c->stash->{nowrapper}  = 1;
                $c->stash->{mailconcept} = $c->view('TT')->render(
                    $c,
                    'tpl/zaak_v1/nl_NL/email/documents/mail.txt',
                );
                #$c->stash->{mailcontent}->{medewerker}  = '';
            }
        }

        $c->stash->{nowrapper}  = 1;
        $c->stash->{template}   = 'zaak/elements/dialog/documents_edit_' . $type . '.tt';
        $c->detach;
    }

    ###
    ### POST!!
    ###
    $type = $c->req->params->{documenttype};

    ### Got a type for profile?
    (
        $c->log->debug(
            'DOC->add: No documenttype given, don\'t know what to work on'
        ),
        $c->res->redirect( $c->uri_for('/zaak/' . $c->stash->{zaak}->id) ),
        $c->detach
    ) unless (
        exists(ZAAKSYSTEEM_CONSTANTS->{document}->{types}->{$type}) &&
        ZAAKSYSTEEM_CONSTANTS->{document}->{types}->{$type}
    );

    ### Common handling done, Move to documenttype handling
    if ($type eq 'dir') {
        $c->forward('add_file');
    } else {
        $c->forward('add_' . $type);
    }
    $c->response->redirect(
        $c->uri_for(
            '/zaak/' . $c->stash->{zaak}->nr
            . (
                $c->stash->{document_depth}
                    ? 'documentdepth=' .  $c->stash->{document_depth}
                    : ''
            ) . '#zaak-elements-documents',
        )
    );

}

sub add_sjabloon : Private {
    my ($self, $c) = @_;

    return unless $c->req->params->{sjabloon_id};

    my $type = $c->req->params->{documenttype};

    my %add_args = map { $_ => $c->req->params->{ $_ } }
        @{ $DOCUMENT_TYPES->{$type}->{modelargs} };

    $add_args{pid} = $c->stash->{document_depth}->id
        if $c->stash->{document_depth};

    ### ZAAKstatus, TODO MOVE TO MODEL
    $add_args{'zaakstatus'} = $c->stash->{'zaak'}->huidige_fase->status;

    my $zaaktype_sjabloon = 
        $c->model('DB::ZaaktypeSjablonen')->find(
            $c->req->params->{sjabloon_id}
        );

    my $sjabloon = $zaaktype_sjabloon->bibliotheek_sjablonen_id;

    return unless $sjabloon;

    if ($c->req->params->{filename}) {
        $add_args{'filename'}   = $c->req->params->{filename} . '.odt';
    } else {
        $add_args{'filename'}   = $sjabloon->naam . '.odt';
    }

    $add_args{'zaak_id'}        = $c->stash->{zaak}->nr;
    $add_args{'documenttype'}   = $type;
    $add_args{'sjabloon_id'}    = $sjabloon->id;

    {
        if ($c->user_exists) {
            $add_args{betrokkene_id} = 'betrokkene-medewerker-'
                . $c->user->uidnumber;
        } elsif ( $c->req->params->{'ztc_aanvrager_id'} ) {
            $add_args{betrokkene_id} =
                $c->req->params->{'ztc_aanvrager_id'};
        } else {
            $add_args{betrokkene_id} =
                $c->stash->{zaak}->aanvrager->rt_setup_identifier;
        }

        if (!$add_args{zaakstatus}) {
            $add_args{zaakstatus} = $c->stash->{zaak}->milestone;
        }
    }

    if (
        $c->model('Documents')->add(
            \%add_args
        )
    ) {
        ### XXX SEND MAIL
        $c->stash->{zaak}->logging->add({
            'component'   => LOGGING_COMPONENT_DOCUMENT,
            'onderwerp'   => 'Sjabloon (' .
                $add_args{filename} . ') toegevoegd'
        });

    #$c->stash->{zaak}->touch('Sjabloon toegevoegd');
    }
}

sub add_mail : Private {
    my ($self, $c) = @_;

    ### TODO: afzender nodig?
#    my $fromo = $c->model('Betrokkene')->get(
#        {},
#        'betrokkene-medewerker-' . $c->user->uidnumber
#    );
#
#    unless (
#        $fromo->email
#    ) {
#        $c->log->debug(
#            'DOC->add: Cannot sent from unknown e-mailaddress'
#        );
#        $c->flash->{result} =
#            'Geen e-mailadres van u bekend, kan deze mail niet verzenden';
#        $c->res->redirect($c->uri_for('/zaak/' . $c->stash->{zaak}->nr));
#        $c->detach;
#    }

    if ($c->req->params->{rcpt_type} eq 'aanvrager') {
        unless (
            $c->stash->{zaak}->aanvrager &&
            $c->stash->{zaak}->aanvrager_object->email
        ) {
            $c->log->debug(
                'DOC->add: Cannot sent to unknown e-mailaddress' .
                $c->stash->{zaak}->aanvrager_object->email
            );
            $c->flash->{result} = 'Geen e-mailadres bekend van aanvrager';
            $c->res->redirect($c->uri_for('/zaak/' . $c->stash->{zaak}->nr));
            $c->detach;
        }

        $c->stash->{rcpt} = $c->stash->{zaak}->aanvrager_object->email;
    } elsif ($c->req->params->{rcpt_type} eq 'medewerker') {
        my $bo = $c->model('Betrokkene')->get(
            {},
            $c->req->params->{rcpt}[0]
        );

        unless (
            $bo &&
            $bo->email
        ) {
            $c->log->debug(
                'DOC->add: Cannot sent to unknown e-mailaddress'
            );
            $c->flash->{result} = 'Geen e-mailadres bekend van behandelaar:';
            $c->res->redirect($c->uri_for('/zaak/' . $c->stash->{zaak}->nr));
            $c->detach;
        }

        $c->stash->{rcpt} = $bo->email;
    } else {
        unless (
            Email::Valid->address($c->req->params->{rcpt}[1])
        ) {
            $c->log->debug(
                'DOC->add: Cannot sent to unknown email address. No email
                address given'
            );
            $c->flash->{result} = 'Geen of ongeldig  e-mailadres opgegeven';
            $c->res->redirect($c->uri_for('/zaak/' . $c->stash->{zaak}->nr));
            $c->detach;
        }
        $c->stash->{rcpt} = $c->req->params->{rcpt}[1]; # rcpt[1] is e-mail, rcpt[0] wordt gebruikt voor naam
    }

    return unless $c->stash->{rcpt};

    my $type = $c->req->params->{documenttype};

    my %add_args = map { $_ => $c->req->params->{ $_ } }
        @{ $DOCUMENT_TYPES->{$type}->{modelargs} };

    $add_args{pid} = $c->stash->{document_depth}->id
        if $c->stash->{document_depth};

    ### ZAAKstatus, TODO MOVE TO MODEL
    $add_args{'zaakstatus'} = $c->stash->{'zaak'}->milestone;
    $add_args{'filename'}   = $c->stash->{rcpt};

    ### MOVE TO MODEL....
    {
        $add_args{zaak_id}        = $c->stash->{zaak}->id;

        if ($c->user_exists) {
            $add_args{betrokkene_id} = 'betrokkene-medewerker-'
                . $c->user->uidnumber;
        } elsif ( $c->req->params->{'ztc_aanvrager_id'} ) {
            $add_args{betrokkene_id} =
                $c->req->params->{'ztc_aanvrager_id'};
        } else {
            $add_args{betrokkene_id} =
                $c->stash->{zaak}->aanvrager->rt_setup_identifier;
        }

    }

    $add_args{message}  = $c->model('Bibliotheek::Sjablonen')->_replace_kenmerken(
        $c->stash->{zaak},
        $add_args{message}
    );

    $add_args{subject}  = $c->model('Bibliotheek::Sjablonen')->_replace_kenmerken(
        $c->stash->{zaak},
        $add_args{subject}
    );


    if (
        my $document = $c->model('Documents')->add(
            \%add_args
        )
    ) {
        ### XXX SEND MAIL
        $c->forward('/zaak/mail/document', [
            $add_args{message},
            $add_args{subject}
        ]);

        $c->stash->{zaak}->logging->add({
            'component'   => LOGGING_COMPONENT_DOCUMENT,
            'onderwerp'   => 'Mail (' .
                $add_args{filename} . ') toegevoegd'
        });
    }
}

sub add_file : Private {
    my ($self, $c) = @_;
    my $type = $c->req->params->{documenttype};

    ### Required filename
    return unless (
        exists($c->req->params->{'filename'}) ||
        $c->req->params->{document_id}
    );

    $c->log->debug('Z::Documents->add_file: found filename, continue');

    my $add_args = $c->req->params;

    ### A new filename has to added in a later stage, since the old one is necessary to trace back
    ### the existing file.

    ### Continue loading model arguments
    if (defined($c->req->params->{pid})) {
        $add_args->{pid} = ($c->req->params->{pid} || undef);
    } elsif ($c->stash->{document_depth}) {
        $add_args->{pid} = $c->stash->{document_depth}->id;
    }

    ### IE Quirk: filenames contain full path
    $add_args->{filename} = $c->req->upload('filename')->basename
        if $c->req->upload('filename');

    $c->log->debug('Z::Documents->add_file: filename correct, continue');
    ### Zaaktype catalogus, TODO MOVE TO MODEL
    if (exists($add_args->{'catalogus'}) && $add_args->{'catalogus'}) {
        my $file_kenmerken  = $c->stash->{zaak}
            ->zaaktype_node_id
            ->zaaktype_kenmerken
            ->search(
            {
                'me.id'                                 => $add_args->{'catalogus'},
                'bibliotheek_kenmerken_id.value_type'   => 'file',
            },
            {
                'join'          => 'bibliotheek_kenmerken_id',
            }
        );

        if ($file_kenmerken->count == 1) {
            my $document = $file_kenmerken->first;
            $c->log->debug('Z::D->add_file: Vond document in kenmerkenbibliotheek' . $document);
            $add_args->{'verplicht'}      =
                $document->value_mandatory;
            $add_args->{'category'}       =
                $document->bibliotheek_kenmerken_id->document_categorie;
            $add_args->{'pip'}       =
                $document->pip;
        }

    }

    if ($c->stash->{pip}) {
        $add_args->{queue} = 1;
        $add_args->{pip} = 1;
    }


    if ($add_args->{dagtekening_jaar}) {
        $add_args->{dagtekeningdatum}     = DateTime->new(
            'year'     => $add_args->{dagtekening_jaar},
            'month'    => $add_args->{dagtekening_maand},
            'day'      => $add_args->{dagtekening_dag},
        );
    }

    if ($add_args->{ontvangst_jaar}) {
        $add_args->{ontvangstdatum}     = DateTime->new(
            'year'     => $add_args->{ontvangst_jaar},
            'month'    => $add_args->{ontvangst_maand},
            'day'      => $add_args->{ontvangst_dag},
        );
    }

    $c->log->debug('Z::Documents->add_file: add file through model with args'
        . Dumper( $add_args )
    );

    my @found = $c->clamscan('filename');

    if (@found) {
        $c->flash->{result} = 'Bestand niet geupload: Virus found in uploaded file: '
            .  $found[0]->{signature};
        $c->flash->{pip_result} = $c->flash->{result};

        $c->response->redirect(
            $c->uri_for(
                ($c->stash->{pip} ? '/pip' : '') . '/zaak/' . $c->stash->{zaak}->id,
            )
        );
        $c->detach;
    }

    $add_args->{'edited_filename'} = $add_args->{'existing_filename'} . $add_args->{'existing_filename_suffix'};

    ### MOVE TO MODEL....
    {
        $add_args->{zaak_id}        = $c->stash->{zaak}->id;

        if ($c->user_exists) {
            $add_args->{betrokkene_id} = 'betrokkene-medewerker-'
                . $c->user->uidnumber;
        } elsif ( $c->req->params->{'ztc_aanvrager_id'} ) {
            $add_args->{betrokkene_id} =
                $c->req->params->{'ztc_aanvrager_id'};
        } else {
            $add_args->{betrokkene_id} =
                $c->stash->{zaak}->aanvrager->rt_setup_identifier;
        }

        if (!$add_args->{zaakstatus}) {
            $add_args->{zaakstatus} = $c->stash->{zaak}->milestone;
        }
    }

    if (my $document = $c->model('Documents')->add(
        $add_args,
        $c->req->upload('filename')
    )) {
    ### XXX TODO ZS2
#        $c->stash->{zaak}->notes->add({
#            'commenttype'   => 'documents',
#            'value'         => 'Document ' . $type . ' (' .
#                $add_args->{filename} . ') toegevoegd'
#        }) if $add_args->{filename};
#
#        $c->stash->{zaak}->notes->add({
#            'commenttype'   => 'documents',
#            'value'         => 'Document ' . $document->id . ' (' .
#                $add_args->{filename} . ') bijgewerkt'
#        }) unless $add_args->{filename};
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

