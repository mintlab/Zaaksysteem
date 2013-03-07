package Zaaksysteem::General::Authentication;

use strict;
use warnings;

use Data::Dumper;

use Scalar::Util qw/blessed/;
use Net::LDAP;

use Zaaksysteem::Constants qw/
    ZAAKSYSTEEM_AUTHORIZATION_ROLES
    ZAAKSYSTEEM_AUTHORIZATION_PERMISSIONS
    ZAAKSYSTEEM_CONSTANTS
/;


sub assert_zaak_permission {
    my $c = shift;

    return 1 if $c->check_zaak_permission(@_);

    $c->forward('/forbidden');
    $c->detach();

    return;
}

sub check_zaak_permission {
    my ($c, $permission) = @_;

    return unless $c->stash->{zaak};
    return unless $c->user_exists;

    my $bid     = $c->user->uidnumber or return;

    my $bo      = $c->model('Betrokkene')->get(
        {
            extern  => 1,
            type    => 'medewerker',
        },
        $bid
    );

    return unless $bo->org_eenheid;

    my $orgid = $bo->org_eenheid->ldapid;

    if (
        $c->stash->{zaak}->kenmerk->behandelaar &&
        $c->stash->{zaak}->kenmerk->behandelaar->id eq $bo->id
    ) {
        return 1;
    }

    if (
        $c->stash->{zaak}->kenmerk->zaakeigenaar &&
        $c->stash->{zaak}->kenmerk->zaakeigenaar->id eq $bo->id
    ) {
        return 1;
    }

#    if (
#        $c->stash->{zaak}->kenmerk->aanvrager &&
#        $c->stash->{zaak}->kenmerk->aanvrager->id eq $bo->id
#    ) {
#        return 1;
#    }
#
    if (
        $c->check_user_role('manager') &&
        $c->stash->{zaak}->kenmerk->aanvrager &&
        $c->stash->{zaak}->kenmerk->aanvrager->id eq $bo->org_eenheid->id
    ) {
        return 1;
    }

    if (
        $c->stash->{zaak}->kenmerk->org_eenheid &&
        $c->stash->{zaak}->kenmerk->org_eenheid->id eq $bo->org_eenheid->id
    ) {
        return 1;
    }


    $c->forward('/forbidden');
    $c->detach();

    return;
}

sub assert_permission {
    my $c = shift;

    return 1 if $c->check_permission(@_);

    $c->forward('/forbidden');
    $c->detach();

    return;
}

sub check_permission {
    my ($c, @roles)  = @_;


    if ($c->check_user_role(qw/admin/)) {
        return 1;
    }

    return unless $c->stash->{zaak};

    if (
        blessed($c->stash->{zaak}->kenmerk->zaakeigenaar) &&
        $c->stash->{zaak}->kenmerk->zaakeigenaar->ex_id == $c->user->uidnumber
    ) {
        return 1;
    }

    $c->log->debug(
        'Check permission(s): ' .
        join(', ', @roles)
    );

    my $success;
    for my $role (@roles) {
        return unless ZAAKSYSTEEM_CONSTANTS->{'authorisation'}
            ->{rechten}->{$role};

        my $auths = $c->stash->{zaak}->zaaktype_id->zaaktype_authorisations
            ->search(
                {
                    recht   => $role,
                }
            );

        next unless $auths->count;

        while (my $auth = $auths->next) {
            $success = $auth->recht if $c->model('Groups')->is_member(
                $auth->group_id
            );
        }
    }

    return unless $success;

    $c->log->debug('Granted permission: ' . $success);

    return 1;
}

### XXX BELOW IS NEW STYLE
sub _get_ldap_role {
    my ($self, $role) = @_;

    return ZAAKSYSTEEM_AUTHORIZATION_ROLES->{ $role }->{'ldapname'};
}

