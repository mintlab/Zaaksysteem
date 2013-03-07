package Zaaksysteem::Zaaktypen::Import;

use strict;
use warnings;

use Params::Profile;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Zaaksysteem::Constants;

use Moose;
use namespace::autoclean;
use Clone qw(clone);
use Carp qw(cluck);


use Zaaksysteem::Zaaktypen::Dependency;

has [qw/prod log dbic groups session filepath problems export_zaaktype/] => (
    'is'    => 'rw',
);



{
    Params::Profile->register_profile(
        method  => 'initialize',
        profile => {
            required        => [ qw/
                session
                groups
                filepath
            /],
        }
    );

    sub initialize {
        my ($self, $params) = @_;

        my $dv = Params::Profile->check(params  => $params);
        die "invalid options" unless $dv->success;
    
        $self->session($params->{session});
        $self->groups($params->{groups});
        $self->filepath($params->{filepath});
    }
}


sub imported_zaaktype {
    my ($self, $zaaktype) = @_;

    if($zaaktype) {
        $self->session->{imported_zaaktype} = $zaaktype;
    }
    
    return $self->session->{imported_zaaktype};
}



sub import {
    my ($self, $zaaktypen_model) = @_;
    
    $self->export_zaaktype(clone $self->imported_zaaktype);
    
    my $import_dependencies = clone $self->session->{import_dependencies};
    #$self->log->debug("importdep: " . Dumper $import_dependencies);
    
    my $zaaktype_node;
    my $zaaktype_id = $self->export_zaaktype->{zaaktype}->{id};

    $self->dbic->txn_do(sub {
        eval {
            # don't modify the session info
            #$zaaktype->{zaaktype}->{id} = $zaaktype->{node}->{zaaktype_id};
            delete $self->export_zaaktype->{zaaktype}->{zaaktype_titel};
            $self->export_zaaktype->{node}->{zaaktype_omschrijving} = 'Import ' . localtime();
            $self->execute_changes($import_dependencies);

            delete $self->export_zaaktype->{zaaktype}->{zaaktype_definitie_id};
            my $main_solution = $import_dependencies->{Zaaktype}->{$zaaktype_id}->solution;
            if($main_solution->{action} eq 'use_existing') {
                $self->export_zaaktype->{zaaktype}->{id} = $main_solution->{id};
                delete $self->export_zaaktype->{zaaktype}->{bibliotheek_categorie_id};
            } elsif($main_solution->{action} eq 'add') { 
                delete $self->export_zaaktype->{zaaktype}->{id};
                $self->export_zaaktype->{node}->{titel} = $main_solution->{name};
                $self->export_zaaktype->{zaaktype}->{bibliotheek_categorie_id} = $main_solution->{bibliotheek_categorie_id};
                delete $self->export_zaaktype->{zaaktype}->{zaaktype_categorie_id};
            } else {
                die "incorrect action";
            }
            
#            $self->log->debug("export zt: " . Dumper $self->export_zaaktype);
            $zaaktype_node = $zaaktypen_model->commit_session(
                session     => $self->export_zaaktype
            );    
        };
    
        if ($@) {
            $self->log->error('Error: ' . $@);
            die("Import error: " . $@);
        } else {
            $self->log->info('Zaaktype geimportuleerd');
        }
    });

    $self->flush;
    return $zaaktype_node;
}


sub execute_changes {
    my ($self, $import_dependencies) = @_;

    foreach my $table (sort keys %$import_dependencies) {

        my $table_items = $import_dependencies->{$table};
        foreach my $id (keys %$table_items) {
            $self->execute_change($table_items->{$id}, $table, $id);
        }
    }
}


sub execute_change {
    my ($self, $dependency, $table, $id) = @_;

    my $sub_items = $dependency->sub_items($self->export_zaaktype);
    
    # implement solution
    my $solution = $dependency->{solution};
    return $solution->{id} unless ($sub_items);

    my $keyname = $dependency->{keyname};
    my $new_id;

    if($solution->{action} eq 'add') {
        $new_id = $self->execute_add_action($dependency, $table, $id);
    } elsif( $solution->{action} eq 'use_existing') {
        $new_id = $solution->{id};
    } else {
        unless($table eq 'BibliotheekCategorie') {
            die "illegal action configured: " . Dumper $dependency;
        }
    }

    if($dependency->{main_zaaktype}) {
        $self->export_zaaktype->{zaaktype}->{id} = $new_id;
        delete $self->export_zaaktype->{zaaktype}->{bibliotheek_categorie_id};
    }

    foreach my $sub_item (@$sub_items) {
        my $item = $sub_item->{sub_item} or die Dumper $sub_items;
        my $key_name = $sub_item->{key_name} or die Dumper $sub_items;
        $item->{$key_name} = $new_id;
    } 
    
    return $new_id;
}


