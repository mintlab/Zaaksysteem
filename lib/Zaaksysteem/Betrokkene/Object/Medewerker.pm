package Zaaksysteem::Betrokkene::Object::Medewerker;

use strict;
use warnings;

use Net::LDAP;
use Data::Dumper;
use Moose;

use constant BOBJECT    => 'Zaaksysteem::Betrokkene::Object';
use constant BRSOBJECT  => 'Zaaksysteem::Betrokkene::ResultSet';

extends BOBJECT;

my $CLONE_MAP = {
    'voorletters'   => 'initials',
    'voornamen'     => 'givenName',
    'email'         => 'mail',
    'geslachtsnaam' => 'sn',
    'display_name'  => 'displayName',
    'telefoonnummer' => 'telephoneNumber',
};
my $UNIFORM = {
    'voorvoegsel'       => 0,
    'straatnaam'        => 'straatnaam',
    'huisnummer'        => 'huisnummer',
    'postcode'          => 'postcode',
    'geslachtsaanduiding'          => 0,
    'woonplaats'        => 'plaats',
};

my $SEARCH_MAP = {
    %{ $CLONE_MAP }
};

has 'intern'    => (
    'is'    => 'rw',
);

has 'ldap_rs'   => (
    'is'    => 'rw',
);

has 'ldapid'   => (
    'is'    => 'rw',
);

### DUMMY:
has [qw/
    huisletter
    huisnummertoevoeging
    mobiel
/] => (
    'is'   => 'ro',
);

### Convenience method containing some sort of display_name
has 'naam' => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        return $self->display_name;
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

has 'afdeling' => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        return $self->org_eenheid->naam
            if $self->org_eenheid;
    },
);

has 'org_eenheid' => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my ($self) = @_;

        if ($self->ldap_rs) {
            # Get eenheid
            my $bclass = BOBJECT . '::OrgEenheid';

            return $bclass->get_by_dn(
                $self->_dispatch_options,
                $self->ldap_rs->dn,
            );
        }
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

sub _connect_ldap {
    my ($self, $dispatch_options) = @_;

    my $ldap = Net::LDAP->new(
        $dispatch_options->{config}->{authentication}->{realms}
            ->{zaaksysteem}->{store}->{ldap_server}
    );


    $ldap->bind;

    return $ldap;
}


