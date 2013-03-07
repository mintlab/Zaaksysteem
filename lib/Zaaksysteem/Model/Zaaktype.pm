package Zaaksysteem::Model::Zaaktype;

use strict;
use warnings;
use Scalar::Util;

use Data::Dumper;
use DateTime;
use Zaaksysteem::Constants;
use parent 'Catalyst::Model';
use File::Copy;

use Moose;

use constant ZAAKTYPE_OBJECT => __PACKAGE__ . '::Object';

use base qw/Zaaksysteem::Model::Zaaktype::General/;

has 'c' => (
    is  => 'rw',
);



my $BETROKKENE_MAP = {
    'bedrijf'       => [qw/
        niet_natuurlijk_persoon
        niet_natuurlijk_persoon_na
    /],
    'natuurlijk_persoon' => [qw/
        natuurlijk_persoon
        natuurlijk_persoon_na
    /],
    'medewerker'    => [qw/
        medewerker
    /],
    'org_eenheid'   => [qw/
        org_eenheid
    /],
};
sub list {
    my ($self, $search) = @_;
    my ($query) = ({});

    if ($search) {
        if ($search->{zaaktype_categorie_id}) {
            if (my $cat = $self->c->model('DB::BibliotheekCategorie')->find(
                    $search->{zaaktype_categorie_id}
                )
            ) {
                $query->{'me.bibliotheek_categorie_id'}
                    = { -in => [
                        $cat->id,
                        @{ $cat->list_of_children }
                        ]
                    };
            }
        }

        if ($search->{webform_toegang}) {
            $query->{'zaaktype_node_id.webform_toegang'}
                = $search->{webform_toegang};
        }

        if ($search->{zaaktype_titel}) {
            $query->{'lower(zaaktype_node_id.titel)'}
                = { 'like' => '%' . lc($search->{zaaktype_titel}) . '%' }
        }

        if ($search->{zaaktype_trefwoorden}) {
            $query->{'lower(zaaktype_node_id.zaaktype_trefwoorden)'}
                = { 'like' => '%' . lc($search->{zaaktype_trefwoorden}) . '%' }
        }

        if ($search->{zaaktype_omschrijving}) {
            $query->{'lower(zaaktype_node_id.zaaktype_omschrijving)'}
                = { 'like' => '%' . lc($search->{zaaktype_omschrijving}) . '%' }
        }

        if ($search->{zaaktype_trigger}) {
            $query->{'zaaktype_node_id.trigger'}
                = lc($search->{zaaktype_trigger});
        }
        if ($search->{zaaktype_betrokkene_type}) {
            $query->{'zaaktype_betrokkenens.betrokkene_type'} = [];

            for my $betrokkene (
                @{
                    $BETROKKENE_MAP->{
                        lc($search->{zaaktype_betrokkene_type})
                    }
                }
            ) {
                push(
                    @{ $query->{'zaaktype_betrokkenens.betrokkene_type'} },
                    $betrokkene
                );
            }
        }
    }

    $query = $query || {};

    unless ($search->{deleted}) {
        $query->{'me.deleted'} = undef;
    }

    $self->c->log->debug('Zaaktype query' . Dumper($query));

    my $zts = $self->c->model('DB::Zaaktype')->search(
        {
            %{ $query }
        },
        {
            join        => [
                'zaaktype_node_id',
                { zaaktype_node_id => 'zaaktype_betrokkenens' }
            ],
            group_by    => [
                'me.id', 'me.zaaktype_node_id', 'me.version', 'me.active',
                'me.created', 'me.last_modified', 'me.deleted',
                'me.bibliotheek_categorie_id'
            ],
            order_by    => ['me.id'],
        }
    );

    return $zts;
}

sub find {
    my ($self, $id) = @_;

    return unless $id =~ /^\d+$/;

    return $self->get($id);

    ### Search database for given ID on zaaksysteem_node
    return unless my $znode = $self->c->model('ZaaktypeNode')->find($id);

    return ZAAKTYPE_OBJECT->new(node_row => $znode);
}

sub delete {
    my ($self, $id) = @_;

    ### Find zaaktype
    my $zt = $self->c->model('DB::Zaaktype')->find($id);

    return unless $zt;

    ### Deprecated / inactive this zaaktype
    $zt->active(0);
    $zt->deleted(DateTime->now);

    $zt->update;

    return 1;
}

sub duplicate {
    my ($self, $id) = @_;

    my $zt = $self->get($id);

    ### Remove edit, and make it create
    delete($zt->{edit});
    $zt->{create} = 1;

    return $zt;
}

## XXX TODO XXX NEW XXX TODO XXX
## Retrieve will be a future alias for get


{
    Zaaksysteem->register_profile(
        method  => 'retrieve',
        profile => {
            required        => [ qw/
            /],
            'optional'      => [ qw/
            /],
            'require_some'  => {
                'zaaktype_id_or_node_id' => [
                    1,
                    'id',
                    'nid'
                ],
            },
            'constraint_methods'    => {
                'id'    => qr/^\d+$/,
                'nid'   => qr/^\d+$/,
            },
        }
    );

    sub retrieve {
        my ($self, %opts) = @_;
        my ($nid);

        my $dv = $self->c->check(
            params  => \%opts
        );

        do {
            $self->c->log->error(
                'Zaaktype->retrieve: invalid options'
            );
            return;
        } unless $dv->success;

        my $object = ZAAKTYPE_OBJECT;

        if ($opts{id}) {
            my $zaaktype = $self->c->model('DB::Zaaktype')->find($opts{id});

            if (
                !$zaaktype ||
                !$zaaktype->zaaktype_node_id ||
                !$zaaktype->zaaktype_node_id->id
            ) {
                $self->c->log->error(
                    'Zaaktype->retrieve: Cannot find zaaktype with id: '
                    . $opts{id}
                );

                return;
            }

            $nid = $zaaktype->zaaktype_node_id->id;
        } else {
            $nid = $opts{nid};
        }

        my $zo  = $object->new(
            'c'         => $self->c,
            'nid'       => $nid,
            'extraopts' => $opts{extraopts}
        );
    }
}



