package Zaaksysteem::Controller::API::Users;

use strict;
use warnings;

use Data::Dumper;
use XML::Dumper;
use Encode qw/from_to/;

use parent 'Catalyst::Controller';

sub dispatch : Chained('/') : PathPart('api/users'): Args(0) {
    my ($self, $c)  = @_;

    unless ($self->_verify_api_key($c, $c->req->params->{api_key})) {
        $c->res->status('401');
        $c->res->body('Forbidden');
        $c->detach;
    }

    ### Convert imput from XML to HASH
    my $xs      = XML::Dumper->new;

    my $data    = $xs->xml2pl($c->req->params->{message});

    my $ld          = $c->model('Users');

    my @components  = @{ $ld->components };
    my $component   = $c->req->params->{component};

    unless (grep({ $_ eq $component } @components)) {
        $c->res->status('500');
        $c->res->body('Component not found');
        $c->detach;
    }

    if ($ld->$component($data)) {
        $c->res->status('200');
        $c->res->body('OK');
        $c->detach;
    }

    $c->res->status('500');
    $c->res->body('NOK');
    $c->detach;
}

sub _verify_api_key {
    my ($self, $c, $api_key) = @_;

    my $config_key  = $c->customer_instance->{start_config}
        ->{APIKEYS}->{ad};

    unless ($api_key =~ /^AD/) {
        $c->log->warn('API Key: incorrect identifier');
        return;
    }

    $api_key    =~ s/^AD-//;

    unless ($api_key eq $config_key) {
        $c->log->warn('API Key: incorrect');
        return;
    }

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