sub search {
    my $self                = shift;
    my $dispatch_options    = shift;
    my $opts                = shift;
    my ($searchr)           = @_;

    ### Will search our LDAP directory containing the asked users
    die('M::B::NP->search() only possible call = class based')
        unless !ref($self);

    ### Connect to our ldap directory
    my $ldap = $self->_connect_ldap($dispatch_options) or
        (
            $dispatch_options->{log}->debug('Failed connecting to ldap directory'),
            return
        );

    my $usersearch = $ldap->search(
        filter  => '(&(objectClass=posixAccount))',
        base    => $dispatch_options->{customer}
            ->{start_config}
            ->{'LDAP'}
            ->{basedn}
    );

    my $org_eenheid;
    if (exists($searchr->{'org_eenheid'}) && $searchr->{'org_eenheid'}) {
        $org_eenheid = $dispatch_options->{dbic}->resultset('Betrokkene')->get(
            {}, 'betrokkene-org_eenheid-' . $searchr->{'org_eenheid'}
        );
    }

    ### Do some searching over these entries depending on given values
    my @results = ();
    foreach my $entry ($usersearch->entries) {
        my $searchfail = 0;
        foreach my $attr (keys %{ $SEARCH_MAP }) {
            if (
                exists($searchr->{$attr}) &&
                $searchr->{$attr}
            ) {
                my $se = $searchr->{$attr};
                unless ($entry->get_value($SEARCH_MAP->{$attr}) =~ /$se/i) {
                    $searchfail++;
                }
            }

            if (
                exists($searchr->{'org_eenheid'}) &&
                $searchr->{'org_eenheid'}
            ) {
                my ($org_ou) = $entry->dn =~ /ou=(.*?),/;

                $searchfail++ unless (
                    $org_ou eq $org_eenheid->naam
                );
            }
        }

        push(@results, $entry) unless $searchfail;
    }

    @results = sort { $a->get_value('sn') cmp $b->get_value('sn') } @results;

    return unless scalar(@results) > 0;

    return BRSOBJECT->new(
        'class'     => __PACKAGE__,
        %{ $dispatch_options },
        'ldap_rs'   => \@results,
        'opts'      => $opts,
    );


    ### Define correct db
    ### TODO: Constants would be fine
#    my ($model);
#    if ($opts->{intern}) {
#        $model = 'DB::Adres';
#    } else {
#        $model = 'DBG::Adres';
#    }
#
#    ### Ask internal or external model about this search
#    my $resultset = $c->model($model)->search(
#        $search,
#        {
#            'join'  => 'natuurlijk_persoons',
#        }
#    );
#
#    return unless $resultset;
#
#    return BRSOBJECT->new(
#        'class'     => __PACKAGE__,
#        'c'         => $c,
#        'dbic_rs'   => $resultset,
#        'opts'      => $opts,
#    );
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

        my ($ldapid, $id) = $self->id =~ /^(\d+)\-(\d+)$/;

        $self->id($id);
        $self->ldapid($ldapid);
    }

    if (!$self->intern) {
#        $self->log->debug('XXX Found external request');

        ### Get id is probably gmid, it is an external request, unless it is
        ### already set of course
        if (!$self->ldapid) {
            $self->ldapid($self->id);
            $self->id(undef);
        }
    }

    ### All set, let's rock and rolla. Depending on where we have to get the
    ### data from, fill in the blanks
    if ($self->{intern}) {
        $self->_load_intern or die('Failed loading M::B::NP Object');
    } else {
        $self->_load_extern or die('Failed loading M::B::NP Object');
    }

    ### Some defaults, should move to Object
    $self->btype('medewerker');
}

sub _load_extern {
    my ($self) = @_;
    my (@entries, $ldapsearch);
    my $ldap = $self->_connect_ldap($self->_dispatch_options);

    my @usersearchq = (
        filter  => '(uidNumber=' . $self->ldapid . ')',
        #filter  => '(&(objectClass=posixAccount))',
        base    => $self->customer
            ->{start_config}
            ->{'LDAP'}
            ->{basedn}
    );

    (
        $self->log->debug(
            'M::B::MW->load: Could not search for ldapuid: ' .  $self->ldapid
        ),
        return
    ) unless $ldapsearch = $ldap->search(@usersearchq);

    (
        $self->log->debug(
            'M::B::MW->load: Could not find external MW because LDAP '
            . ' returned an error: ' .  $ldapsearch->error_text
        ),
        return
    ) if $ldapsearch->is_error;

    (
        $self->log->debug(
            'M::B::MW->load: Could not find external MW by id: ' .  $self->ldapid
            . ', got number of records: ' . $ldapsearch->count
        ),
        return
    ) if $ldapsearch->count != 1;

    @entries = $ldapsearch->entries;

    $self->ldap_rs( shift(@entries) );

    ### External loaded, let's notify the betrokkene id
    my $bo = $self->dbic->resultset('ZaakBetrokkenen')->find_or_create({
        'betrokkene_type'           => 'medewerker',
        'betrokkene_id'             => $self->ldapid,
        'gegevens_magazijn_id'      => $self->ldapid,
        'naam'                      => $self->ldap_rs->get_value('displayName'),
    });

    $self->id($bo->id);

    $self->identifier($self->ldapid . '-' . $self->id);

    ### We are loaded external, now let's set up some triggers and attributes
    $self->_load_attributes;

    return 1;
}

sub _load_intern {
    my ($self) = @_;
    my ($bo);

    (
        $self->log->debug(
            'M::B::MW->load: Could not find internal betrokkene by id ' . $self->id
        ),
        return
    ) unless $bo = $self->dbic->resultset('ZaakBetrokkenen')->find($self->id);

    ### TODO : NO idea yet if I really need this object
    $self->bo($bo);

    ### Retrieve data from internal GM
    return unless $bo->betrokkene_id;

    $self->ldapid($bo->betrokkene_id);

    ### Get external data
    $self->_load_extern or return;

    return 1;
}

