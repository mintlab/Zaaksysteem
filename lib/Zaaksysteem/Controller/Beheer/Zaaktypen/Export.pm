package Zaaksysteem::Controller::Beheer::Zaaktypen::Export;
use Moose;
use namespace::autoclean;

use Hash::Merge::Simple qw( clone_merge );

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use XML::Simple;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::stat;
use XML::Dumper;
use Encode;
use Params::Profile;


use Zaaksysteem::Constants;

BEGIN {extends 'Catalyst::Controller'; }


sub base : Chained('/') : PathPart('beheer/zaaktypen'): CaptureArgs(1) {
    my ( $self, $c, $zaaktype_id ) = @_;

    $c->{stash}->{zaaktype_id} = $zaaktype_id;
}


sub export : Chained('base') : PathPart('export') {
    my ( $self, $c ) = @_;

    my $zaaktype = $c->model('Zaaktypen')->export(
        id => $c->stash->{zaaktype_id},
    );

    $c->stash->{is_array} = sub { my $arg = shift; return ref $arg && ref $arg eq 'ARRAY' };

    $c->stash->{'zaaktype'} = $zaaktype;

    eval {
        my $file = $self->_export_zaaktype_to_file($c, $c->stash->{zaaktype_id});

        if($c->req->param('debug')) {
            my $xml_output = "<pre>".Dumper ($c->stash->{zaaktype}) ."</pre>";
            $c->res->body($xml_output);
        } else {    
            my $filepath = $file->{path} . $file->{filename};
            $c->log->debug("filename: " . $filepath);
            $c->serve_static_file($filepath);    
        
            my $stat = stat($filepath);
            system("rm $filepath");
            $c->res->headers->header(
                'Content-Disposition',
                'attachment; filename="' . $file->{filename}
            );
            $c->res->headers->content_length( $stat->size );
            $c->res->headers->content_type('application/zip');
            $c->res->content_type('application/zip');
        }
    };
    if($@) {
        $c->stash->{export_error} = $@;
        $c->stash->{template} = 'beheer/zaaktypen/export.tt';
    }
}


sub download : Chained('/') : PathPart('beheer/zaaktypen/export/download') {
    my ( $self, $c ) = @_;

    my $zaaktype_archive = $c->config->{files} . '/tmp';
    my $tar_file = 'store.tar.gz';

    chdir $zaaktype_archive;
    my $command = "tar -zcf $tar_file store/*.ztb";
    $c->log->debug($command);

    system($command);
    my $file = $zaaktype_archive .'/'. $tar_file;
    $c->log->debug("file: $file");
    $c->serve_static_file($file);    

    my $stat = stat($file);
#    system("rm $file");
    $c->res->headers->header(
        'Content-Disposition',
        'attachment; filename="' . $tar_file
    );
    $c->log->debug("fddd");
    $c->res->headers->content_length( $stat->size );
    $c->res->headers->content_type('application/zip');
    $c->res->content_type('application/zip');    
}



sub exportall : Chained('/') : PathPart('beheer/zaaktypen/export') {
    my ( $self, $c ) = @_;

    my $zaaktypen = $c->model("DB::Zaaktype")->search({deleted => undef}, {order_by =>{'-asc' => 'id'}});
    
    my $filenames = [];
    my $count = 0;
    while (my $zaaktype = $zaaktypen->next) {
        my $zaaktype_id = $zaaktype->id;
        my $file = $self->_export_zaaktype_to_file($c, $zaaktype_id);
        $c->log->debug("exporting zaaktype $zaaktype_id to " . Dumper $file);
        push @$filenames, {zaaktype_id => $zaaktype_id, filename => $file->{filename}};
        #last if ++$count > 10;
    }
    
    $c->stash->{filenames} = $filenames;
    
    $c->stash->{template} = 'beheer/zaaktypen/exportall.tt';
}

# ----------------------------------- this could be in a model ------------------------------- #



