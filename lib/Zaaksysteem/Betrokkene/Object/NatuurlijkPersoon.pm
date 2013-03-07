package Zaaksysteem::Betrokkene::Object::NatuurlijkPersoon;

use strict;
use warnings;
use Data::Dumper;
use Moose;

use constant BOBJECT    => 'Zaaksysteem::Betrokkene::Object';
use constant BRSOBJECT  => 'Zaaksysteem::Betrokkene::ResultSet';

extends BOBJECT;

my $CLONE_MAP = [qw/
    burgerservicenummer
    a_nummer
    voornamen
    geslachtsnaam
    voorvoegsel
    geslachtsaanduiding
    geboortegemeente
    geboorteplaats
    geboortegemeente_omschrijving
    geboorteregio
    geboorteland
    geboortedatum
    aanhef_aanschrijving
    voorletters_aanschrijving
    voornamen_aanschrijving
    naam_aanschrijving
    voorvoegsel_aanschrijving
    burgerlijke_staat
    indicatie_gezag
    indicatie_curatele
    indicatie_geheim
    authenticatedby
    import_datum
    verblijfsobject_id
    datum_overlijden

    aanduiding_naamgebruik

    partner_voorvoegsel
    partner_geslachtsnaam
    partner_burgerservicenummer

/ ];

my $CONTACT_MAP = {
    telefoonnummer  => 1,
    mobiel          => 1,
    email           => 1,
};

my $ADRES_CLONE_MAP = [qw/
    straatnaam
    huisnummer
    woonplaats
    postcode
    huisletter
    huisnummertoevoeging
    functie_adres
/];

my $SEARCH_MAP = {
    'burgerservicenummer' => 'natuurlijk_persoons.burgerservicenummer',
    'a_nummer' => 'natuurlijk_persoons.a_nummer',
    'voornamen' => 'natuurlijk_persoons.voornamen',
    'geslachtsnaam' => 'natuurlijk_persoons.geslachtsnaam',
    'voorvoegsel' => 'natuurlijk_persoons.voorvoegsel',
    'geslachtsaanduiding' => 'natuurlijk_persoons.geslachtsaanduiding',
    'geboortegemeente' => 'natuurlijk_persoons.geboortegemeente',
    'geboorteplaats' => 'natuurlijk_persoons.geboorteplaats',
    'geboortegemeente_omschrijving' => 'natuurlijk_persoons.geboortegemeente_omschrijving',
    'geboorteregio' => 'natuurlijk_persoons.geboorteregio',
    'geboorteland' => 'natuurlijk_persoons.geboorteland',
    'geboortedatum' => 'natuurlijk_persoons.geboortedatum',
    'aanhef_aanschrijving' => 'natuurlijk_persoons.aanhef_aanschrijving',
    'voorletters_aanschrijving' => 'natuurlijk_persoons.voorletters_aanschrijving',
    'voornamen_aanschrijving' => 'natuurlijk_persoons.voornamen_aanschrijving',
    'naam_aanschrijving' => 'natuurlijk_persoons.naam_aanschrijving',
    'voorvoegsel_aanschrijving' => 'natuurlijk_persoons.voorvoegsel_aanschrijving',
    'burgerlijke_staat' => 'natuurlijk_persoons.burgerlijke_staat',
    'indicatie_gezag' => 'natuurlijk_persoons.indicatie_gezag',
    'indicatie_curatele' => 'natuurlijk_persoons.indicatie_curatele',
    'indicatie_geheim' => 'natuurlijk_persoons.indicatie_geheim',
    'straatnaam'    => 'straatnaam',
    'huisnummer' => 'huisnummer',
    'woonplaats' => 'woonplaats',
    'postcode' => 'postcode',
    'huisletter' => 'huisletter',
    'huisnummertoevoeging' => 'huisnummertoevoeging',
    'datum_overlijden' => 'natuurlijk_persoons.datum_overlijden',
};

### Doorverwijzigingen
#for my $sub (qw/in_onderzoek/) {
#    *{; no strict 'refs'; \*$sub} = sub {
#        my $self        = shift;
#
#        return $self->gm_extern_np->$sub(@_);
#    };
#}

has 'in_onderzoek'  => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $self        = shift;

        return $self->gm_extern_np->in_onderzoek(@_);
    }
);