my $ZAAKTYPE_MAP = {
    'specifiek' => {
        'help'              => 'help',
        'value'             => 'vraag',
        'value_type'        => 'type',
        'key'               => 'key',
        #'value_mandatory'   => 'verplicht_registratie',
        #'value_mandatory_end' => 'verplicht_afhandelen',
        'label'             => 'naam',
        'betrokkene_trigger' => 'betrokkene_trigger',
        'document_key'      => 'document_key'
    },
    'documenten' => {
        'mandatory'         => 'mandatory',
        'category'          => 'category',
        'descriptions'      => 'descriptions',
    },
    'status'    => {
        status_type         => 'type',
        naam                => 'naam',
        afhandeltijd        => 'afhandeltijd',
        betrokkene          => 'betrokkene'
    },
};

sub get {
    my ($self, $id) = @_;

    my $ztr     = $self->c->model('DB::Zaaktype')->find($id);

    return unless $ztr;

    ### node
    my $node    = $ztr->zaaktype_node_id;

    ### Algemeen
    my $rv      = {
        'category'          => (
            $node->zaaktype_categorie_id ?
            $node->zaaktype_categorie_id : (
                $ztr->bibliotheek_categorie_id ?
                $ztr->bibliotheek_categorie_id->id : ''
            )
        ),
        'edit'              => $node->id,
        'algemeen'          => {
            'zt_code'       => $node->code,
            'zt_naam'       => $node->titel,
            'zt_trigger'        => $node->trigger,
            'zt_toelichting'    => $node->toelichting,
            'zt_automatisch_behandelen'    => $node->automatisch_behandelen,
            'zt_webform_toegang'        => $node->webform_toegang,
            'zt_webform_authenticatie'  => $node->webform_authenticatie,
            'zt_adres_relatie'          => $node->adres_relatie,
            'zt_hergebruik'             => $node->aanvrager_hergebruik,
            'zt_toewijzing_zaakintake'  => $node->toewijzing_zaakintake,
            'type_aanvragers' => {},
            'documenten'    => {},
        },
        'specifiek'         => {},
    };

    ### Kenmerken
    my $kenmerken = $node->zaaktype_attributens->search(
        {},
        {
            order_by => [
                { -asc => 'id' },
            ],
        }
    );
    my $speccount = 0;
    while (my $kenmerk = $kenmerken->next) {
        if ($kenmerk->attribute_type eq 'spec') {
            my %spec = map {
                    my $mapk = $ZAAKTYPE_MAP->{specifiek}->{ $_ };
                    $mapk => $kenmerk->$_
                    } keys %{ $ZAAKTYPE_MAP->{specifiek} };

            ### Custom
            if ($kenmerk->value_mandatory) {
                $spec{verplicht} = 'registratie';
            } elsif ($kenmerk->value_mandatory_end) {
                $spec{verplicht} = 'afhandelen';
            } else {
                $spec{verplicht} = 0;
            }
            if (my $specoptions = $kenmerk->zaaktype_values) {
                $spec{'options'} = [];
                while (my $specoption = $specoptions->next) {
                    push(@{ $spec{'options'} }, $specoption->value);
                }
            }

            $speccount++;
            $rv->{specifiek}->{$speccount} = \%spec;
        } else {
            my $values = $kenmerk->zaaktype_values;
            if ($values->count == 1) {
                my $value = $values->first;
                $rv->{algemeen}->{$kenmerk->key}
                    = $value->value;
            }
        }
    }

    ### Statussen
    my $statussen = $node->zaaktype_statuses;
    while (my $status = $statussen->next) {
        ### Default status data
        my $stata = {
            'afhandeltijd'      => $status->afhandeltijd,
            'type'              => $status->status_type,
            'status'            => $status->status,
            'ou_id'             => $status->ou_id,
            'role_id'           => $status->role_id,
            #'org_eenheid_id'    => $status->org_eenheid_id,
            'mail'              => {
                'onderwerp'     => $status->mail_subject,
                'message'       => $status->mail_message
            },
            'subzaken'          => {},
            'kenmerken'         => {},
            'sjablonen'         => {},
            'notificaties'      => {},
            'naam'              => $status->naam,
            'has_checklist'     => $status->checklist,
            'checklist'         => {},
            'documenten'        => {},
            'resultaten'        => {},
        };

        ### subzaken
        my $relaties = $status->zaaktype_relaties;
        my $count = 0;
        while (my $relatie = $relaties->next) {
            $count++;
            next unless $relatie->relatie_zaaktype_id;
            my %reldata = (
                zaaktype_id     => $relatie->relatie_zaaktype_id->id,
                description     => $relatie->relatie_zaaktype_id->titel,
                gerelateerd     => (
                    $relatie->relatie_type eq 'gerelateerd'
                        ?   1
                        :   undef
                ),
                'deelzaak'      => (
                    $relatie->relatie_type eq 'deelzaak'
                        ?   1
                        :   undef
                ),
                'vervolgzaak'   => (
                    $relatie->relatie_type eq 'vervolgzaak'
                        ?   1
                        :   undef
                ),
                'eigenaar_type' => $relatie->eigenaar_type,
                'kopieren_kenmerken' => $relatie->kopieren_kenmerken,
                'status'        => $relatie->status,
                'start_delay'   => $relatie->start_delay,
            );

            $stata->{subzaken}->{$count} = \%reldata;
        }

        ### Kenmerken
        my $kenmerken = $status->zaaktype_kenmerkens->search(
            {},
            {
                order_by => [
                    { -asc => 'id' },
                ],
            }
        );
        $count = 0;
        while (my $kenmerk = $kenmerken->next) {
            $count++;
            my %kenmerkdata = (
                id              => $kenmerk->id,
                label           => $kenmerk->label,
                verplicht       => $kenmerk->value_mandatory,
                pip             => $kenmerk->pip,
                zaakinformatie_view => $kenmerk->zaakinformatie_view,
                document_categorie => $kenmerk->document_categorie,
                description     => $kenmerk->description,
                help            => $kenmerk->help
            );

            if ($kenmerk->bibliotheek_kenmerken_id) {
                $kenmerkdata{bibliotheek_id}  = $kenmerk->bibliotheek_kenmerken_id->id,
                $kenmerkdata{naam}            = $kenmerk->bibliotheek_kenmerken_id->naam,
                $kenmerkdata{type}            = $kenmerk->bibliotheek_kenmerken_id->value_type,
            }

            $stata->{kenmerken}->{$count} = \%kenmerkdata;
        }

        ### Sjablonen
        my $sjablonen = $status->zaaktype_sjablonens->search(
            {},
            {
                order_by => [
                    { -asc => 'id' },
                ],
            }
        );
        $count = 0;
        while (my $sjabloon = $sjablonen->next) {
            $count++;
            my %sjabloondata = (
                id              => $sjabloon->id,
                bibliotheek_id  => $sjabloon->bibliotheek_sjablonen_id->id,
                naam            => $sjabloon->bibliotheek_sjablonen_id->naam,
                label           => $sjabloon->label,
                verplicht       => $sjabloon->mandatory,
                description     => $sjabloon->description,
                automatisch_genereren     => $sjabloon->automatisch_genereren,
                help            => $sjabloon->help
            );

            $stata->{sjablonen}->{$count} = \%sjabloondata;
        }

        ### Notificaties
        my $notificaties = $status->zaaktype_notificaties;
        $count = 0;
        while (my $notificatie = $notificaties->next) {
            $count++;
            my %notificatiedata = (
                id              => $notificatie->id,
                label           => $notificatie->label,
                rcpt            => $notificatie->rcpt,
                email           => $notificatie->email,
                onderwerp       => $notificatie->onderwerp,
                bericht         => $notificatie->bericht,
                intern_block    => $notificatie->intern_block
            );

            $stata->{notificaties}->{$count} = \%notificatiedata;
        }

        ### checklist
        my $checklistzaak = $self->c->model('DB::ChecklistZaak')->search(
            {
                'zaaktype_id' => $node->id,
            },
            {
                order_by => [
                    { -asc => 'id' },
                ],
            }
        );

        if ($checklistzaak->count == 1) {
            $checklistzaak  = $checklistzaak->first;
            my $checklist   = $checklistzaak->checklist_statuses->search(
                {
                    status  => $status->status,
                }
            );

            if ($checklist->count == 1) {
                $checklist      = $checklist->first;
                my $vragen      = $checklist->checklist_vraags;
                my $vrcount     = 0;
                while (my $vraag = $vragen->next) {
                    my $antwoorden = $vraag->checklist_mogelijkhedens;
                    my @answers;
                    while (my $antwoord = $antwoorden->next) {
                        push(@answers, $antwoord->label);
                    }

                    $stata->{checklist}->{++$vrcount} = {
                        'vraag'         => $vraag->vraag,
                        'antwoorden'    => {
                            'type'          => $vraag->vraagtype,
                            'mogelijkheden' => \@answers
                        }
                    };
                }
            }
        }

        ### Resultaten
        if ($stata->{type} eq 'afhandelen') {
            my $resultaten = $node->zaaktype_resultatens;

            if ($resultaten->count) {
                my $rescount = 0;
                while (my $resultaat = $resultaten->next) {
                    $stata->{resultaten}->{++$rescount} =
                        {
                            resultaat               => $resultaat->resultaat,
                            bewaartermijn           => $resultaat->bewaartermijn,
                            vtermijn                => $resultaat->vernietigingstermijn,
                            dossiertype             => $resultaat->dossiertype,
                            ingang                  => $resultaat->ingang,
                        };
                }
            }
        }

        $rv->{status}->{$status->status} = $stata;
    }

    ### Documenten
    my $documenten  = $node->zaaktype_ztc_documentens->search(
        {},
        {
            order_by => [
                { -asc => 'id' },
            ],
        }
    );
    my $doccount    = 0;
    my $curstatus   = 0;
    while (my $document = $documenten->next) {
        if ($curstatus ne $document->zaak_status_id->status) {
            $doccount = 0;
            $curstatus = $document->zaak_status_id->status;
        }
        ++$doccount;
        my $mandatory;
        if ($document->mandatory) {
            $mandatory = 'registratie';
        } elsif ($document->mandatory_end) {
            $mandatory = 'afhandelen';
        }

        my %docdata = (
            kenmerken   => {
                help        => $document->help,
                mandatory   => $mandatory,
                category    => $document->category,
                pip         => $document->pip,
            },
            name => $document->description,
        );

        ### Add to status
        if ($document->zaak_status_id && $document->zaak_status_id->status) {
            $rv->{status}->{$document->zaak_status_id->status}->{documenten}->{
                $doccount
            } = \%docdata;
        }
    }

    ### Betrokkenen
    my $betrokkenen  = $node->zaaktype_betrokkenens;
    if ($betrokkenen->count) {
        while (my $betrokkene = $betrokkenen->next) {
            $rv->{algemeen}->{type_aanvragers}->{$betrokkene->betrokkene_type} = 1,
        }
    }

    ### Authorisation
    my $autho  = $ztr->zaaktype_authorisations->search(
        {},
        {
            order_by => [
                { -asc => 'id' },
            ],
        }
    );
    my $roles       = {};
    while (my $auth = $autho->next) {
        if (!$roles->{$auth->ou_id . '-' . $auth->role_id}) {
            $roles->{$auth->ou_id . '-' . $auth->role_id} = {
                'ou_id'        => $auth->ou_id,
                'role_id'      => $auth->role_id,
                'rechten'   => {}
            };
        }
        $roles->{$auth->ou_id . '-' . $auth->role_id}->{rechten}->{
            $auth->recht
        } = 1;
    }


    my $authcount   = 0;
    for my $role (values %{ $roles }) {
        $rv->{auth}->{++$authcount} = $role;
    }

    return $rv;

}



