package Zaaksysteem::Betrokkene::Object::Bedrijf;

use strict;
use warnings;
use Data::Dumper;
use Moose;

use Zaaksysteem::Constants qw/
    GEGEVENSMAGAZIJN_KVK_PROFILE
/;

use constant BOBJECT    => 'Zaaksysteem::Betrokkene::Object';
use constant BRSOBJECT  => 'Zaaksysteem::Betrokkene::ResultSet';

extends BOBJECT;

my $KVK_DEFINITIE = GEGEVENSMAGAZIJN_KVK_PROFILE;

my $CLONE_MAP = [qw/
    dossiernummer
    subdossiernummer
    hoofdvestiging_dossiernummer
    hoofdvestiging_subdossiernummer
    vorig_dossiernummer
    vorig_subdossiernummer
    handelsnaam
    rechtsvorm
    kamernummer
    faillisement
    surseance
    vestiging_adres
    vestiging_straatnaam
    vestiging_huisnummer
    vestiging_huisnummertoevoeging
    vestiging_postcodewoonplaats
    vestiging_postcode
    vestiging_woonplaats
    correspondentie_adres
    correspondentie_straatnaam
    correspondentie_huisnummer
    correspondentie_huisnummertoevoeging
    correspondentie_postcodewoonplaats
    correspondentie_postcode
    correspondentie_woonplaats
    hoofdactiviteitencode
    nevenactiviteitencode1
    nevenactiviteitencode2
    werkzamepersonen
    contact_naam
    contact_aanspreektitel
    contact_voorletters
    contact_voorvoegsel
    contact_geslachtsnaam
    contact_geslachtsaanduiding
    authenticated
    import_datum
    verblijfsobject_id
/ ];

my $CONTACT_MAP = {
    telefoonnummer  => 1,
    mobiel          => 1,
    email           => 1,
};

my $UNIFORM = {
    'straatnaam'    => 'vestiging_straatnaam',
    'huisnummer'    => 'vestiging_huisnummer',
    'postcode'      => 'vestiging_postcode',
    'geslachtsaanduiding' => 0,
    'woonplaats'    => 'vestiging_woonplaats',
};

my $EXPLICIT_SEARCH = {
    'rechtsvorm'        => 1,
};

### BOGUS FIELDS
has [qw/huisletter huisnummertoevoeging/]   => (
    'is'    => 'rw'
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

### GM FIELDS

has 'gm_bedrijf'     => (
    'is'    => 'rw',
);

has 'gm_extern_np'     => (
    'is'    => 'rw',
);

has 'gmid'      => (
    'is'    => 'rw',
);

has 'intern'    => (
    'is'    => 'rw',
);

### Convenience method containing some sort of display_name
has 'naam' => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        return $self->handelsnaam;
    },
);

has 'display_name' => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        return $self->naam;
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


### BUSSUMID
has 'has_password' => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        if ($self->password) {
            return 1;
        }
    },
);

has 'login' => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        if ($self->password) {
            return $self->dossiernummer;
        }
    },
);