has 'is_briefadres'  => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $self        = shift;

        if (uc($self->functie_adres) eq 'B') {
            return 1;
        }
    }
);


has 'gm_adres'  => (
    'is'    => 'rw',
);

has 'gm_np'     => (
    'is'    => 'rw',
);

has 'gm_extern_np'     => (
    'is'    => 'rw',
);

has 'is_overleden' => (
    'is'    => 'rw',
    'lazy'  => 1,
    'default'   => sub {
        my ($self) = @_;

        return $self->gm_extern_np->is_overleden(@_);
    }
);

has 'gmid'      => (
    'is'    => 'rw',
);

has 'intern'    => (
    'is'    => 'rw',
);

has 'in_zaaksysteem'    => (
    'is'    => 'rw',
);

### Convenience method containing some sort of display_name
### Ai, this one is different from the one we punt in the database as
### display_name. We create a new method display_name to get it even
has 'naam' => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        ### Depends on aanduiding naamgebruik.
        return $self->voorletters . ' '
            . (
                $self->voorvoegsel
                    ? $self->voorvoegsel . ' '
                    : ''
            )
            . $self->geslachtsnaam;
    },
);

### Make sure this is the same as regel 10000.
has 'display_name' => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        ### Depends on aanduiding naamgebruik.
        return $self->voornamen . ' ' . (
                $self->voorvoegsel
                    ? $self->voorvoegsel . ' '
                    : ''
            ) . $self->geslachtsnaam,
    },
);

has 'geslacht'      => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        return 'man' if uc($self->geslachtsaanduiding) eq 'M';
        return 'vrouw' if uc($self->geslachtsaanduiding) eq 'V';

        return;
    }
);

has 'aanhef'      => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        return 'meneer' if uc($self->geslachtsaanduiding) eq 'M';
        return 'mevrouw' if uc($self->geslachtsaanduiding) eq 'V';

        return;
    }
);

has 'aanhef1'      => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        return 'heer' if uc($self->geslachtsaanduiding) eq 'M';
        return 'mevrouw' if uc($self->geslachtsaanduiding) eq 'V';

        return;
    }
);

has 'aanhef2'      => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        return 'de heer' if uc($self->geslachtsaanduiding) eq 'M';
        return 'mevrouw' if uc($self->geslachtsaanduiding) eq 'V';

        return;
    }
);

has 'volledige_naam' => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        ### Depends on aanduiding naamgebruik.
        return $self->voorletters . ' '
            . $self->achternaam;
    },
);

has 'achternaam'  => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        my $aand = uc($self->aanduiding_naamgebruik);

        if ($aand eq 'P') {
            return
                (
                    $self->partner_voorvoegsel
                        ? $self->partner_voorvoegsel . ' '
                        : ''
                )
                . $self->partner_geslachtsnaam;
        } elsif ($aand eq 'V') {
            return
                (
                    $self->partner_voorvoegsel
                        ? $self->partner_voorvoegsel . ' '
                        : ''
                )
                . $self->partner_geslachtsnaam
                . '-'
                . (
                    $self->voorvoegsel
                        ? $self->voorvoegsel . ' '
                        : ''
                )
                . $self->geslachtsnaam
        } elsif ($aand eq 'N') {
            return
                (
                    $self->voorvoegsel
                        ? $self->voorvoegsel . ' '
                        : ''
                )
                . $self->geslachtsnaam
                . '-'
                . (
                    $self->partner_voorvoegsel
                        ? $self->partner_voorvoegsel . ' '
                        : ''
                )
                . $self->partner_geslachtsnaam
        } else {
            return
                (
                    $self->voorvoegsel
                        ? $self->voorvoegsel . ' '
                        : ''
                )
                . $self->geslachtsnaam
        }
    }
);

has 'volledig_huisnummer'   => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;
        return $self->huisnummer
            . (
                $self->huisletter
                    ? ' ' . $self->huisletter
                    : ''
            ) . (
                $self->huisnummertoevoeging
                    ? ' - ' . $self->huisnummertoevoeging
                    : ''
            ) if $self;
    }
);

has 'voorletters'   => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        my ($firstchar) = $self->voornamen =~ /^(\w{1})/;
        my @other_chars = $self->voornamen =~ / (\w{1})/g;

        return join(". ", $firstchar, @other_chars) . (
            ($firstchar || @other_chars) ?
            '.' : ''
        );
    },
);