sub create {
    my ($self, $args) = @_;
    my ($oldnode, $node, $zt);

    ### Depending on $args (OBJECT OR HASH, try to create this zaaktype, for
    ### now, simple way

    if ($args->{edit} && $self->c->session->{zaaktype_auth_only}) {
        ### Find old node
        $oldnode = $self->c->model('DB::ZaaktypeNode')->find(
            $args->{edit}
        );

        return unless $oldnode;

        $zt = $oldnode->zaaktype_id;

        ### Authorization
        $self->_create_auth($args, $zt);

        return 1;
    }

    ### Create row in zaaktype and zaaktype node
    ### Create node
    eval {
        $self->c->model('DB')->txn_do(sub {
            $self->c->log->debug('Creating zaaktype: - Node');
            $node = $self->c->model('DB::ZaaktypeNode')->create(
                {
                    code                    => $args->{algemeen}->{zt_code},
                    titel                   => $args->{algemeen}->{zt_naam},
                    zaaktype_categorie_id   => $args->{category},
                    trigger                 => $args->{algemeen}->{zt_trigger},
                    toelichting             => $args->{algemeen}->{zt_toelichting},
                    automatisch_behandelen  => $args->{algemeen}->{zt_automatisch_behandelen},
                    webform_toegang         => $args->{algemeen}->{zt_webform_toegang},
                    webform_authenticatie   => $args->{algemeen}->{zt_webform_authenticatie},
                    toewijzing_zaakintake   => $args->{algemeen}->{zt_toewijzing_zaakintake},
                    'adres_relatie'         => $args->{algemeen}->{zt_adres_relatie},
                    'aanvrager_hergebruik'  => $args->{algemeen}->{zt_hergebruik},
                    active  => 1,
                    version => 1,
                }
            );

            if ($args->{create}) {
                $self->c->log->debug('Creating zaaktype: - Zaaktype');
                ### Create zaaktype_quickinfo with version
                $zt = $self->c->model('DB::Zaaktype')->create(
                    {
                        version             => 1,
                        active              => 1,
                        zaaktype_categorie_id => $args->{category},
                        zaaktype_node_id    => $node->id,
                    }
                );
            } elsif ($args->{edit}) {
                ### Find old node
                $oldnode = $self->c->model('DB::ZaaktypeNode')->find(
                    $args->{edit}
                );

                return unless $oldnode;

                $zt = $oldnode->zaaktype_id;
            };

            ### Make sure, we always link a node to zaaktype
            $node->zaaktype_id($zt);

            ### Push this node into the other create functions
            $args->{node} = $node;

            $self->c->log->debug('Creating zaaktype: - RT');
            my $queuename   = $args->{node}->id . '-'
                    . $args->{node}->zaaktype_id->id . '-'
                    . $args->{algemeen}->{zt_naam};
            $args->{rt_queue_name} = $queuename;
            $node->zaaktype_rt_queue($queuename);
            $node->version($zt->version + 1);

            $node->update;

            $self->c->log->debug('Creating zaaktype: - algemene data');
            ### First page
            $self->_create_algemeen ($args);
            #$self->_create_documents($args);

            ### Third: Status
            $self->c->log->debug('Creating zaaktype: - statusdata');
            $self->_create_status($args);

            $self->c->log->debug('Creating zaaktype: - specifieke data');
            ### Second: Kenmerken
            $self->_create_specifiek($args);

            $self->c->log->debug('Creating zaaktype: - procesdata');
            ### Last: place procesdocument in files dir
            $self->_copy_procesdocument($args);

            $self->c->log->debug('Creating zaaktype: - authdata');
            ### Authorization
            $self->_create_auth($args, $zt);

            $self->c->log->debug('Creating zaaktype: - rt queeu');
            ### On complete, generate this version in RT3
            $self->_create_rt3      ($args);

            $self->c->log->debug('Creating zaaktype: - update version');
            ### Success, bump version
            if ($args->{edit}) {
                $zt->zaaktype_node_id($node->id);
                $zt->version($zt->version + 1);
                $zt->update;

                $oldnode->deleted(DateTime->now);
                $oldnode->update;
            }
        });
    };

    if ($@) {
        my $errormsg = 'ZT->create. Create error: ' . $@;

        $self->c->log->error($errormsg);
        $self->c->flash->{result} = 
            'Er was een probleem bij het invoeren van dit zaaktype, '
            .' neem contact op met zaaksysteem-beheer voor meer informatie';

        return;
    }

    return $self->retrieve(
        id  => $zt->id
    );
}

