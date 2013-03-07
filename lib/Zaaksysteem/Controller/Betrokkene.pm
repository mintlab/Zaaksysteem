package Zaaksysteem::Controller::Betrokkene;

use strict;
use warnings;
use Data::Dumper;
use parent 'Catalyst::Controller';

use Zaaksysteem::Constants qw/
    ZAAKSYSTEEM_GM_AUTHENTICATEDBY_BEHANDELAAR
    VALIDATION_CONTACT_DATA
/;




sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Zaaksysteem::Controller::Betrokkene in Betrokkene.');
}

sub base : Chained('/') : PathPart('betrokkene'): CaptureArgs(0) {
    my ($self, $c) = @_;

    ## Zaakid?
    if ($c->req->params->{'zaak'}) {
        $c->stash->{zaak} = $c->model('DB::Zaak')->find($c->req->params->{'zaak'});
    }
}

{
    Zaaksysteem->register_profile(
        method  => 'create',
        profile => {
            required => [ qw/
                betrokkene_type
                np-geslachtsnaam
                np-huisnummer
                np-postcode
                np-straatnaam
                np-voornamen
                np-woonplaats
                np-geslachtsaanduiding
            /],
            optional => [ qw/
                create
                np-huisnummertoevoeging
				np-burgerservicenummer
                np-voorvoegsel
                np-geboortedatum
                npc-telefoonnummer
                npc-email
                npc-mobiel
            /],
            constraint_methods  => {
                'np-burgerservicenummer'    => qr/\d+/,
                'np-geboortedatum'          => qr/[\d-]+/,
                'np-geslachtsnaam'          => qr/.+/,
                'np-huisnummer'             => qr/[\d\w]+/,
                'np-postcode'               => qr/^\d{4}\w{2}$/,
                'np-straatnaam'             => qr/.+/,
                'np-voorletters'            => qr/[\w.]+/,
                'np-voornamen'              => qr/.+/,
                'np-woonplaats'             => qr/.+/,
                'npc-email'                 => qr/^.+?\@.+\.[a-z0-9]{2,}$/,
                'npc-telefoonnummer'        => qr/^[\d\+]{6,15}$/,
                'npc-mobiel'                => qr/^[\d\+]{6,15}$/,
            },
            msgs                => {
                'format'    => '%s',
                'missing'   => 'Veld is verplicht.',
                'invalid'   => 'Veld is niet correct ingevuld.',
                'constraints' => {
                    '(?-xism:^\d{4}\w{2}$)' => 'Postcode zonder spatie (1000AA)',
                    '(?-xism:^[\d\+]{6,15}$)' => 'Nummer zonder spatie (e.g: +312012345678)',
                }
            },
        }
    );

    sub create : Chained('/') : PathPart('betrokkene/create'): Args(0) {
        my ($self, $c) = @_;

        if ($c->req->header("x-requested-with") eq 'XMLHttpRequest') {
            $c->zvalidate;
            $c->detach;
        }

        ### Default: view
        $c->stash->{template}   = 'betrokkene/create.tt';
        $c->add_trail(
            {
                uri     => $c->uri_for('/betrokkene/create'),
                label   => 'Nieuw contact',
            }
        );

        if ($c->req->method eq 'POST') {
            # Validate information
            return unless $c->zvalidate && $c->req->params->{create};

            ### Create person

            # Conver postcode
            $c->req->params->{'np-postcode'}
                = uc($c->req->params->{'np-postcode'});

            my $id = $c->model('Betrokkene')->create(
                'natuurlijk_persoon',
                {
                    %{ $c->req->params },
                    authenticatedby =>
                        ZAAKSYSTEEM_GM_AUTHENTICATEDBY_BEHANDELAAR,
                }
            );

            if ($id) {
                $c->flash->{result} = 'Natuurlijk persoon aangemaakt';
                $c->res->redirect(
                    $c->uri_for(
                        '/betrokkene/' . $id,
                        { gm => 1, type => 'natuurlijk_persoon' }
                    )
                );
            }
        }

    }
}


