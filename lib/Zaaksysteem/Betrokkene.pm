package Zaaksysteem::Betrokkene;

use strict;
use warnings;

use Scalar::Util;
use Data::Dumper;
use Params::Profile;

use Moose;

use Zaaksysteem::Betrokkene::Object::NatuurlijkPersoon;
use Zaaksysteem::Betrokkene::Object::Bedrijf;
use Zaaksysteem::Betrokkene::Object::Medewerker;
use Zaaksysteem::Betrokkene::Object::OrgEenheid;

use constant BOBJECT => __PACKAGE__ . '::Object';

my $BETROKKENE_TYPES = {
    'medewerker'            => 'Medewerker',
    'natuurlijk_persoon'    => 'NatuurlijkPersoon',
    'org_eenheid'           => 'OrgEenheid',
    'bedrijf'               => 'Bedrijf',
};


has [qw/prod log dbicg stash config customer/] => (
    'weak_ref' => 1,
    'is'    => 'rw',
);

has [qw/dbic/] => (
    'weak_ref' => 1,
    'is'    => 'rw',
);

has '_dispatch_options' => (
    'is'    => 'ro',
    'lazy'  => 1,
    'default'   => sub {
        my $self    = shift;

        my $dispatch = {
            prod    => $self->prod,
            log     => $self->log,
            dbic    => $self->dbic,
            dbicg   => $self->dbicg,
            stash   => $self->stash,
            config  => $self->config,
            customer => $self->customer
        };

        Scalar::Util::weaken($dispatch->{stash});

        return $dispatch;
    }
);

has 'c' => (
    'is'    => 'ro',
    'weak_ref'  => 1,
);

has 'types'     => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        return $BETROKKENE_TYPES;
    },
);


Params::Profile->register_profile(
    'method'        => 'search',
    'profile'       => {
        required    => [qw/
            type
        /],
        optional    => [qw/
            intern
        /],
        defaults    => {
            'intern'    => 1,
        },
        constraint_methods => {
            'type'      => sub {
                my ($dfv, $val) = @_;

                return (exists($BETROKKENE_TYPES->{$val}) ? 1 : undef);
            },
            'intern'    => qr/^\d*$/,
        }
    }
);

sub search {
    my $self        = shift;
    my $opts        = shift;
    my ($search)    = @_;

    return unless Params::Profile->validate('params' => $opts);

    (
        $self->log->debug( 'M::B->search(): No search parameters given' ),
        return
    ) unless ($search && UNIVERSAL::isa($search, 'HASH'));

    ### Because we do not strictly use the Data::FormValidator object, we have
    ### redefine the defaults here. Not a problem, we keep the information for
    ### the reader in above profile, and also for use in other controllers
    ###
    ### For get, this will be true: we search intern by default, with one but:
    ### it could be a special string, but that is something for the designated
    ### Betrokkene Class.
    $opts->{intern} = (exists($opts->{intern}) ? $opts->{intern} : 1);


    my $bclass      = __PACKAGE__ . '::Object::'
        . $BETROKKENE_TYPES->{ $opts->{type} };

    ### The following eval is not really needed, but because we do want to
    ### kill the object when we cannot make sure it is valid, we will die in
    ### the Object::{TYPE} class. Catch it here, and return undef
    my ($bo);
    eval {
        $bo = $bclass->search(
            $self->_dispatch_options,
            $opts,
            $search,
        );
    };

    ### This logging should be extra.
    (
        $self->log->debug('M::B->search() DIE: ' . $bclass . ':' . $@),
        return
    ) if $@;

    return $bo;

#    my $bclass   = BOBJECT;
#
#    my %object_opts = (
#        'c'             => $self->{c},
#        'search'        => 1,
#    );
#
#    #$opts{intern} = 1 if $internal;
#
#    my $zc = $bclass->new(
#        %object_opts
#    );
#
#    return $zc->search($opts->{type}, @_);
}


Params::Profile->register_profile(
    'method'        => 'get',
    'profile'       => {
        required    => [qw/
        /],
        optional    => [qw/
            type
            intern
        /],
        defaults    => {
            'intern'    => undef,
        },
        constraint_methods => {
            'type'      => sub {
                my ($dfv, $val) = @_;

                return (exists($BETROKKENE_TYPES->{$val}) ? 1 : undef);
            },
            'intern'    => qr/^\d*$/,
        }
    }
);

