package Zaaksysteem::Zaken::Roles::RouteObjecten;

use Moose::Role;
use Data::Dumper;


around 'set_volgende_fase' => sub {
    my $orig                = shift;
    my $self                = shift;

    ### Check current route
    my $set_volgende_fase   = $self->$orig(@_);

    if ($set_volgende_fase) {
        ### Turned OFF, wordt nu geregeld via Fase Afronden pagina
        #$self->_set_role_ou($self->huidige_fase);
    }

    return $set_volgende_fase;
};

sub _set_role_ou {
    my $self        = shift;
    my $fase        = shift;

    return unless $fase;
    #return 1;

    if (
        $self->route_ou eq $fase->ou_id &&
        $self->route_role eq $fase->role_id
    ) {
        return 1;
    }

    $self->route_ou     ( $fase->ou_id);
    $self->route_role   ( $fase->role_id);

    $self->status               ('new');
    $self->behandelaar          (undef);
    $self->behandelaar_gm_id    (undef);

    $self->update;
}

sub wijzig_route {
    my $self        = shift;
    my $route_ou    = shift;
    my $route_role  = shift;

    return unless $route_ou && $route_role;

    $self->route_ou     ( $route_ou );
    $self->route_role   ( $route_role );

    $self->status               ('new');
    $self->behandelaar          (undef);
    $self->behandelaar_gm_id    (undef);

    $self->update;
}

sub _bootstrap_route {
    my $self    = shift;

    if (!$self->route_ou && !$self->route_role) {
        $self->_set_role_ou($self->huidige_fase);
    }

    return 1;
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