sub check_any_user_permission {
    my ($c, @check_permissions) = @_;

#    $c->log->debug(
#        '$c->check_any_user_permission: check for logged in user,'
#        . ' caller: ' . [caller(1)]->[3] . ' / ' . [caller(2)]->[3]
#    );
    return unless $c->user_exists;

#    $c->log->debug(
#        '$c->check_any_user_permission: logged in user,'
#        . ' get permissions'
#    );
    my @permissions = $c->get_user_permissions;
    return unless @permissions;

#    $c->log->debug(
#        '$c->check_any_user_permission: logged in user,'
#        . ' check permissions: ' . join(',', @permissions)
#    );
#    $c->log->debug(
#        'AUTH: User permissions: ' . join(', ', @permissions)
#    );

    ### SPECIAL Always push special permissions: admin to the list of checking
    push (@check_permissions, qw/admin/);

    for my $checkpermission (@check_permissions) {
        if (grep(/^$checkpermission$/, @permissions)) {
            return 1;
        }
    }
}

sub assert_any_user_permission {
    my ($c, @permissions) = @_;

    return 1 if $c->check_any_user_permission(@permissions);

    $c->forward('/forbidden');
    $c->detach();

    return;
}

sub check_any_zaak_permission {
    my ($c, @check_permissions) = @_;

#    $c->log->debug(
#        '$c->check_any_zaak_permission: check for zaak and logged in user,'
#        . ' caller: ' . [caller(1)]->[3] . ' / ' . [caller(2)]->[3]
#    );

    ### Zaak exists?
    return unless $c->stash->{zaak};

    ### User exists?
    return unless $c->user_exists;

#    $c->log->debug(
#        '$c->check_any_zaak_permission: zaak found and user logged in'
#    );

    ### First, check if user is allowed to view zaken
    unless (
        $c->check_any_user_permission(
            'gebruiker'
        )
    ) {
        $c->flash->{result} = 'Geen toegang: u heeft geen rechten'
            .' om zaken te bekijken [!gebruiker]';

        return;
    }

    ### Admins have special rightos
#    $c->log->debug(
#        '$c->check_any_zaak_permission: checking for admin'
#    );

    return 1 if $c->check_any_user_permission('admin');

    ### Info about betrokkene
    my $orgeenheid;
    {
        my $bid     = $c->user->uidnumber or return;
#        $c->log->debug(
#            '$c->check_any_zaak_permission: checking for'
#            .' betrokkene medewerker'
#        );

        my $bo      = $c->model('Betrokkene')->get(
            {
                extern  => 1,
                type    => 'medewerker',
            },
            $bid
        );

        $c->log->debug(
            '$c->check_any_zaak_permission: checking for behandelaar status'
        );
        if (
            $c->stash->{zaak}->behandelaar &&
            $c->stash->{zaak}->behandelaar->gegevens_magazijn_id eq $bo->ldapid
        ) {
            return 1;
        }

        $c->log->debug(
            '$c->check_any_zaak_permission: checking for coordinator status'
        );
        if (
            $c->stash->{zaak}->coordinator &&
            $c->stash->{zaak}->coordinator->gegevens_magazijn_id eq $bo->ldapid
        ) {
            return 1;
        }

        if (
            $c->stash->{zaak}->aanvrager &&
            ($c->stash->{zaak}->aanvrager->gegevens_magazijn_id eq $bo->ldapid) &&
            ($c->stash->{zaak}->aanvrager->betrokkene_type == 'medewerker')
        ) {
            return 1;
        }

        $orgeenheid = $bo->org_eenheid or return;
    }

    ### Loop over roles in zaaktype information
    my $authroles = $c->stash->{zaak}->zaaktype_id->zaaktype_authorisaties->search;

    ### Damn system not giving me role ids, we have to find out ourself
    ### Retrieve all ldaproles
    my $ldaproles = $c->model('Groups')->search;

    #$c->log->debug('Authrole: ldaproles: ' . Dumper($ldaproles));

    ### Strip those from ldaproles which user does not have
    my @userldaproles = $c->user->roles;

    $c->log->debug('Authrole: userroles: ' . Dumper(\@userldaproles));

    $c->log->debug(
        '$c->check_any_zaak_permission: checking zaaktype permissions'
        . ' for permissions: ' . join(',', @check_permissions)
    );
    my %hasldaproles;
    for my $ldaprole (@{ $ldaproles }) {
        if (grep {
                $ldaprole->{short_name} eq $_
            } @userldaproles
        ) {
            $hasldaproles{$ldaprole->{id}} = 1;
        }
    }

#    $c->log->debug('Authrole: hasldaproles: ' . Dumper(\%hasldaproles));

    while (my $authrole = $authroles->next) {
        ### Ou id not same as org_eenheid id from this user?
        if ($authrole->ou_id && $orgeenheid->ldapid ne $authrole->ou_id) {
            next;
        }
#        $c->log->debug(
#            '$c->check_any_zaak_permission: check permission '
#            . $authrole->recht
#        );

        if ($hasldaproles{$authrole->role_id}) {
            if (grep {
                    $_ eq $authrole->recht
                } @check_permissions
            ) {
#                $c->log->debug(
#                    '$c->check_any_zaak_permission: found permission'
#                    . $authrole->recht
#                );
                return 1;
            }
        }
    }


    return;
}

