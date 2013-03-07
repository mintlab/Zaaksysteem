package Zaaksysteem::Betrokkene::Object::Rollen;

use strict;
use warnings;

use Net::LDAP;
use Data::Dumper;
use Moose;

use constant BOBJECT    => 'Zaaksysteem::Betrokkene::Object';
use constant BRSOBJECT  => 'Zaaksysteem::Betrokkene::ResultSet';

extends BOBJECT;

my $CLONE_MAP = {
    'naam'          => 'cn',
    'omschrijving'  => 'description',
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

sub _connect_ldap() {
    my ($self,$c) = @_;

    my $ldap = Net::LDAP->new(
        $self->config->{authentication}->{realms}
            ->{zaaksysteem}->{store}->{ldap_server}
    );

    $ldap->bind;

    return $ldap;
}


sub search {
    my $self        = shift;
    my $c           = shift;
    my $opts        = shift;
    my ($searchr)   = @_;

    ### Will search our LDAP directory containing the asked users
    die('M::B::NP->search() only possible call = class based')
        unless !ref($self);

    ### Connect to our ldap directory
    my $ldap = $self->_connect_ldap($c) or
        (
            $self->log->debug('Failed connecting to ldap directory'),
            return
        );

    my $usersearch = $ldap->search(
        filter  => '(&(objectClass=posixGroup))',
        base    => 'ou=Groups,dc=bussum,dc=zaaksysteem,dc=nl'
    );

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

        }

        push(@results, $entry) unless $searchfail;
    }

    return unless scalar(@results) > 0;

    return BRSOBJECT->new(
        'class'     => __PACKAGE__,
        'c'         => $c,
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
#        $self->log->debug('XXX Load internal id');
        $self->_load_intern or die('Failed loading M::B::NP Object');
    } else {
#        $self->log->debug('XXX Load external id');
        $self->_load_extern or die('Failed loading M::B::NP Object');
    }

    $self->btype('org_eenheid');

}

sub _load_extern {
    my ($self) = @_;
    my (@entries, $ldapsearch);
    my $ldap = $self->_connect_ldap();

    my @usersearchq = (
        filter  => '(gidNumber=' . $self->ldapid . ')',
        #filter  => '(&(objectClass=posixAccount))',
        base    => 'ou=Groups,dc=bussum,dc=zaaksysteem,dc=nl'
    );

    $self->log->debug('Searching for ldapid: ' . $self->ldapid .
        Dumper(\@usersearchq));

    (
        $self->log->debug(
            'M::B::OE->load: Could not search for ldapuid: ' .  $self->ldapid
        ),
        return
    ) unless $ldapsearch = $ldap->search(@usersearchq);

    (
        $self->log->debug(
            'M::B::OE->load: Could not find external OE because LDAP '
            . ' returned an error: ' .  $ldapsearch->error_text
        ),
        return
    ) if $ldapsearch->is_error;

    (
        $self->log->debug(
            'M::B::OE->load: Could not find external OE by id: ' .  $self->ldapid
        ),
        return
    ) if $ldapsearch->count != 1;

    @entries = $ldapsearch->entries;

    $self->ldap_rs( shift(@entries) );

    ### External loaded, let's notify the betrokkene id
    my $bo = $self->dbic->resultset('Betrokkene')->find_or_create({
        'btype'                     => 'org_eenheid',
        'org_eenheid_id'             => $self->ldapid,
        'naam'                      => $self->ldap_rs->get_value('cn'),
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
            'M::B::OE->load: Could not find internal betrokkene by id ' . $self->id
        ),
        return
    ) unless $bo = $self->dbic->resultset('Betrokkene')->find($self->id);

    ### TODO : NO idea yet if I really need this object
    $self->bo($bo);

    ### Retrieve data from internal GM
    return unless $bo->org_eenheid_id;

    $self->ldapid($bo->org_eenheid_id);

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
}

sub set {
    my ($self, $c, $external_id) = @_;

    ### Here we get a group gidNumber. We presume groups will get
    ### deleted from the system, so we create a betrokkene.
    my $identifier = $external_id . '-';

    $self->log->debug('M::B::OE->set called with identifier: ' . $identifier);

    # Load external id
    my $mwo = __PACKAGE__->new(
        'trigger'       => 'get',
        'c'             => $c,
        'id'            => $external_id,
        'intern'        => 0,
    );

    ### Let's do something EXTRA here. We do not want a new betrokkene for
    ### every time we create a medewerker. Medewerkers are 'static'

    ### Find betrokkene by id
    my $bo = $self->dbic->resultset('Betrokkene')->search({
        'btype'                     => 'org_eenheid',
        'org_eenheid_id'             => $mwo->ldapid,
    });

    if (!$bo->count) {
        ### Create betrokkene
        $bo = $self->dbic->resultset('Betrokkene')->create({
            'btype'                     => 'org_eenheid',
            'org_eenheid_id'            => $mwo->ldapid,
            'naam'                      => $mwo->naam,
        });
    } else {
        $bo = $bo->first;
    }

    return unless $bo;
    $identifier .= $bo->id;

    $self->log->debug('M::B::OE->set create identifier ' . $identifier);
    return $identifier;
}

sub get_by_uid {
    my ($self, $c, $uid) = @_;

    ### No die's
    return unless $c && $uid;

    ### Connect to our ldap directory
    my $ldap = $self->_connect_ldap($c) or
        (
            $self->log->debug('Failed connecting to ldap directory'),
            return
        );

    my $ldapsearch = $ldap->search(
        filter  => '(&(objectClass=posixGroup)(memberUid=' . $uid . '))',
        base    => 'ou=Groups,dc=bussum,dc=zaaksysteem,dc=nl'
    );

    $self->log->debug(Dumper($ldapsearch));
    $self->log->debug(Dumper({
        filter  => '(&(objectClass=posixGroup)(memberUid=' . $uid . '))',
        base    => 'ou=Groups,dc=bussum,dc=zaaksysteem,dc=nl'
    }));

    (
        $self->log->debug(
            'M::B::OE->load: Could not find external OE because LDAP '
            . ' returned an error: ' .  $ldapsearch->error_text
        ),
        return
    ) if $ldapsearch->is_error;

    return if $ldapsearch->count < 1;

    my $entry = $ldapsearch->shift_entry;

    return __PACKAGE__->new(
            'trigger'       => 'get',
            'c'             => $c,
            'id'            => $entry->get_value('gidNumber'),
            'extern'        => 1,
        );
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

