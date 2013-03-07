package Zaaksysteem::Controller::Zaaktype;

use strict;
use warnings;

use Data::Dumper;
use parent 'Catalyst::Controller';


sub base : Chained('/') : PathPart('zaaktype'): CaptureArgs(0) {
    my ($self, $c) = @_;

    if ($c->req->path =~ /zaaktype\/categorie/) {
        delete($c->session->{zaaktype_edit});
    }

    $self->_load_trails($c);
}

sub _load_trails {
    my ($self, $c) = @_;

    if ($c->session->{zaaktype_edit}->{category}) {
        my $cat = $c->model('DB::ZaaktypeCategorie')->find(
                $c->session->{zaaktype_edit}->{category}
            );

        if ($cat) {
            $c->add_trail(
                {
                    uri     => $c->uri_for('/zaaktype/categorie/' . $cat->id),
                    label   => 'Categorie: ' . $cat->categorie,
                }
            );
        }
    }

    if ($c->session->{zaaktype_edit}->{edit}) {
        if (my $zn = $c->model('DB::ZaaktypeNode')->find(
                $c->session->{zaaktype_edit}->{edit}
            )
        ) {
            $c->add_trail(
                {
                    uri     => $c->uri_for('/zaaktype/edit/' . $zn->id),
                    label   => 'Zaaktype: ' . $zn->titel,
                }
            );
        }
    }


}

sub begin : Private {
    my ($self, $c, $id) = @_;


    #$c->assert_user_role(qw/admin/);

    $c->forward('/begin');

    if ($c->session->{zaaktype_edit}->{category}) {
        $c->stash->{categorie}
            = $c->model('DB::ZaaktypeCategorie')->find(
                $c->session->{zaaktype_edit}->{category}
            );
    }

    $c->add_trail(
        {
            uri     => $c->uri_for('/zaaktype'),
            label   => 'Zaaktypebeheer',
        }
    );

}

sub view : Chained('base'): PathPart(''): Args(1) {
    my ($self, $c, $id) = @_;

    ### Forward to first section
    # Initiate zaaktype
    delete($c->session->{zaaktype_edit});
    $c->session->{zaaktype_edit} = $c->model('Zaaktype')->find($id);
    $c->stash->{zaaktype_view} = 1;

    $c->stash->{template}   = 'zaaktype/finish.tt';

    $c->stash->{categorie}
        = $c->model('DB::ZaaktypeCategorie')->find(
            $c->session->{zaaktype_edit}->{category}
        );

    $c->add_trail(
        {
            uri     => $c->uri_for('/zaaktype/categorie/' . $c->stash->{categorie}->id),
            label   => $c->stash->{categorie}->categorie
        }
    );

    $c->add_trail(
        {
            uri     => $c->uri_for('/zaaktype/' . $id),
            label   => 'Zaaktype overzicht'
        }
    );
}

sub end : Private {
    my ( $self, $c ) = @_;

    $Data::Dumper::Indent = 1;
    $c->log->debug(Dumper($c->session->{zaaktype_edit}));

    $c->forward('/end');
}


sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('/zaaktype/category/index');
}

sub add : Chained('base'): PathPart('add'): Args(1) {
    my ($self, $c, $catid) = @_;

    ### Forward to first section
    # Initiate zaaktype
    delete($c->session->{zaaktype_edit});
    $c->session->{zaaktype_edit}->{category}    = $catid;
    $c->stash->{categorie}  = $c->model('DB::ZaaktypeCategorie')->find($catid);

    $c->session->{zaaktype_edit}->{create}      = 1;

    $c->forward('/zaaktype/algemeen/edit');
}

{
    Zaaksysteem->register_profile(
        method  => 'verplaats',
        profile => {
            required => [ qw/
                zaaktype_id
                categorie_id
            /],
            constraint_methods => {
                zaaktype_id     => qr/^\d+$/,
                categorie_id     => qr/^\d+$/,
            }
        }
    );

    sub verplaats : Chained('base'): PathPart('verplaats'): Args(1) {
        my ($self, $c, $zaaktype_id) = @_;

        my $zaaktype = $c->model('Zaaktype')->retrieve(
            id  => $zaaktype_id
        ) or return;

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
            $c->req->params->{categorie_id}
        ) {
            $c->res->redirect(
                $c->uri_for('/zaaktype')
            );

            ### Confirmed
            my $dv;
            return unless $dv = $c->zvalidate;

            my $zaaktype_edit = $c->model('Zaaktype')->get($zaaktype->id);

            $zaaktype_edit->{category} = $c->req->params->{categorie_id};

            $c->model('Zaaktype')->create($zaaktype_edit);

            my $db_zt = $zaaktype->ztno->zaaktype_id;
            $db_zt->zaaktype_categorie_id(
                $c->req->params->{categorie_id}
            );

            $db_zt->update;


            ### Msg
            $c->flash->{result} = 'Zaaktype succesvol verplaatst.';

            $c->res->redirect('/zaaktype/categorie/' .  $c->req->params->{categorie_id});

            $c->detach;
        }

       $c->stash->{zaaktype_categorien} =
            $c->model('DB::ZaaktypeCategorie')->search({});

        $c->stash->{zaaktype_id} = $zaaktype->id;
        $c->stash->{zaaktype} = $zaaktype;
        $c->stash->{nowrapper} = 1;
        $c->stash->{template} = 'zaaktype/widgets/verplaats.tt';
    }
}

