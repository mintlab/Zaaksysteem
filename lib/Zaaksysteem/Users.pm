package Zaaksysteem::Users;

use strict;
use warnings;

use Params::Profile;
use Data::Dumper;
use Zaaksysteem::Constants;

use Net::LDAP;

use Moose;
use namespace::autoclean;

use constant    INTERNAL_USERS  => [qw/admin/];
use constant    OBJECT_CLASSES  => [qw/
    inetOrgPerson
    person
    posixAccount
    shadowAccount
    top
/];

use constant    LDAP_COLUMNS    => [qw/
    cn
    sn
    displayName
    givenName
    mail
    telephoneNumber

    homeDirectory
    userPassword
    uid
    uidNumber
    gidNumber
    loginShell
    initials
/];

use constant    LDAP_TRANSLATE_DEPARTMENTS  => {
    'Directie'                  => 'Directieteam',
    'Sociale zaken'             => 'Sociale_Zaken',
    'SoZa'                      => 'Sociale_Zaken',
    'Vergunningen & Handhaving' => 'V&H',
    'Ruimtelijke Inrichting'    => 'RI',
    'Ruimte'                    => 'RI',
    'Sociale Zaken'             => 'Sociale_Zaken',
    'Burgemeester & Wethouders' => 'College',
    'Soziale Zaken'             => 'Sociale_Zaken',
    'Planvoorbereiding en Groenbeheer'  => 'Planvoorbereiding en Groenbeheer',
    'Facilitaire zaken, Receptie en ICT beheer' => 'Facilitaire zaken, Receptie en ICT beheer',
    'DIV en communicatie en WenB werken'   => 'DIV en communicatie en WenB werken',
};


has [qw/customer config prod log ldap _ldaph uidnumber/] => (
    'is'    => 'rw',
);

has 'components'            => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        return [qw/sync_users sync_password/];
    }
);

has 'uidnumber_start'            => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        return 55100;
    }
);

has 'uidnumber'            => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        return shift->uidnumber_start;
    }
);

has 'ldapbase'              => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        return shift->customer->{start_config}->{LDAP}->{basedn};
    }
);


sub ldaph {
    my $self    = shift;

    return $self->_ldaph if $self->_ldaph;

    my $ldap = Net::LDAP->new(
        $self->config
        ->{authentication}
        ->{realms}
        ->{zaaksysteem}
        ->{store}
        ->{ldap_server}
    ) or return;

    $self->log->debug('- Connected to LDAP') if $ldap;

    $ldap->bind($self->config->{LDAP}->{admin},
        password    => $self->config->{LDAP}->{password}
    );

    return $self->_ldaph($ldap);
}

sub sync_users {
    my $self    = shift;
    my $users   = shift;

    $self->log->info('Start synchronizing AD users');

    my $ldap            = $self->ldaph;
    my $local_users     = $self->_retrieve_local_users($ldap);

    my $compared_users  = $self->_compare_users($ldap, $local_users, $users->{Bussum});

    $self->_load_ldap($ldap, $compared_users, $local_users);
}

sub _load_ldap {
    my ($self, $ldap, $compared_users, $local_users)   = @_;

    $self->_modify_ldap($ldap, $compared_users->{modify}, $local_users);
    $self->_create_ldap($ldap, $compared_users->{create});
}

