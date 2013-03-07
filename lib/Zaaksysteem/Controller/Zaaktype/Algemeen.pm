package Zaaksysteem::Controller::Zaaktype::Algemeen;

use strict;
use warnings;

use Data::Dumper;
use Data::UUID;
use parent 'Catalyst::Controller';

my $EDIT_PARAMS = {
      'zt_code'                 => 'zt_code',
      'zt_naam'                 => 'zt_naam',
      'zt_toelichting'          => 'zt_toelichting',
      'ztc_iv3_categorie'       => 'ztc_iv3_categorie',
      'ztc_grondslag'           => 'ztc_grondslag',
      'zt_trigger'              => 'zt_trigger',
      'ztc_handelingsinitiator' => 'ztc_handelingsinitiator',
      'ztc_proces'              => 'ztc_proces',
      'ztc_selectielijst'       => 'ztc_selectielijst',
      'ztc_afhandeltermijn'     => 'ztc_afhandeltermijn',
      'ztc_afhandeltermijn_type' => 'ztc_afhandeltermijn_type',
      'ztc_servicenorm'         => 'ztc_servicenorm',
      'ztc_servicenorm_type'    => 'ztc_servicenorm_type',
      'ztc_escalatiegeel'       => 'ztc_escalatiegeel',
      'ztc_escalatieoranje'     => 'ztc_escalatieoranje',
      'ztc_escalatierood'       => 'ztc_escalatierood',
      'ztc_besluittype'         => 'ztc_besluittype',
      'ztc_openbaarheid'        => 'ztc_openbaarheid',
      'ztc_procesbeschrijving'        => 'ztc_procesbeschrijving',
      'zt_automatisch_behandelen'      => 'zt_automatisch_behandelen',
      'zt_hergebruik'           => 'zt_hergebruik',
      'zt_webform_toegang'      => 'zt_webform_toegang',
      'zt_webform_authenticatie' => 'zt_webform_authenticatie',
      'zt_toewijzing_zaakintake' => 'zt_toewijzing_zaakintake',
      'pdc_meenemen'            => 'pdc_meenemen',
      'pdc_description'         => 'pdc_description',
      'pdc_voorwaarden'         => 'pdc_voorwaarden'
};




sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Zaaksysteem::Controller::Zaaktype::Algemeen in Zaaktype::Algemeen.');
}


{
    Zaaksysteem->register_profile(
        method  => 'edit',
        profile => {
            required => [ qw/
                zt_naam
                zt_code
                zt_trigger
                ztc_handelingsinitiator
                ztc_iv3_categorie
                ztc_grondslag
                ztc_openbaarheid
                ztc_selectielijst
                pdc_description
                pdc_meenemen
                pdc_voorwaarden
                ztc_afhandeltermijn
                ztc_besluittype
                ztc_servicenorm
                type_aanvragers
            /],
            optional            => [ qw/
                ztc_webform_toegang
                ztc_webform_authenticatie
                adrestype
                pdc_tarief_cnt
                pdc_tarief_eur
            /],
            constraint_methods  => {
            },
        }
    );

    sub edit : Chained('/zaaktype/base'): PathPart('algemeen/edit'): Args(0) {
        my ($self, $c) = @_;

        if ($c->req->header("x-requested-with") eq 'XMLHttpRequest') {
            if ($c->zvalidate) {
                # Check documents
                my %document_args;
                $document_args{ $_ } = $c->req->params->{ $_ } for
                    grep(/document_.*?_\d+$/, keys %{ $c->req->params });

                ### Loop over variables
                for my $description (grep(
                        /document_description_(\d+)$/,
                        keys %document_args
                )) {
                    my $count   = $description;
                    $count      =~ s/.*?(\d+)$/$1/g;

                    unless (
                        $c->session->{zaaktype_edit}->{tmp}->{document_kenmerken}
                            ->{ 'document_description_' . $count } &&
                        $c->req->params->{$description}
                    ) {
                        $c->zcvalidate({
                            'invalid' => ['document_description_' . $count],
                        });
                        $c->detach;
                    }
                }
            } else {
                $c->detach;
            }
            $c->zcvalidate({success    => 1});
            $c->detach;
        }

        if (%{ $c->req->params }) {
            ### LOAD parameters
            $c->session->{zaaktype_edit}->{algemeen}
                ->{ $EDIT_PARAMS->{ $_ } } = $c->req->params->{ $_ } for
                    keys %{ $EDIT_PARAMS };

            $c->log->debug('Zaaktoewijzing: ' .
                $c->req->params->{zt_toewijzing_zaakintake}
            );

            $c->forward('load_parameters');
            $c->forward('load_documents');

            $c->response->redirect($c->uri_for('/zaaktype/status/edit'));
            $c->detach;
        } elsif (
            $c->session->{zaaktype_edit}->{edit} &&
            $c->session->{zaaktype_edit}->{algemeen}->{documenten} &&
            %{
                $c->session->{zaaktype_edit}->{algemeen}->{documenten}
            }
        ) {
            my @sorted_keys = sort { $a <=> $b } keys %{
                $c->session->{zaaktype_edit}->{algemeen}->{documenten}
            };

            my $i = 0;
            for my $key (@sorted_keys) {
                my $value =
                    $c->session->{zaaktype_edit}->{algemeen}->{documenten}->{$key};
                $c->session->{zaaktype_edit}->{tmp}->{document_kenmerken}
                    ->{'document_description_' . ++$i} = $value->{kenmerken};
            }
        }

        ### Helper: make tarief readable
        if ($c->session->{zaaktype_edit}->{algemeen}->{pdc_tarief}) {
            (
                $c->session->{zaaktype_edit}->{algemeen}->{pdc_tarief_eur},
                $c->session->{zaaktype_edit}->{algemeen}->{pdc_tarief_cnt}
            ) = split(
                /\./,
                $c->session->{zaaktype_edit}->{algemeen}->{pdc_tarief}
            )
        }
        $c->stash->{params} = $c->session->{zaaktype_edit};

        $c->stash->{template} = 'zaaktype/algemeen/edit.tt';
    }
}