sub edit : Chained('base'): PathPart('edit'): Args() {
    my ($self, $c, $id, $zaaktype_component) = @_;

    $c->session->{zaaktype_edit} = $c->model('Zaaktype')->find($id);
    $c->stash->{categorie}
        = $c->model('DB::ZaaktypeCategorie')->find(
            $c->session->{zaaktype_edit}->{category}
        );

    $self->_load_trails($c);

    if ($zaaktype_component && $zaaktype_component eq 'auth') {
        $c->forward('/zaaktype/auth/edit');
        $c->session->{zaaktype_auth_only} = 1;
    } else {
        $c->forward('/zaaktype/algemeen/edit');
    }
}

sub clone : Chained('base'): PathPart('clone'): Args(1) {
    my ($self, $c, $id) = @_;

    $c->session->{zaaktype_edit} = $c->model('Zaaktype')->duplicate($id);
    $c->stash->{categorie}
        = $c->model('DB::ZaaktypeCategorie')->find(
            $c->session->{zaaktype_edit}->{category}
        );

    $c->forward('/zaaktype/algemeen/edit');
}

{
    Zaaksysteem->register_profile(
        method  => 'delete',
        profile => {
            required => [ qw/
                zaaktype_id
            /],
            constraint_methods => {
                zaaktype_id     => qr/^\d+$/,
            }
        }
    );

    sub delete : Chained('base'): PathPart('delete'): Args() {
        my ($self, $c, $id) = @_;

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

            $c->model('Zaaktype')->delete($dv->valid('zaaktype_id'));

            ### Msg
            $c->flash->{result} = 'Zaaktype succesvol verwijderd.';

            $c->res->redirect('/zaaktype');
            $c->detach;
            return;
        }


        $c->stash->{confirmation}->{message}    =
            'Weet u zeker dat u dit zaaktype wilt verwijderen?'
            . ' Deze actie kan niet ongedaan gemaakt worden. Lopende zaken'
            . ' onder dit zaaktype kunnen worden afgerond, echter, er kunnen'
            . ' geen nieuwe zaken meer worden aangemaakt.';

        $c->stash->{confirmation}->{type}       = 'yesno';

        $c->stash->{confirmation}->{params}     = {
            'zaaktype_id'   => $id
        };

        $c->forward('/page/confirmation');
        $c->detach;
    }
}


sub search : Chained('/'): PathPart('zaaktype/search'): Args(0) {
    my ($self, $c) = @_;

    if ($c->req->header("x-requested-with") ne 'XMLHttpRequest') {
        $c->response->redirect('/');
        $c->detach;
    }

   $c->stash->{zaaktype_categorien} =
        $c->model('DB::BibliotheekCategorie')->search(
            {   pid => undef },
            {
                order_by    => 'naam'
            }
        );

    $c->stash->{nowrapper} = 1;
    $c->stash->{template} = 'widgets/zaaktype/search_popup.tt';
    $c->stash->{search_filter_post} = $c->req->params->{'search_filter_post'};

    ### Internal post, give results
    if (%{ $c->req->params } && $c->req->params->{search}) {
        my %opts;

        $opts{zaaktype_categorie_id} = $c->req->params->{zaaktype_categorie}
            if ($c->req->params->{zaaktype_categorie});

        $opts{zaaktype_titel} = $c->req->params->{zaaktype_naam}
            if ($c->req->params->{zaaktype_naam});


        $opts{zaaktype_trefwoorden} = $c->req->params->{zaaktype_trefwoorden}
            if ($c->req->params->{zaaktype_trefwoorden});

        $opts{zaaktype_omschrijving} = $c->req->params->{zaaktype_omschrijving}
            if ($c->req->params->{zaaktype_omschrijving});


        $opts{zaaktype_betrokkene_type} = $c->req->params->{jsbetrokkene_type}
            if (
                $c->req->params->{jsbetrokkene_type} &&
                $c->req->params->{jsbetrokkene_type} ne 'undefined'
            );

        $opts{zaaktype_trigger} = $c->req->params->{jstrigger}
            if (
                $c->req->params->{jstrigger} &&
                $c->req->params->{jstrigger} ne 'undefined'
            );

        $c->log->debug('Calling zaaktype search with options'. Dumper(\%opts));
        $c->stash->{zaaktypen} = $c->model('Zaaktype')->list(\%opts);

        if ($c->req->params->{json_response}) {
            my (@zaaktypen);
            while (my $zt = $c->stash->{zaaktypen}->next) {
                push(@zaaktypen,
                    {
                        naam    => $zt->zaaktype_node_id->titel,
                        nid      => $zt->zaaktype_node_id->id,
                        id       => $zt->id
                    }
                );
            }
            $c->stash->{json} = {
                'zaaktypen'    => \@zaaktypen,
            };
            $c->forward('Zaaksysteem::View::JSON');
            $c->detach;
        }

        $c->stash->{template} = 'widgets/zaaktype/search_resultrows.tt';
    }
}

sub finish : Chained('base'): PathPart('finish'): Args(0) {
    my ($self, $c) = @_;

    unless (%{ $c->req->params } && $c->req->params->{confirm}) {
        $c->stash->{template} = 'zaaktype/finish.tt';
        $c->detach;
    }

    ### Voer deze info aan ons almachtige sexy modelletje, fat model wel te
    ### verstaan, niet zo'n slanke den
    $c->model('Zaaktype')->create($c->session->{zaaktype_edit});

    $c->res->redirect($c->uri_for('/zaaktype'));

    delete($c->session->{zaaktype_edit});
}


## DEFAULT PATCHED TO CATEGORY

#sub list : Chained('/'): PathPart('zaak/list'): Args(0) {
#    my ($self, $c) = @_;
#
#    ### Retrieve a list of zaken
#    $c->stash->{'template'} = 'zaak/list.tt';
#    $c->stash->{'zaken'}    = $c->model('Zaak')->search_sql(' ');
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

