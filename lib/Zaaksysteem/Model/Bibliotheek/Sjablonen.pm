package Zaaksysteem::Model::Bibliotheek::Sjablonen;

use strict;
use warnings;
use Zaaksysteem::Constants;

use parent 'Catalyst::Model';

use Data::Dumper;
use Digest::MD5::File qw/-nofatals file_md5_hex/;
use OpenOffice::OODoc;
use File::Copy;
use File::Temp;
use File::stat;
use File::Slurp;

use Encode qw/encode/;

use constant SJABLONEN              => 'sjablonen';
use constant SJABLONEN_DB           => 'DB::BibliotheekSjablonen';
use constant SJABLONEN_STRINGS_DB   => 'DB::BibliotheekSjablonenMagicString';
use constant FILESTORE_DB           => 'DB::Filestore';

use Moose;

use utf8;

has 'c' => (
    is  => 'rw',
);

{
    Zaaksysteem->register_profile(
        method  => 'bewerken',
        profile => {
            required => [ qw/
                naam
                bibliotheek_categorie_id
            /],
            optional => [ qw/
                filename
                id
                label
                description
                help
            /],
            constraint_methods  => {
                naam            => qr/^.{2,64}$/,
            },
            'require_some'      => {
                'filename_or_id'    => [1, qw/id filename/]
            },
            msgs                => PARAMS_PROFILE_DEFAULT_MSGS,
        }
    );

    sub bewerken {
        my ($self, $params) = @_;

        my ($magic_strings, $file_store_id, $old_sjabloon);

        my $dv = $self->c->check(
            params  => $params,
        );
        return unless $dv->success;

        my $valid_options = $dv->valid;

        ### Rewrite some values
        my %options = map {
            $_ => $valid_options->{ $_ }
        } keys %{ $valid_options };

        if ($options{filename}) {
            $options{filename}  = $options{naam} . '.odf';
        }

        if ($options{filename}) {
            $magic_strings      = $self->_parse_file(%options)
                or return;

            $file_store_id      = $self->_store_file(%options)
                or return;
        } else {
            $old_sjabloon       = $self->c->model(SJABLONEN_DB)->find(
                $options{id}
            ) or return;

            return unless $old_sjabloon->filestore_id;

            $file_store_id      = $old_sjabloon->filestore_id->id;
        }

        $options{filestore_id} = $file_store_id;

        ### Remove unnecessary variables
        delete($options{id}) unless $options{id};
        delete($options{filename});

        ### Ram er maar in
        my $kenmerk = $self->c->model(SJABLONEN_DB)->update_or_create(\%options)
            or return;

        if ($kenmerk->bibliotheek_sjablonen_magic_strings->count) {
            $kenmerk->bibliotheek_sjablonen_magic_strings->delete;
        }

        if (ref($magic_strings)) {
            for my $magic_string (@{ $magic_strings }) {
                $self->c->model(SJABLONEN_STRINGS_DB)->create({
                    'bibliotheek_sjablonen_id'  => $kenmerk->id,
                    'value'                     => $magic_string,
                });
            }
        }

        return $kenmerk;
    }
}

sub sjabloon_exists {
    my ($self, %opts)   = @_;

    return unless $opts{naam};

    return $self->c->model(SJABLONEN_DB)->search({
        'naam'  => $opts{naam}
    })->count;
}