sub load_parameters : Private {
    my ($self, $c) = @_;

    $c->session->{zaaktype_edit}->{algemeen}
        ->{ $EDIT_PARAMS->{ $_ } } = $c->req->params->{ $_ } for
            keys %{ $EDIT_PARAMS };

    if ($c->session->{zaaktype_edit}->{algemeen}->{zt_trigger} eq 'intern') {
        $c->session->{zaaktype_edit}->{algemeen}->{zt_adres_relatie}
            = 'anders';
    } else {
        $c->session->{zaaktype_edit}->{algemeen}->{zt_adres_relatie}
            = $c->req->params->{adrestype};
    }

    ### Aanvrager hash
    if (
        $c->req->params->{type_aanvragers}
    ) {
        my @type_aanvragers;
        if (
            UNIVERSAL::isa($c->req->params->{type_aanvragers}, 'ARRAY') &&
            @{ $c->req->params->{type_aanvragers} }
        ) {
            @type_aanvragers = @{ $c->req->params->{type_aanvragers} };
        } else {
            $type_aanvragers[0] = $c->req->params->{type_aanvragers};
        }

        $c->session->{zaaktype_edit}->{algemeen}->{type_aanvragers} = {};
        for my $type_aanvrager (@type_aanvragers) {
            $c->session->{zaaktype_edit}->{algemeen}
                ->{type_aanvragers}->{$type_aanvrager} = 1;
        }
    }

    $c->session->{zaaktype_edit}->{algemeen}->{pdc_tarief} =
        $c->req->params->{pdc_tarief_eur} . '.' .
        $c->req->params->{pdc_tarief_cnt};

    ### Proces document
    if ($c->req->upload('ztc_procesbeschrijving')) {
        my $files_dir   = $c->config->{files} . '/tmp/zaaktype_';
        my $ug          = new Data::UUID;


        my $tmpname = $files_dir . $ug->create_str() . '_proces.pdf';
        $c->req->upload('ztc_procesbeschrijving')->copy_to( $tmpname );
        $c->session->{zaaktype_edit}->{proces_tempname} = $tmpname;
    }
}

sub load_documents : Private {
    my ($self, $c) = @_;
    my (@documents, %document_args, %doc_count);

    $document_args{ $_ } = $c->req->params->{ $_ } for
        grep(/document_.*?_\d+$/, keys %{ $c->req->params });

    ### Loop over variables
    for my $description (grep(
            /document_description_(\d+)$/,
            keys %document_args
    )) {
        my $count   = $description;
        $count      =~ s/.*?(\d+)$/$1/g;

        if (!$c->req->params->{'document_description_' . $count}) { next; }

        my %document = map {
            my $label   = $_;
            $label      =~ s/document_(.*?)_\d+$/$1/g;
            $label      => $c->req->params->{ $_ }
        } grep(/document_.*?_$count/, keys %{ $c->req->params });

        if (
            $c->session->{zaaktype_edit}->{tmp}->{document_kenmerken}
                ->{ 'document_description_' . $count }
        ) {
            $document{kenmerken} = $c->session->{zaaktype_edit}->{tmp}
                        ->{document_kenmerken}->{ 'document_description_' .  $count };
        }

        # Update hash:
        $c->session->{zaaktype_edit}->{algemeen}->{documenten}->{$count}
            = \%document;
    }

}

sub document_definities : Chained('/zaaktype/base'): PathPart('algemeen/doc_definitie'): Args(0) {
    my ($self, $c) = @_;

    if (%{ $c->req->params } && $c->req->params->{update}) {
        $c->session->{zaaktype_edit}->{tmp}->{document_kenmerken}
            ->{ $c->req->params->{destination} } = {
                map {
                    my $label   = $_;
                    $label      =~ s/^kenmerk_//g;
                    $label      => $c->req->params->{ $_ }
                } grep(/^kenmerk_/, keys %{ $c->req->params })
            };
        $c->res->body('OK');
        return;
    }

    if (
        $c->session->{zaaktype_edit}->{tmp}->{document_kenmerken}
            ->{ $c->req->params->{destination} }
    ) {
        ### History should overwrite edit parameters
        $c->stash->{history} =
                $c->session->{zaaktype_edit}->{tmp}->{document_kenmerken}
                    ->{ $c->req->params->{destination} };
    }

    $c->stash->{nowrapper} = 1;
    $c->stash->{template}  = 'zaaktype/algemeen/document_definities.tt';
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