sub execute_add_action {
    my ($self, $dependency, $table, $id) = @_;

    # create new item
    # first get the information on the new item from the db_dependencies repository, then
    # feed that to the database. receive the new id, put that in.
    my $remote_record = clone $self->lookup_remote_record($table, $id);
    
    foreach my $key (keys %$remote_record) {
        my $related_table = $self->tablename({id_field => $key});

        if($related_table && $related_table ne 'Zaaktype') {
            my $related_id = $remote_record->{$key};

            if($related_id) {
                my $related_dependency = $self->dependency_item({dependency_type => $related_table, id => $related_id});
        
                if($related_table && keys %$related_dependency) {
                    $self->log->debug("doing related item first $related_table $related_id");
                    my $new_id = $self->execute_change($related_dependency, $related_table, $related_id);
                    $remote_record->{$key} = $new_id;
                }
            } else {
                warn "empty id passed around, why oh why-oh";
            }
        }
    }

    my $dependency_config = ZAAKTYPE_DEPENDENCIES->{$table};
    my $solution = $dependency->solution;

    my $name_field = $dependency_config->{name};

    $remote_record->{$name_field} = $dependency->solution->{name};

    if($table eq 'Zaaktype') {
        # nop
    }
    
    else {
    
# pay close scrutiny here
        my $remote_options = $remote_record->{options} || [];
        delete $remote_record->{options};

        if($remote_record->{pid}) {
            delete $remote_record->{pid};
        }
        
        # categorie id is a special case, happens in non nice fashion. TODO 
        #
        if($solution->{bibliotheek_categorie_id} && exists $remote_record->{bibliotheek_categorie_id}) {
            $remote_record->{bibliotheek_categorie_id} = $solution->{bibliotheek_categorie_id};
        }
##
    die cluck "attempt to create categorie" if($table eq 'BibliotheekCategorie');

        ### Make sure we do not add columns which are deprecated since
        ### OpenSource release. Strip missing columns; This could have been a
        ### oneliner, but for readability I have written it out over several
        ### lines. (Good excuse for not being extremely sharp eh ;) )
        {
            my $clean_record    = {};
            for my $record (keys %{ $remote_record }) {
                next unless grep { $_ eq $record }
                    $self->dbic->source($table)->columns;

                $clean_record->{ $record } = $remote_record->{ $record };
            }

            $remote_record = $clean_record;
        }

        my $row = $self->dbic->resultset($table)->create($remote_record);
        $self->log->debug("creating row $table $id, new local id: " . $row->id);
    
        if($table eq 'BibliotheekKenmerken') {
            
            foreach my $option (@$remote_options) {
                my $value_record = {
                    bibliotheek_kenmerken_id => $row->id,
                    value                    => $option,
                };
                my $value_row = $self->dbic->resultset("BibliotheekKenmerkenValues")->create($value_record);
            }

        } elsif($table eq 'Filestore') {
            my $archive = $self->session->{upload};

            my $source = $archive->extract_path . "/" . $id;
            my $destination = $self->filepath . '../../filestore/' . $row->id;
            system("cp $source $destination");
            die "creation of file unsuccessful" unless -e $destination;
        }

        return $row->id;
    }
}








sub check_dependencies {
    my ($self) = @_;

    my $imported_zaaktype = $self->imported_zaaktype;

    $self->problems(0);
    $self->traverse_zaaktype({ data=>$imported_zaaktype, ancestry=>[] });
}




