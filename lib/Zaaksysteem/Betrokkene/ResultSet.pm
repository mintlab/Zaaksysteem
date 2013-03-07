package Zaaksysteem::Betrokkene::ResultSet;

use strict;
use warnings;

use Moose;

has opts    => (
    is      => 'rw',
);

has dbic_rs => (
    is      => 'rw',
);

has ldap_rs => (
    'is'    => 'rw',
);

has class   => (
    'is'    => 'rw',
);

has [qw/prod log dbic dbicg stash config customer/] => (
    'weak_ref' => 1,
    'is'    => 'ro',
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
            customer => $self->customer,
        };

        Scalar::Util::weaken($dispatch->{stash});

        return $dispatch;
    }
);

has pointer => (
    'is'    => 'rw',
);


sub next {
    my ($self) = @_;

    if (
        $self->opts->{type} ne 'natuurlijk_persoon' &&
        $self->opts->{type} ne 'bedrijf'
    ) {
        return $self->_next_ldap;
    } else {
        return $self->_next_dbic;
    }
}

sub first {
    my ($self) = @_;

    $self->reset;
    return $self->next;
}

sub reset {
    my ($self) = @_;

    if (
        $self->opts->{type} ne 'natuurlijk_persoon' &&
        $self->opts->{type} ne 'bedrijf'
    ) {
        return $self->pointer(0);
    } else {
        return $self->dbic_rs->next;
    }
}

sub count {
    my ($self) = @_;

    if (
        $self->opts->{type} ne 'natuurlijk_persoon' &&
        $self->opts->{type} ne 'bedrijf'
    ) {
        return scalar(@{ $self->ldap_rs });
    } else {
        return $self->dbic_rs->count;
    }
}

sub _next_ldap {
    my ($self) = @_;

    my $bclass = $self->class;

    if (!$self->pointer) {
        $self->pointer(0);
    }

    my $record = $self->ldap_rs->[$self->pointer];

    ### XXX TODO
    ### Small org_eenheid protection, do not show 'users' group
    if (
        $record &&
        $self->{opts}->{type} eq 'org_eenheid' &&
        $record->get_value('ou') eq 'users'
    ) {
        $self->pointer(
            $self->pointer + 1
        );

        $record = $self->ldap_rs->[$self->pointer];
    }

    return unless $record;

    $self->pointer(
        $self->pointer + 1
    );

   # $self->c->log->debug('Hier dan??');
    return $bclass->new(
        trigger => 'get',
        id      => (
            ($self->{opts}->{type} eq 'medewerker')
                ? $record->get_value('uidNumber')
                : $record->get_value('l')
        ) || 0,
        %{ $self->opts },
        %{ $self->_dispatch_options },
    );
}

sub _next_dbic {
    my ($self) = @_;

    my $bclass = $self->class;

    my $record = $self->dbic_rs->next;

    return unless $record;

    my $record_id;
    if (
        $self->opts->{type} eq 'natuurlijk_persoon'
    ) {
        my $first_person;
        if (
            !$record->natuurlijk_persoons ||
            !($first_person = $record->natuurlijk_persoons->first)
        ) {
            return $self->_next_dbic;
        }
        $record_id = $first_person->id;
    } else {
        $record_id = $record->id;
    }

    my $object;
    
    eval {
        $object = $bclass->new(
            trigger => 'get',
            id      => $record_id,
            %{ $self->opts },
            %{ $self->_dispatch_options },
        );
    };

    if ($@) {
        my $errmsg = 'Error opening this record, looping to next: ' . $@;
        $self->c->log->error($errmsg);
        return $self->_next_dbic;
    }

    return $object;
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

