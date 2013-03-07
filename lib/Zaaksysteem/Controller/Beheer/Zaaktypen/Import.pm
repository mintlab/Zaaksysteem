package Zaaksysteem::Controller::Beheer::Zaaktypen::Import;
use Moose;
use namespace::autoclean;

use Hash::Merge::Simple qw( clone_merge );
use XML::Simple;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use Zaaksysteem::Constants;
use Archive::Extract;
use Clone qw(clone);
use XML::Dumper;
use Encode;

 
BEGIN {extends 'Catalyst::Controller'; }

use constant ZAAKTYPEN              => 'zaaktypen';
use constant ZAAKTYPEN_MODEL        => 'DB::Zaaktype';
use constant CATEGORIES_DB          => 'DB::BibliotheekCategorie';


has [qw/importer/] => (
    'is'    => 'rw',
);

sub base : Chained('/') : PathPart('beheer/zaaktypen/import') {
    my ( $self, $c ) = @_;
    
    my $importer = $self->_importer($c);


    my $zaaktype = $importer->imported_zaaktype;
    
    if($zaaktype) {
        eval {
            $self->_session($c)->{problems} = 0;
#            $c->log->debug("zt: " . Dumper $zaaktype);
            $importer->check_dependencies();
warn Dumper $self->_session($c)->{import_dependencies};

            $c->stash->{import_problems}        = $importer->problems;
            $c->stash->{zaaktype}               = $zaaktype;
            $c->stash->{import_dependencies}    = $self->_session($c)->{import_dependencies};
            $c->stash->{dependency_config}      = ZAAKTYPE_DEPENDENCIES;

        };
        if($@) {
            warn "import error: " .$@;
            $c->stash->{dependency_error} = $@;
        }
    }
    
    my $params = $c->req->params();

    $c->stash->{template} = 'beheer/zaaktypen/import.tt';
    if($params->{import} && $importer->problems == 0) {

        eval {
            $c->stash->{template} = 'beheer/zaaktypen/import/finish.tt';
            $c->stash->{zaaktype_node} = $importer->import($c->model('Zaaktypen'));
            $self->_session($c, 'flush');
        };
        if($@) {
            $c->stash->{import_error} = $@;
        }
    }
}

sub upload : Chained('/') : PathPart('beheer/zaaktypen/import/upload') {
    my ( $self, $c ) = @_;

    $self->_upload($c);

    $c->res->redirect($c->uri_for('/beheer/zaaktypen/import'));
    $c->detach();
}


sub flush : Chained('/') : PathPart('beheer/zaaktypen/import/flush') {
    my ( $self, $c ) = @_;

    $self->_session($c, 'flush');
    $c->res->redirect($c->uri_for('/beheer/zaaktypen/import'));
}



# show adjustment form
#
sub adjust : Chained('/') : PathPart('beheer/zaaktypen/import/adjust') {
    my ( $self, $c ) = @_;

    my $params          = $c->req->params();
    my $id              = $c->stash->{id}               = $params->{id};
    my $dependency_type = $c->stash->{dependency_type}  = $params->{dependency_type};

    my $importer= $self->_importer($c);

    $c->stash->{options}         = $importer->dependency_options($dependency_type, {remote_id => $id});
    $c->stash->{dependency_item} = $importer->dependency_item({dependency_type => $dependency_type, id => $id});

    $c->stash->{bib_cat} = $c->model(CATEGORIES_DB)->search({  
        'system'    => { 'is' => undef },
        'pid'       => undef,
    }, {  
        order_by    => ['pid','naam']
    });

    $c->stash->{dependency_config} = ZAAKTYPE_DEPENDENCIES;
    $c->stash->{nowrapper}         = 1;
    $c->stash->{template}          = 'beheer/zaaktypen/import/adjust.tt';
}



sub validate : Chained('/') : PathPart('beheer/zaaktypen/import/validate') {
    my ( $self, $c ) = @_;

    my $params          = $c->req->params();
    my $new_name        = $params->{new_name};
    my $dependency_type = $params->{dependency_type};

    my $importer        = $self->_importer($c);
    
    $new_name ||= $importer->dependency_item({
        dependency_type => $dependency_type, 
        id              => $params->{id}
    })->{name};
    
    my $option = $importer->dependency_options($dependency_type, {name => $new_name});

    my $json = { 
        success => 1
    };
    if($option) {
        $json->{success} = 0;
        $json->{error} = 'Geef een andere naam';
    }

    # validation for category items
    my $dependency_config = ZAAKTYPE_DEPENDENCIES->{$dependency_type};    
    if($dependency_config->{has_category}) {
        unless($params->{bibliotheek_categorie_id}) {
            $json->{success} = 0;
            $json->{categorie_error} = 'Geef een categorie';
        }
        # child already exists
        my $child_count = $c->model(CATEGORIES_DB)->search({
            pid     => $params->{bibliotheek_categorie_id} || 0,
            naam    => $params->{sub_categorie},
        })->count();
        if($child_count) {
            $json->{success} = 0;
            $json->{sub_categorie_error} = 'Subcategorie bestaat al'; 
        }
    }

    $c->stash->{json} = $json;
    $c->forward('Zaaksysteem::View::JSON');
}


