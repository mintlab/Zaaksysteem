package Zaaksysteem::Controller::Beheer::Bibliotheek::ZaaktypeCatalogus;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use Data::Dumper;

use Zaaksysteem::Constants qw/
    ZAAKSYSTEEM_CONSTANTS
    ZAAKSYSTEEM_STANDAARD_KENMERKEN
/;

use constant KENMERKEN              => 'kenmerken';
use constant KENMERKEN_MODEL        => 'Bibliotheek::Kenmerken';
use constant KENMERKEN_DB           => 'DB::BibliotheekKenmerken';
use constant MAGIC_STRING_DEFAULT   => 'doc_variable';
use constant CATEGORIES_DB          => 'DB::BibliotheekCategorie';


sub base : Chained('/beheer/bibliotheek/base') : PathPart('kenmerken'): CaptureArgs(2) {
    my ( $self, $c, $catid, $id ) = @_;

    $c->forward('/beheer/bibliotheek/categories', [ $catid, KENMERKEN]);

    $c->assert_any_user_permission('beheer_kenmerken_admin');

    $c->stash->{bib_type}   = KENMERKEN;
    if ($id) {
        $c->stash->{bib_entry}  = $c->model(KENMERKEN_DB)->find($id)
            or $c->detach;

        $c->add_trail(
            {
                uri     => $c->uri_for('/beheer/bibliotheek/'
                    . $c->stash->{bib_type} . '/'
                    . $catid . '/'
                    . $id
                ),
                label   =>  'Kenmerk: ' . $c->stash->{bib_entry}->naam,
            }
        );

    } else {
        $c->stash->{bib_new}    = 1;
    }
}

sub list : Chained('/'): PathPart('beheer/bibliotheek/kenmerken'): Args() {
    my ( $self, $c, $categorie_id ) = @_;

    $c->stash->{dest_type}  = KENMERKEN;
    $c->stash->{bib_type}   = KENMERKEN;
    $c->stash->{list_table} = KENMERKEN_DB;

    $c->forward('/beheer/bibliotheek/list');
}