my $ZAAKTYPE_ALGEMEEN = {
    'ztc_iv3_categorie'       => 'text',
    'ztc_grondslag'           => 'text',
    'ztc_handelingsinitiator' => 'text',
    'ztc_selectielijst'       => 'text',
    'ztc_afhandeltermijn'     => 'text',
    'ztc_afhandeltermijn_type' => 'text',
    'ztc_servicenorm'         => 'text',
    'ztc_servicenorm_type'    => 'text',
    'ztc_escalatiegeel'       => 'text',
    'ztc_escalatieoranje'     => 'text',
    'ztc_escalatierood'       => 'text',
    'ztc_besluittype'         => 'text',
    'ztc_openbaarheid'        => 'text',
    'ztc_webform_toegang'     => 'text',
    'ztc_webform_authenticatie' => 'text',
    'pdc_meenemen'            => 'text',
    'pdc_description'         => 'text',
    'pdc_voorwaarden'         => 'text',
    'pdc_tarief'              => 'text',
    'ztc_procesbeschrijving'  => 'text',
};

sub _create_algemeen {
    my ($self, $args) = @_;

    my $opts = $args->{algemeen};
    ### Some verifications

    ### Createn maar
    for my $key (keys %{ $ZAAKTYPE_ALGEMEEN }) {
        my $ztc     = $self->c->model('DB::ZaaktypeAttributen')->create(
            {
                zaaktype_node_id    => $args->{node}->id,
                attribute_type      => 'ztc',
                key                 => $key,
                value_type          => $ZAAKTYPE_ALGEMEEN->{ $key }
            }
        );

        ### Create values
        my $ztcv    = $self->c->model('DB::ZaaktypeValues')->create(
            {
                zaaktype_node_id        => $args->{node}->id,
                zaaktype_attributen_id  => $ztc->id,
                value                   => $opts->{ $key },
            }
        );
    }

    ### Aanvragers
    if (
        $opts->{type_aanvragers} &&
        UNIVERSAL::isa($opts->{type_aanvragers}, 'HASH') &&
        %{ $opts->{type_aanvragers} }
    ) {
        for my $aanvrager (keys %{ $opts->{type_aanvragers} }) {
            my $ztcv    = $self->c->model('DB::ZaaktypeBetrokkenen')->create(
                {
                    zaaktype_node_id        => $args->{node}->id,
                    betrokkene_type         => $aanvrager,
                }
            );
        }
    }
}

