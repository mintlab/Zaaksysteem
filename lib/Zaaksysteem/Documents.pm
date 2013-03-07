package Zaaksysteem::Documents;

use strict;
use warnings;
use Data::Dumper;
use File::Copy;
use Digest::MD5::File qw/-nofatals file_md5_hex/;
use Text::Wrap;
use File::stat;
use File::MMagic;

use DateTime;
use Zaaksysteem::Constants;

use Moose;


has 'context' => (
    'is'    => 'rw',
);


{
    Zaaksysteem->register_profile(
        method  => 'list',
        profile => {
            'required'      => [ qw/
            /],
            'optional'      => [ qw/
                zaaktype_kenmerken_id
                pid
                search
                pip
                search_recursive

                queue
                all_documents
                id
                alleen_mappen
            /],
            'defaults'      => {
                pid     => undef,
            },
            'require_some'  => {
                'zaak_id_or_betrokkene' => [1, qw/zaak_id betrokkene/],
            }
        }
    );

    sub list {
        my ($self, $opts)   = @_;
        my $sargs           = {};

        my $dv              = $self->context->check(
            params  => $opts,
            method  => [caller(0)]->[3],
        );

        return unless $dv->success;

        if ($dv->valid('zaak_id')) {
            $sargs->{zaak_id}       = $dv->valid('zaak_id');
        } elsif ($dv->valid('betrokkene')) {
            $sargs->{betrokkene}    = $dv->valid('betrokkene');
        }

        if ($dv->valid('zaaktype_kenmerken_id')) {
            $sargs->{zaaktype_kenmerken_id} =
                $dv->valid('zaaktype_kenmerken_id')
        }

        $sargs->{pid}   = $dv->valid('pid') unless
            $dv->valid('search_recursive');

        if ($dv->valid('pip')) {
            $sargs->{'-nest'} = ['pip' => '1', mimetype => 'dir'];
        }

        if (!$dv->valid('all_documents')) {
            $sargs->{queue} = undef;
            $sargs->{queue} = 1 if $dv->valid('queue');
        }

        if ($dv->valid('id')) {
            $sargs->{id} = $dv->valid('id');
        }

        if ($dv->valid('alleen_mappen')) {
            $sargs->{mimetype} = 'dir';
        }

        return
            $self->context->model('DB::Documents')->search(
                {
                    %{ $sargs },
                    'deleted_on'    => undef,
                },
                {
                    'order_by'  => { -asc => [qw/documenttype filename/] }
                },
        );
    }
}

{
    Zaaksysteem->register_profile(
        method  => 'add',
        profile => {
            'required'      => [ qw/
                documenttype
                betrokkene_id
            /],
            'optional'      => [ qw/
                filename
                zaakstatus
                pid
                document_id
                filestore_id
            /],
            'constraint_methods'    => {
                'documenttype'  => sub {
                    my $val = pop;

                    if (
                        ZAAKSYSTEEM_CONSTANTS->{document}->{types}
                            ->{ $val }
                    ) {
                        return 1;
                    }

                    return;
                },
                'zaakstatus'    => qr/^\d+$/,
            },
            'defaults'      => {
                pid     => undef,
            },
            'require_some'  => {
                'zaak_id_or_betrokkene' => [1, qw/zaak_id betrokkene/],
            }
        }
    );

    sub add {
        my ($self, $opts, $upload)  = @_;
        $opts                       = $opts || {};

        my $dv                      = $self->context->check(
            params  => $opts,
            method  => [caller(0)]->[3],
        );

        unless ($dv->success) {
            $self->context->log->error('DOCUMENT VALUES NOT OK:' .
                Dumper($dv)
            );

            return;
        }

        my $add_function = '_add_' . $dv->valid('documenttype');
        return $self->$add_function($opts, $upload);
    }
}

sub _add_dir {
    my ($self, $opts, $upload)  = @_;
    my $cargs                   = {};

    if ($opts->{zaak_id}) {
        $cargs->{zaak_id}       = $opts->{zaak_id};
    } else {
        $cargs->{betrokkene}    = $opts->{betrokkene};
    }

    $cargs->{filename}          = $opts->{filename};
    $cargs->{pid}               = $opts->{pid};
    $cargs->{zaakstatus}        = $opts->{zaakstatus};

    if ( $self->context->model('DB::Documents')->search($cargs)->count) {
        $self->context->flash->{result} = 'Mapnaam bestaat al';
        $self->context->log->debug('Directory exists');
        return;
    }

    my ($document);
    $cargs->{'mimetype'}        = 'dir';

    unless (
        $document = $self->context->model('DB::Documents')->create({
            %{ $cargs }
        })
    ) {
        $self->context->flash->{result} = 'Probleem bij aanmaken document';
        return;
    }

    $self->context->flash->{result} = 'Map succesvol aangemaakt';

    return $document;
}


