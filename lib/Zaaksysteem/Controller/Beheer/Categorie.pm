package Zaaksysteem::Controller::Beheer::Categorie;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use constant CATEGORIES_DB          => 'DB::BibliotheekCategorie';

use constant CATEGORIE_DESTINATIONS => {
    'zaaktype_catalogus' => {
        url                 => 'zaaktype_catalogus',
        naam                => 'Zaaktype Catalogus',
    },
    'zaaktypen'     => {
        url                 => 'zaaktypen',
        naam                => 'Zaaktype Bibliotheek',
    },
    'kenmerken'     => {
        url                 => 'bibliotheek/kenmerken',
        naam                => 'Kenmerken Bibliotheek',
    },
    'sjablonen'     => {
        url                 => 'bibliotheek/sjablonen',
        naam                => 'Sjablonen Bibliotheek',
    },
};

my $DESTINATIONS    = CATEGORIE_DESTINATIONS;

my $CATEGORY_FIELDS = {
    'naam'      => 'naam',
};


sub base : Chained('/beheer') : PathPart(''): CaptureArgs(0) {
    my ( $self, $c ) = @_;
}


sub categories : Private {
    my ( $self, $c, $catid ) = @_;

    $c->stash->{template}   = 'beheer/categorie/index.tt';

    $c->stash->{dest}       = $DESTINATIONS->{
        $c->stash->{dest_type}
    };

    $c->stash->{cat_url}    = $c->uri_for(
        '/beheer/' . $c->stash->{dest}->{url}
    );

    $c->add_trail(
        {
            uri     => $c->uri_for('/beheer/' .
                $c->stash->{dest}->{url}
            ),
            label   => $c->stash->{dest}->{naam},
        }
    );


    my $categories = $c->model(CATEGORIES_DB)->search({}, {order_by => 'naam'});

    # apply textfilter to results
    my $params = $c->req->params();
    my $textfilter = $params->{'textfilter'};

    if($textfilter) {
        if($c->stash->{'child_category_ids'}) {
            $categories = $categories->search({ 'id' => {'-in' => $c->stash->{'child_category_ids'}}});
        }

        $categories = $categories->search({'naam' => {'ilike' => '%'. $textfilter. '%' }});
    } else {
        $categories = $categories->search({
            pid => (
                $catid && $catid =~ /^\d+$/
                    ? $catid
                    : undef
            ),
        });
    }

    $c->stash->{'categories'} = $categories;


    if ($catid && $catid =~ /^\d+$/) {
        $c->stash->{'categorie'}   = $c->model(CATEGORIES_DB)->find($catid);

        $c->add_trail(
            {
                uri     => $c->uri_for('/beheer/bibliotheek/'
                    . $c->stash->{bib_type} . '/' 
                    . $catid
                ),
                label   => 'Categorie: ' . (
                    $c->stash->{'categorie'}
                        ? $c->stash->{'categorie'}->naam
                        : ''
                    ),
            }
        );
    }
}



sub list : Private {
    my ($self, $c) = @_;

    my $categorie_id = $c->stash->{categorie} ? $c->stash->{categorie}->id : undef;
    $c->stash->{entries} = $c->stash->{entries}->search({'bibliotheek_categorie_id' => $categorie_id});
#    $c->stash->{template} = 'widgets/beheer/' . $c->stash->{dest}->{template_list};
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