my $SPECIFIEK_OPTION_MAP = {
    'dropdown'  => 1,
    'checkbox'  => 1,
};

sub _create_specifiek {
    my ($self, $args) = @_;

    my $opts = $args->{specifiek};
    ### Some verifications

    ### Sorting
    my @sorted_keys = sort { $a <=> $b } keys %{
        $opts
    };

    for my $skey (@sorted_keys) {
        my $kenmerk = $opts->{$skey};

        ### Convert key to something readable
        my $key = lc($kenmerk->{naam});
        $key    =~ s/ /_/g;

        ### Verify document key
        if ($kenmerk->{document_key}) {
            $self->c->log->debug('Has document key:' . $key);

            my $cdocs = $args->{node}->zaaktype_ztc_documentens->search({
                'description' => $kenmerk->{document_key}
            });

            if ($cdocs->count) {
                $self->c->log->debug('Has document key FOUND');
                my $cdoc = $cdocs->first;

                ### Overwrite label
                $key = lc($cdoc->description);
                $key =~ s/ /_/g;
                if ($cdoc->mandatory) {
                    $kenmerk->{verplicht} = 'registratie';
                    $self->c->log->debug('Has document key MANDATORY');
                } else {
                    $kenmerk->{verplicht} = undef;
                }
            }
        }

        my $ztc     = $self->c->model('DB::ZaaktypeAttributen')->create(
            {
                zaaktype_node_id    => $args->{node}->id,
                attribute_type      => 'spec',
                key                 => lc($key),
                betrokkene_trigger  => $kenmerk->{betrokkene_trigger},
                value               => $kenmerk->{vraag},
                value_type          => $kenmerk->{type},
                value_mandatory     =>
                    (
                        ($kenmerk->{verplicht} eq 'registratie')
                            ? 1
                            : undef
                    ),
                value_mandatory_end     =>
                    (
                        ($kenmerk->{verplicht} eq 'afhandelen')
                            ? 1
                            : undef
                    ),
                label               => $kenmerk->{naam},
                help                => $kenmerk->{help},
                document_key        => $kenmerk->{document_key},
            }
        );

        if (
            $kenmerk->{options} &&
            UNIVERSAL::isa($kenmerk->{options}, 'ARRAY') &&
            ZAAKSYSTEEM_CONSTANTS->{veld_opties}->{
                $kenmerk->{type}
            }->{'multiple'}
        ) {
            for my $option (@{ $kenmerk->{options} }) {
                ### Create values
                my $ztcv    = $self->c->model('DB::ZaaktypeValues')->create(
                    {
                        zaaktype_node_id        => $args->{node}->id,
                        zaaktype_attributen_id  => $ztc->id,
                        value                   => $option,
                    }
                );
            }
        }
    }
}

sub _create_rt3 {
    my ($self, $args) = @_;

    $self->_create_rt3_queue    ($args);
    $self->_create_rt3_cf       ($args);
}

sub _create_rt3_queue {
    my ($self, $args) = @_;

    my $rtq         = $self->c->model('RT')->create_object('RT::Queue');

    $rtq->Create(
        'Name'          => $args->{rt_queue_name},
        'Description'   => $args->{node}->zaaktype_id->version . '-'
                    . $args->{algemeen}->{zt_naam},
        'DefaultDueIn'  => ($args->{algemeen}->{ztc_afhandeltermijn} * 7),
    );

    $args->{rtq} = $rtq;

    $self->c->log->info('RT Queue: ' . $args->{rt_queue_name} . ' created');
}