my $ORDER_MAP = {
    'dossiernummer'         => 'dossiernummer',
    'vestiging_woonplaats'         => 'vestiging_woonplaats',
    'handelsnaam'       => 'handelsnaam',
    'vestiging_postcode'               => 'vestiging_postcode'
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
    die('M::B::Bedrijf->search() only possible call = class based')
        unless !ref($self);

    return unless defined($opts->{'intern'});

    ### SOME NOT complicated ORDERING
    if (
        $dispatch_options->{stash}->{order} &&
        defined($ORDER_MAP->{ $dispatch_options->{stash}->{order} })

    ) {
        $roworder = $ORDER_MAP->{ $dispatch_options->{stash}->{order} };
    } else {
        $roworder = 'handelsnaam';
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
    for my $key (keys %{ $searchr }) {
        next unless $searchr->{$key};

        if ($key eq 'postcode') {
            ## XXX POSTCODE, Uppercase without spaces
            my $postcode = $searchr->{ $key };
            $postcode = uc($postcode);
            $postcode =~ s/\s*//g;
            $search->{ $key } = $postcode;
        } elsif ($EXPLICIT_SEARCH->{$key}) {
            $search->{'lower(' . $key . ')'} = lc($searchr->{$key});
        } elsif (!$searchr->{'EXACT'}) {
            $search->{ 'lower(' . $key . ')' }
                = {'like' => '%' . lc($searchr->{ $key }) . '%'};
        } else {
            $search->{ $key }
                = $searchr->{ $key };
        }
    }

    ### Define correct db
    ### TODO: Constants would be fine
    my ($model);
    if ($opts->{intern}) {
        $model = 'DB::GmBedrijf';
    } else {
        $model = 'DBG::Bedrijf';
        $search->{deleted_on} = undef;
    }


    ### Paging
    my $rowlimit = $dispatch_options->{stash}->{paging_rows} =
        $dispatch_options->{stash}->{paging_rows} || 20;
    my $rowpage = $dispatch_options->{stash}->{paging_page} =
        $dispatch_options->{stash}->{paging_page} || 1;

    ### Ask internal or external model about this search
    my @dbopts = (
        $search,
        {
            'page'  => $rowpage,
            'rows'  => $rowlimit,
            'order_by'  => { '-' . $roworderdir => $roworder }
        }
    );

    my $resultset;
    if ($opts->{intern}) {
        $resultset = $dispatch_options->{dbic}->resultset('GmBedrijf')->search(@dbopts);
    } else {
        $resultset = $dispatch_options->{dbicg}->resultset('Bedrijf')->search(@dbopts);
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
        $self->_load_intern or die('Failed loading M::B::Bedrijf Object');
    } else {
#        $self->log->debug('XXX Load external id:' . $self->gmid);
        $self->_load_extern or die('Failed loading M::B::Bedrijf Object');
    }

    ### Some defaults, should move to Object
    $self->btype('bedrijf');

}

sub _load_contact_data {
    my ($self, $gm_id)  = @_;

    return unless $gm_id;

    my $contactdata = $self->dbic->resultset('ContactData')->search(
        {
            gegevens_magazijn_id    => $gm_id,
            betrokkene_type         => 2,
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
            'M::B::Bedrijf->load: Could not find external GM by id: ' . $self->gmid
        ),
        return
    ) unless $gm = $self->dbicg->resultset('Bedrijf')->find($self->gmid);

    $self->gm_bedrijf(    $gm );

    if ($gm->authenticated) {
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
    my $intern_loaded = $self->dbic->resultset('GmBedrijf')->search(
        {
            gegevens_magazijn_id    => $self->gmid
        }
    );

    #if ($intern_loaded->count) {
        ### Load contact
        $self->_load_contact_data($self->gmid);
        #}

    $self->gm_extern_np( $self->gm_bedrijf );

    return 1;
}

sub _load_intern {
    my ($self) = @_;
    my ($bo);

    (
        $self->log->debug(
            'M::B::Bedrijf->load: Could not find internal betrokkene by id ' . $self->id
        ),
        return
    ) unless $bo = $self->dbic->resultset('ZaakBetrokkenen')->find($self->id);

    ### TODO : NO idea yet if I really need this object
    $self->bo($bo);

    ### Retrieve data from internal GM
    return unless $bo->bedrijf;

    ### Make sure we have these data for back reference
    $self->gm_bedrijf(    $bo->bedrijf );

    $self->identifier($bo->bedrijf->id . '-' . $self->id);

    ### Define some authenticated info
    ### Search for source (DBG)
    my $dbg = $self->dbicg->resultset('Bedrijf')->find(
        $bo->bedrijf->gegevens_magazijn_id
    );

    if ($dbg->authenticated) {
        $self->authenticated(1);
    }

    if ($dbg->authenticatedby) {
        $self->authenticated_by(
            $dbg->authenticatedby
        );
    }

    ### We are loaded internal, now let's set up some triggers and attributes
    $self->_load_attributes;

    $self->gmid($bo->bedrijf->gegevens_magazijn_id);

    $self->_load_contact_data($bo->bedrijf->gegevens_magazijn_id)
        if $bo->bedrijf->gegevens_magazijn_id;

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
                        $self->bo->m_natuurlijk_persoon_id->gegevens_magazijn_id;
                }

                my $contactdata = $self->dbic->resultset('ContactData')->search(
                    {
                        gegevens_magazijn_id    => $external_id,
                        betrokkene_type         => 2,
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
                            'betrokkene_type'       => 2,
                            $meth   => $new,
                        }
                    );
                }
            },
        );
    }

    for my $meth (@{ $CLONE_MAP }) {
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

                # Replace - and white space with nothing in telefoonnummer
                if ($meth eq 'telefoonnummer') {
                    $new =~ s/\s|-//g;
                }
                ### Update object
                $self->gm_bedrijf->$meth($new);
                $self->gm_bedrijf->update;
            },
            ### Load custom fields from RT
            'default'   => sub {
                my ($self) = @_;

                return $self->gm_bedrijf->$meth;
            }
        );
    }

    ### Uniformiteit, attributes known to every object, but does not have
    ### a trigger :P
    for my $meth (keys %{ $UNIFORM }) {
        my $localmeth = $UNIFORM->{$meth};
        $self->meta->add_attribute($meth,
            'is'        => 'rw',
            'lazy'      => 1,
            ### On update, add custom field back to RT
            ### Load custom fields from RT
            'default'   => sub {
                my ($self) = @_;

                return '' unless $localmeth;

                return $self->gm_bedrijf->$localmeth;
            }
        );
    }

    ### BUSSUMID, AUTHID
    $self->meta->add_attribute( 'password',
        'is'        => 'rw',
        'lazy'      => 1,
        'trigger'   => sub {
            my ($self, $new, $old) = @_;

            ## Do not update anything when new is the same
            if ($new eq $old) { return $new; }

            return $new unless $self->gm_bedrijf->id;

            ### Search bedrijf in database
            my $auth_bedrijf = $self->dbic->resultset('BedrijfAuthenticatie')
                ->search(
                    {
                        gegevens_magazijn_id    =>
                            $self->gmid,
                    }
                );

            if ($auth_bedrijf->count) {
                $auth_bedrijf = $auth_bedrijf->first;
                $auth_bedrijf->password($new);
                $auth_bedrijf->update;
            } else {
                $auth_bedrijf = $self->dbic->resultset('BedrijfAuthenticatie')
                    ->create(
                        {
                            gegevens_magazijn_id    =>
                                $self->gmid,
                            login                   =>
                                $self->gm_bedrijf->dossiernummer,
                            password                =>
                                $new
                        },
                    );
            }

            $self->login($self->gm_bedrijf->dossiernummer);
            $self->has_password(1);

            return $new;
        },
        'default'   => sub {
            my ($self) = @_;

            if (
                $self->gmid
            ) {
                my $auth_bedrijf = $self->dbic->resultset('BedrijfAuthenticatie')
                    ->search(
                        {
                            gegevens_magazijn_id    =>
                                $self->gmid
                        }
                    );

                if ($auth_bedrijf->count) {
                    $auth_bedrijf = $auth_bedrijf->first;
                    $self->has_password(1);
                    $self->login($auth_bedrijf->login);

                    return $auth_bedrijf->password;
                }

                return;
            }
        }
    );

}