{
    Zaaksysteem->register_profile(
        method  => 'bewerken',
        profile =>
            'Zaaksysteem::Model::Bibliotheek::Kenmerken::bewerken',
    );

    sub bewerken : Chained('base'): PathPart('bewerken'): Args() {
        my ( $self, $c ) = @_;
        my ($dv);

        if ($c->stash->{bib_new}) {
            $c->stash->{bib_id} = 0;
        } else {
            if ( $c->stash->{bib_entry}->system ) {
                $c->flash->{result} = 
                    'Standaard kenmerken kunnen niet '
                    . 'gewijzigd worden.';
                $c->res->redirect(
                    $c->uri_for(
                        '/beheer/bibliotheek/kenmerken/'
                        . $c->stash->{categorie_id}
                    )
                );
                $c->detach;
            }
            $c->stash->{bib_id} = $c->stash->{bib_entry}->id;
        }

        if ($c->stash->{categorie}) {
            $c->stash->{categorie_id} =
                $c->stash->{categorie}->id;
        }

        $c->stash->{bib_cat}        = $c->model(CATEGORIES_DB)->search(
            {
                'system'    => { 'is' => undef },
                'pid'       => undef,
            },
            {
                order_by    => ['pid','naam']
            }
        );

        ### Validation, PROUDLEVEL=7
        if ($c->req->params->{update}) {
            $c->stash->{categorie_id} =
                $c->req->params->{bibliotheek_categorie_id};

            my $validated = 1;
            ### Default validation
            unless ($dv = $c->zvalidate) {
                $validated = 0;
            }

            ### Make sure this name does not exist yet
            if (
                $c->stash->{bib_new} &&
                $c->model(KENMERKEN_MODEL)->kenmerk_exists(
                    'kenmerk_naam'  => $c->req->params->{kenmerk_naam}
                )
            ) {
                my $validated = 0;

                my $row = $c->model(KENMERKEN_DB)->search(
                    {
                        'naam' => $c->req->params->{kenmerk_naam}
                    },
                );

                $row = $row->first;

                #    $c->log->debug('ROW: ' . $row->first->naam);
                $c->zcvalidate({
                    invalid => ['kenmerk_naam'],
                    msgs    => {
                        'kenmerk_naam'  => 'Kenmerk bestaat al in de categorie: '
                            . (
                                $row->bibliotheek_categorie_id
                                    ? $row->bibliotheek_categorie_id->naam
                                    : ''
                            ),
                    },
                });
            } else {
                unless ($c->req->params->{kenmerk_type} eq 'file') {
                    ### Extended validation (magic string given and free?
                    if (
                        $c->stash->{bib_new} &&
                        (
                            !$c->req->params->{kenmerk_magic_string} ||
                            $c->req->params->{kenmerk_magic_string} ne
                            $c->model(KENMERKEN_MODEL)
                                ->generate_magic_string(
                                    $c->req->params->{kenmerk_magic_string}
                                )
                        )
                    ) {
                        $c->zcvalidate({ invalid => ['kenmerk_magic_string']});
                        my $validated = 0;
                    }
                }
            }

            if (
                !$validated ||
                $c->req->header("x-requested-with") eq 'XMLHttpRequest' &&
                exists($c->req->params->{do_validation})
            ) {
                $c->detach;
            }


            ### Let's work our magic on the bibliotheek
            my $options = $dv->valid;

            ### Checkboxes
            $options->{kenmerk_besluit} = $dv->valid('kenmerk_besluit');

            if (
                my $kenmerk = $c->model(KENMERKEN_MODEL)->bewerken(
                    $options
                )
            ) {

                if ($c->req->params->{json_response}) {
                    $c->stash->{json} = {
                        'id'    => $kenmerk->id
                    };
                    $c->forward('Zaaksysteem::View::JSON');
                    $c->detach;
                }

                $c->flash->{result} = 'Kenmerk succcesvol aangemaakt';
            } else {
                $c->flash->{result} = 'Fout bij aanmaken kenmerk';
            }
        }

        if ($c->req->header("x-requested-with") && $c->req->header("x-requested-with") eq 'XMLHttpRequest') {
            if ($c->stash->{bib_id}) {
                $c->stash->{bib_entry} = $c->model(KENMERKEN_MODEL)->get(
                    id  => $c->stash->{bib_id}
                );
            }

            $c->stash->{template} =
                'beheer/bibliotheek/kenmerken/edit.tt';

            $c->detach;
        }

        $c->res->redirect(
            $c->uri_for(
                '/beheer/bibliotheek/kenmerken/'
                . $c->stash->{categorie_id}
            )
        );
        $c->detach;
    }
}