my $RT_CUSTOMCF_MAP = {
    'text'          => 'Freeform-1',
    'textarea'      => 'Freeform-1',
    'select'        => 'Freeform-1',
    'option'        => 'Freeform-1',
};

sub _create_rt3_cf {
    my ($self, $args) = @_;

    ### Get zaaktype_attributen
    my $attributen  = $args->{node}->zaaktype_attributens->search(
        {
            attribute_type  => 'spec'
        }
    );

    while (my $attribute = $attributen->next) {
        my $key = 'ztcs_' . $attribute->key;

        #$self->c->log->debug('Working on attr ' . $key);

        my $rtcf        = $self->c->model('RT')->create_object('RT::CustomField');
        my $rtcftype    = ZAAKSYSTEEM_CONSTANTS->{veld_opties}->{
            $attribute->value_type
        }->{'rt'};

        my $rtcfdescr   = $attribute->label || $key;

        $rtcf->Create(
            'Name'          => lc($key),
            'TypeComposite' => $rtcftype,
            'Description'   => $rtcfdescr,
            'LookupType'    => 'RT::Queue-RT::Ticket',
            'ObjectType'    => 'RT::Queue',
        );

        my ($ok, $msg) = $rtcf->AddToObject($args->{rtq});
    }

    #### XXX NEW STYLE
    my $kenmerken = $args->{node}->zaaktype_kenmerkens;

    while (my $kenmerk = $kenmerken->next) {
        my $kenmerkdb   = $kenmerk->bibliotheek_kenmerken_id;
        my $rtcf        = $self->c->model('RT')->create_object('RT::CustomField');
        my $rtcftype    = ZAAKSYSTEEM_CONSTANTS->{veld_opties}->{
            $kenmerkdb->value_type
        }->{'rt'};

        my ($bynameok)  = $rtcf->Load('kenmerk_id_' . $kenmerkdb->id);
        $self->c->log->debug('Load by id result: ' . $bynameok);

        if (!$bynameok) {
            $rtcf->Create(
                'Name'          => 'kenmerk_id_' . $kenmerkdb->id,
                'TypeComposite' => $rtcftype,
                'Description'   => $kenmerkdb->label,
                'LookupType'    => 'RT::Queue-RT::Ticket',
                'ObjectType'    => 'RT::Queue',
            );
        }

        my ($ok, $msg) = $rtcf->AddToObject($args->{rtq});
    }
}

sub _create_documents {
    my ($self, $args) = @_;

    return 1 unless (
        $args->{algemeen}->{documenten} &&
        UNIVERSAL::isa($args->{algemeen}->{documenten}, 'HASH')
    );

    my $opts = $args->{algemeen}->{documenten};

    ### Sorting
    my @sorted_keys = sort { $a <=> $b } keys %{
        $opts
    };

    for my $key (@sorted_keys) {
        my $document = $opts->{$key};

        $self->c->model('DB::ZaaktypeZtcDocumenten')->create(
            {
                zaaktype_node_id    => $args->{node}->id,
                mandatory           =>
                    (
                        $document->{kenmerken}->{mandatory}
                            ? 1
                            : undef
                    ),
                pip                 =>
                    (
                        $document->{kenmerken}->{pip}
                            ? 1
                            : undef
                    ),
                category            => $document->{kenmerken}->{category},
                description         => $document->{description},
                help                => $document->{kenmerken}->{help},
                active              => 1,
            }
        );
    }
}

sub _create_auth {
    my ($self, $args, $zt) = @_;

    return 1 unless (
        $args->{auth} &&
        UNIVERSAL::isa($args->{auth}, 'HASH')
    );

    my $opts = $args->{auth};

    ### Sorting
    my @sorted_keys = sort { $a <=> $b } keys %{
        $opts
    };

    ### Delete old rights
    my $old_rights = $self->c->model('DB::ZaaktypeAuthorisation')->search({
        'zaaktype_id'   => $zt->id
    });

    $old_rights->delete;

    for my $key (@sorted_keys) {
        my $group = $opts->{$key};

        for my $recht (keys %{ $group->{rechten} }) {
            $self->c->model('DB::ZaaktypeAuthorisation')->create(
                {
                    zaaktype_id         => $zt->id,
                    ou_id               => $group->{ou_id},
                    role_id             => $group->{role_id},
                    recht               => $recht
                }
            );
        }
    }
}