has 'can_verwijderen'   => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return 1 unless $self->gm_extern_np->authenticated;

        return;
    },
);


#sub search {
#    my $self    = shift;
#    my $searchr = shift;
#
#    my ($search);
#
#    for my $key (keys %{ $searchr }) {
#        my $searchkey = $key;
#        if ($key =~ /^gm-/) {
#            $key =~ s/^gm-//;
#
#            $search->{'natuurlijk_persoons.' . $key} = $searchr->{$searchkey};
#        } elsif ($key =~ /^adres-/) {
#            $key =~ s/^adres-//;
#
#            $search->{$key} = $searchr->{$searchkey};
#        }
#    }
#
#    ### Replace gm with tablename, adres with tablename
#    $self->log->debug('Searching for NP, credentials: ' .
#        Dumper($search)
#    );
#
#
#    return $self->c->model('DBG::Adres')->search(
#        $search,
#        {
#            'join'  => 'natuurlijk_persoons',
#        }
#    );
#}


my $ORDER_MAP = {
    'geslachtsnaam'     => 'geslachtsnaam',
    'voornamen'         => 'voornamen',
    'voorvoegsel'       => 'voorvoegsel',
    'bsn'               => 'burgerservicenummer',
    'geboortedatum'     => 'geboortedatum',
    'straatnaam'        => 'straatnaam',
    'huisnummer'        => 'huisnummer',
    'authenticated'     => 'authenticated',
};
my $ORDER_DIR = {
    'ASC'       => 'asc',
    'DESC'      => 'desc',
};
sub search {
    my $self        = shift;
    my $dispatch_options = shift;
    my $opts        = shift;
    my ($searchr)   = @_;
    my ($roworder, $roworderdir);

    ### We will return a resultset layer over DBIx::Class containing
    ### data, we will use to populate this class. That's why we cannot
    ### be called when we are the object itself. Should be a future
    ### feature
    die('M::B::NP->search() only possible call = class based')
        unless !ref($self);

    return unless defined($opts->{'intern'});


    ### SOME NOT complicated ORDERING
    if (
        $dispatch_options->{stash}->{order} &&
        defined($ORDER_MAP->{ $dispatch_options->{stash}->{order} })

    ) {
        $roworder = $ORDER_MAP->{ $dispatch_options->{stash}->{order} };
    } else {
        $roworder = 'geslachtsnaam';
    }

    if (
        $dispatch_options->{stash}->{order_direction} &&
        defined($ORDER_DIR->{ $dispatch_options->{stash}->{order_direction} })
    ) {
        $roworderdir = $ORDER_DIR->{ $dispatch_options->{stash}->{order_direction} };
    } else {
        $roworderdir = 'asc'
    }

    ### Ok, we got the information we need, now we have to search the
    ### database GM or our internal version, but first, define some variables
    ### with our variable map.
    my $search = {};
    for (keys %{ $SEARCH_MAP }) {
        next unless defined($searchr->{ $_ });

        if ($_ eq 'geboortedatum') {
            $search->{$SEARCH_MAP->{ $_ }} = $searchr->{ $_ };
        } elsif ($_ eq 'huisnummer') {
            $search->{$SEARCH_MAP->{ $_ }} = $searchr->{ $_ };
        } elsif ($_ eq 'burgerservicenummer') {
            $search->{$SEARCH_MAP->{ $_ }} = $searchr->{ $_ };
        } elsif ($_ eq 'postcode') {
            ## XXX POSTCODE, Uppercase without spaces
            my $postcode = $searchr->{ $_ };
            $postcode = uc($postcode);
            $postcode =~ s/\s*//g;
            $search->{$SEARCH_MAP->{ $_ }} = {
                'like' => '%' . $postcode . '%'
            };
        } elsif (!$searchr->{'EXACT'}) {
            $search->{ 'lower(' . $SEARCH_MAP->{ $_ } . ')' }
                = {'like' => '%' . lc($searchr->{ $_ }) . '%'};
        } else {
            $search->{ $SEARCH_MAP->{ $_ } }
                = $searchr->{ $_ };
        }
    }

    ### Define correct db
    ### TODO: Constants would be fine
    my ($model);
    if ($opts->{intern}) {
        $model = 'DB::GmAdres';
    } else {
        $model = 'DBG::Adres';
        $search->{'natuurlijk_persoons.deleted_on'} = undef;
    }

    ### Paging
    my $rowlimit = $dispatch_options->{stash}->{paging_rows} =
        $dispatch_options->{stash}->{paging_rows} || 40;
    my $rowpage = $dispatch_options->{stash}->{paging_page} =
        $dispatch_options->{stash}->{paging_page} || 1;

    if($opts->{rows_per_page}) {
        $rowlimit = $opts->{rows_per_page};
    }
    ### Ask internal or external model about this search
    my @dbopts = (
        #['lower(natuurlijk_persoons.geslachtsnaam)', qw/kip/ ],
        $search,
        {
            'join'      => 'natuurlijk_persoons',
            'page'      => $rowpage,
            'rows'      => $rowlimit,
            'order_by'  => { '-' . $roworderdir => $roworder }
        }

    );
    my $resultset;
    if ($opts->{intern}) {
        $resultset = $dispatch_options->{dbic}->resultset('GmAdres')->search(@dbopts);
    } else {
        $resultset = $dispatch_options->{dbicg}->resultset('Adres')->search(@dbopts);
    }

    return unless $resultset;

    ### Paging info
    $dispatch_options->{stash}->{paging_total}       = $resultset->pager->total_entries;
    $dispatch_options->{stash}->{paging_lastpage}    = $resultset->pager->last_page;

    return BRSOBJECT->new(
        'class'     => __PACKAGE__,
        'dbic_rs'   => $resultset,
        'opts'      => $opts,
        %{ $dispatch_options },
    );
}


