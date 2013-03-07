package Zaaksysteem::Betrokkene::Object::Notes;

use strict;
use warnings;
use Moose;



has 'betrokkene'        => (
    'weak_ref'  => 1,
    'is'    => 'rw',
    'isa'   => 'Object',
);

has 'c' => (
    'weak_ref'  => 1,
    'is'    => 'rw',
);

has [qw/prod log dbic dbicg stash config/] => (
    'weak_ref'  => 1,
    'is'    => 'ro',
);

has 'list'          => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        my $exid    = $self->betrokkene->ex_id || 0;

        return $self->dbic->resultset('BetrokkeneNotes')->search(
            {
                betrokkene_exid => $self->betrokkene->ex_id,
                betrokkene_type => $self->betrokkene->btype
            },
            {
                order_by    => { -desc      => 'created' }
            }
        );
    },
);


sub add {
    my ($self, $note) = @_;

    $self->dbic->resultset('BetrokkeneNotes')->create(
        $note
    );

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

