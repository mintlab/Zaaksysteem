package Zaaksysteem::LDAP::User;

use warnings;
use strict;

use base 'Catalyst::Authentication::Store::LDAP::User';

sub user_ou {
    my $self    = shift;

    my $ldap    = $self->store->ldap_bind;

    my ($ou)    = $self->ldap_entry->dn =~ /ou=(.*?),/;

    ### First, remove all memberships
    my $roles   = $ldap->search( # perform a search
        base   => $self->store->user_basedn,
        filter => "(&(objectClass=organizationalUnit)(ou=$ou))",
    );

    return unless $roles->count;

    return $roles->entry(0);
}

sub get_roles {
    my $self    = shift;

    my $ldap    = $self->store->ldap_connect;

    my $dn      = $self->ldap_entry->dn;

    ### First, remove all memberships
    my $roles   = $ldap->search( # perform a search
        base   => $self->store->user_basedn,
        filter => "(&(objectClass=posixGroup)(memberUid=$dn))",
    );

    next unless $roles->count;

    return $roles->entries;
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