sub _load_attributes {
    my ($self) = @_;

    for my $meth (keys %{ $CLONE_MAP }) {
        $self->meta->add_attribute($meth,
            'is'        => 'rw',
            'lazy'      => 1,
            ### On update, add custom field back to RT
#            'trigger'   => sub {
#                my ($self, $new, $old) = @_;
#
#                ## Do not update anything when new is the same
#                if ($new eq $old) { return $new; }
#
#                # And definetly do not update the adres_id
#                if ($meth eq 'adres_id') { return; }
#
#                ### Update object
#                $self->gm_np->$meth($new);
#                $self->gm_np->update;
#            },
            ### Load custom fields from RT
            'default'   => sub {
                my ($self) = @_;

                return $self->ldap_rs->get_value($CLONE_MAP->{$meth});
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

                return $self->config->{gemeente}->{$localmeth};
            }
        );
    }
}

sub set {
    my ($self, $dispatch_options, $external_id) = @_;

    ### Here we get a medewerk uidNumber. We presume medewerkers will get
    ### deleted from the system, so we create a betrokkene.
    my $identifier = $external_id . '-';

    $dispatch_options->{log}->debug('M::B::MW->set called with identifier: ' . $identifier);

    # Load external id
    my $mwo = __PACKAGE__->new(
        'trigger'       => 'get',
        'id'            => $external_id,
        'intern'        => 0,
        %{ $dispatch_options }
    );


    ### Let's do something EXTRA here. We do not want a new betrokkene for
    ### every time we create a medewerker. Medewerkers are 'static'

    ### Find betrokkene by id
#    my $bo = $dispatch_options->{dbic}->resultset('ZaakBetrokkenen')->search({
#        'betrokkene_type'           => 'medewerker',
#        'betrokkene_id'             => $mwo->ldapid,
#    });

#    if (!$bo->count) {
#        ### Create betrokkene
    my $bo = $dispatch_options->{dbic}->resultset('ZaakBetrokkenen')->create({
        'betrokkene_type'           => 'medewerker',
        'betrokkene_id'             => $mwo->ldapid,
        'gegevens_magazijn_id'      => $mwo->ldapid,
        'naam'                      => $mwo->display_name,
    });
#    } else {
#        $bo = $bo->first;
#
#        unless ($bo->naam eq $mwo->display_name) {
#            $bo->naam($mwo->display_name);
#            $bo->update;
#        }
#    }

    return unless $bo;
    $identifier .= $bo->id;

    $dispatch_options->{log}->debug('M::B::MW->set create identifier ' . $identifier);
    return 'medewerker-' . $identifier;
}

#sub set {
#    my ($self, $id) = @_;
#    my ($copy, $adrescopy) = {};
#
#    ### Found this id?
#    my $npo = $self->c->model('DBG::NatuurlijkPersoon')->find($id);
#    return unless $npo;
#
#    $copy->{ $_ } = $npo->$_ for @{ $CLONE_MAP };
#
#    my $npadreso = $npo->adres_id;
#
#    $adrescopy->{ $_ } = $npadreso->$_ for @{ $ADRES_CLONE_MAP };
#
#    my $npaoo = $self->c->model('DB::GMAdres')->create(
#        {
#            %$adrescopy
#        }
#    );
#
#    ### Copy this ID to our GM
#    my $npoo = $self->c->model('DB::GMNatuurlijkPersoon')->create(
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
#    my $bo = $self->c->model('DB::Betrokkene')->create({
#        'btype'                     => 'natuurlijk_persoon',
#        'gm_natuurlijk_persoon_id'  => $npoo->id,
#        'naam'                      => $npoo->voornamen . ' ' . $npoo->geslachtsnaam,
#    });
#
#    return $bo->id;
#}
#
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