sub _create_ldap {
    my ($self, $ldap, $compared_users)   = @_;

    my $ldap_departments    = LDAP_TRANSLATE_DEPARTMENTS;
    my $departments = {};
    for my $username (keys %{ $compared_users }) {
        ### Define DN, check for existence
        my $ou  = 'Temp';
        if ($compared_users->{ $username }->{department}) {
            my $department = $compared_users->{ $username }->{department};

            $department    = $ldap_departments->{$department}
                if $ldap_departments->{$department};

            my $sh      = $ldap->search( # perform a search
                base   => $self->ldapbase,
                filter => "(&(objectClass=organizationalUnit)(ou=" .
                    $department
                    . "))"
            );

            if ($sh->count) {
                $self->log->debug('- Found department: ' .
                    $department
                );

                $ou = $department
            } else {
                $departments->{ $department }
                = 1;
            }
        }

        my $dn  = "cn=$username,ou=$ou,". $self->ldapbase;

        my $add = {};

        for my $column (keys %{
                $self->_return_clean_user($compared_users->{$username})
            }
        ) {
            $add->{$column} =
                $compared_users->{$username}->{$column};
        }

        if ($compared_users->{$username}->{force_uidNumber}) {
            $add->{uidNumber} = $add->{gidNumber} =
                $compared_users->{$username}->{force_uidNumber};
        } else {
            $self->uidnumber($self->uidnumber + 1);
            $add->{uidNumber} = $self->uidnumber;
            $add->{gidNumber} = $self->uidnumber;
        }

        ### DO LDAP
        #$self->log->debug('- ADD LDAP: ' . Dumper([$dn,$add]));
        $self->log->info('- ADD USER: ' . $dn);

        my $result = $ldap->add(
            $dn,
            attr        => [
                %{ $add },
                objectclass => OBJECT_CLASSES
            ],
        );
        $result->code && $self->log->error("failed to add entry: $dn : ", $result->error
            . ' / ' . Dumper($add)
        );

        if (!$result->code) {
            $self->_handle_role($ldap,$dn);
        }
    }

    $self->log->info('Departments NOT FOUND: ' . "\n" . join("\n", keys %{
                $departments })) if scalar(keys %{ $departments });
}

sub _handle_role {
    my ($self, $ldap, $dn)  = @_;

    $self->log->debug('- Roles: Adding ' . $dn . ' to Behandelaar');

    my $sh      = $ldap->search( # perform a search
        base   => $self->ldapbase,
        filter => "(&(objectClass=posixGroup)(cn=Behandelaar))",
    );

    return unless $sh->count;

    my $behandelaar = $sh->entry(0);

    $sh      = $ldap->search( # perform a search
        base   => $self->ldapbase,
        filter => "(&(objectClass=posixGroup)(cn=Behandelaar)(memberUid=$dn))",
    );

    return 1 if $sh->count;

    my $result = $ldap->modify(
        $behandelaar->dn,
        changes => [
            add     => [
                memberUid   => $dn
            ],
        ]
    );
    $result->code && $self->log->error("failed to add role: $dn : ", $result->error);
}

sub _delete_ldap {
    my ($self, $ldap, $compared_users, $local_users, $force)   = @_;

    for my $username (keys %{ $compared_users }) {
        my $dn      = $local_users->{$username}->{dn};

        #$self->log->debug('- REMOVE LDAP: ' . Dumper([$dn]));
        #$self->log->info('- ADD USER: ' . $dn);

        if ($force) {
            my $result = $ldap->delete( $dn );
            $result->code && $self->log->error("failed to remove entry: $dn : ", $result->error);
        }
    }
}

sub _return_clean_user {
    my ($self, $userdata) = @_;

    my $rv = {};

    my $columns = LDAP_COLUMNS;

    for my $column (@{ $columns }) {
        next unless $userdata->{$column};
        $rv->{ $column } = $userdata->{$column};
    }

    return $rv;
}