sub view_base : Chained('base'): PathPart('') : CaptureArgs(1) {
    my ($self, $c, $id) = @_;

    return unless $id =~ /^\d+$/;

    my $betrokkene_type = $c->req->params->{type};

    $c->stash->{requested_bid} = $id;

    if ($c->req->params->{gm}) {
        $c->stash->{betrokkene} = $c->model('Betrokkene')->get(
            {
                type    => $betrokkene_type,
                intern  => 0,
            },
            $id
        );

        $c->stash->{'betrokkene_edit'} = 1 unless
            !$c->req->params->{edit} ||
            $c->stash->{'betrokkene'}->authenticated
    } else {
        $c->stash->{betrokkene} = $c->model('Betrokkene')->get(
            {},
            $id
        );
    }

    if (
        $c->stash->{betrokkene} &&
        $c->stash->{betrokkene}->in_onderzoek
    ) {
        $c->flash->{'result'} = 'WAARSCHUWING: De GBA-gegevens van de '
            . 'aanvrager van deze zaak zijn in onderzoek. ['
            . join(',', @{
                    $c->stash->{betrokkene}->in_onderzoek
                }
            ) . ']';
    }

    $c->detach unless $c->stash->{betrokkene};
}

sub view : Chained('view_base'): PathPart('') : Args() {
    my ($self, $c) = @_;

    $c->stash->{template}   = 'betrokkene/view.tt';
    if ($c->check_any_user_permission(qw/contact_nieuw contact_search/)) {
        $c->stash->{can_betrokkene_edit} = 1;
    }

    $c->stash->{force_result_finish} = 1;

    $c->stash->{zaken}  = $c->model('Zaken')->zaken_pip(
        {
            page                    => ($c->req->params->{'page'} || 1), 
            rows                    => 10,
            betrokkene_type         => $c->stash->{betrokkene}->btype,
            gegevens_magazijn_id    => $c->stash->{betrokkene}->ex_id,
            type_zaken              => 'open',
            'sort_direction'        => $c->req->params->{sort_direction},
            'sort_field'            => $c->req->params->{sort_field},
        }
    );

    $c->stash->{resolved_zaken}     = $c->model('Zaken')->zaken_pip(
        {
            page                    => ($c->req->params->{'page'} || 1), 
            rows                    => 10,
            betrokkene_type         => $c->stash->{betrokkene}->btype,
            gegevens_magazijn_id    => $c->stash->{betrokkene}->ex_id,
            type_zaken              => 'resolved',
            'sort_direction'        => $c->req->params->{sort_direction},
            'sort_field'            => $c->req->params->{sort_field},
        }
    );

    if ($c->stash->{betrokkene}->verblijfsobject) {
        $c->stash->{adres_zaken}        = $c->model('Zaken')->adres_zaken(
            {
                page                    => ($c->req->params->{'page'} || 1), 
                rows                    => 10,
                nummeraanduiding        => $c->stash->{betrokkene}
                                                ->verblijfsobject
                                                ->hoofdadres,
                'sort_direction'        => $c->req->params->{sort_direction},
                'sort_field'            => $c->req->params->{sort_field},
            }
        );
    }

    $c->stash->{ $_ }     = $c->req->params->{ $_ }
            for qw/sort_direction sort_field/;

    $c->stash->{'display_fields'} = $c->model('SearchQuery')->get_display_fields();

    ### TODO ZS2
#    $c->stash->{'adres_zaken'}          = $c->model('Zaak')->search_sql('
#        CF.{bag_items} LIKE "%verblijfsobject-'
#        .  $c->stash->{betrokkene}->verblijfsobject->id . '%"'
#    ) if (
#        $c->stash->{betrokkene} &&
#        $c->stash->{betrokkene}->verblijfsobject
#    );
}