sub get {
    my $self    = shift;
    my $opts    = shift;
    my $id      = shift;

use Time::HiRes qw(tv_interval gettimeofday);
my $t0 = [gettimeofday];

    ### Validation and id?
    Params::Profile->validate('params' => $opts) or return;

    (
        $self->log->debug( 'M::B->get(): Invalid ID, not an integer' ),
        return
    ) unless $id && $id =~ /^[\d\-\w]+$/;

    ### We simply cannot continue, when we do not have a type, there is no
    ### pointer given about what kind of betrokkene this is and it is not a
    ### magic string
    unless (
        exists($opts->{type}) && $opts->{type}
    ) {
        my ($bid, $betrokkene_type);

        ### No internal pointer, we assume this is a 'magic' id or plain id
        if (!$id && (!exists($opts->{intern}) || !$opts->{intern})) {
            ### No magic string, and id is not a betrokkene id
            $self->log->debug(
                'M::B->get(): Not any idea where you want to '
                . ' get this information from, make sure you provide a'
                . ' betrokkene id (intern = 1) || at least an id'
            );
            return;
        }

        if ($id =~ /-/) {
            my ($req_type, $orig_id);

            if ($id =~ /^betrokkene-/) {
                $opts->{intern} = 0;
                ($opts->{type}, $id) = $id =~ /(\w+)-(\d+)$/;
            } else {
                $opts->{intern} = 1;
                ($req_type, $orig_id, $bid) = $id =~ /^([\w\_]*)-?(\d+)\-(\d+)$/;

                $self->log->debug('TRY Found REGTYPE');
                if ($req_type) {
                    $self->log->debug('Found REGTYPE');
                    $opts->{type} = $req_type;
                    $id =~ s/^[\w\_]+\-//g;
                }

            }
        }

        if ($opts->{intern} && !$bid) {
            $bid = $id;
        }

        ### Ok, fallback, id is probably a betrokkeneid
        if (!$bid && !$opts->{type}) {
            $bid = $id;
            $opts->{intern} = 1;
        }

        ### Get type from betrokkene database
        if (!$opts->{type}) {
            my $bdb = $self->dbic->resultset('ZaakBetrokkenen')->find($bid) or (
                $self->log->debug(
                    'M::B->get(): No betrokkene found by id ' .
                    $bid
                ),
                return
            );

            $opts->{type} = $bdb->betrokkene_type;
        }
    }

    $self->log->debug('LETS SEE: ' . $opts->{type} . ':' . $id);

    ### Because we do not strictly use the Data::FormValidator object, we have
    ### redefine the defaults here. Not a problem, we keep the information for
    ### the reader in above profile, and also for use in other controllers
    ###
    ### For get, this will be true: we search intern by default, with one but:
    ### it could be a special string, but that is something for the designated
    ### Betrokkene Class.
    $opts->{intern} = (exists($opts->{intern}) ? $opts->{intern} : undef);

    my $bclass      = __PACKAGE__ . '::Object::'
        . $BETROKKENE_TYPES->{ $opts->{type} };

    ### The following eval is not really needed, but because we do want to
    ### kill the object when we cannot make sure it is valid, we will die in
    ### the Object::{TYPE} class. Catch it here, and return undef
    my ($bo, $cache);

    my $bo_opts = {
        'trigger'       => 'get',
        'id'            => $id,
        %{ $self->_dispatch_options },
        %{ $opts }
    };

    if ($cache = $self->_bo_from_cache($bo_opts)) {
        return $cache;
    }

    eval {
        $bo = $bclass->new(%{ $bo_opts });
    };


    ### This logging should be extra.
    (
        $self->log->debug('M::B->get() DIE: ' . $@),
        return
    ) if $@;
    
    $self->_bo_set_cache($bo_opts, $bo);

    $self->log->debug("got betrokkene, took : " . tv_interval($t0, [gettimeofday]));

    return $bo;
}

sub _bo_set_cache {
    my ($self, $bo_opts, $bo) = @_;

    return unless $bo_opts->{stash};

    my $stash       = $bo_opts->{stash};

    my $cache_id    =
        'intern:' . ($bo_opts->{intern} || 0) . ';' .
        'extern:' . ($bo_opts->{extern} || 0) . ';' .
        'type:' . ($bo_opts->{type} || 0) . ';' .
        'id:' . ($bo_opts->{id} || 0) . ';';

    return ($stash->{'__Betrokkene_Cache'}->{$cache_id} = $bo);
}

sub _bo_from_cache {
    my ($self, $bo_opts) = @_;

    return unless $bo_opts->{stash};

    my $stash       = $bo_opts->{stash};

    my $cache_id    =
        'intern:' . ($bo_opts->{intern} || 0) . ';' .
        'extern:' . ($bo_opts->{extern} || 0) . ';' .
        'type:' . ($bo_opts->{type} || 0) . ';' .
        'id:' . ($bo_opts->{id} || 0) . ';';

    return unless $stash->{'__Betrokkene_Cache'}->{$cache_id};

    $self->log->debug('Retrieved betrokkene from cache: ' . $bo_opts->{id});
    return $stash->{'__Betrokkene_Cache'}->{$cache_id};
}

sub set {
    my ($self, $ident) = @_;
    my ($type, $id);

    return unless (($type, $id) = $ident =~ /betrokkene-(\w+)-(\d+)/);

    my $bclass      = __PACKAGE__ . '::Object::'
        . $BETROKKENE_TYPES->{ $type };

    my ($identifier);
    eval {
        $identifier  = $bclass->set($self->_dispatch_options, $id);
    };

    (
        $self->log->debug('M::B->get() DIE: ' . $@),
        return
    ) if $@;

    return $identifier;
}


sub create {
    my ($self, $type, $params) = @_;

    my $bclass      = __PACKAGE__ . '::Object::'
        . $BETROKKENE_TYPES->{ $type };

    my ($identifier);
    eval {

        $identifier  = $bclass->create($self->_dispatch_options, $params);
    };

    (
        $self->log->error('M::B->create() DIE: ' . $@),
        return
    ) if $@;

    return $identifier;
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