sub _modify_ldap {
    my ($self, $ldap, $compared_users, $local_users)   = @_;

    for my $username (keys %{ $compared_users }) {
        my $dn      = $local_users->{$username}->{dn};

        ### Check for Temp as ou, then check the department
        my ($ou)    = $dn =~ /ou=(.*?),/;

        if (
            $ou eq 'Temp' &&
            $compared_users->{ $username }->{department}
        ) {
            $self->log->info(
                'Found user in Temp, try to create it in '
                .'correct OU by removing this user and creating a new one'
            );
            #Skip this user, create a new user and delete current user
            $self->_delete_ldap(
                $ldap,
                {
                    $username => $compared_users->{$username},
                },
                $local_users,
                1
            );

            $compared_users->{$username}->{force_uidNumber} =
                $local_users->{$username}->{uidNumber};

            $self->_create_ldap(
                $ldap,
                {
                    $username => $compared_users->{$username},
                },
                $local_users
            );

            next;
        }

        delete($local_users->{dn});

        my $modify  = {};

        for my $column (keys %{
                $self->_return_clean_user(
                    $compared_users->{ $username }
                )
            }
        ) {
            next if ($column eq 'gidNumber' || $column eq 'uidNumber');

            if (defined($local_users->{$username}->{$column})) {
                if (
                    $local_users->{$username}->{$column} eq
                    $compared_users->{$username}->{$column}
                ) {
                    next;
                }
                $modify->{replace} = [] unless $modify->{replace};
                push(@{ $modify->{replace} }, $column => $compared_users->{$username}->{$column});
            } else {
                $modify->{add} = [] unless $modify->{add};
                push(@{ $modify->{add} }, $column => $compared_users->{$username}->{$column});
            }
        }

        if (!scalar(keys(%{ $modify }))) {
            next;
        }

        my $result = $ldap->modify(
            $dn,
            changes => [
                %{ $modify }
            ]
        );
        $result->code && $self->log->error("failed to add entry: $dn : ", $result->error
            . ' / ' . Dumper($modify)
        );

        if (!$result->code) {
            $self->_handle_role($ldap,$dn);
        }

        ### DO LDAP
        $self->log->info('- Modified user: ' . $dn);
    }
}

sub _compare_users {
    my ($self, $ldap, $local_users, $users) = @_;

    my $rv = {
        'modify'    => {},
        'create'    => {},
        'delete'    => {},
    };

    for my $username (keys %{ $users }) {
        $username       = lc($username);
        my $userdata    = $users->{$username};

        ### Required
        next unless $userdata->{sn};

        $userdata->{homeDirectory}  = '/home/' . $username;
        $userdata->{loginShell}     = '/bin/bash';
        $userdata->{uid}            = $username;

        $userdata->{initials}       = $userdata->{givenName};
        $userdata->{initials}       =~ s/( ?[a-zA-Z])\w+/$1./g;

        if (
            defined($local_users->{$username}) &&
            $local_users->{$username}->{userPassword} &&
            !$userdata->{userPassword}
        ) {
            $userdata->{userPassword} = $local_users->{$username}->{userPassword};
        }

        $userdata->{initials}       =~ s/( ?[a-zA-Z])\w+/$1./g;

        if (!$local_users->{$username}) {
            $rv->{create}->{$username}  = $userdata;
            next;
        }

        ### Edit
        $rv->{modify}->{$username}      = $userdata;
    }

    for my $username (keys %{ $local_users }) {
        if (!$users->{$username}) {
            $rv->{delete}->{$username}  = $users->{$username};
        }
    }

    return $rv;
}

sub _retrieve_local_users {
    my $self    = shift;
    my $ldap    = shift;

    $self->log->info('- Retrieve all users for comparison');

    my $sh      = $ldap->search( # perform a search
        base   => $self->ldapbase,
        filter => "(&(objectClass=posixAccount))"
    );

    return {} unless $sh->count;

    my @entries = $sh->entries;
    my $columns = LDAP_COLUMNS;

    my $local_users = {};

    my $uidNumber   = 0;

    for my $entry (@entries) {
        my $rv = {};
        for my $column (@{ $columns }) {
            $rv->{ $column } = $entry->get_value($column)
                if $entry->exists($column);
        }

        $rv->{dn}   = $entry->dn;

        if ($entry->get_value('uidNumber') > $uidNumber) {
            $uidNumber = $entry->get_value('uidNumber');
        }

        $local_users->{ lc($entry->get_value('cn')) } = $rv;
    }

    if ($uidNumber > $self->uidnumber_start) {
        $self->uidnumber($uidNumber);
    }

    $self->log->info('UIDNUMBER' . $uidNumber);

    return $local_users;
}

