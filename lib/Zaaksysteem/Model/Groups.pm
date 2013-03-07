package Zaaksysteem::Model::Groups;

use strict;
use warnings;
use Net::LDAP;
use parent 'Catalyst::Model';

use Data::Dumper;

use Moose;

has 'c' => (
    'is'    => 'rw',
);

sub _connect_ldap {
    my ($self) = @_;

    my $ldap = Net::LDAP->new(
        $self->c->config->{authentication}->{realms}
            ->{zaaksysteem}->{store}->{ldap_server}
    );

    $ldap->bind;

    return $ldap;
}

sub is_member {
    my ($self, $gid) = @_;

    return unless $self->c->user_exists;

    ### Connect to our ldap directory
    my $ldap = $self->_connect_ldap or
        (
            $self->c->log->debug('Failed connecting to ldap directory'),
            return
        );

    my $usersearch = $ldap->search(
        filter  => '(&(objectClass=posixGroup)(memberUid='
            . $self->c->user->ldap_entry->dn
            . ')(gidNumber=' . $gid . '))',
        base    => $self->c->config->{customer}
            ->{start_config}
            ->{'LDAP'}
            ->{basedn}
    );


    return unless $usersearch->count;

    return 1;
}

sub return_roles_by_member {
    my ($self, $member) = @_;

    return unless $self->c->user_exists;

    ### Connect to our ldap directory
    my $ldap = $self->_connect_ldap or
        (
            $self->c->log->debug('Failed connecting to ldap directory'),
            return
        );

    my $usersearch = $ldap->search(
        filter  => '(&(objectClass=posixGroup)'
                    . '(memberUid=' . $member . '))',
        base    => $self->c->config->{customer}
            ->{start_config}
            ->{'LDAP'}
            ->{basedn}
    );

    $self->c->log->debug('Auth: ' .$self->c->config->{customer}
            ->{start_config}
            ->{'LDAP'}
            ->{basedn} . ':' . $member
            . ':' . $usersearch->count . ':'
            . '(&(objectClass=posixGroup)'
                    . '(memberUid=' . $member . '))'
    );

    return unless $usersearch->count;

    return $usersearch->entries;
}

sub search {
    my $self        = shift;

    ### Connect to our ldap directory
    my $ldap = $self->_connect_ldap or
        (
            $self->c->log->debug('Failed connecting to ldap directory'),
            return
        );

    my $usersearch = $ldap->search(
        filter  => '(&(objectClass=posixGroup))',
        base    => $self->c->config->{customer}
            ->{start_config}
            ->{'LDAP'}
            ->{basedn}
    );

    my @results = ();
    foreach my $entry ($usersearch->entries) {
        my $searchfail  = 0;
        my $dn          = $entry->dn;
        my $cn          = $entry->get_value('cn');
        my ($parent_ou) = $dn =~ /cn=$cn,ou=(.*?),/;


        push(@results, {
            'ou'            => $parent_ou,
            'naam'          => $entry->get_value('description'),
            'short_name'    => $cn,
            'id'            => $entry->get_value('gidNumber'),
        });

    }

    return $self->sort_by_depth(\@results);
}

sub get_ou_by_id {
    my $self        = shift;
    my $id          = shift;

    ### Connect to our ldap directory
    my $ldap = $self->_connect_ldap or
        (
            $self->c->log->debug('Failed connecting to ldap directory'),
            return
        );

    my $usersearch = $ldap->search(
        filter  => '(&(objectClass=organizationalUnit)(l=' . $id . '))',
        base    => $self->c->config->{customer}
            ->{start_config}
            ->{'LDAP'}
            ->{basedn}
    );

    return unless $usersearch->entry(0);

    return $usersearch->entry(0)->get_value('ou');
}

sub get_role_by_id {
    my $self        = shift;
    my $id          = shift;

    ### Connect to our ldap directory
    my $ldap = $self->_connect_ldap or
        (
            $self->c->log->debug('Failed connecting to ldap directory'),
            return
        );

    my $usersearch = $ldap->search(
        filter  => '(&(objectClass=posixGroup)(gidNumber=' . $id . '))',
        base    => $self->c->config->{customer}
            ->{start_config}
            ->{'LDAP'}
            ->{basedn}
    );

    return unless $usersearch->entry(0);

    return $usersearch->entry(0)->get_value('cn');
}

sub search_ou {
    my $self        = shift;

    ### Connect to our ldap directory
    my $ldap = $self->_connect_ldap or
        (
            $self->c->log->debug('Failed connecting to ldap directory'),
            return
        );

    my $usersearch = $ldap->search(
        filter  => '(&(objectClass=organizationalUnit))',
        base    => $self->c->config->{customer}
            ->{start_config}
            ->{'LDAP'}
            ->{basedn},
    );

    my @results = ();
    foreach my $entry ($usersearch->entries) {
        my $ou          = $entry->get_value('ou');

        push(@results,
            {
                ou  => $ou,
                id  => $entry->get_value('l')
            }
        );
    }

    return [ sort @results ];
}

sub sort_by_depth {
    my ($self, $rollen) = @_;

    my @sorted = sort { ($a->{ou}||'') cmp ($b->{ou}||'') } @{ $rollen };

    return \@sorted;
}

sub ACCEPT_CONTEXT {
    my ($self, $c) = @_;

    $self->c($c);

    return $self;
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

