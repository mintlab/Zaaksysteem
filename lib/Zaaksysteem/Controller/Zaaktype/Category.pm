package Zaaksysteem::Controller::Zaaktype::Category;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use DateTime;

my $CATEGORY_FIELDS = {
    'categorie'      => 'categorie',
    'eigenaar'       => 'eigenaar',
    'behandelaar'    => 'behandelaar',
};



sub index : Chained('/zaaktype/base'): PathPart('categorie'): Args(0) {
    my ($self, $c) = @_;

    ### Load categories
    $c->stash->{categorien} = $c->model('DB::ZaaktypeCategorie')->search(
        {
            deleted_on  => undef,
            pid         => undef,
        },
        {
            order_by    => 'categorie'
        }
    );

    $c->stash->{template} = 'zaaktype/categorie/index.tt';
}

sub zaaktypes : Chained('/zaaktype/base'): PathPart('categorie'): Args(1) {
    my ($self, $c, $id) = @_;

    ### Load categorie
    $c->stash->{categorie}  = $c->model('DB::ZaaktypeCategorie')->find($id);

    unless ($c->stash->{categorie}) {
        $c->res->redirect($c->uri_for('/zaaktype'));
        $c->detach;
    }

    $c->add_trail(
        {
            uri     => $c->uri_for('/zaaktype/categorie/' .  $c->stash->{categorie}->id),
            label   => 'Categorie: ' . $c->stash->{categorie}->categorie,
        }
    );

    ### Load zaaktypes with categorie
    ### XXX TODO, Move backward
    $c->stash->{zaaktypen}  = $c->stash->{categorie}->zaaktypes->search(
        {
            deleted => undef
        },
    );

    $c->stash->{template}   = 'zaaktype/index.tt';

}

sub edit : Chained('/zaaktype/base'): PathPart('categorie/edit'): Args() {
    my ($self, $c, $id) = @_;
    my ($categorie);

    $c->stash->{nowrapper} = 1;
    $c->stash->{template} = 'zaaktype/categorie/edit.tt';

    if (%{ $c->req->params } && $c->req->params->{action}) {

        my %args = map { $_ => $c->req->params->{ $CATEGORY_FIELDS->{ $_ } } }
            keys %{ $CATEGORY_FIELDS };

        $args{pid} = $c->req->params->{parent_id} || undef;

        if (!$id) {
            $categorie = $c->model('DB::ZaaktypeCategorie')->create(
                \%args
            );
        } else {
            $categorie = $c->model('DB::ZaaktypeCategorie')->find($id);
            $categorie->$_($c->req->params->{ $CATEGORY_FIELDS->{ $_ } })
                for keys %{ $CATEGORY_FIELDS };

            $categorie->update;
        }

        $c->flash->{result} = 'Zaaktype categorie ' . $categorie->categorie
                . ' succesvol bijgewerkt';
        $c->res->redirect( $c->uri_for('/zaaktype/categorie/' . $categorie->id) );
        $c->detach;
    } elsif ($id) {
        $c->stash->{categorie} = $c->model('DB::ZaaktypeCategorie')->find($id);
    }
}

sub delete : Chained('/zaaktype/base'): PathPart('categorie/delete'): Args(1) {
    my ($self, $c, $id) = @_;

    my $categorie   = $c->model('DB::ZaaktypeCategorie')->find($id);

    ### Find zaaktype
    my $zt_nodes    = $categorie->zaaktypes->search(
        {
            deleted => undef
        }
    );

    if (
        %{ $c->req->params } &&
        $c->req->params->{confirmed}
    ) {
        if (
            !$zt_nodes->count
        ) {
            $categorie->deleted_on(DateTime->now);
            if ($categorie->update) {
                $c->flash->{result} = 'Zaaktype categorie ' . $categorie->categorie
                        . ' succesvol verwijderd';
            } else {
                $c->flash->{result} = 'Helaas kan deze Zaaktype categorie'
                        . ' om onbekende reden niet verwijderd worden.'
            }
        }

        $c->res->redirect( $c->uri_for('/zaaktype') );
        $c->detach;
    }

    if ($zt_nodes->count) {
        $c->stash->{confirmation}->{message}    =
            'Helaas kan dit zaaktype niet worden verwijderd. Er zijn'
            . ' nog zaaktypen actief.';
    } else {
        $c->stash->{confirmation}->{message}    =
            'Weet u zeker dat u deze categorie wilt verwijderen?'
    }

    $c->stash->{confirmation}->{type}       = 'yesno';

    $c->stash->{confirmation}->{params}     = {
        'zaaktype_id'   => $id
    };

    $c->stash->{confirmation}->{uri}        =
        $c->uri_for(
            '/zaaktype/categorie/delete/' . $id
        );

    $c->forward('/page/confirmation');
    $c->detach;
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

