package Zaaksysteem::SBUS::Dispatcher::Soap;

use Moose::Role;
use Data::Dumper;

use FindBin qw/$Bin/;

use XML::Compile::WSDL11;      # use WSDL version 1.1
use XML::Compile::SOAP11;      # use SOAP version 1.1
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::Translate::Reader;

has wsdl => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        #warn('CONFIG: ' . Dumper($self));
        warn($self->app->config->{home} .  '/share/wsdl/stuf/bg0204/bg0204.wsdl');
        my $wsdl = XML::Compile::WSDL11->new(
            $self->app->config->{home} . '/share/wsdl/stuf/bg0204/bg0204.wsdl'
        );

        $wsdl->importDefinitions(
            $self->app->config->{home} . "/share/wsdl/stuf/0204/stuf0204.xsd"
        );
        $wsdl->importDefinitions(
            $self->app->config->{home} . "/share/wsdl/stuf/bg0204/bgstuf0204.xsd"
        );
        $wsdl->importDefinitions(
            $self->app->config->{home} . "/share/wsdl/stuf/bg0204/bg0204.xsd"
        );

        $wsdl->addHook(
            before => sub {
                my ($doc, $value, $path) = @_;

                if (my ($novalue) = $value =~ /NIL:(.*)/) {
                    my ($tag)       = $path =~ /\/([\w\d_-]*)$/;

                    my $value    = XML::LibXML::Element->new( 'BG:' . $tag );
                    $value->setAttribute('xsi:nil', 'true');
                    $value->setAttribute('StUF:noValue', $novalue);
                    return $value;
                }

                return $value;
            }
        );

        my $transport   = XML::Compile::Transport::SOAPHTTP->new(
            'address'   => 'https://dev.zaaksysteem.nl/api/stuf/bg0204',
        );

        $transport->userAgent->ssl_opts(
            'SSL_key_file' =>
            '/etc/apache2/ssl/baarn_cmg.key'
        );

        $transport->userAgent->ssl_opts(
            'SSL_cert_file' =>
            '/etc/apache2/ssl/baarn_cmg.crt'
        );

        $wsdl->compileCalls(
            transport    => $transport
        );

        return $wsdl;
    }
);

sub _dispatch_soap {
    my $self        = shift;
    my $call        = shift;
    my $params      = shift;

    my ($answer, $trace) = $self->wsdl->call(
        $call, $params
    );
    warn $trace->request->as_string;

    return $answer;
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