sub search : Chained('base'): PathPart('search') {
    my ($self, $c) = @_;

    $c->stash->{ $_ } = $c->req->params->{ $_ } for (
        keys (%{ $c->req->params })
    );

    # AJAX
    if ($c->req->header("x-requested-with") eq 'XMLHttpRequest') {
        $c->stash->{nowrapper} = 1;

            $c->log->debug('Searching for: ' . Dumper($c->req->params));
        $c->stash->{betrokkene_type} = $c->req->params->{betrokkene_type} ||
            $c->req->params->{jstype};
        if (exists($c->req->params->{search})) {
            my %sparams = ();

            for my $key (keys %{ $c->req->params }) {
                if ($c->req->params->{$key}) {
                    my $rawkey = $key;
                    $key =~ s/np-//g;
                    $sparams{$key} = $c->req->params->{$rawkey};
                }
            }

            my $rows_per_page = $c->req->param('rows_per_page') || '';
            delete($sparams{$_}) for qw/import_datum url method jscontext jsversion jsfill submit search jstype rows_per_page/;

            my $type    = $c->req->params->{jstype};
            if ($c->req->params->{jsversion} == 3) {
                $c->log->debug('Betrokkene server VERSION 3');
                delete($sparams{$_}) for grep { /^ezra_client_info/ } keys %{
                    $c->req->params
                };
                $type   = $c->req->params->{betrokkene_type};
            }

            $c->stash->{betrokkene_type} = $type;

            delete($sparams{betrokkene_type});


            $c->stash->{template} = 'betrokkene/popup/search_resultrows.tt';
            $c->stash->{results} = $c->model('Betrokkene')->search(
                {
                    type    => $type,
                    intern  => 0,
                    rows_per_page => $rows_per_page,
                },
                \%sparams
            );

            $c->detach;
        }

        $c->stash->{template} = 'betrokkene/popup/search.tt';
    } else {
        $c->stash->{template} = 'betrokkene/search.tt';
        $c->add_trail(
            {
                uri     => $c->uri_for('/betrokkene/search'),
                label   => 'Contact zoeken',
            }
        );

        ## Paging
        $c->stash->{ $_ } = $c->req->params->{ $_ }
            for grep {
                $c->req->params->{ $_ } &&
                $c->req->params->{ $_ } =~ /^\d+/
            } qw/paging_page paging_rows/;

        my %sparams = ();
        my ($startsearch, $betrokkene_type);

        if (exists($c->req->params->{search})) {
            for my $key (keys %{ $c->req->params }) {
                if ($c->req->params->{betrokkene_type} eq 'natuurlijk_persoon') {
                    if ($c->req->params->{$key} && $key =~ /^np-/) {
                        my $rawkey = $key;
                        $key =~ s/np-//g;
                        $sparams{$key} = $c->req->params->{$rawkey};
                    }
                } elsif ($c->req->params->{betrokkene_type} eq 'bedrijf') {
                    my $rawkey = $key;
                    next if (
                        lc($rawkey) eq 'search' ||
                        lc($rawkey) eq 'betrokkene_type'
                    );
                    $sparams{$key} = $c->req->params->{$rawkey};
                } elsif ($c->req->params->{betrokkene_type} eq 'medewerker') {
                    my $rawkey = $key;
                    next if (
                        lc($rawkey) eq 'search' ||
                        lc($rawkey) eq 'betrokkene_type'
                    );
                    $sparams{$key} = $c->req->params->{$rawkey};
                }

            }
            $betrokkene_type = $c->req->params->{'betrokkene_type'};

            $startsearch++;
        } elsif (
            (
                $c->stash->{paging_page} ||
                $c->req->params->{order}
            ) && $c->session->{betrokkene_search_data}
        ) {
            %sparams            = %{ $c->session->{betrokkene_search_data} };
            $betrokkene_type    = $c->session->{betrokkene_type};
            $startsearch++;
        } else {
            delete($c->session->{betrokkene_search_data});
        }

        if ($startsearch) {
            $c->session->{betrokkene_search_data} = \%sparams;
            $c->session->{betrokkene_type} = $betrokkene_type;

            $c->stash->{template} = 'betrokkene/search_results.tt';

            $c->log->debug('Search for betrokkene with params' .
                Dumper(\%sparams));


            # Geboortedatum...
            if ($sparams{'geboortedatum-dag'}) {
                $sparams{'geboortedatum'} =
                    sprintf('%02d', $sparams{'geboortedatum-jaar'}) . '-'
                    . sprintf('%02d', $sparams{'geboortedatum-maand'}) . '-'
                    .$sparams{'geboortedatum-dag'};
            } elsif ($sparams{'geboortedatum'}) {
                $sparams{'geboortedatum'} =~ s/^(\d{2})-(\d{2})-(\d{4})$/$3-$2-$1/;
            }

$c->log->debug("contact search params: " . Dumper \%sparams);
            $c->stash->{betrokkenen} = $c->model('Betrokkene')->search(
                {
                    type    => $betrokkene_type,
                    intern  => 0,
                },
                \%sparams
            );

            $c->stash->{betrokkene_type} = $betrokkene_type;
        }

    }
}

