package Zaaksysteem::Controller::Plugins::Maps;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use Geo::Coder::Google;
use Data::Dumper;





sub retrieve : Local {
    my ( $self, $c ) = @_;

    ### Prevent external sites from using this option
    #if (!$c->user_exists && !$c->session->{pip}) {
    #    $c->res->body('NOK');
    #    $c->detach;
    #}

    my $json = {
        maps => {
            'succes'    => 0
        }
    };

    if ($c->req->params->{query}) {
        my $geocoder = Geo::Coder::Google->new(
            apikey => $c->config->{google_api_key}
        );

        my $result  = $geocoder->geocode(
            'location'  => $c->req->params->{query}
        );

        if (
            $result &&
            $result->{AddressDetails} &&
            $result->{AddressDetails}->{Country}->{AdministrativeArea}
        ) {
            $json->{maps}->{succes} = 1;
            $json->{maps}->{adres}  = $result->{'address'};
            if (
                $result &&
                $result->{Point} &&
                $result->{Point}->{coordinates} &&
                UNIVERSAL::isa($result->{Point}->{coordinates}, 'ARRAY')
            ) {
                $json->{maps}->{coordinates}  =
                    $result->{Point}->{coordinates}->[1]
                    . ' ' .
                    $result->{Point}->{coordinates}->[0]

            }
        }
        $c->log->debug('P::Maps->retrieve loc: ' . Dumper($result));
    }

    $c->log->debug('P::Maps->retrieve result: ' . Dumper($json));

    $c->stash->{json} = $json;
    $c->forward('Zaaksysteem::View::JSON');
    $c->detach;
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