sub _store_file {
    my ($self, %options) = @_;
    my ($filename);

    $filename = $options{filename};

    my $upload      = $self->c->req->upload('filename');

    # store in DB
    my $options     = {
        'filename'      => $filename,
        'filesize'      => $upload->size,
        'mimetype'      => $upload->type,
    };

    my $filestore   = $self->c->model(FILESTORE_DB)->create($options);

    if (!$filestore) {
        $self->c->log->error(
            'Bib::S->_parse_file: Hm, kan filestore entry niet aanmaken: '
            . $filename
        );
        $self->c->flash->{result} = 'ERROR: Kan bestand niet aanmaken op omgeving';
        return;
    }

    # Store on system
    my $files_dir   = $self->c->config->{files} . '/filestore';

    if (!$upload->copy_to($files_dir . '/' . $filestore->id)) {
        $filestore->delete;
        $self->c->log->error(
            'Bib::S->_parse_file: Hm, kan bestand niet aanmaken: '
            . $filename
        );
        $self->c->flash->{result} = 'ERROR: Kan bestand niet kopieren naar omgeving';
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

sub _parse_file {
    my ($self, %options) = @_;
    my (@magic_strings);

    my $filename        = $options{filename};

    if (!$self->c->req->upload('filename')) {
        $self->c->log->error(
            'Bib::S->_parse_file: Bizar, kan file niet vinden: ' . $filename
        );
        $self->c->flash->{result} = 'ERROR: Bestand niet geupload';
        return;
    }

    ### Parse filename
    my $fh = $self->c->req->upload('filename')->fh or do {
        $self->c->log->error(
            'Bib::S->_parse_file: Kan filehandle niet openen'
        );
        $self->c->flash->{result} = 'ERROR: Onmogelijk om bestand te openen, contact systeembeheer';
        return;
    };

    my $encoding    = $OpenOffice::OODoc::XPath::LOCAL_CHARSET;
    my $doc         = odfDocument(
        file            => $self->c->req->upload('filename')->tempname,
        local_encoding  => $encoding
    ) or do {
        $self->c->log->error(
            'Bib::S->_parse_file: Kan opendocument file niet openen'
        );
        $self->c->flash->{result} = 'ERROR: Ongeldig ODF document';
        return;
    };

    my $rawtext = $doc->getTextContent();
    (@magic_strings) = $rawtext =~ /\[\[([\w0-9_]+)\]\]/g;

#    for (@list) {
#        $self->c->log->debug('String: ' . $_);
#
#
#        if (!$_ || $_ !~ /\[\[[\w0-9_]+\]\]/) { next; }
#
#        my (@line_magic_strings) = $_ =~ /\[\[([\w0-9_]+)\]\]/g;
#
#        push (@magic_strings, @line_magic_strings);
#    }

    $self->c->log->debug(
        'Bib::S->_parse_file: Vond magic strings: '
        . "\n -" . join("\n -", @magic_strings)
    );

    return \@magic_strings if scalar(@magic_strings);
    return 1;
}

sub retrieve {
    my ($self, %opt) = @_;

    return $self->c->model(SJABLONEN_DB)->find($opt{id});
}



{
    Zaaksysteem->register_profile(
        method  => 'download_sjabloon',
        profile => {
            required => [ qw/
                filename
                document_id
                output_filetype
                mimetype
            /],
            constraint_methods  => {
                document_id     => qr/^\d+$/,
            },
        }
    );

    sub download_sjabloon {
        my ($self, %params) = @_;

        my $dv              = $self->c->check(
            params  => \%params
        );

        return unless $dv->success;
        my $valid_options       = $dv->valid;

        return unless (
            exists(ZAAKSYSTEEM_CONSTANTS->{document}->{sjabloon}->{export_types}->{
                $valid_options->{output_filetype}
            })
        );

        my $document_files_dir  = $self->c->config->{files} . '/documents';
        my $document_file       = $document_files_dir . '/' .
            $valid_options->{document_id};

        $self->convert_and_download($document_file, $valid_options->{mimetype}, 
            $valid_options->{filename}, 
            $valid_options->{output_filetype}
        );
        return;


    }

    sub _send_to_browser {
        my ($self, %opt)    = @_;


        my $outputfiletype  = $opt{filetype};
        my $outputfilename  = $opt{filename};
        my $showfilename    = $opt{showfilename};

        utf8::downgrade($outputfiletype);
        utf8::downgrade($outputfilename);
        utf8::downgrade($showfilename);

        my $stat            = stat($outputfilename);

        # Filename
        {
            my $filename    = $showfilename;
            $filename       =~ s/\.[\w\d]+$//;
            $self->c->res->headers->header(
                'Content-Disposition',
                'attachment; filename="'
                    . $filename . '.' . $outputfiletype
                    . '"'
            );
        }

        my $filetypeinfo = ZAAKSYSTEEM_CONSTANTS->{document}->{sjabloon}->{export_types}->{
            $outputfiletype
        };

        $self->c->serve_static_file($outputfilename);
        $self->c->res->headers->content_length( $stat->size );
        $self->c->res->headers->content_type($filetypeinfo->{mimetype});
        $self->c->res->content_type($filetypeinfo->{mimetype});
        $self->c->res->content_length( $stat->size );

        return 1;
    }

    sub _convert_to_tmp {
        my ($self, %opt) = @_;

        my $tmp_doc_h    = File::Temp->new(
            UNLINK => 1
        );

        utf8::downgrade($opt{filetype});

        copy(
            $opt{filename},
            $tmp_doc_h->filename . '.odt'
        );

        my $tmph                = File::Temp->new(
            UNLINK => 1
        );

        my $outputfile          = $tmph->filename . '.' .
            $opt{filetype};

        system(
            '/usr/bin/jodconverter '
            . $tmp_doc_h->filename . '.odt '
            . $outputfile
        );

        return $outputfile;
    }
    
    sub convert_and_download {
        my ($self, $input_document_file, $input_mimetype, $output_filename, $output_filetype) = @_;
        
         #File::Slurp
        my $content = read_file($input_document_file);
        
        if($output_filetype ne 'odt') {
            my $output_mimetype = ZAAKSYSTEEM_CONSTANTS->{document}->{sjabloon}->{export_types}->{$output_filetype}->{mimetype};

            use HTTP::Request::Common;
            my $ua = LWP::UserAgent->new;
            my $result = $ua->request(POST 'http://localhost:8080/converter/service', 
                Content => $content,
                Content_Type => $input_mimetype,
                Accept => $output_mimetype,
            );
            $content = $result->content();
        
            $output_filename =~ s|\.odt$|'.'.$output_filetype|eis;
        }
        $self->c->log->debug('input_document_file: '. $input_document_file . ', input_mimetype: ' . $input_mimetype . ', filename: ' . $output_filename . ', filetype: ' . $output_filetype);
        
        utf8::downgrade($output_filename);

        $self->c->res->headers->header( 'Content-Type'  => 'application/x-download' );
        $self->c->res->headers->header(
            'Content-Disposition'  =>
                "attachment;filename=\"" . $output_filename . "\"\n\n"
        );        
    
        $self->c->res->body($content);
    }
        
}



{
    Zaaksysteem->register_profile(
        method  => 'create_sjabloon',
        profile => {
            optional => [ qw/
                direct_download
                filetype
                filename
            /],
            'require_some'      => {
                'sjabloon_id_or_naam'    => [
                    1,
                    qw/
                        sjabloon_id
                        systeem_document
                    /
                ],
                'document_id_or_naam'    => [
                    1,
                    qw/
                        document_id
                        systeem_document
                    /
                ],
                'zaak_nr_or_naam'    => [
                    1,
                    qw/
                        zaak_nr
                        systeem_document
                    /
                ],
            },
            constraint_methods  => {
                sjabloon_id     => qr/^\d+$/,
                document_id     => qr/^\d+$/,
            },
        }
    );

    sub create_sjabloon {
        my ($self, %params) = @_;

        my $dv = $self->c->check(
            params  => \%params
        );

        $self->c->log->debug('B::S->create_sjabloon: validating' . Dumper (\%params) . 'success: ' . $dv->success);
        unless($dv->success) {
            $self->c->log->debug('B::S->create_sjabloon: validation error' . Dumper $dv);
            return;
        }

        ### Check for existence sjabloon
        my $valid_options   = $dv->valid;

        if ($valid_options->{systeem_document}) {
            $self->c->log->debug('Systeem document: ' .
                $valid_options->{systeem_document}
            );
            my $sys_sjablonen = $self->c->model(SJABLONEN_DB)->search(
                {
                    naam        => $valid_options->{systeem_document},
                }
            );

            return unless $sys_sjablonen->count;

            $valid_options->{sjabloon_id} = $sys_sjablonen->first->id;
        }

        my $sjabloon = $self->retrieve(
            'id'    => $valid_options->{sjabloon_id}
        );
        
        unless($sjabloon) {
            $self->c->log->debug('B::S->create_sjabloon: sjabloon '.$valid_options->{sjabloon_id}. ' not found in db');
            return;
        }

        my $files_dir       = $self->c->config->{files} . '/filestore';
        my $sjabloon_file   = $files_dir . '/' . $sjabloon->filestore_id->id;

        $self->c->log->debug('B::S->create_sjabloon: look for file');
        if (! -f $sjabloon_file) { return; }

        $self->c->log->debug('B::S->create_sjabloon: decode file');

        my $workdir = '/tmp/zaaksysteem_work_dir/';

        if (! -d $workdir) {
            mkdir($workdir);
        }

        ### Workaround Archive::Zip bug, Archive::Zip::Archive Line 436
        ### Stripping dots in directories instead only in files
        my $md5sum           = file_md5_hex($sjabloon_file);
        my $tmpsjabloon_file = $workdir . '/' . $md5sum;

        ### Open document
        my $encoding    = $OpenOffice::OODoc::XPath::LOCAL_CHARSET;

        my $doc         = odfDocument(
            file            => $sjabloon_file,
            local_encoding  => $encoding,
	    work_dir        => $workdir,
        ) or do {
            $self->c->log->error(
                'Bib::S->_parse_file: Kan opendocument file niet openen'
            );
            return;
        };

        $self->c->log->debug('B::S->create_sjabloon: replace kenmerken');

        ### Make sure the parse of kenmerken won't kill the copy here.
        eval {
            $self->_replace_kenmerken($valid_options->{zaak_nr}, $doc);
        };

        if ($@) {
            $self->c->log->debug('B::S->create_sjabloon: errors with'
                . ' replacing kenmerken: ' . $@);
        }

        if ($valid_options->{direct_download}) {
            # Create tmp file
            my $tmp_doc_h    = File::Temp->new(
                UNLINK => 1
            );

            my $outputfile = $self->_convert_to_tmp(
                'filename'  => $tmp_doc_h->filename,
                'filetype'  => $valid_options->{filetype}
            );

            $self->_send_to_browser(
                'filename'  => $outputfile,
                'filetype'  => $valid_options->{filetype}
            );
        } else {
            my $document_files_dir  = $self->c->config->{files} . '/documents';
            my $document_file       = $document_files_dir . '/' .
                $valid_options->{document_id};

            $self->c->log->debug('B::S->create_sjabloon: save file');
            if ($doc->save($tmpsjabloon_file)) {
                copy($tmpsjabloon_file, $document_file);
                return 1;
            }
        }

        return;
    }
}

sub touch_zaak {
    my ($self, $zaak)   = @_;

    return unless $zaak;

    if ($zaak->zaaktype_node_id->zaaktype_definitie_id->extra_informatie) {
        my $toelichting = $self->_replace_kenmerken(
                $zaak,
                $zaak->zaaktype_node_id->zaaktype_definitie_id->extra_informatie
            );

        if ($zaak->onderwerp ne substr($toelichting,0,255)) {
            $zaak->onderwerp(substr($toelichting,0,255));
            $zaak->update;
        }
    }
}

sub _replace_kenmerken {
    my ($self, $zaak_nr, $source) = @_;

    # Retrieve zaak
    my $zaak;
    if (UNIVERSAL::can($zaak_nr, 'isa')) {
        $zaak   = $zaak_nr;
    } else {
        $zaak   = $self->c->model('DB::Zaak')->find($zaak_nr);
    }
    die('No zaak given') unless $zaak;

    my $zt      = $zaak->zaaktype_node_id;

    if ($zt->zaaktype_kenmerken->count) {
        my $kenmerken       = $zt->zaaktype_kenmerken->search(
            {
                'is_group'  => undef
            },
            {
                prefetch    => 'bibliotheek_kenmerken_id'
            }
        );

        my $kenmerken_data = $zaak->zaak_kenmerken->search_all_kenmerken({});

        while (my $kenmerk  = $kenmerken->next) {
            next if $kenmerk->bibliotheek_kenmerken_id->value_type eq 'file';

            my $bibid       = $kenmerk->bibliotheek_kenmerken_id->id;
            my $value       = $kenmerken_data->{$bibid};

            ### Make sure we handle arrays correctly:
            my $replace_value;
            if (UNIVERSAL::isa($value, 'ARRAY')) {
                $replace_value = join(", \n", @{ $value });
            } else {
                $replace_value = $value
            }

            ### Make sure valuta get's showed correctly
            if ($kenmerk->bibliotheek_kenmerken_id->value_type =~ /valuta/) {
                $replace_value = sprintf('%01.2f', $replace_value);
                $replace_value =~ s/\./,/g;
            }

            ### Make sure we show bag items the 'correct' way
            if ($kenmerk->bibliotheek_kenmerken_id->value_type =~ /^bag/) {
                $replace_value = $self->c->model('Gegevens::Bag')
                    ->bag_human_view_by_id($replace_value);
            }

            if (UNIVERSAL::isa($source, 'HASH')) {
                $self->_kenmerk_replace(
                    $source,
                    $kenmerk->magic_string,
                    $replace_value
                );
            } else {
                $source = $self->_kenmerk_replace(
                    $source,
                    $kenmerk->magic_string,
                    $replace_value
                );

            }
        }
    }

    $source = $self->_replace_base_kenmerken($zaak, $source);
    $source = $self->_replace_betrokkene_kenmerken($zaak, $source);
    $source = $self->_clear_other_kenmerken($source);

    return $source;
}

sub _clear_other_kenmerken {
    my ($self, $source) = @_;

    if (UNIVERSAL::isa($source, 'HASH')) {
        $source->selectElementsByContent(
            '\[\[.*?\]\]',
            #$source->outputTextConversion($value)
            ''
        );
    } else {
        $source =~ s/\[\[.*?\]\]//g;
    }

    return $source;
}

sub _kenmerk_replace_on_oodoc {
    my ($self, $source, $key, $value) = @_;

#    warn('1NO ERRORS HERE: ' . $key);
    my @elements    = $source->selectElementsByContent(
        '\[\[' . $key . '\]\]',
    );

#    warn('2NO ERRORS HERE: ' . $key);
    for my $element (@elements) {
        $value  =~ s/(, )?\n/[[BR]]/g;
        #$value  = encode('utf-8', $value);
#        warn('3NO ERRORS HERE: ' . $key);
        $source->substituteText(
            $element,
            '\[\[' . $key . '\]\]',
            $source->outputTextConversion($value)
        );
#        warn('4NO ERRORS HERE: ' . $key);
        #my $loop_protection= undef;
        $source->setChildElements(
            $element, 'text:line-break',
            replace => '\[\[BR\]\]',
        );
#        warn('5NO ERRORS HERE: ' . $key);
    }
}

sub _kenmerk_replace {
    my ($self, $source, $key, $value) = @_;

    eval {
        if (UNIVERSAL::isa($source, 'HASH')) {
            $self->_kenmerk_replace_on_oodoc($source, $key, $value);
        } else {
            $source =~ s/\[\[$key\]\]/$value/g;
        }
    };

    if ($@) {
        $self->c->log->error('Error converting element: '
            . $key . ':' . $@
        );
    }

    return $source;
}

sub _replace_betrokkene_kenmerken {
    my ($self, $zaak, $source) = @_;

    my $betrokkenen = $zaak->zaak_betrokkenen->search_gerelateerd;

    my $kenmerken_h = ZAAKSYSTEEM_BETROKKENE_KENMERK;
    my @kenmerken   = keys %{ $kenmerken_h };

    while (my $betrokkene = $betrokkenen->next) {
        my $magic_string = $betrokkene->magic_string_prefix;

        my $betrokkene_object = $zaak->betrokkene_object(
            {
                'magic_string_prefix'    => $magic_string
            }
        ) or next;

        for my $kenmerk_postfix (@kenmerken) {
            my $kenmerk = $magic_string . '_' . $kenmerk_postfix;

            eval {
                $source = $self->_kenmerk_replace(
                    $source,
                    $kenmerk,
                    ZAAKSYSTEEM_BETROKKENE_SUB->(
                        $zaak, $betrokkene_object, $kenmerk_postfix
                    )
                );
            };
            if ($@) {
                $self->c->log->error('Error converting element: '
                    . $kenmerk . ':' . $@
                );
            }
        }
    }

    return $source;
}


sub _replace_base_kenmerken {
    my ($self, $zaak, $source) = @_;

    my $standaard_kenmerken = ZAAKSYSTEEM_STANDAARD_KENMERKEN;

    for my $kenmerk (keys %{ $standaard_kenmerken }) {
        if (UNIVERSAL::isa($source, 'HASH')) {
            eval {
#                $self->c->log->debug('Replacing: ' . $kenmerk . ' with: ' .
#                    $zaak->systeemkenmerk($kenmerk)
#                );

                $self->_kenmerk_replace(
                    $source,
                    $kenmerk,
                    $zaak->systeemkenmerk($kenmerk)
                );
            };
            if ($@) {
                $self->c->log->error('Error converting element: '
                    . $kenmerk . ':' . $@
                );
            }
        } else {
            eval {
                $source = $self->_kenmerk_replace(
                    $source,
                    $kenmerk,
                    $zaak->systeemkenmerk($kenmerk)
                );
            };
            if ($@) {
                $self->c->log->error('Error converting element: '
                    . $kenmerk . ':' . $@
                );
            }
        }
    }

    return $source;
}


sub ACCEPT_CONTEXT {
    my ($self, $c) = @_;

    $self->{c} = $c;

    return $self;
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