sub get : Chained('base'): PathPart('get'): Args(1) {
    my ($self, $c, $id) = @_;

    if ($c->req->params->{betrokkene_type}) {
        $c->stash->{'betrokkene'} = $c->model('Betrokkene')->get(
            {
                intern  => 0,
                type    => $c->req->params->{betrokkene_type},
            },
            $id
        ) or return;
    } else {
        $c->stash->{'betrokkene'} = $c->model('Betrokkene')->get({}, $id)
            or return;
    }

    if ($c->req->params->{actueel} && $c->req->params->{actueel} =~ /^\d+$/) {
        if ($c->stash->{'betrokkene'}->gm_extern_np) {
            my $gegevens_magazijn_id =
                $c->stash->{'betrokkene'}->gm_extern_np->id;

            $c->stash->{betrokkene} = $c->model('Betrokkene')->get(
                {
                    intern  => 0,
                    type    => $c->stash->{betrokkene}->btype,
                },
                $gegevens_magazijn_id
            );

            $c->log->debug('Externe betrokkene vraag');
        }
    }

    if ($c->req->header("x-requested-with") eq 'XMLHttpRequest') {
        $c->stash->{nowrapper} = 1;

        $c->stash->{template} = 'betrokkene/popup/get.tt';
    }
}

#sub prepare_page : Private {
#    my ($self, $c) = @_;
#
#    $c->forward('/page/add_menu_item', [
#        {
#            'main' => [
#                {
#                    'cat'   => 'Contacten',
#                    'name'  => 'Nieuw contact',
#                    'href'  => $c->uri_for('/betrokkene/create')
#                },
#                {
#                    'cat'   => 'Contacten',
#                    'name'  => 'Contact zoeken',
#                    'href'  => $c->uri_for('/search/betrokkene')
#                },
#            ],
#        }
#    ]);
#}

