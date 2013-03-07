package Zaaksysteem::DB::ResultSet::ChecklistVraag;

use strict;
use warnings;

use Moose;

extends 'DBIx::Class::ResultSet', 'Zaaksysteem::Zaaktypen::BaseResultSet';

use constant    PROFILE => {
    required        => [qw/
    /],
    optional        => [qw/
    /],
};

sub _validate_session {
    my $self            = shift;
    my $profile         = PROFILE;
    my $rv              = {};

    $self->__validate_session(@_, $profile);
}

sub _retrieve_as_session {
    my $self            = shift;
    my $extra_options   = shift;

    ### 1.1.9
#    if ($extra_options->{node} && !$extra_options->{node}->zaaktype_definitie_id) {
#        my $node    = $extra_options->{node};
#        my $stata   = {};
#        my $checklistzaak = $self->result_source->schema->resultset('ChecklistZaak')->search(
#            {
#                'zaaktype_id' => $node->id,
#            },
#            {
#                order_by => [
#                    { -asc => 'id' },
#                ],
#            }
#        );
#
#        if ($checklistzaak->count == 1) {
#            $checklistzaak  = $checklistzaak->first;
#            for my $status (1..$node->zaaktype_statussen->count) {
#                my $checklist   = $checklistzaak->checklist_statuses->search(
#                    {
#                        status  => $status,
#                    }
#                );
#                if ($checklist->count == 1) {
#                    $checklist      = $checklist->first;
#                    my $vragen      = $checklist->checklist_vraags;
#                    my $vrcount     = 0;
#                    while (my $vraag = $vragen->next) {
#                        my $antwoorden = $vraag->checklist_mogelijkhedens;
#                        my @answers;
#                        while (my $antwoord = $antwoorden->next) {
#                            push(@answers, $antwoord->label);
#                        }
#
#                        $stata->{++$vrcount} = {
#                            'vraag'         => $vraag->vraag,
#                        };
#                    }
#                }
#            }
#        }
#        return $stata;
#    } else {
        return $self->next::method($extra_options, @_);
#    }
}

sub _commit_session {
    my $self            = shift;
    my $profile         = PROFILE;
    my $rv              = {};

    my $commit_result = $self->next::method(
        @_,
        {
            status_id_column_name   => 'zaaktype_status_id',
        }
    );

    return $commit_result unless $_[1];

    return unless $commit_result;

    my $node                    = shift;
    my $element_session_data    = shift;

    while (my ($counter, $data_params) = each %{ $element_session_data }) {
        if ($data_params->{mogelijkheden}) {

            while (my ($mcounter, $mdata_params) = each %{ $data_params->{mogelijkheden} }) {
                my $data;
                my $relatie_info    =
                    $self->result_source->relationship_info('checklist_mogelijkhedens');

                my $relatie_object  = $self->result_source->schema->resultset($relatie_info->{source});

                my @columns         = $relatie_object->result_source->columns;
                $data->{ $_ }       = $mdata_params->{ $_ } for @columns;

                delete($data->{id});

                #$data_params->{mogelijkheden}->{vraag_id} = $commit_result->{$counter}->id;
                $data->{vraag_id} = $commit_result->{$counter}->id;

                $relatie_object->create($data);
            }
        }
    }

    return 1;
}

1;