sub approve : Chained('/') : PathPart('beheer/zaaktypen/import/approve') {
    my ( $self, $c ) = @_;

    my $params          = $c->req->params();
    my $id              = $c->stash->{id}               = $params->{id};
    my $dependency_type = $c->stash->{dependency_type}  = $params->{dependency_type};
    my $action          = $params->{action};

    $c->log->debug("Params: " . Dumper $params);
    my $dependency_config = ZAAKTYPE_DEPENDENCIES->{$dependency_type};
    my $importer = $self->_importer($c);

    my $dependency_item = $importer->dependency_item({dependency_type => $dependency_type, id =>$id});
    my $solution = $dependency_item->{solution} ||= {};
    $solution->{action} = $action;
    
    if($action eq 'add') {
        # validate the new name. if it exists, show an error and reshow the adjustment page
        $solution->{name} = $params->{new_name} || $dependency_item->{name};
        delete $solution->{id};

        
        if($dependency_config->{has_category}) {
            #$c->log->debug("Dep: " . Dumper $dependency_item);
            my $remote_record = $importer->lookup_remote_record($dependency_type, $id);
#            if(exists $dependency_item->{ancestry_hash}->{'zaaktype,zaaktype_node_id'}) { #TODO
#                my $zaaktype_id = $remote_record->{zaaktype_id};
#                $remote_record = $importer->lookup_remote_record('Zaaktype', $zaaktype_id);
#            }
            
            my $bibliotheek_categorie_id = $remote_record->{bibliotheek_categorie_id};
            $c->log->debug("bibcatID: " . $bibliotheek_categorie_id);
            if($bibliotheek_categorie_id) {
                 my $categorie_dependency_item = $importer->dependency_item({
                     dependency_type => 'BibliotheekCategorie', 
                     id              =>  $bibliotheek_categorie_id,
                 });
     
                 $categorie_dependency_item->solution({
                     action  => 'use_existing',
                     id      => $params->{bibliotheek_categorie_id},
                 });

                $solution->{bibliotheek_categorie_id} = $params->{bibliotheek_categorie_id};
            }
        }
        
        if($params->{multi_cat} && $dependency_config->{has_category}) {
            # look for other elements in the same group that also need to be placed in a category
            my $dependency_type_items = $self->_session($c)->{import_dependencies}->{$dependency_type};

            foreach my $other_id (keys %$dependency_type_items) {

                my $dependency = $importer->dependency_item({
                    dependency_type => $dependency_type, 
                    id              => $other_id
                });
                my $solution = $dependency->solution;
                unless($solution && %$solution) {
                $c->log->debug("dep: " . $params->{bibliotheek_categorie_id});
                    
                    $dependency->bibliotheek_categorie_id(
                        $params->{bibliotheek_categorie_id}
                    );
                }
                $c->log->debug("dep: " . Dumper $dependency);

            }
        }
        
        # only mark the item as 'changed' when the name has actually been modified
        if($solution->{name} ne $dependency_item->{name} || $params->{bibliotheek_categorie_id}) {
            $dependency_item->{solution}->{changed} = 1;
        }
        
    
    } elsif($action eq 'use_existing') {
        $solution->{id} = $params->{new_id};
        
        my $option = $importer->dependency_options($dependency_type, {id => $solution->{id}});

        $solution->{name} = $option->{name};
        $dependency_item->{solution}->{changed} = 1;
    } elsif($action eq 'revert') {
        delete $dependency_item->{solution};
    } else {
        die "incorrect action $action";
    }
    

    $c->stash->{nowrapper} = 1;
    if($params->{multi_cat}) {
     #   $c->forward('base');
    }


    $importer->check_dependencies();
    $c->stash->{dependency_config} = ZAAKTYPE_DEPENDENCIES;
    $c->stash->{dependency_item}   = $dependency_item;
    $c->stash->{template}          = 'beheer/zaaktypen/import/item.tt';
}



# ---------------------------- only friends can see private parts ---------------------- #



sub _importer {
    my ($self, $c) = @_;

    my $importer = $c->model('Zaaktypen::Import');
    my $filepath = $c->config->{files} .  '/tmp/store/';
    
    $importer->initialize({
        groups      => $c->model('Groups'), 
        filepath    => $filepath,
        session     => $self->_session($c),
    });

    return $importer;
}


sub _upload : Private {
    my ($self, $c) = @_;

    $self->_session($c, 'flush');

    my $params = $c->req->params();

    # this is IE, all in one    
    my $uploaded_file = $params->{upload};
    if($uploaded_file && $c->req->upload('upload')) {
        $c->forward("/form/fileupload");
    }
    # end IE

    my $filestore_id = $c->session->{last_fileupload}->{filestore_id};
    my $upload = $c->session->{last_fileupload}->{upload};


    my $options = {
        'filename'  => $upload->filename,
        'id'        => '0',
        'naam'      => $upload->filename,
    };
    
    $self->_session($c)->{'import_filename'} = $upload->filename;

    my $filestore = $c->model('Filestore');
    my $path = $filestore->_path($c, $filestore_id);
    
    my $archive = Archive::Extract->new( archive => $path, type => 'zip' );

    my $extract_path = $self->_filepath($c) . $filestore_id;
    $archive->extract(to => $extract_path);
    my $zaaktype_xml_file = $extract_path . '/zaaktype.xml';

    $self->_session($c)->{upload} = $archive;

    my $zaaktype = XML::Dumper::xml2pl($zaaktype_xml_file);

    $zaaktype->{filename} = $upload->filename;

    $self->_importer($c)->imported_zaaktype($zaaktype);
}



sub _session : Private {
    my ($self, $c, $flush) = @_;

    die "need c" unless($c);

    if($flush) {
        $c->log->debug('flush zaaktype import session');
        my $extract_path = $self->_filepath($c);
        system("rm -rf ${extract_path}*");
        return $c->session->{zaaktype_import} = {};
    }
    return $c->session->{zaaktype_import} ||= {};
}



sub _filepath : Private {
    my ($self, $c) = @_;

    return $c->config->{files} . '/tmp/store/';
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