sub _export_zaaktype_to_file {
    my ($self, $c, $zaaktype_id) = @_;

# flush accumulated stuff
    delete $c->stash->{zaaktype_export};

    my $zaaktype = $c->model('Zaaktypen')->export(
        id => $zaaktype_id,
    );

    $self->_preprocess_zaaktype({c => $c, data => $zaaktype});

    $zaaktype->{zaaktype}->{id} = $zaaktype_id;
    $zaaktype->{db_dependencies} = $c->stash->{zaaktype_export}->{db_dependencies};
    $c->stash->{zaaktype} = $zaaktype;
    my $xml_output = XML::Dumper::pl2xml($zaaktype);    
    $xml_output = encode("utf-8", $xml_output);
    
       
    my $zip = Archive::Zip->new();
    
    # main xml body
    my $string_member = $zip->addString($xml_output, 'zaaktype.xml');

    # attachments
    my $attached_files = $self->_attached_files($c);
    $c->log->debug("attached files: " . Dumper $attached_files);
    foreach my $attached_file (keys %$attached_files) {
        my $filepath = $attached_files->{$attached_file};

        if(-e $filepath) {
            $c->log->debug("adding $attached_file");
            my $file_member = $zip->addFile( $filepath, $attached_file );
        } else {
            warn "couldnt find filestore file, maybe because of test environment?";
            $zip->addString("dummy file", $attached_file);
        }
    }

    my $filename = $zaaktype->{node}->{titel};
    
    my $safe_filename_characters = "a-zA-Z0-9_.-";
    $filename =~ tr/ /_/; 
    $filename =~ s/[^$safe_filename_characters]/_/g;
    
    my $path = $c->config->{files} . '/tmp/store/';
    my $zipfilename = $path . $filename . '.ztb';

    unless ( $zip->writeToFileNamed($zipfilename) == AZ_OK ) {
        die 'write error' . $!;
    }

    return {filename => $filename . '.ztb', path => $path};
}






{
    Params::Profile->register_profile(
        method  => '_preprocess_zaaktype',
        profile => {
            required        => [ qw/
                c
                data
            /],
            'optional'      => [ qw/
                parent
            /],
            'constraint_methods'    => {
            },
        }
    );


    sub _preprocess_zaaktype {
        my ($self, $params) = @_;
    
        my $dv = Params::Profile->check(params  => $params);
        die "invalid options" unless $dv->success;
    
        my $c       = $params->{c};
        my $data   = $params->{data};
        my $parent  = $params->{parent} || '';

    
        foreach my $key (keys %$data) {
            my $child_data = $data->{$key};
    
            if($key eq 'zaaktype_node_id') {

                #look up the title, substitute that
                my $zaaktype_node_id = $data->{$key};
                die "need zaaktype_node_id" unless $zaaktype_node_id;
                my $zaaktype_node = $c->model('DB::ZaaktypeNode')->find($zaaktype_node_id);

                $data->{zaaktype_titel} = $zaaktype_node->zaaktype_id->zaaktype_node_id->titel;
                delete $data->{$key};
            }

    
            if( $key eq 'zaaktype_definitie_id' || 
                $key eq 'zaak_status_id' || 
                $key eq 'zaaktype_categorie_id'
            ) {
                
                $c->log->debug('deleting data key: ' . $parent . ', key: ' . $key . ', value: ' . Dumper $data->{$key});
                delete $data->{$key};
            }

            
            if(ref $child_data && ref $child_data eq 'HASH') {
                # skip number when deciding who's the parent
                my $parent = $key =~ m|^\d+$| ? $parent : $key;
                $self->_preprocess_zaaktype({c => $c, data => $child_data, parent => $parent});
            } elsif(ref $child_data && ref $child_data eq 'ARRAY') {
                #$c->log->debug("arrray found: " . Dumper $child_data);
            } else {
                if($parent eq 'regels' && $key eq 'settings') {
                    delete $data->{$key};
                } else {           
                    $self->_lookup_id_field({c => $c, data => $data, key =>$key});
                }
            }
        }
    }
}



