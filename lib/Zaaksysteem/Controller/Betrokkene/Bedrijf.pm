package Zaaksysteem::Controller::Betrokkene::Bedrijf;

use strict;
use warnings;
use Data::Dumper;
use parent 'Catalyst::Controller';




sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Zaaksysteem::Controller::Betrokkene::Bedrijf in Betrokkene::Bedrijf.');
}

{
    sub create : Local {
        my ($self, $c) = @_;

        ### Remove some fields
        {
            ### Get profile from Model
            my $profile = $c->get_profile(
                'method'=> 'create',
                'caller' => 'Zaaksysteem::Betrokkene::Object::Bedrijf'
            ) or die('Could not find profile');

            my @required_fields = grep {
                $_ ne 'vestiging_postcodewoonplaats' ||
                $_ ne 'vestiging_adres'
            } @{ $profile->{required} };

            push(@required_fields, 'rechtsvorm');

            $profile->{required} = \@required_fields;

            $c->register_profile(
                method => 'create',
                profile => $profile,
            );
        }


        if ($c->req->header("x-requested-with") eq 'XMLHttpRequest') {
            $c->zvalidate;
            $c->detach;
        }

        ### Default: view
        $c->stash->{template}   = 'betrokkene/create.tt';

        if ($c->req->method eq 'POST') {
            # Validate information
            return unless $c->zvalidate;

            ### Create person
            my $id = $c->model('Betrokkene')->create('bedrijf', $c->req->params);

            if ($id) {
                $c->flash->{result} = 'Organisatie aangemaakt: ' . $id;
                $c->res->redirect(
                    $c->uri_for(
                        '/betrokkene/' . $id,
                        { gm => 1, type => 'bedrijf' }
                    )
                );
            }
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

