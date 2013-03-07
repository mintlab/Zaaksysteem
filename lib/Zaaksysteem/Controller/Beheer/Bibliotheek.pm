package Zaaksysteem::Controller::Beheer::Bibliotheek;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use Data::Dumper;

use constant CATEGORIES_DB           => 'DB::BibliotheekCategorie';

my $CATEGORY_FIELDS = {
    'naam'      => 'naam',
};


sub base : Chained('/') : PathPart('beheer/bibliotheek'): CaptureArgs(0) {
    my ( $self, $c ) = @_;

}


sub categories : Private {
    my ( $self, $c, $catid, $type ) = @_;

    $c->stash->{template} = 'beheer/bibliotheek/categories.tt';

    $c->stash->{bib_type} = $type;

    $c->add_trail(
        {
            uri     => $c->uri_for('/beheer/zaaktype_catalogus/'
            ),
            label   => 'Zaaktype Catalogus',
        }
    );

    $c->stash->{bib_cat}        = $c->model(CATEGORIES_DB)->search(
        {
            pid => ($catid && $catid =~ /^\d+$/ ? $catid : undef),
        },
        {
            order_by    => 'naam'
        }
    );

    if ($catid && $catid =~ /^\d+$/) {
        $c->stash->{categorie}   = $c->model(CATEGORIES_DB)->find($catid)
            or $c->detach;
    } elsif (lc($catid) ne 'skip') {
        $c->detach;
    }
}


sub list : Chained('/') : PathPart('beheer/bibliotheek'): CaptureArgs(0) {
    my ( $self, $c, $categorie_id ) = @_;


    $c->log->debug('Category-ID: '.Dumper($categorie_id));


    my @total_elements;
    my @all_table_lists;

$c->log->debug('Total Elementscount: '.Dumper(%{ $c->stash->{'list_types'} }));

    # Van alle soorten (Zaaktype/kenmerken/sjablonen) de hoeveelheden ophalen
    while (my ($list_id, $list_data) = each (%{ $c->stash->{'list_types'} })) {
        $c->stash->{'list_table'} = $list_data->{'DB'};
        $c->log->debug($list_id.' - '.$c->stash->{'list_table'});

        #$c->stash->{'total_elements'} = $self->_list_child_categories($c, $categorie_id);
        push (@total_elements, $self->_list_child_categories($c, $categorie_id));
        push (@all_table_lists, $c->stash->{'element_count'});

        $c->stash->{'element_count'}      = undef;
        $c->stash->{'child_category_ids'} = undef;
        $c->stash->{'list_table'}         = undef;
    }

    $c->log->debug('Total elements: '.Dumper(@total_elements));
    $c->log->debug('All table lists: '.Dumper(@all_table_lists));

    # Alle totalen bij elkaar optellen
    # Zet een lijst in een array en tel de andere lijsten er bij op
    my $total_list = pop (@all_table_lists);

    for my $list_total (@all_table_lists) {
        while (my ($id, $total) = each(%{ $list_total })) {
            $total_list->{$id} += $total;
        }
    }

    # Alle resultaten combineren
    $c->log->debug('Total elements: '.Dumper($total_list));

$c->stash->{'list_table'} = $total_list;
$c->stash->{'element_count'} = $total_list;

#$c->detach;

    ### Load categories
    $c->forward('/beheer/categorie/categories', $categorie_id);

    $c->log->debug('Bibs: '.$c->stash->{'bib_type'});


#$c->log->debug("Categories: ".Dumper(%{$c->stash->{'categories'}}));

	my $params = $c->req->params();

    my $page = $params->{'page'} || 1;
    my $display_params = {};


    $c->stash->{'list_table'} = 'DB::Zaaktype';
    my $list_table = $c->stash->{'list_table'} or die 'need list_table in stash';
    $c->stash->{'entries'} = $c->model($c->stash->{'list_table'})->search($display_params, {page=>$page});

    my $textfilter = $params->{'textfilter'};


    if($textfilter) {
        if($c->stash->{'apply_text_filter_function'}) {
            my $apply_text_filter_function = $c->stash->{'apply_text_filter_function'};
            $c->stash->{'entries'} = &$apply_text_filter_function($c, $c->stash->{'entries'}, $textfilter);
        } else {
            $c->stash->{'entries'} = $c->stash->{'entries'}->search({
               'naam' => {'ilike' => '%'. $textfilter. '%' },
            });
        }

        if($categorie_id) {
            # include the current category
            my $search_category_ids = [$categorie_id, @{$c->stash->{'child_category_ids'}}];
            $c->stash->{'entries'} = $c->stash->{'entries'}->search({bibliotheek_categorie_id => {-in => $search_category_ids} });
        }
    } else {
        # Load entries in relation to categorie
        $c->forward('/beheer/categorie/list');
    }

    $c->stash->{'template'} = 'widgets/beheer/bibliotheek/list.tt';
}






sub _list_child_categories {
    my ($self, $c, $categorie_id) = @_;

    my $child_categories = $c->model(CATEGORIES_DB)->search({'pid' => $categorie_id});

    my $element_count = $c->model($c->stash->{'list_table'})->search({'bibliotheek_categorie_id' => $categorie_id})->count();

    $c->stash->{'child_category_ids'} ||= []; 
    my %id_lookup = map { $_ => 1 } @{$c->stash->{'child_category_ids'}};

    while(my $row = $child_categories->next()) { 
        # protect against cyclical child/parent relationships
        next if exists $id_lookup{$row->id};

        push @{$c->stash->{'child_category_ids'}}, '' . $row->id;  # stringify using ''
        $element_count += $self->_list_child_categories($c, $row->id);
    }

    $c->stash->{'element_count'} ||= {};
    $c->stash->{'element_count'}->{$categorie_id||'root'} = $element_count;
    
    return $element_count;
}



