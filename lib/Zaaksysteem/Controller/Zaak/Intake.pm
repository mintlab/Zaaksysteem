package Zaaksysteem::Controller::Zaak::Intake;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use File::Copy;
use Data::Dumper;
use File::stat;
#use File::MimeInfo::Magic;
use File::MMagic;

use ClamAV::Client;




sub load : Local {
    my ( $self, $c ) = @_;

    $c->forward('/zaak/intake/check_dropped_files');
}

sub check_dropped_files : Private {
    my ( $self, $c ) = @_;
    my (@files);

    ### Get list of files
    {
        opendir(
            my $dh,
            $c->config->{dropdir}
        ) || die "can't opendir: $!";

        @files = grep { ! -d $c->config->{dropdir} . '/' . $_ } readdir($dh);

        closedir $dh;
    }

    my $now = time;

    for my $filename (@files) {
        my $file    = $c->config->{dropdir} . '/' . $filename;
        my $fo      = stat($file);

        ### Check for viruses
        $c->log->debug(
            'Z::I->check_dropped_files: found file: '
            . $filename
        );

        next unless $fo;

        my $scanner = ClamAV::Client->new();

        my ($path, $result) = $scanner->scan_path(
            $c->config->{dropdir} . '/' . $filename
        );

        if ($path && $result) {
            $c->flash->{result} = 'Failed loading drops: Virus Found ' .
                ' in file: ' . $filename . ': ' . $result;
            $c->log->error(
                'Z::I->check_dropped_files: virus found in file: '
                . $filename
            );
            next;
        }

        $c->log->debug(
            'Z::I->check_dropped_files: file: '
            . $filename . ': no virusus found'
        );

        my $mm      = new File::MMagic;
        my $mimetype = $mm->checktype_filename($file);

        $c->log->debug('mimetype: ' . $mimetype);
        if($filename =~ m|\.xls$|) {
            $mimetype = 'application/vnd.ms-excel';
        }
        if($filename =~ m|\.ods$|) {
            $mimetype = 'application/vnd.oasis.opendocument.spreadsheet';
        }
        if($filename =~ m|\.odt$|) {
            $mimetype = 'application/vnd.oasis.opendocument.text';
        }
        my $doc = $c->model('DB::DroppedDocuments')->create({
            'filesize'  => $fo->size,
            'filename'  => $filename,
            'mimetype'  => $mimetype,
        });

        $c->log->debug(
            'Z::I->check_dropped_files: file: '
            . $filename . ': created db row'
        ) if $doc;

        $c->log->debug(
            'Z::I->check_dropped_files: file: '
            . $filename . ': could not create db row'
        ) unless $doc;


        $c->log->debug(
            'Calling command rename with options: ['
            . $file . ',' . $c->config->{files} . '/drops/' . $doc->id
        );
        unless(move(
            $file,
            $c->config->{files} . '/drops/' . $doc->id
        )) {
            $doc->delete;
            $c->flash->{result} = 'Failed loading drop: '
                . $filename . ': Permission denied';

            $c->log->error(
                'Failed loading drop: ' . $filename . ': ' . $!
            );
        }
    }

    $c->response->body('OK');
}

sub get : Local {
    my ($self, $c, $dropid) = @_;

    my $document        = $c->model('DroppedDocuments')->find($dropid);

    if (!$document) {
        $c->flash->{result} = 'File not found';

        $c->response->redirect(
            $c->uri_for(
                '/zaak/intake',
                undef,
                {
                    scope   => 'documents'
                }
            )
        );
        $c->detach;
    }

    my $filename        = $c->config->{files} . '/drops/' . $dropid;

    my $stat = stat($filename);

    (
        $c->log->debug('Geen bestand gevonden op disk'),
        return
    ) unless ($stat);

    $c->res->headers->header(
        'Content-Disposition',
        'attachment; filename="' . $document->filename . '"'
    );

    $c->serve_static_file($c->config->{files} . '/drops/' . $dropid);

    $c->res->headers->content_length( $stat->size );
    $c->res->headers->content_type($document->mimetype);
    $c->res->content_type($document->mimetype);

    return;







}

sub redrop_document : Private {
    my ( $self, $c, $id, $extraopts ) = @_;

    my $document    = $c->model('DB::Documents')->find($id);

    return unless $document;

    $c->log->debug('Drop document back from document: ' . $id);
    my $dropdoc     = $c->model('DB::DroppedDocuments')->create({
        'filesize'  => $document->filesize,
        'filename'  => $document->filename,
        'mimetype'  => $document->mimetype,
    });

    my $files_dir   = $c->config->{files} . '/documents';
    my $file        = $files_dir . '/' . $document->id;

    my $logmsg = 'Document "' . $document->filename . '"'
        . ' geweigerd' . ( $extraopts->{omschrijving}
            ? ': ' . $extraopts->{omschrijving}
            : '.'
        );

    $c->stash->{zaak}->logging->add({
        component       => 'dropped_document',
        component_id    => $dropdoc->id,
        is_bericht      => 1,
        onderwerp       => $logmsg,
        bericht         => $extraopts->{omschrijving} || undef
    });

    return 1 if rename(
        $file,
        $c->config->{files} . '/drops/' . $dropdoc->id
    );

    return;
}

