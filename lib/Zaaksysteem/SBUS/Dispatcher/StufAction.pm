package Zaaksysteem::SBUS::Dispatcher::StufAction;

use strict;
use base qw(Catalyst::Action::SOAP);
use IO::Seekable qw/SEEK_SET/;
use Zaaksysteem::SBUS::Constants;

sub execute {
    my $self = shift;
    my ( $controller, $c ) = @_;

    $self->prepare_soap_helper(@_);

    my $prefix          = $controller->soap_action_prefix;

    ### Custom mintlab code, to find soapaction according to berichtsoort
    {
        my $body            = $c->req->body;
        my $xml_str         = join('', <$body>);

        if (ref($c->req->body)) {
            ### Reset body to 0 pointer
            $c->req->body->seek(0,SEEK_SET);

            my ($berichtsoort)  = $xml_str =~ /<.*?berichtsoort>(.*)?<\/.*?berichtsoort>/;
            if ($berichtsoort) {
                my $operation   = STUF_BERICHTSOORT_ACTION->{lc($berichtsoort)};
                $c->req->headers->header('SOAPAction', $prefix . $operation);
            }
        }
    }

    my $soapaction      = $c->req->headers->header('SOAPAction');
    unless ($soapaction) {
        $c->log->error('No SOAP Action');
        $c->stash->{soap}->fault({code => 500,reason => 'Invalid SOAP message'});
        $c->detach;
    }

    $soapaction     =~ s/(^\"|\"$)//g;
    unless ($prefix eq substr($soapaction,0,length($prefix))) {
        $c->log->error('Bad SOAP Action');
        $c->stash->{soap}->fault({code => 500,reason => 'Invalid SOAP message'});
        $c->detach;
    }

    my $operation   = substr($soapaction,length($prefix));
    my $action      = $controller->action_for($operation);

    unless ($action) {
        $c->log->error('SOAP Action does not map to any operation');
        $c->stash->{soap}->fault({code => 500,reason => 'Invalid SOAP message'});
        $c->detach;
    }

    $c->forward($operation);
}

1;

__END__




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