sub BUILD {
    my ($self) = @_;

    ### Nothing to do if we do not know which way we came in
    return unless ($self->trigger eq 'get' && $self->id);

    ### It depends on the 'intern' option, weather we retrieve
    ### our data from our our snapshot DB, or GM. When there is
    ### no intern defined, we will look at the id for a special string
    if ($self->id =~ /\-/) {
        $self->log->debug('XXX Found special string');

        ### Special string, no intern defined, go to intern default
        if (!defined($self->{intern})) {
            $self->log->debug('XXX Found internal request');
            $self->{intern} = 1;
        }

        my ($gmid, $id) = $self->id =~ /^(\d+)\-(\d+)$/;

        $self->id($id);
        $self->gmid($gmid);
    }

    if (!$self->intern) {
#        $self->log->debug('XXX Found external request');

        ### Get id is probably gmid, it is an external request, unless it is
        ### already set of course
        if (!$self->gmid) {
            $self->gmid($self->id);
            $self->id(undef);
        }
    }

    ### All set, let's rock and rolla. Depending on where we have to get the
    ### data from, fill in the blanks
    if ($self->{intern}) {
#        $self->log->debug('XXX Load internal id: ' . $self->id);
        $self->_load_intern or die('Failed loading M::B::NP Object');
    } else {
#        $self->log->debug('XXX Load external id:' . $self->gmid);
        $self->_load_extern or die('Failed loading M::B::NP Object');
    }

    ### Some defaults, should move to Object
    $self->btype('natuurlijk_persoon');

}

sub _load_contact_data {
    my ($self, $gm_id)  = @_;

    return unless $gm_id;

    my $contactdata = $self->dbic->resultset('ContactData')->search(
        {
            gegevens_magazijn_id    => $gm_id,
            betrokkene_type         => 1,
        }
    );

    $self->log->debug('load contactdata: ' . $gm_id);

    return unless $contactdata->count;
    $contactdata = $contactdata->first;

    for my $key (keys %{ $CONTACT_MAP }) {
        $self->{$key} = $contactdata->$key;
    }
}

sub _load_extern {
    my ($self) = @_;
    my ($gm);

    (
        $self->log->debug(
            'M::B::NP->load: Could not find external GM by id: ' . $self->gmid
        ),
        return
    ) unless $gm = $self->dbicg->resultset('NatuurlijkPersoon')->find($self->gmid);

    $self->gm_np(    $gm );
    $self->gm_adres( $self->gm_np->adres_id );

    if ($gm->authenticated) {
        $self->log->debug('Found authenticated user');
        $self->authenticated(1);
    }

    if ($gm->authenticatedby) {
        $self->authenticated_by(
            $gm->authenticatedby
        );
    }

    ### We are loaded external, now let's set up some triggers and attributes
    $self->_load_attributes;

    ### Try to find this person loaded within betrokkenen
    my $intern_loaded = $self->dbic->resultset('GmNatuurlijkPersoon')->search(
        {
            gegevens_magazijn_id    => $self->gmid
        }
    );

    #if ($intern_loaded->count) {
        ### Load contact
        $self->_load_contact_data($self->gmid);
        #}

    $self->gm_extern_np( $self->gm_np );

    return 1;
}