{
    Zaaksysteem->register_profile(
        method  => '_add_file',
        profile => {
            'required'      => [ qw/
                documenttype
                betrokkene_id
            /],
            'optional'      => [ qw/
                category
                filename
                document_id
                zaakstatus
                pid
                catalogus
                verplicht
                post_registratie
                pip
                help
                ontvangstdatum
                dagtekeningdatum
                versie
                queue
                edited_filename
                actie_rename_when_exists
                filestore_id
            /],
            'constraint_methods'    => {
                'documenttype'  => sub {
                    my $val = pop;

                    if (
                        ZAAKSYSTEEM_CONSTANTS->{document}->{types}
                            ->{ $val }
                    ) {
                        return 1;
                    }

                    return;
                },
                'zaakstatus'    => qr/^\d+$/,
            },
            'defaults'      => {
                pid     => undef,
            },
            'require_some'  => {
                'zaak_id_or_betrokkene' => [1, qw/zaak_id betrokkene/],
                'document_id_or_filename' => [1, qw/document_id filename/],
            }
        }
    );

    sub _add_file {
        my ($self, $opts, $upload)  = @_;

        my $cargs                   = {};

        my $dv                      = $self->context->check(
            params  => $opts,
            method  => [caller(0)]->[3],
        );

        return unless $dv->success;

        $cargs                      = { %{ $dv->valid } };

        ### Delete extra BI vars not for database
        delete($cargs->{actie_rename_when_exists});

        my $checkargs = {
            'filename'  => $cargs->{filename},
            'pid'       => $cargs->{pid},
            'deleted_on' => undef,
        };

        ### Rename file to something sane
        $checkargs->{filename}          =~ s/[^\w_\-\.=,\s]/_/g;
        $cargs->{edited_filename}       =~ s/[^\w_\-\.=,\s]/_/g;

        if ($cargs->{zaak_id}) {
            $checkargs->{zaak_id}       = $cargs->{zaak_id};
        } else {
            $checkargs->{betrokkene}    = $cargs->{betrokkene};
        }

        my $existing_doc =
            $self->context->model('DB::Documents')->search($checkargs);

        if (
            (
                !$dv->valid('document_id') && 
                $existing_doc->count
            ) ||
            (
                $dv->valid('document_id') &&
                $existing_doc->count &&
                $existing_doc->first->id != $dv->valid('document_id')
            )
        ) {
            if ($dv->valid('actie_rename_when_exists')) {
                my $count = 0;
                while (
                    $self->context
                        ->model('DB::Documents')
                        ->search($checkargs)->count
                ) {
                    my ($file, $ext) = $checkargs->{filename} =~ /(.*)\.(.*)$/;

                    $checkargs->{filename}  = $file . '_'
                        . ++$count . '.' .  $ext;
                }

                $cargs->{filename} = $checkargs->{filename};
            } else {
                $self->context->flash->{result} = 'Bestand bestaat al';
                $self->context->log->debug('Filename exists');
                return;
            }
        }

        my $files_dir = $self->context->config->{files} . '/documents';

        if (!$upload && !$dv->valid('document_id')) {
            $self->context->flash->{result} = 'Probleem bij het uploaden van document, contact systeembeheer';
            $self->context->log->error('Problem uploading, no upload object given');
            return;
        }

        my $olddoc;
        if ($upload) {
            $cargs->{'mimetype'}        = $upload->type;
            $cargs->{'filesize'}        = $upload->size;
        } else {
            return unless $dv->valid('document_id');
        }

        if ($dv->valid('document_id')) {
            $olddoc  = $self->context->model('DB::Documents')->find(
                $dv->valid('document_id')
            );

            return unless $olddoc;

            if (!$upload) {
                $cargs->{'mimetype'}        = $olddoc->mimetype;
                $cargs->{'filesize'}        = $olddoc->filesize;
                $cargs->{'filename'}        = $cargs->{'edited_filename'}; #$olddoc->filename;
                $cargs->{'documenttype'}    = $olddoc->documenttype;
            }

            $cargs->{'versie'}              = ($olddoc->versie + 1);
        }
        
        # the field 'edited_filename' is passed to allow override of filename
        delete $cargs->{'edited_filename'} if(exists $cargs->{'edited_filename'});

        $cargs->{'versie'}                  = $cargs->{versie} || 1;

        if ($cargs->{'catalogus'} && $cargs->{'zaak_id'}) {
            my $z_object        = $self->context->model('DB::Zaak')->find($cargs->{'zaak_id'});

            $self->context->log->debug('M::D->add_file: search kenmerk in'
                . 'kenmerken bibliotheek'
            );
            my $file_kenmerken  = $z_object->zaaktype_node_id->zaaktype_kenmerken->search(
                {
                    'me.id'                                 => $cargs->{'catalogus'},
                },
            );

            if ($file_kenmerken->count == 1) {
                $self->context->log->debug('M::D->add_file: found kenmerk in'
                    . 'kenmerken bibliotheek'
                );
                my $kdocument = $file_kenmerken->first;
                if ($kdocument->type eq 'file') {
                    $cargs->{'verplicht'}      =
                        $kdocument->value_mandatory;
                    $cargs->{'category'}       =
                        $kdocument->bibliotheek_kenmerken_id->document_categorie;
                    $cargs->{'pip'}       = $kdocument->pip;
                }

                $cargs->{'zaaktype_kenmerken_id'}   = $cargs->{catalogus};
            }

        }

        $cargs->{queue} = undef;
        $cargs->{queue} = 1 if $dv->valid('queue');

        $self->context->log->debug('M::D->add_file: going to create'
            . Dumper($cargs)
        );

        my $document;

        delete($cargs->{document_id});
        my $filestore_id = $cargs->{filestore_id};
        delete $cargs->{filestore_id};
        if ( $document = $self->context->model('DB::Documents')->create($cargs) ) {
            $self->context->log->debug('Created document ' . $document->id);
            if ($upload) {
                my $success = 0;
                if($filestore_id) {
                    $success = rename(
                        $self->context->config->{files} . '/filestore/' . $filestore_id,
                        $files_dir . '/' . $document->id
                    );
                } else {
                    $success = $upload->copy_to($files_dir . '/' . $document->id);
                }

                unless ($success) {
                    $self->context->flash->{result} = 'Probleem bij aanmaken document';
                    $self->context->log->debug('Probleem bij aanmaken document, couldnt copy to '.$files_dir.' (1): ' . 
                        $dv->valid('document_id') . ' [' . $!
                    );
                    $document->delete;
                    return;
                }

            } else {
                unless (copy(
                        $files_dir . '/' . $dv->valid('document_id'),
                        $files_dir . '/' . $document->id
                    )
                ) {
                    $self->context->flash->{result} = 'Probleem bij aanmaken document';
                    $self->context->log->debug('Probleem bij aanmaken document (2): ' . 
                        $dv->valid('document_id') . ' [' . $! . ']'
                    );
                    $document->delete;
                    return;
                }
            }

            ### CREATE MD5 FROM HASH
            my $md5sum = file_md5_hex($files_dir . '/' .  $document->id);
            $self->context->log->debug('MD5: ' . $md5sum);
            do {
                $document->delete;
                return;
            } unless $md5sum;
           
            $document->md5($md5sum);
            $document->update;

        } else {
            $self->context->flash->{result} = 'Probleem bij aanmaken document';
            return;
        }


        ### Make old version disappear
        if ($olddoc) {
            $olddoc->deleted_on(DateTime->now());
            $olddoc->update;
        }

        ### Logging
        if ($document->zaak_id) {
            $document->zaak_id->logging->add({
                'component'     => LOGGING_COMPONENT_DOCUMENT,
                'component_id'  => $document->id,
                'onderwerp'     => 'Document "'
                    . $document->filename . '" ['
                    . $document->id . '] succesvol '
                    . ($olddoc
                        ? 'bewerkt[' . $olddoc->id .']'
                        : 'aangemaakt'
                    )
            });
        }

        $self->context->flash->{result} = 'Document succesvol aangemaakt';

        return $document;
    }
}


