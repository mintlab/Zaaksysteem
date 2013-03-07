package Zaaksysteem::Controller::Beheer::Bibliotheek::Sjablonen;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use File::stat;

use Data::Dumper;

use Zaaksysteem::Constants qw/ZAAKSYSTEEM_CONSTANTS/;

use constant SJABLONEN              => 'sjablonen';
use constant SJABLONEN_MODEL        => 'Bibliotheek::Sjablonen';
use constant SJABLONEN_DB           => 'DB::BibliotheekSjablonen';
use constant CATEGORIES_DB          => 'DB::BibliotheekCategorie';


sub base : Chained('/beheer/bibliotheek/base') : PathPart('sjablonen'): CaptureArgs(2) {
    my ( $self, $c, $catid, $id ) = @_;

    $c->forward('/beheer/bibliotheek/categories', [ $catid, SJABLONEN]);

    $c->assert_any_user_permission('beheer_sjablonen_admin');

    $c->stash->{bib_type}   = SJABLONEN;

    if ($id) {
        $c->stash->{bib_entry}  = $c->model(SJABLONEN_DB)->find($id)
            or $c->detach;

        $c->add_trail(
            {
                uri     => $c->uri_for('/beheer/zaaktype_catalogus/'
                    . $catid
                ),
                label   => 'Categorie: ' . $c->stash->{categorie}->naam,
            }
        ) if ($c->stash->{categorie});

        $c->add_trail(
            {
                uri     => $c->uri_for('/beheer/zaaktype_catalogus/'
                    . $catid . '/'
                    . $id
                ),
                label   =>  'Sjabloon: ' . $c->stash->{bib_entry}->naam,
            }
        );

    } else {
        $c->stash->{bib_new}    = 1;
    }
}


sub list : Chained('/'): PathPart('beheer/bibliotheek/sjablonen'): Args() {
    my ( $self, $c, $categorie_id ) = @_;

    $c->stash->{dest_type}   = SJABLONEN;
    $c->stash->{bib_type}   = SJABLONEN;
    $c->stash->{list_table}   = SJABLONEN_DB;

    $c->forward('/beheer/bibliotheek/list');
}



sub download
    : Chained('base')
    : PathPart('download'): Args()
{
    my ($self, $c) = @_;

    $c->assert_any_user_permission('beheer_sjablonen_admin');

    my $filename    = $c->stash->{bib_entry}->naam . '.odt';

    my $filestore   = $c->stash->{bib_entry}->filestore_id;

    my $file        = $c->config->{files} . '/filestore/'
        . $filestore->id;

    my $stat = stat($file);

    unless($stat) {
        $c->log->debug("sjabloon file $file not found, aborting");  
        return;
    }

    $c->res->headers->header(
        'Content-Disposition',
        'attachment; filename="'
            . $filename . '"'
    );

    $c->log->debug(
        'Serving static file: ' . $filename
        . ' with filetype: ' . $c->res->content_type
    );

    $c->res->content_length( $stat->size );
    $c->serve_static_file($file);

    $c->res->headers->content_length( $stat->size );
    $c->res->headers->content_type($filestore->mimetype);
    $c->res->content_type($filestore->mimetype);
}

sub dddddlist : Chained('ddddddddd/beheer/bibliotheek/base'): PathPart('sjablonen'): Args() {
    my ( $self, $c, $catid ) = @_;

    $c->forward('/beheer/bibliotheek/categories', [ $catid, SJABLONEN]);

    $c->assert_any_user_permission('beheer_sjablonen_admin');

    $c->stash->{bib_type}   = SJABLONEN;

    $c->stash->{bib}        = $c->model(SJABLONEN_DB)->search(
        {},
        {
            order_by    => 'naam'
        }
    );

    $c->forward('/beheer/bibliotheek/list');
}

sub view : Chained('base'): PathPart(''): Args(0) {
    my ( $self, $c) = @_;

    $c->stash->{template} = 'beheer/bibliotheek/sjablonen/view.tt';
}