sub _make_intern {
    my ($self, $dispatch_options, $gmo) = @_;

    $dispatch_options->{log}->debug('M::B::Bedrijf->_make_intern called with object: ' . ref($gmo));
    return unless ref($gmo) eq __PACKAGE__;

    (
        $dispatch_options->{log}->error('M::B::Bedrijf->set: Not an external GM object'),
        return
    ) if $gmo->intern;

    my $create = {
        map { $_ => $gmo->gm_bedrijf->$_ }
        @{ $CLONE_MAP }
    };

    ### Quick hacks
    if ($create->{surseance} && $create->{surseance} eq 'Y') {
        $create->{surseance} = 1;
    } else {
        $create->{surseance} = 0;
    }

    ### Create the link
    $create->{'gegevens_magazijn_id'}  = $gmo->gmid;

    return $self->_create_intern(
        $dispatch_options,
        {},
        $create
    );
}

{
    Params::Profile->register_profile(
        method  => 'create',
        profile => $KVK_DEFINITIE
    );

    sub create {
        my ($self, $dispatch_options, $params) = @_;
        my ($create) = ({});

        my $dv = Params::Profile->check(
            params  => $params,
        );

        return unless $dv->success;

        $create = $dv->valid;

        ### Ongeauthoriseerde gebruiker, geen GBA
        $create->{authenticated} = 0;

        $create->{authenticatedby} = $params->{authenticatedby}
            if $params->{authenticatedby};

        ### Forward to make-intern
        my $boid = $self->_create_extern($dispatch_options,undef,$create);

        return $boid;
    }
}

