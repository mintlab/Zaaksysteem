package Zaaksysteem::Controller::API::StUF::BG0204;

use strict;
use warnings;

use Data::Dumper;

use Scalar::Util qw/blessed/;

use constant COMPONENT_KENNISGEVING => 'kennisgeving';
use constant MODEL_SBUS             => 'SBUS';

use utf8;

use parent qw/
    Catalyst::Controller::SOAP
    Zaaksysteem::Controller::API::StUF
/;

__PACKAGE__->config->{wsdl} = {
    'wsdl'      => Zaaksysteem->config->{home} . '/share/wsdl/stuf/bg0204/bg0204.wsdl',
    'schema'    => [
        Zaaksysteem->config->{home} . '/share/wsdl/stuf/0204/stuf0204.xsd',
        Zaaksysteem->config->{home} . '/share/wsdl/stuf/bg0204/bgstuf0204.xsd',
        Zaaksysteem->config->{home} . '/share/wsdl/stuf/bg0204/bg0204.xsd',
    ],
};

__PACKAGE__->config->{xml_compile} = {
    reader  => {
        sloppy_integers => 1,
        interpret_nillable_as_optional => 1,
        check_values    => 0,
        'hooks' => [
            {
                before => sub {
                    my ($node, $value, $path) = @_;

                    ### Stuf patch, we just don't want any historic events,
                    ### for people moving out. Our library simply cannot handle
                    ### this.
                    ### This routine will remove the second
                    ### PRSADR(INS,VBL,ETC) from the xml
                    if ($node->nodeName =~ /:PRS$/) {
                        my @children = $node->childNodes();

                        my $found = {};
                        for my $child (@children) {
                            if ($child->nodeName =~ /:PRSADR\w{3}$/) {
                                if ($found->{$child->nodeName}) {
                                    $node->removeChild($child);
                                }

                                $found->{$child->nodeName} = 1;
                            }
                        }
                    }

                    ### Vicrea Patch, add nillable when we get a noValue
                    ### attribute
                    if (
                        $node->hasAttributeNS(
                            'http://www.egem.nl/StUF/StUF0204',
                            'noValue'
                        ) &&
                        !$node->hasAttributeNS(
                            'http://www.w3.org/2001/XMLSchema-instance',
                            'nil'
                        )
                    ) {
                        $node->setAttributeNS(
                            'http://www.w3.org/2001/XMLSchema-instance',
                            'nil',
                            'true'
                        );
                    }

                    return $node;
                },
                after => sub {
                    my ($node, $value, $path) = @_;

                    return $value unless (
                        $value eq 'NIL' ||
                        $node->hasAttributeNS(
                            'http://www.egem.nl/StUF/StUF0204',
                            'noValue'
                        )
                    );

                    if (
                        $node->getAttributeNS(
                            'http://www.egem.nl/StUF/StUF0204',
                            'noValue'
                        ) ne 'geenWaarde'
                    ) {
                        return 'NIL:geenWaarde'
                    }

                    return 'NIL';
                }
            }
        ]
    }
};

my $stuf_direction      = {
    'PRS'       => 'natuurlijk_persoon'
};

__PACKAGE__->config->{soap_action_prefix} =
    'http://www.egem.nl/StUF/sector/bg/0204/';

__PACKAGE__->config->{wsdlservice} = 'StUFBGAsynchroon';

sub sbus : Path('') :ActionClass(+Zaaksysteem::SBUS::Dispatcher::StufAction) { }

sub import_prs : Local {
    my ($self, $c) = @_;

#    $c->forward('verify_client');
    die('NOT USABLE');


    my $lxml    = XML::LibXML->new();
    my $xml     = $lxml->parse_file('/home/michiel/testbericht.xml');

    my $stuf                = $c->model(MODEL_SBUS);

    print $xml->toString();
    my ($definition) = $self->decoders
        ->{ontvangKennisgeving}->($xml);

    my $object      = $definition->{kennisgeving}
        ->{stuurgegevens}
        ->{entiteittype};

    $c->log->debug(Dumper($definition));

    $c->log->debug(Dumper($stuf->response(
        $c,
        {
            operation   => 'kennisgeving',
            sbus_type   => 'StUF',
            object      => $object,
            input       => $definition,
            input_raw   => $xml->toString(),
        }
    )));

    $c->res->body('OK:');
}