sub assert_any_zaak_permission {
    my ($c, @permissions) = @_;

    return 1 if $c->check_any_zaak_permission(@permissions);

    $c->forward('/forbidden');
    $c->detach();

    return;
}

sub get_user_permissions {
    my ($c)     = @_;
    my $dv      = {};

    return () unless $c->user_exists;

    my @ldaproles       = $c->user->roles;
    my $zs_auth_roles   = ZAAKSYSTEEM_AUTHORIZATION_ROLES;

#    $c->log->debug(
#        '$c->get_user_permissions: logged in user,'
#        . ' got permissions: ' . join(',', @ldaproles)
#    );
    for my $ldaprole (@ldaproles) {
        for my $permission_group (values %{ $zs_auth_roles }) {
            if (
                $permission_group->{ldapname} eq $ldaprole &&
                defined($permission_group->{rechten}) &&
                defined($permission_group->{rechten}->{global})
            ) {
                $dv->{ $_ } = 1
                    for keys %{ $permission_group->{rechten}->{global} };
            }
        }
    }

    return keys %{ $dv };
}

sub check_user_role {
    my ($c, @roles) = @_;

    return unless $c->user_exists;

    my @ldaproles = $c->user->roles;

#    $c->log->debug(
#        'AUTH: Requesting check for roles: '
#        . join(', ', @roles)
#    );

    my $zs_auth_roles   = ZAAKSYSTEEM_AUTHORIZATION_ROLES;

    my @permissions;
    for my $check_role (@roles) {
        next unless $zs_auth_roles->{$check_role};

        if (grep {
                $_ eq $zs_auth_roles->{$check_role}->{ldapname}
            } @ldaproles
        ) {
#            $c->log->debug('AUTH: Found role: '
#                . $check_role . ' in LDAP store'
#            );

            return 1;
        }
    }

#    $c->log->debug(
#        'AUTH: Did not find requested roles'
#        . ' in LDAP store'
#    );

    return;
}

sub list_available_permissions {
    my ($c) = @_;

    return ZAAKSYSTEEM_AUTHORIZATION_PERMISSIONS;
}

sub assert_user_role {
    my ($c, @roles) = @_;

    return 1 if $c->check_user_role(@roles);

    $c->forward('/forbidden');
    $c->detach();

    return;
}

sub user_betrokkene {
    my ($c) = @_;

    return unless (ref($c) && $c->user_exists && $c->user);

    my $betrokkene_id   = $c->user->uidnumber;

    my $betrokkene_obj  = $c->model('Betrokkene')->get(
        {
            extern  => 1,
            type    => 'medewerker',
        },
        $betrokkene_id
    );

    return unless $betrokkene_obj;
    return $betrokkene_obj;
}

sub user_ou_id {
    my ($c) = @_;

    my $betrokkene_obj  = $c->user_betrokkene
        or return;

    return $betrokkene_obj->org_eenheid->ldapid
        if $betrokkene_obj->org_eenheid;
    return;
}

sub user_roles {
    my ($c) = @_;

    return unless (ref($c) && $c->user_exists && $c->user);
    return $c->user->roles;
}

sub user_roles_ldap {
    my ($c) = @_;

    return unless (ref($c) && $c->user_exists && $c->user);

    my @entries = $c->model('Groups')->return_roles_by_member(
        $c->user->ldap_entry->dn
    );

    return @entries;
}

sub user_roles_ids {
    my ($c) = @_;
    my @ids;

    my @entries   = $c->user_roles_ldap
        or return;

    for my $entry (@entries) {
        push(@ids, $entry->get_value('gidNumber'));
    }

    return @ids;
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

