package Zaaksysteem::Model::Regels;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model::Factory::PerRequest';

__PACKAGE__->config(
    class       => 'Zaaksysteem::Regels',
    constructor => 'new',
);


sub prepare_arguments {
    my ($self, $c) = @_;

    return {
        'log'       => $c->log,
        'dbic'      => $c->model('DB'),
    };
}

1;


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