{
    Zaaksysteem->register_profile(
        method  => '_add_mail',
        profile => {
            'required'      => [ qw/
                documenttype
                filename
                message
                betrokkene_id
            /],
            'optional'      => [ qw/
                zaakstatus
                pid
                rcpt
                subject
            /],
            'constraint_methods'    => {
                'zaakstatus'    => qr/^\d+$/,
            },
            'defaults'      => {
                pid     => undef,
            },
            'require_some'  => {
                'zaak_id_or_betrokkene' => [1, qw/zaak_id betrokkene/],
            }
        }
    );

    sub _add_mail {
        my ($self, $opts)           = @_;
        my $cargs                   = {};

        my $dv                      = $self->context->check(
            params  => $opts,
            method  => [caller(0)]->[3],
        );

        return unless $dv->success;

        $cargs                      = $dv->valid;

        ### Mail defaults
        $cargs->{'category'}        = 'Email';
        $cargs->{'mimetype'}        = 'text/email';

        ### WRAP message
        $Text::Wrap::columns = 78;
        $opts->{'message'} = wrap('', '', $opts->{'message'});

        $cargs->{'filesize'}        = length($opts->{'message'});

        my $document;
        my %appends;
        for my $append (qw/subject message rcpt/) {
            $appends{$append} = $cargs->{$append};
            delete($cargs->{$append});
        }


        if ($document = $self->context->model('DB::Documents')->create($cargs)) {
            $self->context->log->debug('Created document for mail ' . $document->id);

            my $mail = $self->context->model('DB::DocumentsMail')->create({
                'document_id'       => $document->id,
                %appends
            });

            ## Fail...
            if (!$mail) {
                $document->delete;
                $self->context->flash->{result} = 'Probleem bij aanmaken e-mail';
                return;
            }

            $self->context->log->debug('Created mail document' . $mail->id);
        } else {
            $self->context->flash->{result} =
                'Probleem bij aanmaken document voor e-mail';
            return;
        }

        if ($document->zaak_id) {
            $document->zaak_id->logging->add({
                'component'     => LOGGING_COMPONENT_DOCUMENT,
                'component_id'  => $document->id,
                'onderwerp'     => 'Document "'
                    . $document->filename . '" ['
                    . $document->id . '] succesvol '
                    . 'aangemaakt'
            });
        }


        return $document;
    }
}