{
    Params::Profile->register_profile(
        method  => '_include_reference',
        profile => {
            required        => [ qw/
                c
                data
                key
            /],
            'optional'      => [ qw/
                from_can_id
            /],
            'constraint_methods'    => {
            },
        }
    );


    sub _include_reference {
        my ($self, $params) = @_;
    
        my $dv = Params::Profile->check(params  => $params);
        die "invalid options" unless $dv->success;
    
        my $c               = $params->{c};
        my $data            = $params->{data};
        my $key             = $params->{key};
        my $from_can_id     = $params->{from_can_id};

    
        my $id = $data->{$key};
    
        if($key eq 'role_id') {
            my $role = $c->model('Groups')->get_role_by_id($id);
    
            $role ||= 'Organisatorische eenheid niet gevonden ('. $id . ')';
            if($role) {
                $self->_db_dependency({
                    c       => $c, 
                    table   =>'LdapRole', 
                    id      => $id, 
                    db_row  => { short_name => $role }
                });
            }
            return;
        } elsif($key eq 'ou_id') {
    
            my $ou = $c->model('Groups')->get_ou_by_id($id);

            $ou ||= 'Organisatorische eenheid niet gevonden ('. $id . ')';
            if($ou) {
                $self->_db_dependency({
                    c       => $c, 
                    table   => 'LdapOu', 
                    id      => $id, 
                    db_row  => { ou => $ou }
                });
            }
            return;
        } elsif($key eq 'relatie_zaaktype_id') {
            # it's really a zaaktype_node_id. just look that up and substitute
            
            my $zaaktype_node = $c->model("DB::ZaaktypeNode")->find($id);
            die "incorrect zaaktype, relatie zaaktype_node_id $id not found" unless($zaaktype_node);
    
            my $zaaktype_id = $zaaktype_node->zaaktype_id->id;
            die "incorrect zaaktype, couldn't find zaaktype" unless($zaaktype_id);
            $id = $data->{$key} = $zaaktype_id;
        }
        
    
        my $table = $self->_tablename({ id_field => $key }) or return;
    
        my $db_row = $c->model("DB::".$table)->find($id);
        die "incorrect zaaktype, could not find $table $id" . Dumper $data unless($db_row);
    
        if($db_row) {
    
            if($self->_db_dependency({
                c       => $c, 
                table   => $table, 
                id      => $id
            })) {
                $c->log->debug("table $table id $id already included");
                return;
            }
    
            my $hash = $self->_retrieve_db_row_as_hash({
                c       => $c, 
                table   => $table, 
                db_row  => $db_row
            });
    
            $self->_db_dependency({
                c       => $c, 
                table   => $table, 
                id      => $id, 
                db_row  => $hash
            });
    
    
            if($table eq 'BibliotheekKenmerken') {
                my $options = $c->model("DB::BibliotheekKenmerkenValues")->search({
                    bibliotheek_kenmerken_id => $id
                });
                my @values = ();
                while (my $option = $options->next) {
                    push @values, $option->value;
                }
                if(@values) {
                    $hash->{options} = \@values;
                }
            }
    
        }
    }
}