{
    Params::Profile->register_profile(
        method  => 'traverse_zaaktype',
        profile => {
            'optional'      => [ qw/
                ancestry
                data
            /],
        }
    );
    sub traverse_zaaktype {
        my ($self, $params) = @_;

        my $dv = Params::Profile->check(params  => $params);
        die "invalid options" unless $dv->success;
        
        my $ancestry = $params->{ancestry};
        my $data     = $params->{data};
        
        foreach my $key (sort keys %$data) {  
            next if($key eq 'BibliotheekCategorie');
            my $child_data = $data->{$key};
            next unless defined $child_data;
            
            if(ref $child_data && ref $child_data eq 'HASH') {
                my $new_ancestry = clone $ancestry;
                push @$new_ancestry, $key;
                $self->traverse_zaaktype({data=>$child_data, ancestry=>$new_ancestry});
    
            } elsif(ref $child_data && ref $child_data eq 'ARRAY') {
            } else {
                
                if(my $table = $self->tablename({id_field => $key})) {

                    if(
                        $data->{$key}                   && 
                        $data->{$key} =~ m|^\d+$|       && 
                        int($data->{$key}) > 0          &&
                        $table ne 'BibliotheekCategorie'
                    ) {
                        $self->check_dependency($table, $data, $key, $ancestry);
                    }
                }
            }
        }
    }


}