sub document_get :Chained('/') : PathPart('zaak/intake/document/get'): Args(2) {
    my ($self, $c, $id, $filename) = @_;

    $c->serve_static_file($c->config->{'files'} . '/drops/' . $id);

    my $stat = stat($c->config->{'files'} . '/drops/' . $id);

    my $doc = $c->model('DB::DroppedDocuments')->find($id) or return;

    $c->res->headers->content_length( $stat->size );
    $c->res->headers->content_type($doc->mimetype);
}

sub link : Chained('/') : PathPart('zaak/intake/link'): Args() {
    my ($self, $c) = @_;

    $c->assert_any_user_permission('documenten_intake');

    return unless (
        $c->req->params->{queue_document_id} ||
        $c->req->params->{document_id}
    );

    $c->stash->{nowrapper} = 1;

    $c->stash->{template} = 'zaak/widgets/link.tt';

    my ($zaak);

    if ($c->req->params->{zaaknr}) {
        $zaak = $c->model('DB::Zaak')->find($c->req->params->{zaaknr});

        if (!$zaak) {
            $c->stash->{link_error} = 'Zaaknummer '
                . $c->req->params->{zaaknr}
                . ' kan niet gebruikt worden:'
                . ' zaak bestaat niet ';
        } elsif (
            $zaak->status eq 'deleted' ||
            $zaak->status eq 'resolved'
        ) {
            $c->stash->{link_error} = 'Zaaknummer ' . $zaak->id
                . ' kan niet gebruikt worden:'
                . ' zaak is ' .
                ($zaak->status eq 'deleted' ? 'vernietigd' : 'afgehandeld');
        }
    }

    my $toegevoegd = 0;

    if ($c->req->params->{queue_document_id}) {
        $c->stash->{doc} =
            $c->model('DB::Documents')->find($c->req->params->{queue_document_id}) or return;

        $c->stash->{postprefix} = 'queue_';

        if (
            $zaak &&
            $c->req->params->{'link'} &&
            $zaak->status ne 'deleted' &&
            $zaak->status ne 'resolved'
        ) {
            ### We need more details
            if (!$c->req->params->{document_details}) {
                $c->stash->{zaak} = $zaak;

                $c->stash->{template} = 'zaak/widgets/link_details.tt';
                $c->detach;
            }

            my $oldzaaknr   = $c->stash->{doc}->zaak_id;

            $c->stash->{doc}->zaak_id($c->req->params->{zaaknr});
            $c->stash->{doc}->update;

            $c->response->redirect(
                $c->uri_for(
                    '/zaak/' . (ref($oldzaaknr) ? $oldzaaknr->id : $oldzaaknr)
                )
            );

            $c->log->debug('Linked document to zaak: ' .
                $c->req->params->{zaaknr}
            );
            $c->detach;
        }

    } elsif ($c->req->params->{document_id}) {
        $c->stash->{doc} = $c->model('DB::DroppedDocuments')->find($c->req->params->{document_id}) or return;

        my $args = {};
        if (
            $zaak &&
            $c->req->params->{'link'} &&
            $zaak->status ne 'deleted' &&
            $zaak->status ne 'resolved'
        ) {
            ### We need more details
            if (!$c->req->params->{document_details}) {
                $c->stash->{zaak} = $zaak;

                $c->stash->{template} = 'zaak/widgets/link_details.tt';
                $c->detach;
            }

            my $add_args = {
                document_type   => 'file',
                category        => $c->req->params->{category},
                id              => $c->req->params->{document_id},
                zaaknr          => $c->req->params->{zaaknr},
                help            => $c->req->params->{help},
            };

            if ($c->req->params->{catalogus}) {
                $add_args->{catalogus} = $c->req->params->{catalogus};
            }

            $c->forward(
                '/zaak/intake/add_to_zaak',
                [
                    $add_args
                ],
            );

            $toegevoegd = 1;

            $c->response->redirect(
                $c->uri_for(
                    '/zaak/intake/',
                    { scope => 'documents'}
                )
            );

        }
    }

    if ($toegevoegd) {
        $c->flash->{result} = 'Het document is toegevoegd aan het zaakdossier'
            . ' met zaaknummer: ' . $c->req->params->{zaaknr};
    }
}