{
    Params::Profile->register_profile(
        method  => '_retrieve_db_row_as_hash',
        profile => {
            required        => [ qw/
                c
                table
                db_row
            /],
            'optional'      => [ qw/
            /],
            'constraint_methods'    => {
            },
        }
    );


    sub _retrieve_db_row_as_hash {
        my ($self, $params) = @_;
    
        my $dv = Params::Profile->check(params  => $params);
        die "invalid options" unless $dv->success;
    
        my $c       = $params->{c};
        my $table   = $params->{table};
        my $db_row  = $params->{db_row};
        
        my $result = {};
        my @columns = $db_row->result_source->columns;
    
        for my $column (@columns) {
            next if($column eq 'id');
    
            if (ref($db_row->$column) && $db_row->$column->can('id')) {
    
                my $id = $result->{$column} = $db_row->$column->id;
    
                # also find sub-dependencies, include these too.
                my $table = $self->_tablename({ id_field => $column });
    
                if($table && !$self->_db_dependency({
                    c       => $c, 
                    table   =>$table, 
                    id      => $id
                })) {
                    my $hash = {};
                    
                    # to avoid endless recursion, first create the empty dependency,
                    # then continue to fill it with values. this disarms circular references
                    $self->_db_dependency({
                        c       => $c, 
                        table   => $table, 
                        id      => $id, 
                        db_row  => $hash
                    });
                    
                    my $retrieved_hash = $self->_retrieve_db_row_as_hash({
                        c       => $c, 
                        table   => $table, 
                        db_row  => $db_row->$column
                    });
    
                    foreach my $key (keys %$retrieved_hash) {
                        $hash->{$key} = $retrieved_hash->{$key};
                    }
                }
                
            } elsif (!ref($db_row->$column)) {
                $result->{$column} = $db_row->$column;
            } else {
                $c->log->debug("ug?");
            }
            
        }
    
        if(exists $result->{zaaktype_node_id}) {
            #look up the title, substitute that
            my $zaaktype_node_id = $result->{zaaktype_node_id};
            my $zaaktype_node = $c->model('DB::ZaaktypeNode')->find($zaaktype_node_id);
            $result->{zaaktype_titel} = $zaaktype_node->zaaktype_id->zaaktype_node_id->titel;
            delete $result->{zaaktype_node_id};
        }
    
        if($table eq 'Filestore') {
    #        $c->log->debug("filestore in da house: " . $db_row->id . ',dffdfd' . Dumper $result);
            
            my $filestore_path = $c->config->{files} . '/filestore/' . $db_row->id;
            #unless(-e $filestore_path) {
            #    warn "file not found: $filestore_path";
            #}
    
            $self->_attached_files($c)->{$db_row->id} = $filestore_path;
        }
        
        return $result;
    }
}



{
    Params::Profile->register_profile(
        method  => '_lookup_id_field',
        profile => {
            required        => [ qw/
                c
                data
                key
            /],
            'optional'      => [ qw/
            /],
            'constraint_methods'    => {
            },
        }
    );

    sub _lookup_id_field : Private {
        my ($self, $params) = @_;
    
        my $dv = Params::Profile->check(params  => $params);
        die "invalid options" unless $dv->success;
    
        my $c       = $params->{c};
        my $data    = $params->{data};
        my $key     = $params->{key};

        return unless($key =~ m|_id$| || $key =~ m|_kenmerk$|);
        
        return unless($data->{$key} && $data->{$key} =~ m|^\d+$|);
    
        return unless int($data->{$key}) > 0;
        
        $self->_include_reference({c => $c, data => $data, key => $key});
    }
}




{
    Params::Profile->register_profile(
        method  => '_tablename',
        profile => {
            required        => [ qw/
                id_field
            /],
            'optional'      => [ qw/
            /],
            'constraint_methods'    => {
            },
        }
    );
    
    sub _tablename {
        my ($self, $params) = @_;
    
        my $dv = Params::Profile->check(params  => $params);
        die "invalid options" unless $dv->success;
    
        my $id_field = $params->{id_field};

        my $config = ZAAKTYPE_DEPENDENCY_IDS;
        foreach my $regexp (keys %$config) {
            next unless($id_field =~ m|$regexp|);
    
            return $config->{$regexp};
        }
        
        return undef;
    }
}




{
    Params::Profile->register_profile(
        method  => '_db_dependency',
        profile => {
            required        => [ qw/
                c
                table
                id
            /],
            'optional'      => [ qw/
                db_row
            /],
            'constraint_methods'    => {
            },
        }
    );
   
    sub _db_dependency : Private {
        my ($self, $params) = @_;

        my $dv = Params::Profile->check(params  => $params);
        die "invalid options" unless $dv->success;
    
        my $c       = $params->{c};
        my $table   = $params->{table};
        my $id      = $params->{id};
        my $db_row  = $params->{db_row};

    
        if($db_row) {
            $c->stash->{zaaktype_export}->{db_dependencies}->{$table}->{$id} ||= $db_row;
        } else {
            return $c->stash->{zaaktype_export}->{db_dependencies}->{$table}->{$id};
        }
    }
}

sub _attached_files : Private {
    my ($self, $c) = @_;

    return $c->stash->{zaaktype_export}->{attached_files} ||= {};
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