{
    Params::Profile->register_profile(
        method  => 'tablename',
        profile => {
            required      => [ qw/
                id_field
            /],
        }
    );
    
    sub tablename {
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

#
# the export script has generously provided us with a lookup table containing
# full table rows of the referenced items. lookup the table row that goes
# with the id, then have the 'match' function check if it's a match. in that case
# all is well and dandy and we do nothing. if there's reasonable doubt, give the 
# user a choice. 
#
sub check_dependency {
    my ($self, $table, $data, $key, $ancestry) = @_;

    my $id = $data->{$key};
    
    my $dependency = $self->dependency_item({dependency_type => $table, id => $id});

    if($table eq 'Zaaktype' && $id eq $self->imported_zaaktype->{zaaktype}->{id}) {
        $dependency->{main_zaaktype} = 1;
    }
    # if the reference has already been looked up, just add the ancestry to the item. e.g. one
    # kenmerk may be used in different phases of the zaaktype. It only needs to be resolved once,
    # but we need to know where to replace it during the actual import.
    if($dependency->solution) {
        $dependency->add_ancestry($ancestry, $key);
        return;
    }

    my $remote_record;
    unless($remote_record = $self->lookup_remote_record($table, $id)) {
        $self->log->debug("table: $table" . Dumper( $data) . 'key: '. $key . Dumper $ancestry);
        die 'Fout in zaaktype bestand. ' . " $key $table $id mist";
    }
    
    my $match_fields    = ZAAKTYPE_DEPENDENCIES->{$table}->{match};
    my $name_field      = ZAAKTYPE_DEPENDENCIES->{$table}->{name};
    my $condition       = {map { $_ => $remote_record->{$_} } @$match_fields};    

    # record the original name of the item
    $dependency->name($remote_record->{$name_field});
    $dependency->id($data->{$key});
    $dependency->add_ancestry($ancestry, $key);

    my $match = $self->find_match($table, $dependency, $condition, $data);

    # category stuff
    my $dependency_config = ZAAKTYPE_DEPENDENCIES->{$table};

    my $is_ldap = ($table eq 'LdapRole' || $table eq 'LdapOu');

    if($match->{count} == 0 && !$is_ldap) {
    
        # inform the user that the item has not been found and ask for permission to insert it
        my $solution = {
            action  => 'add',
            name    => $remote_record->{$name_field},
        };

        if($dependency_config->{has_category}) {
            if($dependency->bibliotheek_categorie_id) {
                $solution->{bibliotheek_categorie_id} = $dependency->bibliotheek_categorie_id;
                $dependency->solution($solution);         
            } else {
                my $categorie_id = $self->find_category_match($remote_record->{bibliotheek_categorie_id});
                if($categorie_id) {
                    $dependency->bibliotheek_categorie_id($categorie_id);
                } else {
                    # user will have to clear up the category thing before this can be inserted
                    $dependency->remove_solution();
                    $self->problems($self->problems + 1);
                    $self->log->debug("(2) no automatic resolution found for $key $table $id ($match->{count} matches)");
                }
            }
        } else {
            $dependency->solution($solution);
        }

    } elsif($match->{count} == 1) {
        die "coding error, match should contain somethin (feed programmer more coffee)" unless($match->{id});
        
        my $name = $remote_record->{$name_field};
        if($table eq 'Zaaktype') {
        #    $name = $dependency->name;
        }

        unless($dependency->solution) {
            $dependency->solution({
                action          => 'use_existing',
                id              => $match->{id},
                name            => $name,
            });
        }

        if($table eq 'Zaaktype') {
            $dependency->id($match->{id});
        }

    } else {
        unless($table eq 'BibliotheekCategorie') {
            $self->problems($self->problems + 1);
            $self->log->debug("no automatic resolution found for $key $table $id ($match->{count})");
        }
    }
}



#
# find out if the given category is present on the receiving system. track it
# back to the top. also, if this dependency has been cleared already, offer
# that solution
#
sub find_category_match {
    my ($self, $bibliotheek_categorie_id) = @_;


# create a string with the remote ancestry
    my $count = 0;
    my $parent;
    my $remote_ancestry = [];
    while($bibliotheek_categorie_id) {
        my $remote_record = $self->lookup_remote_record(
            'BibliotheekCategorie', 
            $bibliotheek_categorie_id
        );
        push @$remote_ancestry, $remote_record->{naam} if($remote_record->{naam});

        last unless($remote_record->{pid});
        
        $bibliotheek_categorie_id = $remote_record->{pid};
        if(++$count > 50) {
            die "elvis has left the building";
        }
    }
    
    my $pid = 0;
    foreach my $ancestor (@$remote_ancestry) {
        #$self->log->debug("ancestor: " . $ancestor);
        my $resultset = $self->dbic->resultset("BibliotheekCategorie")->search({
            naam => $ancestor,
            pid  => $pid,
        });

        return undef unless($resultset->count() == 1);
        $self->log->debug("resultset count: " . $resultset->count());
        my $local_categorie = $resultset->first();
        $pid = $local_categorie->pid;
    }

    return $pid;
}



sub lookup_remote_record {
    my ($self, $table, $id) = @_;

    return $self->imported_zaaktype->{db_dependencies}->{$table}->{$id};
}




sub find_match {
    my ($self, $table, $dependency, $condition, $data) = @_;

    my $result = {count => 0};

    if($table eq 'LdapRole' || $table eq 'LdapOu') {
                
        my $ldap_match = $self->check_ldap_dependencies($table, $condition);

        if($ldap_match) {
            $result->{count} = 1;
            $result->{id} = $ldap_match->{id};
        }

    } elsif($table eq 'Zaaktype') {

        my $resultset = $self->dbic->resultset("ZaaktypeNode")->search({
                'me.titel' => $dependency->name,
                'zaaktypes.deleted' => undef,
                'me.deleted' => undef,
            },
            {
                join     => 'zaaktypes',
                distinct => 1,
                columns  => ['zaaktype_id'],
            }
        );
        $result->{count} = $resultset->count();
        if($result->{count} == 1) {
            my $row = $resultset->first();
            

            $dependency->id($row->zaaktype_id->id);
            $result->{id} = $row->zaaktype_id->id;
        }

    } elsif($table eq 'BibliotheekKenmerken' && $data->{options} && scalar @{$data->{options}}) {
    
        # bibliotheek kenmerken types like option and checkbox have related rows in the 
        # bibliotheek_kenmerken_values table. verify if these are the same.

        ### Make sure we do not add columns which are deprecated since
        ### OpenSource release. Strip missing columns; This could have been a
        ### oneliner, but for readability I have written it out over several
        ### lines. (Good excuse for not being extremely sharp eh ;) )
        {
            my $clean_record    = {};
            for my $record (keys %{ $condition }) {
                next unless grep { $_ eq $record }
                    $self->dbic->source($table)->columns;

                $clean_record->{ $record } = $condition->{ $record };
            }

            $condition = $clean_record;
        }
        my $resultset = $self->dbic->resultset($table)->search($condition);
        my $count = $resultset->count();

        if($count) {
            my $db_row   = $resultset->first();
            
            my $options = $self->dbic->resultset("BibliotheekKenmerkenValues")->search({
                bibliotheek_kenmerken_id => $db_row->id,
            });
            my @values = ();
            while (my $option = $options->next) {
                push @values, $option->value;
            }
            my $local_options = join ",", sort @values;
            my $items = $data->{options};
            $items = [$items] unless ref $items;
            my $remote_options = join ",", sort @$items;
            if($local_options eq $remote_options) {
                $result->{id} = $db_row->id;
                $result->{count} = $count;
            }
        }
    
    } else {
        ### Make sure we do not add columns which are deprecated since
        ### OpenSource release. Strip missing columns; This could have been a
        ### oneliner, but for readability I have written it out over several
        ### lines. (Good excuse for not being extremely sharp eh ;) )
        {
            my $clean_record    = {};
            for my $record (keys %{ $condition }) {
                next unless grep { $_ eq $record }
                    $self->dbic->source($table)->columns;

                $clean_record->{ $record } = $condition->{ $record };
            }

            $condition = $clean_record;
        }

        my $resultset    = $self->dbic->resultset($table)->search($condition);
        $result->{count} = $resultset->count();

        if($result->{count} == 1) {
            my $db_row   = $resultset->first();
            $result->{id} = $db_row->id;
        }
    }

    return $result;
}



sub check_ldap_dependencies {
    my ($self, $table, $condition) = @_;

    my $items = $table eq 'LdapOu' ? $self->groups->search_ou() : $self->groups->search();
    
    foreach my $item (@$items) {
        my $score = 0;
        foreach my $field (keys %$condition) {
            $score++ if($item->{$field} eq $condition->{$field});
        }
        return $item if($score == scalar keys %$condition);  # return the first match
    }
    return undef;
}


#
# these contain all the options for a dependency. e.g. in the case of 'kenmerken', this
# returns a list with all the kenmerken that can be linked.
#
sub dependency_options {
    my ($self, $dependency_type, $query) = @_;
    
    my $dependency_config = ZAAKTYPE_DEPENDENCIES->{$dependency_type}
        or return undef;

    my $table = $dependency_type;

#    unless($self->_session->{dependency_options}->{$table}) {
        my $name_field = $dependency_config->{name};
        my $options = {};

        my $resultset;        
        my @options = ();

        if($table eq 'Zaaktype') {
            $resultset = $self->dbic->resultset("Zaaktype")->search({
                'me.deleted' => undef,
            }, {
                prefetch => 'zaaktype_node_id',
            });
            
            while (my $item = $resultset->next) {
                push @options, { 
                    id      => $item->id,
                    name    => $item->zaaktype_node_id->titel,
                };
            }
        } elsif($table eq 'LdapOu') {
            my $items = $self->groups->search_ou();
            foreach my $item (@$items) {
                push @options, { 
                    id      => $item->{id},
                    name      => $item->{ou},
                };
            }
        } elsif($table eq 'LdapRole') {
            my $items = $self->groups->search();
            foreach my $item (@$items) {
                push @options, { 
                    id      => $item->{id},
                    name    => $item->{short_name},
                };
            }
        } else {
            $options->{order_by} = $name_field;

            my $alternative_condition = {};
            $self->log->debug("table: $table");
            if($table eq 'BibliotheekKenmerken') {
                $alternative_condition->{system} = undef;
            }

            $resultset = $self->dbic->resultset($table)->search($alternative_condition, $options);

            while (my $item = $resultset->next) {
                push @options, { 
                    id      => $item->id,
                    name    => $item->$name_field,
                };
            }
        }

        
        $self->session->{dependency_options}->{$table} = \@options;
#    }
    
    if($query && $query->{id}) {
        foreach my $option (@{$self->session->{dependency_options}->{$table}}) {
            return $option if($option->{id} eq $query->{id});
        }
        return undef;
    }
    if($query && $query->{name}) {
        foreach my $option (@{$self->session->{dependency_options}->{$table}}) {
            return $option if($option->{name} eq $query->{name});
        }
        return undef;
    }

    return $self->session->{dependency_options}->{$table};
}




{
    Params::Profile->register_profile(
        method  => 'dependency_item',
        profile => {
            required        => [ qw/
                dependency_type
                id
            /],
        }
    );    
    sub dependency_item {
        my ($self, $params) = @_;
        
        my $dv = Params::Profile->check(params  => $params);
        die "invalid options" .Dumper ($params) unless $dv->success;

        my $dependency_type = $params->{dependency_type};
        my $id              = $params->{id};

        unless(exists $self->session->{import_dependencies}->{$dependency_type}->{$id}) {
            $self->session->{import_dependencies}->{$dependency_type}->{$id} = 
                new Zaaksysteem::Zaaktypen::Dependency();
        }
        return $self->session->{import_dependencies}->{$dependency_type}->{$id};
    }
}





sub flush {
    my ($self) = @_;

    $self->log->debug('flush zaaktype import session');
    my $extract_path = $self->filepath();
    system("rm -rf ${extract_path}*");
    $self->session({});
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