sub _load_intern {
    my ($self) = @_;
    my ($bo);

    (
        $self->log->warn(
            'M::B::NP->load: Could not find internal betrokkene by id ' . $self->id
        ),
        return
    ) unless $bo = $self->dbic->resultset('ZaakBetrokkenen')->find($self->id);

    ### TODO : NO idea yet if I really need this object
    $self->bo($bo);

    ### Retrieve data from internal GM
    return unless $bo->natuurlijk_persoon;

    ### Make sure we have these data for back reference
    $self->gm_np(    $bo->natuurlijk_persoon );
    $self->gm_adres( $self->gm_np->adres_id );

    $self->identifier($bo->natuurlijk_persoon->id . '-' . $self->id);

    ### Define some authenticated info
    ### Search for source (DBG)
    my $dbg = $self->dbicg->resultset('NatuurlijkPersoon')->find(
        $bo->natuurlijk_persoon->gegevens_magazijn_id
    );

    if ($dbg->authenticated) {
        $self->log->debug('Found authenticated user');
        $self->authenticated(1);
    }

    if ($dbg->authenticatedby) {
        $self->authenticated_by(
            $dbg->authenticatedby
        );
    }

    ### We are loaded internal, now let's set up some triggers and attributes
    $self->_load_attributes;

    $self->_load_contact_data($bo->natuurlijk_persoon->gegevens_magazijn_id)
        if $bo->natuurlijk_persoon->gegevens_magazijn_id;

    $self->gmid($bo->natuurlijk_persoon->gegevens_magazijn_id);

    $self->gm_extern_np( $dbg );

    return 1;
}

sub _load_attributes {
    my ($self) = @_;

    for my $meth (keys %{ $CONTACT_MAP }) {
        $self->meta->add_attribute($meth,
            'is'        => 'rw',
            ### On update, add custom field back to RT
            'trigger'   => sub {
                my ($self, $new, $old) = @_;
                my ($external_id);

                $self->log->debug('Trigger called for contactupdate: ' .
                    $meth);

                ## Do not update anything when new is the same
                if ($new eq $old) { return $new; }

                if ($self->gmid) { 
                    $external_id = $self->gmid;
                } else {
                    $external_id =
                        $self->bo->natuurlijk_persoon->gegevens_magazijn_id;
                }

                my $contactdata = $self->dbic->resultset('ContactData')->search(
                    {
                        gegevens_magazijn_id    => $external_id,
                        betrokkene_type         => 1,
                    }
                );

                if ($contactdata->count) {
                    $contactdata = $contactdata->first;
                    $contactdata->$meth($new);
                    $contactdata->update;
                } else {
                    $contactdata = $self->dbic->resultset('ContactData')->create(
                        {
                            'gegevens_magazijn_id'  => $external_id,
                            'betrokkene_type'       => 1,
                            $meth   => $new,
                        }
                    );
                }
            },
        );
    }

    for my $meth (@{ $CLONE_MAP }, 'adres_id') {
        $self->meta->add_attribute($meth,
            'is'        => 'rw',
            'lazy'      => 1,
            ### On update, add custom field back to RT
            'trigger'   => sub {
                my ($self, $new, $old) = @_;

                ## Do not update anything when new is the same
                if ($new eq $old) { return $new; }

                # And definetly do not update the adres_id
                if ($meth eq 'adres_id') { return; }

                ### Update object
                $self->gm_np->$meth($new);
                $self->gm_np->update;
            },
            ### Load custom fields from RT
            'default'   => sub {
                my ($self) = @_;

                return $self->gm_np->$meth;
            }
        );
    }

    ### Adres?
    for my $meth (@{ $ADRES_CLONE_MAP }) {
        $self->meta->add_attribute($meth,
            'is'        => 'rw',
            'lazy'      => 1,
            ### On update, add custom field back to RT
            'trigger'   => sub {
                my ($self, $new, $old) = @_;

                ## Do not update anything when new is the same
                if ($new eq $old) { return $new; }

                ### Update object
                $self->gm_adres->$meth($new);
                $self->gm_adres->update;
                
                ### Remove verblijfsobject
                $self->gm_np->verblijfsobject_id(undef);
                $self->gm_np->update;
            },
            ### Load custom fields from RT
            'default'   => sub {
                my ($self) = @_;

                return $self->gm_adres->$meth;
            }
        );
    }
}