{
    Zaaksysteem->register_profile(
        method  => '_add_sjabloon',
        profile => {
            'required'      => [ qw/
                documenttype
                betrokkene_id
                sjabloon_id
            /],
            'optional'      => [ qw/
                category
                filename
                document_id
                zaakstatus
                pid
                catalogus
                verplicht
                post_registratie
                pip
                help
                ontvangstdatum
                dagtekeningdatum
                versie
                actie_rename_when_exists
            /],
            'constraint_methods'    => {
                'documenttype'  => sub {
                    my $val = pop;

                    if (
                        ZAAKSYSTEEM_CONSTANTS->{document}->{types}
                            ->{ $val }
                    ) {
                        return 1;
                    }

                    return;
                },
                'zaakstatus'    => qr/^\d+$/,
            },
            'defaults'      => {
                pid     => undef,
            },
            'require_some'  => {
                'zaak_id_or_betrokkene' => [1, qw/zaak_id betrokkene/],
                'document_id_or_filename' => [1, qw/document_id filename/],
            }
        }
    );

    sub _add_sjabloon {
        my ($self, $opts, $upload)  = @_;
        my $cargs                   = {};

        my $dv                      = $self->context->check(
            params  => $opts,
            method  => [caller(0)]->[3],
        );

        $self->context->log->debug('M::Doc->_add_sjabloon: validate');

        return unless $dv->success;

        $cargs                      = { %{ $dv->valid } };

        delete($cargs->{actie_rename_when_exists});


        my $checkargs = {
            'filename'  => $cargs->{filename},
            'pid'       => $cargs->{pid},
            'deleted_on' => undef,
        };

        if ($cargs->{zaak_id}) {
            $checkargs->{zaak_id}       = $cargs->{zaak_id};
        } else {
            $checkargs->{betrokkene}    = $cargs->{betrokkene};
        }


        $self->context->log->debug('M::Doc->_add_sjabloon: prepare');

        my $existing_doc =
            $self->context->model('DB::Documents')->search($checkargs);

        if (
            (
                !$dv->valid('document_id') &&
                $existing_doc->count
            ) ||
            (
                $dv->valid('document_id') &&
                $existing_doc->count &&
                $existing_doc->first->id != $dv->valid('document_id')
            )
        ) {
            if ($dv->valid('actie_rename_when_exists')) {
                my $count = 0;
                while (
                    $self->context
                        ->model('DB::Documents')
                        ->search($checkargs)->count
                ) {
                    my ($file, $ext) = $checkargs->{filename} =~ /(.*)\.(.*)$/;

                    $checkargs->{filename}  = $file . '_'
                        . ++$count . '.' .  $ext;
                }

                $cargs->{filename} = $checkargs->{filename};
            } else {
                $self->context->flash->{result} = 'Bestand bestaat al';
                $self->context->log->debug('Filename exists');
                return;
            }
        }

        my $files_dir = $self->context->config->{files} . '/documents';

        my $olddoc;
        if ($dv->valid('document_id')) {
            $olddoc  = $self->context->model('DB::Documents')->find(
                $dv->valid('document_id')
            );

            return unless $olddoc;

            if (!$upload) {
                $cargs->{'mimetype'}        = $olddoc->mimetype;
                $cargs->{'filesize'}        = $olddoc->filesize;
                $cargs->{'filename'}        = $olddoc->filename;
            }

            $cargs->{'versie'}          = ($olddoc->versie + 1);
        }

        if ($cargs->{'catalogus'} && $cargs->{'zaak_id'}) {
            my $z_object        = $self->context->model('DB::Zaak')->find($cargs->{'zaak_id'});
            my $zt_object       = $z_object->zaaktype_node_id;

            $self->context->log->debug('M::D->add_sjabloon: search kenmerk in'
                . 'kenmerken bibliotheek'
            );
            my $file_kenmerken  = $zt_object->zaaktype_kenmerken->search(
                {
                    'me.id'                                 => $cargs->{'catalogus'},
                },
            );

            if ($file_kenmerken->count == 1) {
                $self->context->log->debug('M::D->add_sjabloon: found kenmerk in'
                    . 'kenmerken bibliotheek'
                );
                my $kdocument = $file_kenmerken->first;
                if ($kdocument->type eq 'file') {
                    $cargs->{'verplicht'}      =
                        $kdocument->bibliotheek_kenmerken_id->value_mandatory;
                    $cargs->{'category'}       =
                        $kdocument->bibliotheek_kenmerken_id->document_categorie;
                    $cargs->{'pip'}       = $kdocument->pip;
                }

                $cargs->{'zaaktype_kenmerken_id'}   = $cargs->{catalogus};
            }

        }
        $cargs->{'versie'}                  = $cargs->{versie} || 1;

        my $document;

        $self->context->log->debug('M::Doc->_add_sjabloon: create doc');
        delete($cargs->{sjabloon_id});
        delete($cargs->{document_id});

        if ( $document = $self->context->model('DB::Documents')->create($cargs) ) {
            $self->context->log->debug('Created document ' . $document->id);

            if ($dv->valid('document_id')) {
                $self->context->log->debug('M::Doc->_add_sjabloon: edit sjabloon document');
                unless (copy(
                        $files_dir . '/' . $dv->valid('document_id'),
                        $files_dir . '/' . $document->id
                    )
                ) {
                    $self->context->flash->{result} = 'Probleem bij aanmaken document';
                    $self->context->log->debug('Probleem bij aanmaken document (3): ' . 
                        $dv->valid('document_id') . ' [' . $!
                    );
                    $document->delete;
                    return;
                }
            } else {
                $self->context->log->debug('M::Doc->_add_sjabloon: create sjabloon');
                if (
                    $self->context->model('Bibliotheek::Sjablonen')->create_sjabloon(
                        sjabloon_id => $dv->valid('sjabloon_id'),
                        document_id => $document->id,
                        zaak_nr     => $cargs->{zaak_id}
                    )
                ) {
                    # Define filesize etc
                    if (my $fstat = stat($files_dir . '/' . $document->id)) {
                        my $mm      = new File::MMagic;
                        my $mimetype = $mm->checktype_filename($files_dir . '/' . $document->id);

                        $document->filesize($fstat->size);
                        $document->mimetype('application/vnd.oasis.opendocument.text');

                        $document->update;
                    }
                } else {
                    $self->context->flash->{result} = 'Probleem bij aanmaken document';
                    $self->context->log->debug('Probleem bij aanmaken document (4): ' 
                        #.$dv->valid('document_id') . ' [' . $! . ']'
                    );
                    $document->delete;
                    return;
                }
            }

            ### CREATE MD5 FROM HASH
            my $md5sum = file_md5_hex($files_dir . '/' .  $document->id);
            $self->context->log->debug('MD5: ' . $md5sum);
            do {
                $document->delete;
                return;
            } unless $md5sum;

            $document->md5($md5sum);
            $document->update;
        } else {
            $self->context->flash->{result} = 'Probleem bij aanmaken document';
            return;
        }

        ### Make old version disappear
        if ($olddoc) {
            $olddoc->deleted_on(DateTime->now());
            $olddoc->update;
        }

        if ($document->zaak_id) {
            $document->zaak_id->logging->add({
                'component'     => LOGGING_COMPONENT_DOCUMENT,
                'component_id'  => $document->id,
                'onderwerp'     => 'Sjabloon "'
                    . $document->filename . '" ['
                    . $document->id . '] succesvol '
                    . 'gegenereerd'
            });
        }

        $self->context->flash->{result} = 'Document succesvol aangemaakt';

        return $document;
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