sub add_to_zaak : Private {
    my ($self, $c, $opts) = @_;
    my $args = {};

    $c->assert_any_user_permission('documenten_intake');
    my $doc = $c->model('DB::DroppedDocuments')->find($opts->{id}) or return;

    ## Prepare
    $args->{'documenttype'}     = $opts->{document_type};
    $args->{'category'}         = $opts->{category};
    $args->{'filename'}         = $doc->filename;
    $args->{'help'}             = $opts->{help};
    $args->{'queue'}            = 1 unless $opts->{'noqueue'};

    $args->{'catalogus'}        = $opts->{'catalogus'}
        if $opts->{'catalogus'};

    if ($c->user_exists) {
        $args->{betrokkene_id} = 'betrokkene-medewerker-'
            . $c->user->uidnumber;
    }

    ## Make object
    my $upload = Zaaksysteem::Controller::Zaak::Intake::_DocumentDrop->new(
        size    => $doc->filesize,
        type    => $doc->mimetype,
        id      => $doc->id,
        c       => $c,
    );

    my $zaak = $c->model('DB::Zaak')->find($opts->{zaaknr}) or return;

    $args->{zaak_id} = $opts->{zaaknr};

    return unless $c->model('Documents')->add($args,$upload);

    $doc->delete;

    return 1;
}

{
    Zaaksysteem->register_profile(
        method  => 'verplaats',
        profile => {
            required => [ qw/
                document_id
                betrokkene_type
                ztc_behandelaar_id
            /],
            constraint_methods => {
                document_id     => qr/^\d+$/,
            }
        }
    );

    sub verplaats : Chained('/') : PathPart('zaak/intake/verplaats'): Args() {
        my ($self, $c) = @_;

        $c->assert_any_user_permission('documenten_intake');
        return unless $c->req->params->{betrokkene_type};

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
                $c->uri_for('/zaak/intake', { scope => 'documents' })
            );

            my $dv;
            $c->log->debug('Validatie fail?');
            return unless ($dv = $c->zvalidate);
            $c->log->debug('OR NOT Validatie fail?');

            my $doc = $c->model('DB::DroppedDocuments')
                ->find($c->req->params->{document_id}) or return;

                #my $bo      = $c->model('Betrokkene')->get(
                #{},
                #$dv->valid('ztc_behandelaar_id')
                #);

                #return unless $bo;
            $c->log->debug('OR DOC fail?:' .  $c->req->params->{'ztc_behandelaar_id'});

            $doc->betrokkene_id($c->req->params->{'ztc_behandelaar_id'});
            $doc->update;

            $c->detach;
        }

        if ($c->req->params->{betrokkene_type} eq 'medewerker') {
            $c->stash->{template} = 'zaak/widgets/set_behandelaar.tt';
        } else {
            $c->stash->{template} = 'zaak/widgets/set_org_eenheid.tt';
        }
    }
}


sub nieuw {}

{
    Zaaksysteem->register_profile(
        method  => 'delete',
        profile => {
            required => [ qw/
                document_id
            /],
            constraint_methods => {
                document_id     => qr/^\d+$/,
            }
        }
    );

    sub delete : Chained('/') : PathPart('zaak/intake/delete'): Args() {
        my ($self, $c) = @_;

        $c->assert_any_user_permission('documenten_intake');
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
                $c->uri_for('/zaak/intake', { scope => 'documents' })
            );

            ### Confirmed
            my $dv;
            return unless $dv = $c->zvalidate;

            my $doc = $c->model('DB::DroppedDocuments')
                ->find($c->req->params->{document_id}) or return;

            ### Remove document
            my $docpath = 
                $c->config->{'files'} . '/drops/' .
                $c->req->params->{document_id};

            my $docname = $doc->filename;

            ### Remove file
            unlink($docpath) if ( -f $docpath );

            ### Remove from db
            $doc->delete;

            ### Msg
            $c->flash->{result} = 'Document "' . $docname . '"'
                . ' succesvol verwijderd.';

            $c->detach;
            return;
        }

        $c->stash->{confirmation}->{message}    =
            'Weet u zeker dat u dit document wilt verwijderen?'
            . ' Deze actie kan niet ongedaan gemaakt worden';

        $c->stash->{confirmation}->{type}       = 'yesno';

        $c->stash->{confirmation}->{params}     = {
            'document_id'   => $c->req->params->{'document_id'},
        };

        $c->forward('/page/confirmation');
        $c->detach;
    }
}



package Zaaksysteem::Controller::Zaak::Intake::_DocumentDrop;

use strict;
use warnings;

use Moose;

has 'size' => (
    'is'    => 'rw',
);

has 'type' => (
    'is'    => 'rw',
);

has 'id' => (
    'is'    => 'rw'
);

has 'c' => (
    'is'    => 'rw'
);

sub copy_to {
    my ($self, $target) = @_;

    rename(
        $self->c->config->{files} . '/drops/' . $self->id,
        $target
    );


    return 1;
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

