package Zaaksysteem::Zaken::ResultSetChecklistAntwoord;

use Moose;
use Data::Dumper;

extends 'DBIx::Class::ResultSet';

sub update_checklist {
    my ($self, $options, $args, $zaak) = @_;

    return unless ($options && UNIVERSAL::isa($options, 'HASH'));

    die('No zaak given') unless $zaak;

    my $status_id = $args->{fase_id};

    while (my ($vraag_id, $option) = each %{ $options }) {
        ### Retrieve vraag
        my $vraag = $self->result_source
            ->schema
            ->resultset('ChecklistVraag')
            ->search({
                'id'                => $vraag_id,
                'zaaktype_node_id'  => $zaak->zaaktype_node_id->id
            }
        );

        next unless $vraag->count;

        ## For later reference
        $vraag = $vraag->first;

        ### Check change
        if (
            $self->search({
                vraag_id => $vraag->id,
            })->count
        ) {
            my $antwoord = $self->search({
                vraag_id    => $vraag->id
            })->first;

            if ($antwoord->antwoord ne $option) {
                $antwoord->zaak_id->logging->add({
                    component   => 'checklist',
                    component_id => $vraag->zaaktype_status_id->id,
                    onderwerp   => 'Antwoord voor vraag: "'
                        . substr($vraag->vraag, 0, 150)
                        . '" gewijzigd naar "' . $option . '"'
                });
            }
        } else {
            $self->result_source
                ->schema
                ->resultset('Logging')->add({
                    component   => 'checklist',
                    component_id => $vraag->zaaktype_status_id->id,
                    zaak_id     => $zaak->id,
                    onderwerp   => 'Antwoord voor vraag: "'
                        . substr($vraag->vraag, 0, 150)
                        . '" gewijzigd naar "' . $option . '"'
            });
        }

        ### Delete antwoorden
        $self->search({
            'vraag_id'  => $vraag->id
        })->delete;

        ### Add antwoord
        $self->create({
            'vraag_id'      => $vraag->id,
            'antwoord'      => $option,
        });
    }

    ### Check unlisted items
    my $vragen = $self->result_source
        ->schema
        ->resultset('ChecklistVraag')
        ->search({
        'zaaktype_node_id'      => $zaak->zaaktype_node_id->id,
        'zaaktype_status_id'    => $status_id
    });

    while (my $vraag = $vragen->next) {
        if (
            $options->{$vraag->id} ||
            !$vraag->checklist_antwoords->search({
                zaak_id => $zaak->id
            })->count
        ) {
            next;
        }

        my $antwoorden = $self->search({
            'vraag_id'  => $vraag->id
        });

        if ($antwoorden->count) {
            $antwoorden->delete;

            $self->result_source
                ->schema
                ->resultset('Logging')->add({
                    component    => 'checklist',
                    component_id => $vraag->zaaktype_status_id->id,
                    zaak_id      => $zaak->id,
                    onderwerp    => 'Antwoord voor vraag: "'
                        . substr($vraag->vraag, 0, 150)
                        . '" gewijzigd naar "geen antwoord"'
            });
        }
    }
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