{
    Zaaksysteem->register_profile(
        method  => 'bewerken',
        profile =>
            'Zaaksysteem::Model::Bibliotheek::Sjablonen::bewerken',
    );

    sub bewerken : Chained('base'): PathPart('bewerken'): Args() {
        my ( $self, $c ) = @_;
        my ($dv);

        if ($c->stash->{bib_new}) {
            $c->stash->{bib_id} = 0;
        } else {
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
            my $validated = 0;

            ### Default validation
            if ($dv = $c->zvalidate) {
                if (
                    $c->stash->{bib_new} &&
                    $c->model(SJABLONEN_MODEL)->sjabloon_exists(
                        'naam'  => $c->req->params->{naam}
                    )
                ) {
                    $c->zcvalidate({ invalid => ['naam']});
                } else {
                    $validated = 1;
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

            if (
                my $sjabloon = $c->model(SJABLONEN_MODEL)->bewerken(
                    $options
                )
            ) {

                if ($c->req->params->{json_response}) {
                    $c->stash->{json} = {
                        'id'    => $sjabloon->id
                    };
                    $c->forward('Zaaksysteem::View::JSON');
                    $c->detach;
                }

                $c->flash->{result} = 'Sjabloon succcesvol aangemaakt';
            }
        }

        if ($c->req->header("x-requested-with") eq 'XMLHttpRequest') {
            if ($c->stash->{bib_id}) {
                $c->stash->{bib_entry} = $c->model(SJABLONEN_MODEL)->retrieve(
                    id  => $c->stash->{bib_id}
                );
            }

            $c->stash->{template} =
                'beheer/bibliotheek/sjablonen/edit.tt';

            $c->detach;
        }

        $c->res->redirect(
            $c->uri_for(
                '/beheer/zaaktype_catalogus/'
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

    ### Confirmed
    my $flag_only = 0;
    if (
        $entry->zaaktype_sjablonens->count
    ) {
        ### in depth search
        my $used_in_zaaktype_sjablonen = $entry->zaaktype_sjablonens->search;
        my $notused = 1;
        while (
            $notused &&
            (my $zt_sjabloon = $used_in_zaaktype_sjablonen->next)
        ) {
            if (
                $zt_sjabloon->zaaktype_node_id->id eq
                $zt_sjabloon->zaaktype_node_id->zaaktype_id->zaaktype_node_id->id &&
                !$zt_sjabloon->zaaktype_node_id->zaaktype_id->deleted
            ) {
                $c->stash->{confirmation}->{message} =
                    'Helaas, dit sjabloon is in gebruik door een of meedere actieve zaaktypen.';
                $notused=0;
                next;
            }

            ### Ok: Er zijn alleen nog verwijderde zaaktypen, is er een zaak
            ### ooit aan gekoppeld?
            if ($zt_sjabloon->zaaktype_node_id->zaaks->count) {
                ### En is minstens 1 zaak _niet_ vernietigd
                if ($zt_sjabloon->zaaktype_node_id->zaaks->search(
                        { status => { '!=' => 'deleted' }}
                    )->count
                ) {
                    $c->log->debug('Vond een actieve zaak met dit sjabloon');
                    $c->stash->{confirmation}->{message} =
                        'Helaas, dit sjabloon is in gebruik door een of meerdere zaken.';
                    $notused = 0;
                    next;
                } else {
                    $flag_only = 1;
                }
            }

            ### Ok, looks like it is not used, er is geen actieve zaaktype
            ### en de inactieve zaaktypen hebben allemaal geen zaken gekoppeld
            ### gehad... Free to wipe, notused=1
        }
        if (!$notused) {
            $c->stash->{confirmation}->{msgonly}    = '1';

            ### Msg
            $c->detach('/page/confirmation');
        }
    }

    ### Post
    if ( $c->req->params->{confirmed}) {
        if ($flag_only) {
            $entry->deleted(DateTime->now());
            $entry->update;

            $c->log->debug(
                'Sjabloon ' . $entry->id . ' verwijderd dmv flag'
            );
        } else {
            ### Do not forget to delete magic strings
            $entry->bibliotheek_sjablonen_magic_strings->delete;
            $entry->delete;
            $c->log->debug(
                'Sjabloon ' . $entry->id . ' verwijderd'
            );
        }

        ### Msg
        $c->flash->{result} = 'Sjabloon succesvol verwijderd.';
        $c->res->redirect(
            $c->uri_for(
                '/beheer/bibliotheek/sjablonen/'
                . $entry->bibliotheek_categorie_id->id
            )
        );

        $c->detach;
        return;
    }


    $c->stash->{confirmation}->{message}    =
        'Weet u zeker dat u dit sjabloon wilt verwijderen?'
        . ' Deze actie kan niet ongedaan gemaakt worden. Maar geen zorgen, dit
        sjabloon is niet in gebruik door een zaaktype';

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
    : PathPart('sjablonen/search')
    : Args()
{
    my ( $self, $c )        = @_;

    return unless (
        $c->req->header("x-requested-with") &&
        $c->req->header("x-requested-with") eq 'XMLHttpRequest'
    );
    $c->stash->{bib_type}   = SJABLONEN;

    $c->stash->{bib_cat}        = $c->model(CATEGORIES_DB)->search(
        {
            'pid'       => undef,
        },
        {
            order_by    => 'naam'
        }
    );

    if ($c->req->params->{search}) {
        ### Return json response with results
        my $json = [];

        my %search_query    = ();
        $search_query{'lower(naam)'} = {
            'like' => '%' .  lc($c->req->params->{naam}) . '%'
        } if $c->req->params->{naam};
        $search_query{bibliotheek_categorie_id} =
            $c->req->params->{bibliotheek_categorie_id}
                if $c->req->params->{bibliotheek_categorie_id};

        $search_query{'deleted'}    = undef;

        my $kenmerken = $c->model(SJABLONEN_DB)->search(
            \%search_query,
            {
                order_by    => 'naam'
            }
        );

        while (my $kenmerk = $kenmerken->next) {
            push(@{ $json },
                {
                    'naam'                  => $kenmerk->naam,
                    'categorie'             => $kenmerk->bibliotheek_categorie_id->naam,
                    'id'                    => $kenmerk->id,
                }
            );
        }

        $c->stash->{json} = $json;
        $c->detach('Zaaksysteem::View::JSON');
    }

    $c->stash->{template} = 'widgets/beheer/bibliotheek/search.tt';
}

#
#
#sub get_magic_string
#    : Chained('/beheer/bibliotheek/base')
#    : PathPart('kenmerken/get_magic_string')
#    : Args()
#{
#    my ( $self, $c )        = @_;
#
#    my $suggestion = $c->model(SJABLONEN_MODEL)
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

