package Zaaksysteem::Payment::Ogone;

use strict;
use warnings;

use Moose;
use URI;
use URI::QueryParam;
use LWP::UserAgent;
use Digest::SHA1 qw/sha1_hex/;

use Data::Dumper;

my %PUBLIC_ATTR = (
    ### Variable
    orderid     => 'orderID',
    amount      => 'amount',
    pspid       => 'PSPID',
    shasign     => 'SHASign',

    ### Static
    'language' => 'language',
    'currency' => 'currency',
    'accepturl' => 'accepturl',
    'declineurl' => 'declineurl',
    'exceptionurl' => 'exceptionurl',
    'cancelurl' => 'cancelurl',
    'backurl' => 'backurl',
    'homeurl' => 'homeurl',
);

my @SHA1_ATTR   = (
    'amount',
    'currency',
    'orderid',
);


#use constant DIGID_RETURN_CODES => {
#    '0000'      => 'digid_succes',
#    '0001'      => 'digid_tijdelijk_buiten_dienst',
#    '0003'      => 'digid_niet_in_staat_te_verwerken',
#    '0004'      => 'digid_credentials_ongeldig',
#    '0007'      => 'digid_communicatie_ongeldig',
#    '0030'      => 'digid_verzoek_ongeldig',
#    '0032'      => 'digid_verzoek_ongeldig',
#    '0033'      => 'digid_aansluitgegevens_ongeldig',
#    '0040'      => 'digid_geannuleerd',
#    '0050'      => 'digid_zend_opnieuw',
#    '0070'      => 'digid_ongeldige_sessie'
#};

use constant OGONE_SERVER_DATA => {
    TEST => {
        'posturl'   => 'https://secure.ogone.com/ncol/test/orderstandard.asp',
        #'posturl'   => 'http://dev.zaaksysteem.nl:3000/plugins/ogone/test',
        'accepturl' =>
            'plugins/ogone/api/accept',
        'declineurl' =>
            'plugins/ogone/api/decline',
        'exceptionurl' =>
            'plugins/ogone/api/exception',
        'cancelurl' =>
            'plugins/ogone/api/cancel',
        'backurl' =>
            'http://www.bussum.nl/',
        'layout'    => {},
        'language'  => 'nl_NL',
        'currency'  => 'EUR',
        'pspid'     => 'gembussum',
    },
    PROD => {
        'posturl'   => 'https://secure.ogone.com/ncol/prod/orderstandard.asp',
        #'posturl'   => 'http://dev.zaaksysteem.nl:3000/plugins/ogone/test',
        'accepturl' =>
            'plugins/ogone/api/accept',
        'declineurl' =>
            'plugins/ogone/api/decline',
        'exceptionurl' =>
            'plugins/ogone/api/exception',
        'cancelurl' =>
            'plugins/ogone/api/cancel',
        'backurl' =>
            'http://www.bussum.nl/',
        'layout'    => {},
        'language'  => 'nl_NL',
        'currency'  => 'EUR',
        'pspid'     => 'gembussum',
    },
};

### OGONE PUBLIC VARS
has [ keys %PUBLIC_ATTR ] => (
    is      => 'rw',
);

### OGONE STATIC VARS
has [qw/variables omschrijving zaaknr layout posturl shasign succes status verified baseurl/] => (
    is      => 'rw'
);

### Defaults for model
has [qw/log config session params c/] => (
    is      => 'rw',
);

has 'prod'  => (
    'is'        => 'rw',
);

has 'dummy' => (
    'is'        => 'rw',
);

sub start_payment {
    my ($self, %opt)    = @_;

    ### Clear ancient data
    $self->clear_payment;

    {
        for my $variable (qw/amount omschrijving zaaknr/) {
            die('Missing variable ' . $variable) unless $opt{$variable};

            $self->$variable($opt{$variable});
        }

        die('Missing shapass') unless $opt{shapass};
    }

    ### URLS
    {
        my $prod_test_data  = OGONE_SERVER_DATA;

        my $prodortest  = 'TEST';
        $prodortest     = 'PROD' if $self->prod;

        while (my ($target, $data) = each %{ $prod_test_data->{$prodortest} }) {
            if ($target =~ /url/ && $data !~ /http/) {
                $self->$target($self->baseurl . $data);
                next;
            }
            $self->$target($data);
        }
    }

    ### Order id
    $self->orderid(time() . 'z' . $self->zaaknr);

    ### SHA1
    {
        my $shapass = $opt{shapass};

        my ($field, $logfield) = ('','');
        for my $key (sort keys %PUBLIC_ATTR) {
            next if $self->$key eq '';
            $logfield .= uc($key) . '=' . $self->$key;
            $field .= uc($key) . '=' . $self->$key . $shapass;
        }

        #$field .= $shapass;

        $self->shasign(uc(sha1_hex($field)));
        $self->log->debug(
            'Z:P:Ogone->start_payment: Hashing key: '
            . $logfield
        );

        $self->log->debug(
            'Z:P:Ogone->start_payment: Hashed key: '
            . $self->shasign
        );
        $self->log->debug(
            'Z:P:Ogone->start_payment: Hashed logkey: '
            . uc(sha1_hex($logfield))
        );
    }


    $self->variables(\%PUBLIC_ATTR);
}

sub verify_payment {
    my ($self, %opt) = @_;

    ### Clear ancient data
    $self->clear_payment;

    die('Missing shapass') unless $opt{shapass};

    ### Fill object
    {
        my $shapass     = $opt{shapass};
        delete($opt{shapass});
        my $shagiven    = $opt{SHASIGN};
        delete($opt{SHASIGN});

        my %fields;
        $fields{uc($_)} = $opt{$_} for keys %opt;

        my ($field, $logfield) = ('','');
        for my $key (sort keys %fields) {
            my $value   = $fields{$key};
            next if $value eq '';

            $field      .= uc($key) . '=' . $value . $shapass;
            $logfield   .= uc($key) . '=' . $value;
        }

        my $shafound    = sha1_hex($field);

        $self->log->debug(
            'Z:P:Ogone->verify_payment: Hashing key: '
            . $logfield
        );

        $self->log->debug(
            'Z:P:Ogone->verify_payment: Hashed key: '
            . uc($shafound)
        );
        $self->log->debug(
            'Z:P:Ogone->verify_payment: Hashed logkey: '
            . uc(sha1_hex($logfield))
        );

        ### Fill information
        for my $key (keys %fields) {
            my $lckey   = lc($key);
            next unless $self->can($lckey);

            $self->$lckey($fields{$key});
        }

        if (uc($shafound) eq uc($shagiven)) {
            $self->log->debug(
                'Z:P:Ogone->start_payment: Verified ogone hash: '
                . $shagiven
            );

            #$self->succes(1);
            $self->verified(1);

            if ($fields{STATUS} eq '9') {
                $self->succes(1);
                $self->log->info(
                    'Z:P:Ogone->start_payment: Verified ogone hash and'
                    . ' succesfull transaction'
                );

            } else {
                $self->log->info(
                    'Z:P:Ogone->start_payment: Verified ogone hash but'
                    . ' NO succesfull transaction'
                );
            }
        } else {
            $self->log->debug(
                'Z:P:Ogone->start_payment: Verified ogone hash, NOT VALID: '
                . $shagiven
            );

            $self->verified(undef);
            $self->succes(undef);
        }

        # Correct amount, irritating ogone:
        $self->amount(($self->amount*100));
    }

    return $self->verified;
}

sub clear_payment {
    my ($self) = @_;

    $self->$_(undef) for qw/amount omschrijving zaaknr orderid shasign succes/;
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

