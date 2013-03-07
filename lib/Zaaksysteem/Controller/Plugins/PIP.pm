package Zaaksysteem::Controller::Plugins::PIP;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use Data::Dumper;
use JSON;




sub base : Chained('/') : PathPart('pip'): CaptureArgs(0) {
    my ($self, $c) = @_;

    ### ANNOUNCE PIP
    $c->stash->{pip} = 1;

    ### Make sure we are logged in, or clean everything up, preventing other
    ### problems
    unless (
        $c->session->{pip} &&
        (
            (
                $c->session->{pip}->{ztc_aanvrager} =~
                    /^betrokkene-natuurlijk_persoon/ &&
                $c->model('Plugins::Digid')->succes
            ) ||
            (
                $c->session->{pip}->{ztc_aanvrager} =~
                    /^betrokkene-bedrijf/ &&
                $c->model('Plugins::Bedrijfid')->succes
            )
        )
    ) {
        $c->log->debug(
            'Lost digid session, deleting pip: ' .
            ($c->session->{pip}->{ztc_aanvrager}||'-') . ':' .
            $c->model('Plugins::Digid')->succes . ':' .
            $c->model('Plugins::Bedrijfid')->succes
        );

        delete($c->session->{pip});
    }

    if (
        !$c->session->{pip} &&
        $c->req->action !~ /pip\/login/
    ) {
        $c->response->redirect($c->uri_for('/pip/login'));
        $c->detach;
    }

    $c->stash->{betrokkene} = $c->model('Betrokkene')->get(
        {},
        $c->session->{pip}->{ztc_aanvrager}
    ) if $c->session->{pip};

    ### Make sure user is logged in with DigID
    $c->stash->{pip_session} = 1 if $c->session->{pip};
    $c->stash->{template_layout} = 'plugins/pip/layouts/pip.tt';
}

sub zaak : Chained('base') : PathPart('zaak'): CaptureArgs(1) {
    my ($self, $c, $zaaknr) = @_;

    return unless $zaaknr =~ /^\d+$/;

    $c->stash->{'zaak'} = $c->model('DB::Zaak')->find($zaaknr);

    unless ($c->stash->{zaak}) {
        $c->response->redirect($c->uri_for('/pip'));
        $c->detach;
    }


    ### Security
    unless (
        $c->stash->{zaak}->aanvrager &&
        $c->stash->{zaak}->aanvrager_object->betrokkene_identifier eq
            $c->session->{pip}->{ztc_aanvrager}
    ) {
        die('security?:' .
            $c->stash->{zaak}->aanvrager_object->betrokkene_identifier);
        $c->res->redirect(
            $c->uri_for('/pip')
        );

        $c->detach;
    }

    ### Find fase
    {
        if ($c->req->params->{fase} =~ /^\d+$/) {
            my $fases = $c->stash->{zaak}->zaaktype_node_id->zaaktype_statussen->search(
                {
                    status  => $c->req->params->{fase}
                }
            );

            $c->stash->{requested_fase} = $fases->first if $fases->count;
        } else {
            $c->stash->{requested_fase} =
                $c->stash->{zaak}->huidige_fase;
        }
    }
}

sub add_file : Chained('zaak'): PathPart('documents/0/add') : Args() {
    my ($self, $c, $element) = @_;

    unless (%{ $c->req->params } && $c->req->params->{documenttype}) {
        $c->stash->{nowrapper}  = 1;
        $c->stash->{template}   = 'zaak/elements/dialog/documents_edit_file.tt';
        $c->detach;
    }

    $c->forward('/zaak/documents/add_file');

    $c->response->redirect(
        $c->uri_for(
            '/pip/zaak/' . $c->stash->{zaak}->nr,
            undef,
        )
    );
}

sub get : Chained('zaak'): PathPart('documents/0/get') : Args() {
    my ($self, $c, $id) = @_;

    $c->forward('/zaak/documents/get', [ $id ]);
}

sub view_element : Chained('zaak'): PathPart('view_element'): Args(1) {
    my ($self, $c, $element) = @_;

    $c->forward('/zaak/view_element', [ $element ]);
}

sub overview : Chained('zaak') : PathPart(''): Args() {
    my ($self, $c) = @_;

    $c->stash->{template} = 'plugins/pip/overview.tt';
}