sub verwijderen : Chained('base'): PathPart('verwijderen'): Args() {
    my ( $self, $c )    = @_;
    my $entry           = $c->stash->{bib_entry};

    return unless $entry;

    if ( $entry->system ) {
        $c->flash->{result} = 
            'Standaard kenmerken kunnen niet '
            . 'gewijzigd worden.';
        $c->res->redirect(
            $c->uri_for(
                '/beheer/bibliotheek/kenmerken/'
                . $entry->bibliotheek_categorie_id->id
            )
        );
        $c->detach;
    }

    ### Confirmed
    if (
        $entry->zaaktype_kenmerkens->count
    ) {
        ### in depth search
        my $used_in_zaaktype_kenmerken = $entry->zaaktype_kenmerkens->search;
        my $notused = 1;
        while (
            $notused &&
            (my $zt_kenmerk = $used_in_zaaktype_kenmerken->next)
        ) {
            if (!$zt_kenmerk->zaaktype_node_id->zaaktype_id->deleted) {
                $notused=0;
                next;
            }

            ### Ok: Er zijn alleen nog verwijderde zaaktypen, is er een zaak
            ### ooit aan gekoppeld?
            if ($zt_kenmerk->zaaktype_node_id->zaaks->count) {
                $notused = 0;
                next;
            }

            ### Ok, looks like it is not used, er is geen actieve zaaktype
            ### en de inactieve zaaktypen hebben allemaal geen zaken gekoppeld
            ### gehad... Free to wipe, notused=1
        }

        if (!$notused) {
            $c->stash->{confirmation}->{msgonly}    = '1';

            ### Msg
            $c->stash->{confirmation}->{message} = 'Helaas, dit kenmerk is in gebruik door een zaaktype.';
            $c->detach('/page/confirmation');
        }
    }

    ### Post
    if ( $c->req->params->{confirmed}) {

        $entry->delete;

        ### Msg
        $c->flash->{result} = 'Kenmerk succesvol verwijderd.';

        $c->detach;
        return;
    }


    $c->stash->{confirmation}->{message}    =
        'Weet u zeker dat u dit kenmerk wilt verwijderen?'
        . ' Deze actie kan niet ongedaan gemaakt worden. Maar geen zorgen, dit
        kenmerk is niet in gebruik door actieve zaaktypen.';

    $c->stash->{confirmation}->{type}       = 'yesno';

    $c->stash->{confirmation}->{uri}     = $c->uri_for(
                            '/beheer/bibliotheek/' . $c->stash->{bib_type} . '/'
                            . $entry->bibliotheek_categorie_id->id . '/'
                            . $entry->id . '/verwijderen'
        );

    $c->forward('/page/confirmation');
    $c->detach;
}

sub search
    : Chained('/beheer/bibliotheek/base')
    : PathPart('kenmerken/search')
    : Args()
{
    my ( $self, $c )        = @_;

    return unless (
        $c->req->header("x-requested-with") &&
        $c->req->header("x-requested-with") eq 'XMLHttpRequest'
    );
    $c->stash->{bib_type}   = KENMERKEN;

    $c->stash->{bib_cat}        = $c->model(CATEGORIES_DB)->search(
        {
            'system'    => { 'is' => undef },
            'pid'       => undef,
        },
        {
            order_by    => ['pid','naam']
        }
    );


	my $hide_veld_opties = {map {$_, 1} qw/bag_adressen bag_openbareruimtes bag_straat_adressen googlemaps file/};
	$c->stash->{'hide_veld_opties'} = $hide_veld_opties;

    if ($c->req->params->{search}) {
        ### Return json response with results
        my $json = [];

        my %search_query    = ();
        $search_query{'lower(naam)'} = {
            'like' => '%' .  lc($c->req->params->{naam}) . '%'
        } if $c->req->params->{naam};
        $search_query{value_type} = $c->req->params->{kenmerk_type}
            if $c->req->params->{kenmerk_type};
        $search_query{bibliotheek_categorie_id} =
            $c->req->params->{bibliotheek_categorie_id}
                if $c->req->params->{bibliotheek_categorie_id};
        $search_query{'system'} = {
            'is' => undef,
        };
        

# search_filter_post means this search is to setup search filters. (TRAC 168)
# not every type is useful for searching
# add a where clause to get rid of those
		if($c->req->param('search_filter_post') && !exists $search_query{'value_type'}) {
			$search_query{'value_type'} = { '-not_in' => [keys %$hide_veld_opties] };
		}

        $search_query{'deleted'}    = undef;


        my $kenmerken = $c->model(KENMERKEN_DB)->search(
            \%search_query,
            {
                order_by    => 'naam'
            }
        );

        while (my $kenmerk = $kenmerken->next) {
        	
#        $c->log->debug('getting it: ' . Dumper ($kenmerk->naam). Dumper $kenmerk->value_type);

            next unless $kenmerk->bibliotheek_categorie_id;
            push(@{ $json },
                {
                    'naam'          => $kenmerk->naam,
                    'invoertype'    =>
                        ZAAKSYSTEEM_CONSTANTS->{
                            'veld_opties'
                        }->{$kenmerk->value_type}->{label},
                    'categorie'     => $kenmerk->bibliotheek_categorie_id->naam,
                    'id'    => $kenmerk->id,
                }
            );
        }

        $c->stash->{json} = $json;
        $c->detach('Zaaksysteem::View::JSON');
    }

    $c->stash->{'search_filter_post'} = $c->req->param('search_filter_post');
    $c->stash->{template} = 'widgets/beheer/bibliotheek/search.tt';
}