{
    sub _load_update_profile {
        my ($self, $c) = @_;

        if ($c->req->params->{betrokkene_type} eq 'bedrijf') {
            ### Get profile from Model
            my $profile = $c->get_profile(
                'method'=> 'create',
                'caller' => 'Zaaksysteem::Betrokkene::Object::Bedrijf'
            ) or return;

            my @required_fields = grep {
                $_ ne 'vestiging_postcodewoonplaats' ||
                $_ ne 'vestiging_adres'
            } @{ $profile->{required} };

            push(@required_fields, 'rechtsvorm');

            $profile->{required} = \@required_fields;

            $c->register_profile(
                method => 'update',
                profile => $profile,
            );
        } else {
            $c->register_profile(
                method => 'update',
                profile => 'Zaaksysteem::Controller::Betrokkene::create'
            );
        }
    }

    my $BETROKKENE_MAP = {
        bedrijf => 2,
        natuurlijk_persoon => 1,
    };

    Zaaksysteem->register_profile(
        method => 'update',
        profile => VALIDATION_CONTACT_DATA
    );

    sub update : Chained('base'): PathPart('info/update'): Args(1) {
        my ($self, $c, $gmid) = @_;

        return unless $c->check_any_user_permission(qw/contact_nieuw contact_search/);

        ### Betrokkene edit only 
        if ($c->req->params->{betrokkene_edit}) {
            $self->_load_update_profile($c)
                if $c->req->params->{betrokkene_edit};
        } else {
            $c->register_profile(
                'method'    => 'update',
                profile     => VALIDATION_CONTACT_DATA,
            );
        }

        if (
            $c->req->header("x-requested-with") eq 'XMLHttpRequest'
        ) {
            $c->zvalidate;
            $c->detach;
        }

        ### END Betrokkene edit only

        my $contact_data = $c->model('DB::ContactData')->search({
            gegevens_magazijn_id  => $gmid,
            betrokkene_type         => $BETROKKENE_MAP->{
                $c->req->params->{betrokkene_type}
            },
        });

        if ($contact_data->count) {
            $contact_data = $contact_data->first;
        } else {
            $contact_data = $c->model('DB::ContactData')->create({
                    gegevens_magazijn_id    => $gmid,
                    betrokkene_type         => $BETROKKENE_MAP->{
                        $c->req->params->{betrokkene_type}
                    },
            });
        }

        # Update niet authentieke gegevens
        if ($c->req->params->{betrokkene_edit} && (my $dv = $c->zvalidate)) {
            my $gmbetrokkene = $c->model('Betrokkene')->get(
                {
                    type    => $c->req->params->{betrokkene_type},
                    intern  => 0,
                },
                $gmid
            );

            unless ($gmbetrokkene->authenticated) {
                if ($c->req->params->{betrokkene_type} eq 'bedrijf') {
                    my $params = $dv->valid;
                    for my $dbkey (keys %{ $params }) {
                        $gmbetrokkene->$dbkey($c->req->params->{$dbkey})
                            if $gmbetrokkene->can($dbkey);
                    }
                } else {
                    for my $pkey (grep(/^np-/, keys %{ $c->req->params })) {
                        my $dbkey = $pkey;
                        $dbkey =~ s/^np-//g;

                        $gmbetrokkene->$dbkey($c->req->params->{$pkey})
                            if $gmbetrokkene->can($dbkey);
                    }
                }
            }
        }

        # Update contactgegevens
        if ($c->zvalidate) {
            $contact_data->mobiel($c->req->params->{'npc-mobiel'});
            $contact_data->telefoonnummer($c->req->params->{'npc-telefoonnummer'});
            $contact_data->email($c->req->params->{'npc-email'});
            $contact_data->update;
        }

        if ($c->stash->{zaak}) {
            $c->res->redirect($c->uri_for('/zaak/' . $c->stash->{zaak}->nr));
        } else {
            # Remove edit on post
            my $referer = $c->req->referer;
            $referer =~ s/[&\?]?edit=1//;
            $c->res->redirect($referer);
        }
    }
}

{
    sub verwijder : Chained('base'): PathPart('verwijder'): Args(2) {
        my ($self, $c, $betrokkene_type, $gmid) = @_;

        return unless $c->check_any_user_permission(qw/contact_nieuw contact_search/);

        return unless $gmid;

        my $gmbetrokkene = $c->model('Betrokkene')->get(
            {
                type    => $betrokkene_type,
                intern  => 0,
            },
            $gmid
        );

        # Update niet authentieke gegevens
        if (
            %{ $c->req->params } &&
            $c->req->params->{confirmed}
        ) {
            $c->response->redirect(
                $c->uri_for(
                    '/betrokkene/search'
                )
            );

            do {
                $c->flash->{result} = 'Deze betrokkene kan niet'
                    . ' worden verwijderd';
                $c->detach;
            } unless $gmbetrokkene->can_verwijderen;

            if ($gmbetrokkene->verwijder) {
                $c->flash->{result} =
                    'Betrokkene "' . $gmbetrokkene->naam . '" succesvol verwijderd';
            }
        }

        $c->stash->{confirmation}->{message}    =
            'Weet u zeker dat u betrokkene "'
            . $gmbetrokkene->naam . '" wilt verwijderen?';

        $c->stash->{confirmation}->{type}       = 'yesno';
        $c->stash->{confirmation}->{uri}        =
            $c->uri_for(
                '/betrokkene/verwijder/' . $betrokkene_type . '/' . $gmid
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