sub index : Chained('base') : PathPart(''): Args(0) {
    my ($self, $c) = @_;

    my $view = $c->req->params->{view};

    $c->stash->{template} = 'plugins/pip/index.tt';

    my $ownid = $c->session->{pip}->{ztc_aanvrager};
    $ownid =~ s/betrokkene-//g;

    my $ownsql = '
        (
            CF.{aanvrager} LIKE "' . $ownid . '-%"
        )
    ';

    my $sql = {
        'zaken'         =>
            $ownsql . ' AND Status!="resolved"',
        'afgehandelde_zaken' =>
            $ownsql . ' AND Status="resolved"',
    };

    ### Asked for a search view?
    if (
        $view || (
            $c->session->{search_query}->{raw_sql} &&
            $c->req->params->{paging_page}
        )
    ) {
        if ($view eq 'zaken') {
            $c->session->{search_query}->{raw_sql} = $sql->{zaken};
        } elsif ($view eq 'afgehandelde_zaken') {
            $c->session->{search_query}->{raw_sql}
                = $sql->{afgehandelde_zaken};
        }
        $c->forward('/search/load_search_results');
        $c->detach;
    }

    #$c->stash->{paging_page} = $c->req->params->{paging_page};
    #$c->stash->{paging_rows} = $c->req->params->{paging_rows};



    $c->log->debug('ZTC Aanvrager: '.$c->session->{pip}->{ztc_aanvrager});

#my $id = $c->session->{pip}->{ztc_aanvrager};
#
#$c->log->debug('BID: '.$id);
#
#my ($req_type, $orig_id, $bid) = $id =~ /([\w\_]*)\-([\w\_]*)\-(\d+)$/;
#$c->log->debug('BID: '.$bid);
#
#my $bdb = $c->model('Betrokkene')->find($bid);
#
#$c->log->debug('SIZE: '.$bdb->count);

$c->log->debug('USER-ID: '.Dumper($c->user));

    my $onafgeronde_zaken = $c->model('DB::ZaakOnafgerond')->search(
        {
            betrokkene              => $c->session->{pip}->{ztc_aanvrager}
        },
        {
            page                    => ($c->req->params->{'page'} || 1),
            rows                    => 10,
        }
    );


    $c->log->debug('COUNT ONAFGEHANDELDE ZAKEN: '.$onafgeronde_zaken->count());


    $c->stash->{'onafgehandelde_zaken_json'} = ();
    while (my $onafgeronde_zaak = $onafgeronde_zaken->next) {
        $c->log->debug('Onafgehandelde zaak tegengekomen!');

        push (@{$c->stash->{'onafgehandelde_zaken_json'}},
            JSON->new->utf8(0)->decode($onafgeronde_zaak->get_column('json_string')));
    }

    my $zaaktype_ids = ();
    for my $onafgerond (@{$c->stash->{'onafgehandelde_zaken_json'}}) {
        push (@{$zaaktype_ids}, $onafgerond->{'zaaktype_id'});
    }

    if (!$zaaktype_ids) {
        $zaaktype_ids = ([]);
    }

    $c->log->debug('Nodeids: ' . Dumper($zaaktype_ids));

    $onafgeronde_zaken = $c->model('DB::Zaaktype')->search(
        {
            'me.id'                 => { -in => $zaaktype_ids },
            'me.deleted'            => undef,
        },
        {
            join                    => 'zaaktype_node_id',
            page                    => ($c->req->params->{'page'} || 1), 
            rows                    => 10,
        }
    );

    $c->stash->{'onafgeronde_zaken'}         = $onafgeronde_zaken;
    $c->stash->{'hostname'}                  = 'dev.zaaksysteem.nl:3011';
    $c->stash->{'display_fields_onafgerond'} = [qw/titel/];

    $c->stash->{zaken}  = $c->model('Zaken')->zaken_pip(
        {
            page                    => ($c->req->params->{'page'} || 1), 
            rows                    => 10,
            betrokkene_type         => $c->stash->{betrokkene}->btype,
            gegevens_magazijn_id    => $c->stash->{betrokkene}->ex_id,
            type_zaken              => 'open',
        }
    );
    $c->stash->{afgehandelde_zaken}  = $c->model('Zaken')->zaken_pip(
        {
            page                    => ($c->req->params->{'page'} || 1), 
            rows                    => 10,
            betrokkene_type         => $c->stash->{betrokkene}->btype,
            gegevens_magazijn_id    => $c->stash->{betrokkene}->ex_id,
            type_zaken              => 'resolved',
        }
    );
    $c->stash->{'display_fields'} = $c->model('SearchQuery')->get_display_fields({
        pip => 1
    });

    $c->log->debug('COUNT: ' . $c->stash->{zaken}->count);


#    $c->stash->{'zaken'}                = $c->model('Zaak')->search_sql(
#        $sql->{zaken}
#    );
#    $c->stash->{'afgehandelde_zaken'}   = $c->model('Zaak')->search_sql(
#        $sql->{afgehandelde_zaken}
#    );
}

