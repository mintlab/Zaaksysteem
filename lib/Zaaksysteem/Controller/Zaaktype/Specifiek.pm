package Zaaksysteem::Controller::Zaaktype::Specifiek;

use strict;
use warnings;
use Data::Dumper;
use parent 'Catalyst::Controller';




sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Zaaksysteem::Controller::Zaaktype::Specifiek in Zaaktype::Specifiek.');
}

sub edit : Chained('/zaaktype/base'): PathPart('specifiek/edit'): Args(0) {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        $c->forward('sort_kenmerken');
        #$c->forward('load_kenmerken_args');
        $c->response->redirect($c->uri_for('/zaaktype/auth/edit'));
        #$c->response->redirect($c->uri_for('/zaaktype/specifiek/edit'));
        $c->detach;
    }


    ### When status numbero uno has some files to add, make sure we place it
    ### in this pagos
    #$c->forward('load_document_types');

    $c->stash->{params} = $c->session->{zaaktype_edit};
    $c->stash->{template} = 'zaaktype/specifiek/edit.tt';

}

sub sort_kenmerken : Private {
    my ($self, $c) = @_;

    return unless $c->session->{zaaktype_edit}->{status};


    while (my ($statusnr) = each %{ $c->session->{zaaktype_edit}->{status} }) {
        my $kenmerken_sorted = {};
        while (my ($identifier, $sort) = each %{ $c->req->params }) {
            next unless $identifier     =~ /^kenmerk_id/;

            my ($statusid, $kenmerkid)  = $identifier =~ /(\d+)_(\d+)$/;
            next unless ($statusid eq $statusnr);

            $kenmerken_sorted->{$sort} =
                $c->session->{zaaktype_edit}->{status}->{$statusnr}->{kenmerken}->{$kenmerkid};
        }

        $c->session->{zaaktype_edit}->{status}->{$statusnr}->{kenmerken} =
            $kenmerken_sorted;
    }
}

#sub load_document_types : Private {
#    my ($self, $c) = @_;
#
#    if (
#        $c->session->{zaaktype_edit}->{status}->{1} &&
#        $c->session->{zaaktype_edit}->{status}->{1}->{documenten} &&
#        %{
#            $c->session->{zaaktype_edit}->{status}->{1}->{documenten}
#        }
#    ) {
#        ### Temp
#        my ($count, $edit) = (0,0);
#        if (
#            $c->session->{zaaktype_edit}->{specifiek} &&
#            %{ $c->session->{zaaktype_edit}->{specifiek} }
#        ) {
#            $count = keys %{
#                $c->session->{zaaktype_edit}->{specifiek}
#            };
#
#            $edit = 1;
#        }
#
#        while (my ($i, $document) = each %{
#                $c->session->{zaaktype_edit}->{status}->{1}
#                    ->{documenten}
#            }
#        ) {
#            ### loop over specifieke kenmerken, do we already have this
#            ### document_key?
#            if ($edit) {
#                my $continue = 1;
#                for my $tmp_spec (values %{
#                    $c->session->{zaaktype_edit}->{specifiek}
#                }) {
#                    if (
#                        $tmp_spec->{document_key} &&
#                        $tmp_spec->{document_key} eq
#                            $document->{name}
#                    ) {
#                        $continue = 0;
#                        $c->log->debug('Spec it ;)' .
#                             $tmp_spec->{document_key}
#                        );
#                    }
#                }
#
#                next unless $continue;
#            }
#                $c->log->debug('Document meuk: ' . $document->{name});
#            $c->session->{zaaktype_edit}->{specifiek}->{++$count} = {
#                'betrokkene_trigger' => 'all',
#                'options' => [],
#                'verplicht' => 0,
#                'help' => $document->{help},
#                'vraag' => 'Bijlage ' . $document->{name},
#                'type' => 'file',
#                'naam' => $document->{name},
#                'key'   => $document->{name},
#                'document_key' => $document->{name},
#            },
#        }
#    }
#
#}

sub load_kenmerken_args : Private {
    my ($self, $c) = @_;
    my (@kenmerken);

    ### Let's be awesome
    delete($c->session->{zaaktype_edit}->{specifiek});

    my %raw_kenmerken = map {
        $_ => $c->req->params->{ $_ }
    } grep(/kenmerk_.*?_\d+$/, keys %{ $c->req->params });

    for my $key (grep(
            /kenmerk_naam_(\d+)$/,
            keys %raw_kenmerken
    )) {
        my $count   = $key;
        $count      =~ s/.*?(\d+)$/$1/g;

        my %kenmerk = map {
            my $label   = $_;
            $label      =~ s/kenmerk_(.*?)_\d+$/$1/g;
            $label      => $c->req->params->{ $_ }
        } grep(/_$count$/, keys %raw_kenmerken);

        if (
            $c->session->{zaaktype_edit}->{tmp}->{specifieke_kenmerken}
                ->{'kenmerk_naam_' . $count}
        ) {
            for my $kkey (keys
                    %{ $c->session->{zaaktype_edit}->{tmp}
                        ->{specifieke_kenmerken}
                        ->{'kenmerk_naam_' . $count}
                    }
            ) {
                $kenmerk{$kkey} =
                    $c->session->{zaaktype_edit}->{tmp}->{specifieke_kenmerken}
                        ->{'kenmerk_naam_' . $count}->{$kkey};

                $c->log->debug('Added:' . $kkey);
            }
        }

        $kenmerk{'kenmerk_naam'} = lc($kenmerk{'kenmerk_naam'});

        $c->session->{zaaktype_edit}->{specifiek}->{$count} = \%kenmerk;
    }
}


sub kenmerk_definitie : Chained('/zaaktype/base'): PathPart('specifiek/kenmerk_definitie'): Args(0) {
    my ($self, $c) = @_;

    if (%{ $c->req->params } && $c->req->params->{update}) {
        $c->session->{zaaktype_edit}->{tmp}->{specifieke_kenmerken}
            ->{ $c->req->params->{destination} } = {
                map {
                    my $label   = $_;
                    $label      =~ s/^kenmerk_//g;
                    $label      => $c->req->params->{ $_ }
                } grep(/^kenmerk_/, keys %{ $c->req->params })
            };

        ### Special case: options
        if (
            $c->session->{zaaktype_edit}->{tmp}->{specifieke_kenmerken}
                ->{ $c->req->params->{destination} }->{'options'} &&
            !UNIVERSAL::isa(
                $c->session->{zaaktype_edit}->{tmp}->{specifieke_kenmerken}
                    ->{ $c->req->params->{destination} }->{'options'}
                , 'ARRAY'
            )
        ) {
            $c->session->{zaaktype_edit}->{tmp}->{specifieke_kenmerken}
                ->{ $c->req->params->{destination} }->{'options'} = [
                split('\n',
                    $c->session->{zaaktype_edit}->{tmp}->{specifieke_kenmerken}
                        ->{ $c->req->params->{destination} }->{'options'}
                )
            ];
        }

        $c->res->body('OK');
        return;
    }

    if (
        $c->session->{zaaktype_edit}->{tmp}->{specifieke_kenmerken}
            ->{ $c->req->params->{destination} }
    ) {
        $c->stash->{history} =
                $c->session->{zaaktype_edit}->{tmp}->{specifieke_kenmerken}
                    ->{ $c->req->params->{destination} };
    }

    $c->stash->{params} = $c->session->{zaaktype_edit};
    $c->stash->{nowrapper} = 1;
    $c->stash->{template}  = 'zaaktype/specifiek/kenmerk_definities.tt';
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