sub _create_status {
    my ($self, $args) = @_;

    ### Comprehensive section, will create statussen and checklists
    return 1 unless (
        $args->{status} &&
        UNIVERSAL::isa($args->{status}, 'HASH') &&
        %{ $args->{status} }
    );

    my $opts = $args->{status};

    while (my ($statusnr, $statusdata) = each %{ $opts }) {
        ### Create status in database
        $self->c->log->debug('Creating zaaktype / status: - create');
        my $status = $self->c->model('DB::ZaaktypeStatus')->create(
            {
                zaaktype_node_id    => $args->{node}->id,
                status              => $statusnr,
                status_type         => $statusdata->{type},
                naam                => $statusdata->{naam},
                afhandeltijd        => $statusdata->{afhandeltijd} || 0,
                ou_id               => $statusdata->{ou_id},
                role_id             => $statusdata->{role_id},
                mail_subject        => $statusdata->{mail}->{onderwerp},
                mail_message        => $statusdata->{mail}->{message},
                checklist           => $statusdata->{has_checklist},
            }
        );

        ### Status created, mark documents to status
#        for my $docdata (values %{ $statusdata->{documenten} }) {
#            ### Search for document
#            my $documents = $args->{node}->zaaktype_ztc_documentens->search(
#                {
#                    'description'   => $docdata->{name}
#                }
#            );
#
#            if ($documents->count) {
#                my $document = $documents->first;
#
#                $document->zaak_status_id($status->id);
#
#                $document->update;
#            }
#        }

        $self->c->log->debug('Creating zaaktype / status: - checklist');
        ### Create necessary checklist
        $self->_create_checklist($args, $statusdata, $status);

        $self->c->log->debug('Creating zaaktype / status: - subzaken');
        ### Forth: Subzaken
        $self->_create_subzaken($args, $statusdata, $status);

        $self->c->log->debug('Creating zaaktype / status: - docs');
        ### Fifth: Documenten
        $self->_create_documenten($args, $statusdata, $status);

        $self->c->log->debug('Creating zaaktype / status: - kenmerken');
        ### Sixth: Kenmerken
        $self->_create_kenmerken($args, $statusdata, $status);

        $self->c->log->debug('Creating zaaktype / status: - sjablonen');
        ### Sevenh: Sjablonen
        $self->_create_sjablonen($args, $statusdata, $status);

        $self->c->log->debug('Creating zaaktype / status: - notificaties');
        ### Sevenh: Sjablonen
        $self->_create_notificaties($args, $statusdata, $status);

#        $self->c->log->debug('Creating zaaktype / status: - regels');
#        $self->_create_regels($args, $statusdata, $status);


        ### Aanvragers
        $self->c->log->debug('Creating zaaktype / status: - resultaten');
        for my $resultaat (values %{ $statusdata->{resultaten} }) {
            my $resv    = $self->c->model('DB::ZaaktypeResultaten')->create(
                {
                    zaaktype_node_id        => $args->{node}->id,
                    zaaktype_status_id      => $status->id,
                    resultaat               => $resultaat->{resultaat},
                    bewaartermijn           => $resultaat->{bewaartermijn},
                    vernietigingstermijn    => $resultaat->{vtermijn},
                    dossiertype             => $resultaat->{dossiertype},
                    ingang                  => $resultaat->{ingang},
                }
            );
        }
    }

}

sub _create_kenmerken {
    my ($self, $args, $statusdata, $status) = @_;

    my $opts = $statusdata->{kenmerken};

    return unless (UNIVERSAL::isa($opts, 'HASH'));

    ### Sorting
    my @sorted_keys = sort { $a <=> $b } keys %{
        $opts
    };

    for my $key (@sorted_keys) {
        my $kenmerk = $opts->{$key};
            #while (my ($count, $document) = each %{ $opts }) {

        $self->c->log->debug('Creating zaaktype / status / kenmerk: - ' . $key);
        my $kenmerkdb = $self->c->model('DB::ZaaktypeKenmerken')->create(
            {
                zaaktype_node_id            => $args->{node}->id,
                bibliotheek_kenmerken_id    => $kenmerk->{id},
                label                       => $kenmerk->{label} || undef,
                value_mandatory             => $kenmerk->{verplicht} || undef,
                description                 => $kenmerk->{description} || undef,
                help                        => $kenmerk->{help} || undef,
                pip                         => $kenmerk->{pip} || undef,
                zaakinformatie_view         => $kenmerk->{zaakinformatie_view} || undef,
                document_categorie          => $kenmerk->{document_categorie} || undef,
                zaak_status_id              => $status->id,
            }
        );
    }

    return 1;

}

sub _create_sjablonen {
    my ($self, $args, $statusdata, $status) = @_;

    my $opts = $statusdata->{sjablonen};

    return unless (UNIVERSAL::isa($opts, 'HASH'));

    ### Sorting
    my @sorted_keys = sort { $a <=> $b } keys %{
        $opts
    };

    for my $key (@sorted_keys) {
        my $sjabloon = $opts->{$key};
            #while (my ($count, $document) = each %{ $opts }) {

        my $sjabloondb = $self->c->model('DB::ZaaktypeSjablonen')->create(
            {
                zaaktype_node_id            => $args->{node}->id,
                bibliotheek_sjablonen_id    => $sjabloon->{id},
                label                       => $sjabloon->{label} || undef,
                mandatory                   => $sjabloon->{verplicht} || undef,
                description                 => $sjabloon->{description} || undef,
                help                        => $sjabloon->{help} || undef,
                zaak_status_id              => $status->id,
                automatisch_genereren       => $sjabloon->{automatisch_genereren}
            }
        );
    }

    return 1;

}

sub _create_notificaties {
    my ($self, $args, $statusdata, $status) = @_;

    my $opts = $statusdata->{notificaties};

    return unless (UNIVERSAL::isa($opts, 'HASH'));

    ### Sorting
    my @sorted_keys = sort { $a <=> $b } keys %{
        $opts
    };

    for my $key (@sorted_keys) {
        my $notificatie = $opts->{$key};
            #while (my ($count, $document) = each %{ $opts }) {

        my $notificatiedb = $self->c->model('DB::ZaaktypeNotificatie')->create(
            {
                zaaktype_node_id            => $args->{node}->id,
                zaak_status_id              => $status->id,
                label                       => $notificatie->{label} || undef,
                rcpt                        => $notificatie->{rcpt} || undef,
                email                       => $notificatie->{email} || undef,
                onderwerp                   => $notificatie->{onderwerp} || undef,
                bericht                     => $notificatie->{bericht} || undef,
                intern_block                => $notificatie->{intern_block} || undef,
            }
        );
    }

    return 1;

}