sub delete : Private {
    my ($self, $c, $id) = @_;

    ### Find id
    my $entry   = $c->stash->{bibliotheek}->find($id);

    ### Check entry
    if (!$entry) {
        $c->flash->{result} =
            'Kan het onderdeel niet verwijderen want het kan niet'
            .' gevonden worden';

        return;
    }

    ### Delete it
    if ($entry->delete) {
        $c->flash->{result} = 'Onderdeel succesvol verwijderd';
        return 1;
    }

    return;
}

sub categoriebase : Chained('/') : PathPart('beheer/bibliotheek/categorie'): CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash->{bib_id} = $id;
}

{
    Zaaksysteem->register_profile(
        method  => 'categorie_bewerken',
        profile => {
            'required'      => [],
            'optional'      => [],
        }
    );

    sub categorie_bewerken : Chained('categoriebase'): PathPart('bewerken'): Args() {
        my ($self, $c, $type, $pid)   = @_;

        $c->stash->{bib_type}   = $type;
        my $id                  = $c->stash->{bib_id};
        $c->stash->{pid}        = $pid
            if $pid;

        my ($categorie);

        $c->stash->{nowrapper} = 1;
        $c->stash->{template} = 'beheer/bibliotheek/categorie/edit.tt';

        if (%{ $c->req->params } && $c->req->params->{update}) {

            my %args = map { $_ => $c->req->params->{ $CATEGORY_FIELDS->{ $_ } } }
                keys %{ $CATEGORY_FIELDS };

            if ($pid) {
                $args{pid} = $pid;
            }

            if ($id) {
                $categorie = $c->model('DB::BibliotheekCategorie')->find($id);
            }

            if (
                (!$categorie || $categorie->naam ne $args{naam}) &&
                $c->model('DB::BibliotheekCategorie')->search(
                    \%args
                )->count
            ) {
                $c->zcvalidate(
                    {
                        invalid => ['naam'],
                        msgs    => {
                            naam    => 'Categorie bestaat al'
                        }
                    }
                );

                $c->log->error(
                    'Bibliotheek->categorie_bewerken: Categorie "'
                    . $args{'naam'} . '" bestaat al.'
                );
                $c->detach;
            } elsif (
                $c->req->header("x-requested-with") eq 'XMLHttpRequest' &&
                exists($c->req->params->{do_validation})
            ) {
                $c->zcvalidate({success => 1 });
                $c->detach;
            }


            if (!$categorie) {
                $categorie = $c->model('DB::BibliotheekCategorie')->create(
                    \%args
                );
            } else {
                $categorie->$_($c->req->params->{ $CATEGORY_FIELDS->{ $_ } })
                    for keys %{ $CATEGORY_FIELDS };

                $categorie->update;
            }

            $c->flash->{result} = 'Bibliotheek categorie ' . $categorie->naam
                    . ' succesvol bijgewerkt';
            $c->res->redirect(
                $c->uri_for(
                    '/beheer/zaaktype_catalogus/' .  $categorie->id
                )
            );
            $c->detach;
        } elsif ($id) {
            $c->stash->{categorie} = $c->model('DB::BibliotheekCategorie')->find($id);
        }
    }
}

{
    Zaaksysteem->register_profile(
        method  => 'categorie_verwijderen',
        profile => {
            'required'      => [],
            'optional'      => [],
        }
    );

    sub categorie_verwijderen : Chained('categoriebase'): PathPart('verwijderen'): Args() {
        my ($self, $c, $type, $pid)   = @_;

        $pid = $pid || 0;

        if (
            %{ $c->req->params } &&
            $c->req->params->{confirmed}
        ) {


            $c->response->redirect($c->uri_for('/beheer/zaaktype_catalogus'));

            my $categorie = $c->model(CATEGORIES_DB)->find(
                { id => $c->stash->{bib_id}}
            );

            if (!$categorie) {
                $c->flash->{result} =
                    'ERROR: Helaas, kan de categorie niet vinden';

                $c->detach;
            }

            if (
                $categorie->bibliotheek_kenmerkens->count ||
                $categorie->bibliotheek_sjablonens->count
            ) {
                $c->flash->{result} =
                    'ERROR: Helaas, kan de categorie niet verwijderen,'
                    .' bepaalde onderdelen uit de bibliotheek maken hier'
                    .' gebruik van.';

                $c->detach;
            }

            if (
                $categorie->bibliotheek_categories->count
            ) {
                $c->flash->{result} =
                    'ERROR: Helaas, kan de categorie niet verwijderen,'
                    .' deze is niet leeg.';

                $c->detach;
            }

            if ($categorie->delete) {
                $c->flash->{result} =
                    'Categorie ' . $categorie->naam . ' succesvol verwijderd';
            }

            $c->detach;
        }

        $c->stash->{confirmation}->{message}    =
            'Weet u zeker dat u deze categorie wilt verwijderen?';

        $c->stash->{confirmation}->{type}       = 'yesno';
        $c->stash->{confirmation}->{uri}        =
            $c->uri_for(
                '/beheer/bibliotheek/categorie/' . $c->stash->{bib_id}
                .'/verwijderen/' . $type
            );


        $c->forward('/page/confirmation');
        $c->detach;
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