sub _make_intern {
    my ($self, $dispatch_options, $gmo) = @_;

    $dispatch_options->{log}->debug('M::B::NP->_make_intern called with object: ' . ref($gmo));
    return unless ref($gmo) eq __PACKAGE__;

    (
        $dispatch_options->{log}->error('M::B::NP->set: Not an external GM object'),
        return
    ) if $gmo->intern;

#    # Load external id
#    my $gmo = __PACKAGE__->new(
#        'trigger'       => 'get',
#        'c'             => $c,
#        'id'            => $external_id,
#        'intern'        => 0,
#    );
#
#    return unless $gmo;

    ### Create the copy
    my %np_values           = map { $_ => $gmo->gm_np->$_ }
        @{ $CLONE_MAP };
    my %np_adres_values     = map { $_ => $gmo->gm_adres->$_ }
        @{ $ADRES_CLONE_MAP };

    ### Create the link
    $np_values{'gegevens_magazijn_id'}  = $gmo->gmid;

    my $create = {
        'adres' => \%np_adres_values,
        'gm'    => \%np_values,
    };

    return $self->_create_intern(
        $dispatch_options,
        {},
        $create
    );
}

sub create {
    my ($self, $dispatch_options, $params) = @_;
    my ($create) = ({});

    ### generate data
    $create->{gm} = {
        map {
            my $label = $_;
            $label =~ s/^np-//g;
            $label => $params->{ $_ }
        } grep(/^np-/, keys %{ $params })
    };

    $create->{gmc} = {
        map {
            my $label = $_;
            $label =~ s/^npc-//g;
            $label => $params->{ $_ }
        } grep(/^npc-/, keys %{ $params })
    };

    $create->{adres} = {};
    for my $adresid (@{ $ADRES_CLONE_MAP }) {
        delete($create->{gm}->{$adresid});

        $create->{adres}->{$adresid} =
            $params->{'np-' . $adresid};
    }

    ### Ongeauthoriseerde gebruiker, geen GBA
    $create->{gm}->{authenticated} =
        (
            $create->{authenticated} ? 1 : undef
        );

    ### Type given?
    if ($params->{authenticated_by}) {
        $create->{gm}->{authenticatedby} =
            $params->{authenticated_by};
    }

    ### Forward to make-intern
    my $boid = $self->_create_extern($dispatch_options,undef,$create);

    $dispatch_options->{log}->debug('BO-ID: ' . $boid);

    return $boid;
}

sub _create_extern {
    my ($self, $dispatch_options, $opts, $create) = @_;

    my $npaoo = $dispatch_options->{dbicg}->resultset('Adres')->create(
        $create->{'adres'}
    );

    return unless $npaoo;
    $dispatch_options->{log}->debug(
        'M::B::NP->_create_extern created adres with id ' .
        $npaoo->id
    );

    ### Copy this ID to our GM
    my $npoo = $dispatch_options->{dbicg}->resultset('NatuurlijkPersoon')->create(
        {
            'adres_id'      => $npaoo->id,
            %{ $create->{gm} }
        }
    );

    return unless $npoo;

    $dispatch_options->{log}->debug('M::B::NP->_create_extern created gm with id: ' . $npoo->id);

    ### Register contact_data
    if (
        $create->{gmc} &&
        %{ $create->{gmc} }
    ) {
        my $npco = $dispatch_options->{dbic}->resultset('ContactData')->create(
            {
                'gegevens_magazijn_id'  => $npoo->id,
                'betrokkene_type'       => 1,
                %{ $create->{gmc} }
            }
        );
    }

    return $npoo->id;
}