sub _create_extern {
    my ($self, $dispatch_options, $opts, $create) = @_;

    my $bedrijf = $dispatch_options->{dbicg}->resultset('Bedrijf')->create(
        $create
    );

    return unless $bedrijf;

    $dispatch_options->{log}->debug(
        'M::B::Bedrijf->_create_extern created bedrijf with id ' .
        $bedrijf->id . ' and attrs' . Dumper($create)
    );

    return $bedrijf->id;
}

sub _create_intern {
    my ($self, $dispatch_options, $opts, $create) = @_;

    ### Copy this ID to our GM
    my $bedrijf = $dispatch_options->{dbic}->resultset('GmBedrijf')->create(
        $create
    );

    return unless $bedrijf;

    $dispatch_options->{log}->debug('M::B::Bedrijf->_create_intern created gm with id: ' . $bedrijf->id);

    ### Create betrokkene
    my $bo = $dispatch_options->{dbic}->resultset('ZaakBetrokkenen')->create({
        'betrokkene_type'           => 'bedrijf',
        'betrokkene_id'             => $bedrijf->id,
        'gegevens_magazijn_id'      => $bedrijf->gegevens_magazijn_id,
        'naam'                      => $bedrijf->handelsnaam
    });

    ### Register contact_data
    if (
        $create->{gmc} &&
        $create->{gm}->{'gegevens_magazijn_id'} &&
        %{ $create->{gmc} }
    ) {
        my $npco = $dispatch_options->{dbic}->resultset('ContactData')->create(
            {
                'gegevens_magazijn_id'  => $bedrijf->gegevens_magazijn_id,
                'betrokkene_type'       => 2,
                %{ $create->{gmc} }
            }
        );
    }

    return unless $bo;

    $dispatch_options->{log}->debug('M::B::Bedrijf->_create_intern created BO:' . $bo->id);

    return $bo->id;
}

sub set {
    my ($self, $dispatch_options, $external_id) = @_;

    ### We assume id is a GM id, because we cannot set an old betrokkene
    ### 'again'. So, we will load __PACKAGE__ with trigger get and as an
    ### external object. Feed it to our internal baker, and return a classy
    ### string with information;
    my $identifier = $external_id . '-';

    $dispatch_options->{log}->debug('M::B::Bedrijf->set called with identifier: ' . $identifier);

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

    $dispatch_options->{log}->debug('M::B::Bedrijf->set create identifier ' . $identifier);

    return 'bedrijf-' . $identifier;
}


sub verwijder {
    my ($self) = @_;

    $self->gm_extern_np->deleted_on(DateTime->now());
    return $self->gm_extern_np->update;
}


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