sub get_magic_string
    : Chained('/beheer/bibliotheek/base')
    : PathPart('kenmerken/get_magic_string')
    : Args()
{
    my ( $self, $c )        = @_;

    my $suggestion = $c->model(KENMERKEN_MODEL)
       ->generate_magic_string($c->req->params->{naam});
    $c->res->body($suggestion);
}

sub get_veldoptie
    : Chained('/')
    : PathPart('beheer/bibliotheek/kenmerken/get_veldoptie')
    : Args()
{
    my ( $self, $c )        = @_;

    if (
        !$c->req->params->{kenmerk_id} ||
        $c->req->params->{kenmerk_id} !~ /^\d+$/
    ) {
        $c->res->body('');
        $c->detach;
    };

    my $kenmerk     = $c->model(KENMERKEN_MODEL)->get(
        'id'    => $c->req->params->{kenmerk_id}
    );

    unless ($kenmerk) {
        $c->res->body('');
        $c->detach;
    }

    $c->stash->{nowrapper}  = 1;

    $c->stash->{veldoptie_type} = $kenmerk->{kenmerk_type};
    $c->stash->{veldoptie_name} = $c->req->params->{veldoptie_name};
    $c->stash->{veldoptie_opties} = $kenmerk->{kenmerk_options};

    $c->log->debug('so far so good:' . $c->stash->{veldoptie_type});

    $c->stash->{template}   = 'widgets/general/veldoptie.tt';
}

sub setup : Local {
    my ($self, $c) = @_;

    ### Sets up standaard kenmerken wanneer deze nog niet zijn aangemaakt
    my $zaaknummer = $c->model('DB::BibliotheekKenmerken')->search(
        'magic_string'  => 'zaaknummer',
        system  => 1,
    );

    my ($cat, $kenmerken);
    if ($zaaknummer->count) {
        $c->res->body(
            $c->res->body .
            '<br />OK (Systeemkenmerken bestaan al)'
        );

        $cat            = $c->model('DB::BibliotheekCategorie')->search(
            {
                naam    => 'Systeemkenmerken',
                system  => 1,
            }
        );

        $c->detach unless $cat->count;

        $cat = $cat->first;

    } else {
        $cat         = $c->model('DB::BibliotheekCategorie')->create(
            {
                naam    => 'Systeemkenmerken',
                label   => 'Systeemkenmerken',
                system  => 1,
            }
        );
    }

    $kenmerken   = ZAAKSYSTEEM_STANDAARD_KENMERKEN;

    for my $kenmerk (keys %{ $kenmerken }) {
        my $old = $c->model('DB::BibliotheekKenmerken')->search(
            {
                naam        => $kenmerk,
                system      => 1,
            }
        );

        next if $old->count;

        $c->model('DB::BibliotheekKenmerken')->create(
            {
                naam        => $kenmerk,
                value_type  => 'text',
                label       => $kenmerk,
                description => $kenmerk,
                magic_string => $kenmerk,
                system      => 1,
                bibliotheek_categorie_id    => $cat->id
            }
        );
        $c->res->body(
            $c->res->body . '<br/>Added ' . $kenmerk
        );
    }

    $c->res->body(
        $c->res->body . '<br/>DONE'
    );
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