sub contact : Chained('base') : PathPart('contact'): Args(0) {
    my ($self, $c) = @_;

    my $res = $c->model('Betrokkene')->get(
        {},
        $c->session->{pip}->{ztc_aanvrager}
    );

    if (exists($c->req->params->{update})) {
        $res->mobiel($c->req->params->{'npc-mobiel'});
        $res->email($c->req->params->{'npc-email'});
        $res->telefoonnummer($c->req->params->{'npc-telefoonnummer'});
    }

    $c->stash->{'betrokkene'} = $res;

    $c->stash->{template} = 'plugins/pip/contact.tt';
}

sub login : Chained('base') : PathPart('login'): Args() {
    my ($self, $c, $type) = @_;
    my ($bsn, $kvknummer);

    ### Type natuurlijk_persoon or bedrijf
    if (!$type) {
        $c->stash->{template} = 'plugins/pip/login_type.tt';
        $c->detach;

        ### Zorg voor een schone start
        $c->logout;
        $c->delete_session;
    }

    ### Just check if user is logged in via digid
    if (
        $type eq 'natuurlijk_persoon'
    ) {
        if (!$c->model('Plugins::Digid')->succes) {
            $c->res->redirect($c->uri_for(
                '/auth/digid',
                {
                    verified_url    => $c->uri_for('/pip/login/natuurlijk_persoon')
                }
            ));

            $c->detach;
        } else {
            $bsn = $c->model('Plugins::Digid')->uid;
        }
    } elsif ($type eq 'bedrijf') {
        if (!$c->model('Plugins::Bedrijfid')->succes) {
            $c->res->redirect($c->uri_for(
                '/auth/bedrijfid',
                {
                    verified_url    => $c->uri_for('/pip/login/bedrijf')
                }
            ));

            $c->detach;
        } else {
            $kvknummer = $c->model('Plugins::Bedrijfid')->login;
        }
    } else {
        $c->res->redirect( $c->uri_for('/pip') );
        $c->detach;
    }


    if ($bsn) {
        $c->log->debug(
            'Request for DigID uid: ' . $bsn
        );

        my $res = $c->model('Betrokkene')->search(
            {
                type    => 'natuurlijk_persoon',
                intern  => 0,
            },
            {
                'burgerservicenummer'   => $bsn
            },
        );

        if ($res->count) {
            my $bo = $res->next;

            if ($bo->gmid) {
                $c->session->{pip}->{ztc_aanvrager} = 'betrokkene-natuurlijk_persoon-'
                    . $bo->gmid;

                $c->flash->{result} = 'U bent succesvol aangemeld via Digid';
                $c->response->redirect($c->uri_for('/pip'));
                $c->detach;
            }
        }

        ### Hmm, BSN not found, logout with message
        $c->flash->{result} = 'U bent succesvol aangemeld, maar helaas kunnen'
            . ' wij geen zaken vinden in ons systeem. Om veiligheidsredenen'
            . ' bent u uitgelogd.';

        $c->res->redirect($c->uri_for('/auth/digid/logout'));
        $c->detach;
    } elsif ($kvknummer) {
        $c->log->debug(
            'Request for Bedrijfid kvknummer: ' . $kvknummer
        );

        my $res = $c->model('Betrokkene')->search(
            {
                type    => 'bedrijf',
                intern  => 0,
            },
            {
                'dossiernummer'   => $kvknummer
            },
        );

        if ($res->count) {
            my $bo = $res->next;

            if ($bo->gmid) {
                $c->log->debug(
                    'Succesvol Bedrijfid kvknummer: ' . $kvknummer
                );
                $c->session->{pip}->{ztc_aanvrager} = 'betrokkene-bedrijf-'
                    . $bo->gmid;

                $c->flash->{result} = 'U bent succesvol aangemeld via Bedrijfid';
                $c->response->redirect($c->uri_for('/pip'));
                $c->detach;
            }
        }

        ### Hmm, BSN not found, logout with message
        $c->flash->{result} = 'U bent succesvol aangemeld, maar helaas kunnen'
            . ' wij geen zaken vinden in ons systeem. Om veiligheidsredenen'
            . ' bent u uitgelogd.';
        $c->log->debug(
            'Geen zaken voor Bedrijfid kvknummer: ' . $kvknummer
        );

        $c->res->redirect($c->uri_for('/auth/bedrijfid/logout'));
        $c->detach;
    }
}

sub logout : Chained('base') : PathPart('logout'): Args(0) {
    my ($self, $c) = @_;

    $c->delete_session;

    $c->response->redirect($c->uri_for('/pip'));
}

sub zaaktypeinfo : Chained('zaak'): PathPart('zaaktypeinfo'): Args(0) {
    my ($self, $c) = @_;

    $c->stash->{nowrapper} = 1;
    $c->stash->{template} = 'zaak/zaaktypeinfo.tt'
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