sub sync_user {
    my $self    = shift;
}

sub get_all_roles {
    my $self    = shift;
    my $ldap    = $self->ldaph;
    my $rv      = [];

    my $sh      = $ldap->search( # perform a search
        base   => $self->ldapbase,
        filter => "(&(objectClass=posixGroup))"
    );

    return $rv unless $sh->count;

    my @roles;

    for my $entry ($sh->entries) {
        my ($ou)    = $entry->dn =~ /ou=(.*?),/;

        my $role    = {
            dn  => $entry->dn,
            cn  => $entry->get_value('cn'),
        };

        $role->{ou} = $ou if $ou;

        push(@roles, $role);
    }

    return \@roles;
}

sub get_all_medewerkers {
    my $self    = shift;
    my $ldap    = $self->ldaph;
    my $rv      = [];

    my $sh      = $ldap->search( # perform a search
        base   => $self->ldapbase,
        filter => "(&(objectClass=posixAccount))"
    );

    return $rv unless $sh->count;

    my @entries = $sh->entries;

    for my $entry (@entries) {
        my $mw      = {};
        my $dn      = $entry->dn;

        $mw->{ $_ } = $entry->get_value($_) for
            qw/cn displayName uid uidNumber/;

        ### Get OU
        my ($ou)    = $dn =~ /ou=(.*?),/;

        $mw->{ou}   = $ou;

        ### Get roles
        my $roles   = $ldap->search( # perform a search
            base   => $self->ldapbase,
            filter => "(&(objectClass=posixGroup)(memberUid=$dn))",
        );

        my %roles;
        if ($roles->count) {
            for my $role ($roles->entries) {
                $roles{$role->dn} = 1;
            }
        }

        $mw->{roles}    = \%roles;

        push(@{ $rv }, $mw);
    }

    return $rv;
}

sub deploy_user_in_roles {
    my ($self, $username, $userroles) = @_;

    my $ldap    = $self->ldaph;

    my $sh      = $ldap->search( # perform a search
        base   => $self->ldapbase,
        filter => "(&(objectClass=posixAccount)(cn=$username))"
    );

    return unless $sh->count;

    my $user    = $sh->entry(0);
    my $dn      = $user->dn;

    ### First, remove all memberships
    my $roles   = $ldap->search( # perform a search
        base   => $self->ldapbase,
        filter => "(&(objectClass=posixGroup)(memberUid=$dn))",
    );

    for my $role ($roles->entries) {
        my $result = $ldap->modify(
            $role->dn,
            delete  => {
                memberUid   => $user->dn,
            }
        );

        $result->code && $self->log->error("failed to delete memberUid: " .
            $user->dn . " : ", $result->error);
    }

    ### Add entries
    for my $role (@{ $userroles }) {
        my $result = $ldap->modify(
            $role,
            add  => {
                memberUid   => $user->dn,
            }
        );

        $result->code && $self->log->error("failed to add memberUid: " .
            $user->dn . " : ", $result->error);
    }
}

sub get_role_by_id {
    my ($self, $role_id) = @_;

    my $ldap    = $self->ldaph;

    ### First, remove all memberships
    my $roles   = $ldap->search( # perform a search
        base   => $self->ldapbase,
        filter => "(&(objectClass=posixGroup)(gidNumber=$role_id))",
    );

    return unless $roles->count;

    return $roles->entry(0);
}

sub get_ou_by_id {
    my ($self, $ou_id) = @_;

    my $ldap    = $self->ldaph;

    ### First, remove all memberships
    my $ous   = $ldap->search( # perform a search
        base   => $self->ldapbase,
        filter => "(&(objectClass=organizationalUnit)(l=$ou_id))",
    );

    return unless $ous->count;

    return $ous->entry(0);
}


__PACKAGE__->meta->make_immutable;



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

