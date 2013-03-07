package Zaaksysteem::SBUS::Objecten::ADR;

use Moose;

use Zaaksysteem::SBUS::Types::StUF::ADR;

has 'capability'    => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        return {
            StUF    => 1,
        };
    },
);

extends qw/Zaaksysteem::SBUS::Objecten/;

### options contains
### {
###     traffic_object
###     mutatie_type
### }
sub _commit_to_database {
    my ($self, $create, $options) = @_;

    $create->{object_type}  = 'ADR';

    return $self->app->model('DBG')->resultset('BagNummeraanduiding')
        ->import_entry(
            $self->app,
            $create,
            $options
        );
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