sub _create_intern {
    my ($self, $dispatch_options, $opts, $create) = @_;

    my $npaoo = $dispatch_options->{dbic}->resultset('GmAdres')->create(
        $create->{'adres'}
    );

    return unless $npaoo;
    $dispatch_options->{log}->debug(
        'M::B::NP->_create_intern created adres with id ' .
        $npaoo->id
    );

    ### Copy this ID to our GM
    my $npoo = $dispatch_options->{dbic}->resultset('GmNatuurlijkPersoon')->create(
        {
            'adres_id'      => $npaoo->id,
            %{ $create->{gm} }
        }
    );

    ### Register contact_data
    if (
        $create->{gmc} &&
        $create->{gm}->{'gegevens_magazijn_id'} &&
        %{ $create->{gmc} }
    ) {
        my $npco = $dispatch_options->{dbic}->resultset('ContactData')->create(
            {
                'gegevens_magazijn_id'  => $create->{gm}->{'gegevens_magazijn_id'},
                'betrokkene_type'       => 1,
                %{ $create->{gmc} }
            }
        );
    }

    return unless $npoo;

    $dispatch_options->{log}->debug('M::B::NP->_create_intern created gm with id: ' . $npoo->id);

    ### Create betrokkene
    my $bo = $dispatch_options->{dbic}->resultset('ZaakBetrokkenen')->create({
        'betrokkene_type'           => 'natuurlijk_persoon',
        'betrokkene_id'             => $npoo->id,
        'gegevens_magazijn_id'      => $create->{gm}->{'gegevens_magazijn_id'},
        'naam'                      => $npoo->voornamen . ' ' . (
                $npoo->voorvoegsel
                    ? $npoo->voorvoegsel . ' '
                    : ''
            ) . $npoo->geslachtsnaam,
    });

    return unless $bo;
    $dispatch_options->{log}->debug('M::B::NP->_create_intern created BO:' . $bo->id);

    return $bo->id;
}

sub set {
    my ($self, $dispatch_options, $external_id) = @_;

    ### We assume id is a GM id, because we cannot set an old betrokkene
    ### 'again'. So, we will load __PACKAGE__ with trigger get and as an
    ### external object. Feed it to our internal baker, and return a classy
    ### string with information;
    my $identifier = $external_id . '-';

    $dispatch_options->{log}->debug('M::B::NP->set called with identifier: ' . $identifier);

    # Load external id
    my $gmo = __PACKAGE__->new(
        'trigger'       => 'get',
        'id'            => $external_id,
        'intern'        => 0,
        %{ $dispatch_options },
    );

    return unless $gmo;

    # Feed it to our baker
    my $bid = $self->_make_intern($dispatch_options, $gmo) or return;

    $identifier .= $bid;

    $dispatch_options->{log}->debug('M::B::NP->set create identifier ' . $identifier);

    return 'natuurlijk_persoon-' . $identifier;
}


#sub _set {
#    my ($self, $id) = @_;
#    my ($copy, $adrescopy) = {};
#
#    ### Found this id?
#    my $npo = $self->dbicg->resultset('NatuurlijkPersoon')->find($id);
#    return unless $npo;
#
#    $copy->{ $_ } = $npo->$_ for @{ $CLONE_MAP };
#
#    my $npadreso = $npo->adres_id;
#
#    $adrescopy->{ $_ } = $npadreso->$_ for @{ $ADRES_CLONE_MAP };
#
#    my $npaoo = $self->dbic->resultset('GmAdres')->create(
#        {
#            %$adrescopy
#        }
#    );
#
#    ### Copy this ID to our GM
#    my $npoo = $self->dbic->resultset('GmNatuurlijkPersoon')->create(
#        {
#            'gegevens_magazijn_id'  => $id,
#            'adres_id' => $npaoo->id,
#            %$copy
#        }
#    );
#
#    #$self->log->debug('Gaatie? ');
#
#    ### Set this id
#    my $bo = $self->dbic->resultset('ZaakBetrokkenen')->create({
#        'betrokkene_type'           => 'natuurlijk_persoon',
#        'betrokkene_id'             => $npoo->id,
#        'gegevens_magazijn_id'      => $id,
#        'naam'                      => $npoo->naam,
#    });
#
#    return $bo->id;
#}

sub verwijder {
    my ($self) = @_;

    $self->gm_extern_np->deleted_on(DateTime->now);
    return $self->gm_extern_np->update;
}

#sub _init {
#    my ($self, $c) = @_;
#
#
#}

# NEW. This subroutine will provide the Betrokkene class the information
# needed to get information from this class.. Strange eh :)

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

