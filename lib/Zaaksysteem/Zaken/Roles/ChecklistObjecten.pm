package Zaaksysteem::Zaken::Roles::ChecklistObjecten;

use Moose::Role;
use Data::Dumper;


sub is_checklist_compleet {
    my $self    = shift;

    my $fasen   = $self->zaaktype_node_id
        ->zaaktype_statussen
        ->search(
            status  => $self->volgende_fase->status
        );

    my $fase    = $fasen->first or die('Er is geen volgende fase');

    my $vragen  = $fase->zaaktype_checklists->search;

    my $error   = 0;

    while (my $vraag    = $vragen->next) {
        my $antwoorden = $self->checklist->search(
            vraag_id    => $vraag->id,
        );

        if (!$antwoorden->count) {
            $error = 1;
        }
    }

    return 1 unless $error;
    return;
}

around 'can_volgende_fase' => sub {
    my $orig    = shift;
    my $self    = shift;

    return unless $self->$orig(@_);

    if (!$self->is_checklist_compleet) {
        return;
    }

    return 1;
};


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