sub test_dispatch : Local {
    my ($self, $c) = @_;

    #$c->forward('verify_client');
    die('do not use');

    my $stuf                = $c->model(MODEL_SBUS);

    $stuf->request(
        $c,
        {
            operation   => 'search',
            sbus_type   => 'StUF',
            object      => 'PRS',
            input       => {
                'burgerservicenummer'   => '1234567891',
            },
        }
    );

    $c->res->body('OK:');
}


sub ontvangKennisgeving :WSDLPortWrapped('StUFBGAsynchronePort') {
    my ($self, $c, $xml)    = @_;

    #$c->forward('verify_client');

    $c->log->debug(Dumper($xml));
    $c->stash->{soap}->compile_return(
        $c->forward('handle_kennisgeving', [ $xml ])
    );
}

#sub ontvangAsynchroneVraag :WSDLPortWrapped('StUFBGAsynchronePort') {
#    my ($self, $c, $xml)    = @_;
#
#    die
#    #$c->forward('verify_client');
#    $c->log->debug(Dumper($xml));
#    return;
#}

sub handle_kennisgeving : Private {
    my ($self, $c, $xml)    = @_;

    my $stuf                = $c->model(MODEL_SBUS);

    $c->log->debug('Sending SOAP bevestigingsbericht');

    my $object      = $xml->{kennisgeving}
        ->{stuurgegevens}
        ->{entiteittype};

    my $response = $stuf->response(
        $c,
        {
            operation   => 'kennisgeving',
            sbus_type   => 'StUF',
            object      => $object,
            input       => $xml,
            input_raw   => $c->stash->{soap}->envelope(),
        }
    );

    $c->log->debug('DUMPER: ' . Dumper($response));

    return $response;
}

sub verify_client : Private {
    my ($self, $c) = @_;

    if ($c->user_exists || $c->stash->{ssl_client_side}) {
        return 1;
    }

    $c->detach;
}

sub import_bag : Local {
    my ($self, $c) = @_;

    die('TURNED OFF');

    my $lxml    = XML::LibXML->new();

    my $xmlobj  = $lxml->parse_file('/home/michiel/bag_baarn.xml');
    #my $xml2  = $lxml->parse_string($testxml);

    my $stuf                = $c->model(MODEL_SBUS);

    ### Find first kennisgevingsBericht
    my @nodes   = $xmlobj->getElementsByTagNameNS(
        'http://www.egem.nl/StUF/sector/bg/0204',
        'kennisgevingsBericht'
    );

    my $count = 0;
    for my $node (@nodes) {
        my $xml = $lxml->parse_string($node->toString());


        my ($definition) = $self->decoders
            ->{ontvangKennisgeving}->($xml);

        next unless $definition;

        $count++;

        my $object      = $definition->{kennisgeving}
            ->{stuurgegevens}
            ->{entiteittype};

        $stuf->response(
            $c,
            {
                operation   => 'kennisgeving',
                sbus_type   => 'StUF',
                object      => $object,
                input       => $definition,
                input_raw   => $node->toString(),
            }
        );
    }

    $c->res->body('OK:' . $count);
}

sub import_prs_bulk : Local {
    my ($self, $c) = @_;

    #die('TURNED OFF');

    my $lxml    = XML::LibXML->new();

    my $xmlobj  = $lxml->parse_file('/home/michiel/zsml_corrected.xml');
    #my $xml2  = $lxml->parse_string($testxml);

    my $stuf                = $c->model(MODEL_SBUS);

    ### Find first kennisgevingsBericht
#    my @nodes   = $xmlobj->getElementsByTagNameNS(
#        'http://www.egem.nl/StUF/sector/bg/0204',
#        'kennisgevingsBericht'
#    );
    my @nodes   = $xmlobj->getElementsByTagNameNS(
        'http://www.egem.nl/StUF/sector/bg/0204',
        'kennisgevingsBericht'
    );

    warn('TOTAL COUNT: '. scalar(@nodes));

    my $count = 0;
    for my $node (@nodes) {
        warn ('COUNT: '. $count);

        #$c->log->debug('STRING: '. Dumper($node->toString()));
        my $xml = $lxml->parse_string($node->toString());
        #my $xml = $node;


        my ($definition) = $self->decoders
            ->{ontvangKennisgeving}->($xml);

        next unless $definition;

        $count++;

        my $object      = $definition->{kennisgeving}
            ->{stuurgegevens}
            ->{entiteittype};

        $stuf->response(
            $c,
            {
                operation   => 'kennisgeving',
                sbus_type   => 'StUF',
                object      => $object,
                input       => $definition,
                input_raw   => $node->toString(),
            }
        );
    }

    $c->res->body('OK:' . $count);
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