sub _create_regels {
    my ($self, $args, $statusdata, $status) = @_;

    my $opts = $statusdata->{regels};

    return unless (UNIVERSAL::isa($opts, 'HASH'));

    ### Sorting
    my @sorted_keys = sort { $a <=> $b } keys %{
        $opts
    };

    for my $key (@sorted_keys) {
        my $regel = $opts->{$key};
            #while (my ($count, $document) = each %{ $opts }) {

        $self->c->log->debug('Regel: ' . Dumper $regel);
        my $regeldb = $self->c->model('DB::ZaaktypeRegel')->create(
            {
                zaaktype_node_id            => $args->{node}->id,
                zaak_status_id              => $status->id,
                settings                    => $regel->{settings} || undef,
            }
        );
    }

    return 1;

}

sub _create_checklist {
    my ($self, $args, $statusdata, $status) = @_;

    my $opts = $statusdata->{checklist};

    ### First check, did we already create a checklist for this zaaktype?
    my $czs = $self->c->model('DB::ChecklistZaak')->search({
        'zaaktype_id'   => $args->{node}->id,
    });

    my ($cz);
    if (!$czs->count) {
        ### Create checklist
        $cz = $self->c->model('DB::ChecklistZaak')->create({
                zaaktype_id => $args->{node}->id,
            }
        );
    } else {
        $cz = $czs->first;
    }

    ### Create checklist status
    my $cs = $self->c->model('DB::ChecklistStatus')->create(
        {
            checklist_id    => $cz->id,
            status          => $status->status,
        }
    );


    ### Sorting
    my @sorted_keys = sort { $a <=> $b } keys %{
        $opts
    };

    for my $key (@sorted_keys) {
        my $question = $opts->{$key};
        #while (my ($qnr, $question) = each %{ $opts }) {
        ### Create checklist questions
        my $cv = $self->c->model('DB::ChecklistVraag')->create(
            {
                status_id   => $cs->id,
                nr          => $key,
                vraag       => $question->{vraag},
                vraagtype   => $question->{antwoord}->{type},
            }
        );

        my @answers;
        if ($question->{antwoord}->{type} ne 'yesno') {
            @answers = split(/\n/, $question->{antwoord}->{mogelijkheden});
        } else {
            @answers = ('Ja','Nee');
        }

        for my $answer (@answers) {
            my $cva = $self->c->model('DB::ChecklistMogelijkheden')->create(
                {
                    vraag_id            => $cv->id,
                    mogelijkheid_type   => $cv->vraagtype,
                    label               => $answer,
                }
            );
        }
    }
}

sub _create_documenten {
    my ($self, $args, $statusdata, $status) = @_;

    my $opts = $statusdata->{documenten};

    ### Sorting
    my @sorted_keys = sort { $a <=> $b } keys %{
        $opts
    };

    for my $key (@sorted_keys) {
        my $document = $opts->{$key};
            #while (my ($count, $document) = each %{ $opts }) {
        $self->c->model('DB::ZaaktypeZtcDocumenten')->create(
            {
                zaaktype_node_id    => $args->{node}->id,
                mandatory           =>
                    (
                        (
                            $document->{kenmerken}->{mandatory} eq
                                'registratie'
                        )
                            ? 1
                            : undef
                    ),
                mandatory_end       =>
                    (
                        (
                            $document->{kenmerken}->{mandatory} eq
                                'afhandelen'
                        )
                            ? 1
                            : undef
                    ),
                pip                 =>
                    (
                        $document->{kenmerken}->{pip}
                            ? 1
                            : undef
                    ),
                category            => $document->{kenmerken}->{category},
                description         => $document->{name},
                help                => $document->{kenmerken}->{help},
                active              => 1,
                zaak_status_id      => $status->id,
            }
        );
    }

    return 1;
}

sub _create_subzaken {
    my ($self, $args, $statusdata, $status) = @_;

    my $opts = $statusdata->{subzaken};

    ### Create relatie
    while (my ($count, $zaaktype) = each %{ $opts }) {
        my %create_args = (
            zaaktype_node_id        => $args->{node}->id,
            relatie_zaaktype_id     => $zaaktype->{zaaktype_id},
            relatie_type            => (
                $zaaktype->{deelzaak}
                    ? 'deelzaak'
                    : 'gerelateerd'
            ),
            zaaktype_status_id      => $status->id,
            mandatory               => (
                $zaaktype->{mandatory}
                    ? 1
                    : undef
            ),
            eigenaar_type           => $zaaktype->{eigenaar_type},
            kopieren_kenmerken      => $zaaktype->{kopieren_kenmerken},
            status                  => $zaaktype->{status},
            start_delay             => $zaaktype->{start_delay},
        );

        $self->c->model('DB::ZaaktypeRelatie')->create(
            \%create_args
        );
    }

    return 1;
}

sub _copy_procesdocument {
    my ($self, $args) = @_;

    return 1 unless $args->{proces_tempname};

    my $files_dir = $self->c->config->{root} . '/public/files/';

    if (
        File::Copy::copy(
            $args->{proces_tempname},
            $files_dir . $args->{node}->zaaktype_id->id . '_proces.pdf'
        )
    ) {
        $self->c->log->info('Copied procesdocumentation to correct dir');
        unlink($args->{proces_tempname});
        return 1;
    }

    $self->c->log->info(
        'Error copiing procesdocumentation: '
        . $!
        . '[' . $args->{proces_tempname} . ']'
    );

    return;

}


sub ACCEPT_CONTEXT {
    my ($self, $c) = @_;

    $self->{c} = $c;
    Scalar::Util::weaken($self->{c});

    return $self;
}

#sub _create_specifiek {
#    my ($self, $args) = @_;

#    my $opts = $args->{specifiek};
    ### Some verifications



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

