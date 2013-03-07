package Zaaksysteem::Auth::Digid;

use strict;
use warnings;

use Moose;
use URI;
use URI::QueryParam;
use LWP::UserAgent;

use Data::Dumper;

use constant DIGID_RETURN_CODES => {
    '0000'      => 'digid_succes',
    '0001'      => 'digid_tijdelijk_buiten_dienst',
    '0003'      => 'digid_niet_in_staat_te_verwerken',
    '0004'      => 'digid_credentials_ongeldig',
    '0007'      => 'digid_communicatie_ongeldig',
    '0030'      => 'digid_verzoek_ongeldig',
    '0032'      => 'digid_verzoek_ongeldig',
    '0033'      => 'digid_aansluitgegevens_ongeldig',
    '0040'      => 'digid_geannuleerd',
    '0050'      => 'digid_zend_opnieuw',
    '0070'      => 'digid_ongeldige_sessie'
};

use constant DIGID_SERVER_URL => {
    TEST => 'https://was-preprod1.digid.nl/was/server',
    PROD => 'https://was.digid.nl/was/server',
};

has [qw/log config session params c/] => (
    is      => 'rw',
);

has [qw/succes cancel error uid betrouwbaarheidsniveau verified_url baseurl/] => (
    is      => 'rw'
);

has 'prod' => (
    'is'        => 'rw',
);

sub BUILD {
    my $self = shift;

    ### Check for session
    if (exists($self->session->{_digid})) {
        $self->_load_session;
    }

    if ($self->params->{rid} && !$self->succes) {
        $self->verify;
    }
}

sub authenticate {
    my ($self, %opts) = @_;

    ### Remove digid session
    delete($self->session->{_digid});

    my $ua  = LWP::UserAgent->new;
    $ua->timeout(5);
    if ($ua->can('ssl_opts')) {
        $ua->ssl_opts(verify_hostname => 0);
    }


    ### Prepare Request
    my $uri     = URI->new("","http");
    $uri->query_form(
        'request'           => 'authenticate',
        'a-select-server'   =>
            $self->config->{'select_server'},
        'app_id'          =>
            $self->config->{'app_id'},
        'shared_secret'     =>
            $self->config->{'shared_secret'},
        'app_url'           => $opts{app_url} ||
            $self->baseurl . 'auth/digid'
    );

    my $digid_server_url = (
        $self->prod
            ? DIGID_SERVER_URL->{PROD}
            : DIGID_SERVER_URL->{TEST}
    );

    ### Request
    my $rv  = $ua->get(
        $digid_server_url . '?' . $uri->query
    );

    ### Check
    if (!$rv->is_success || !$rv->content) {
        $self->log->info('Digid: authenticatie request mislukt'
            . $digid_server_url . ':' . $rv->content
        );
        $self->error(
            'DigiD Error: onbekend, no content'
        );
        $self->succes(undef);
        return;
    }

    ### Explode response
    $uri            = URI->new("", "http");
    $uri->query($rv->content);

    my $digid_rv    = $uri->query_form_hash;

    if ($digid_rv->{result_code} eq '0000') {
        my $msg = 'Digid: authenticatie request geslaagd';
        $self->log->info($msg);
    } elsif ($digid_rv->{result_code} eq '0040') {
        $self->cancel(1);
        my $msg = 'Digid: authenticatie request geannuleerd';
        $self->log->info($msg);
        $self->error($msg);
        $self->succes(undef);
        return;
    } else {
        my $msg =
            'Digid: authenticatie request mislukt, code: ' .
            $digid_rv->{result_code};
            $digid_rv->{result_code} . ' ' .
            DIGID_RETURN_CODES->{$digid_rv->{result_code}};
        $self->log->error($msg);
        $self->error(
            'DigiD Error: ' . $digid_rv->{result_code}
            . ': ' . DIGID_RETURN_CODES->{$digid_rv->{result_code}}
        );

        return;
    }

    ### Succes
    $self->session->{_digid} = {};

    $self->session->{_digid}->{rid} = $digid_rv->{rid};

    if ($opts{verified_url}) {
        $self->session->{_digid_verified_url} = $opts{verified_url};
    }

    ### return redirection url
    my $redirection_url = $digid_rv->{as_url}
        . '&rid=' . $digid_rv->{'rid'}
        . '&a-select-server=' . $digid_rv->{'a-select-server'};

    $self->log->info('Digid Authenticatie: Redirecting to url: ' . $redirection_url);
    return $redirection_url;
}

sub verify {
    my ($self) = @_;

    my $ua  = LWP::UserAgent->new;
    $ua->timeout(5);
    if ($ua->can('ssl_opts')) {
        $ua->ssl_opts(verify_hostname => 0);
    }

    ### Verify digid in session
    if (!$self->session->{_digid}->{rid}) {
        $self->log->info('Digid: verificatie mislukt, geen rid');
        $self->error(
            'DigiD verificatie error: geen rid in session'
        );
        $self->succes(undef);
        return;
    } elsif (
        $self->session->{_digid}->{rid} ne
        $self->params->{rid}
    ) {
        $self->log->info('Digid: verificatie mislukt, geen rid match');
        $self->log->info(
            'Digid RID: ' . $self->params->{rid}
            . ' / Our RID: ' . $self->session->{_digid}->{rid}
        );
        $self->error(
            'DigiD verificatie error: no rid match with session'
        );
        $self->succes(undef);
        return;
    }

    ### Rid found

    ### Prepare Request
    my $uri     = URI->new("","http");
    $uri->query_form(
        'request'               => 'verify_credentials',
        'aselect_credentials'   =>
            $self->params->{aselect_credentials},
        'rid'                   =>
            $self->params->{rid},
        'shared_secret'     =>
            $self->config->{'shared_secret'},
        'a-select-server'   =>
            $self->config->{'select_server'},
    );

    my $digid_server_url = (
        $self->prod
            ? DIGID_SERVER_URL->{PROD}
            : DIGID_SERVER_URL->{TEST}
    );

    ### Request
    my $rv  = $ua->get(
        $digid_server_url . '?' . $uri->query
    );

    # Whatever happens, expire the damn key
    $self->c->session_expire_key('_digid' => '900');

    ### Check
    if (!$rv->is_success || !$rv->content) {
        $self->log->info('Digid: verificatie request mislukt');
        $self->error(
            'DigiD Error: onbekend, no content'
        );
        $self->succes(undef);
        return;
    }

    ### Explode response
    $uri            = URI->new("", "http");
    $uri->query($rv->content);

    my $digid_rv    = $uri->query_form_hash;

    if ($digid_rv->{result_code} eq '0000') {
        my $msg = 'Digid: verificatie request geslaagd';
        $self->log->info($msg);
    } elsif ($digid_rv->{result_code} eq '0040') {
        $self->cancel(1);
        my $msg = 'Digid: verificatie request geannuleerd';
        $self->log->info($msg);
        $self->error($msg);
        $self->succes(undef);
        return;
    } else {
        my $msg =
            'Digid: verificatie request mislukt: ' .
            $digid_rv->{result_code} . ' ' .
            DIGID_RETURN_CODES->{$digid_rv->{result_code}};
        $self->log->error($msg);
        $self->error(DIGID_RETURN_CODES->{$digid_rv->{result_code}});

        return;
    }

    ### Geslaagd
    ### Load session
    $self->session->{_digid}->{uid}                     = $digid_rv->{uid};
    $self->session->{_digid}->{betrouwbaarheidsniveau}  =
        $digid_rv->{betrouwbaarheidsniveau};

    $self->_load_session;

    return 1;
}

sub logout {
    my ($self) = @_;

    ### Destroy session
    delete($self->session->{_digid});

    $self->$_(undef) for qw/
        succes
        uid
        betrouwbaarheidsniveau
    /;
}

sub _load_session {
    my ($self) = @_;

    return unless exists($self->session->{_digid}->{uid});

    $self->succes(1);
    $self->verified_url(
        $self->session->{_digid_verified_url}
    );
    $self->uid($self->session->{_digid}->{uid});
    $self->betrouwbaarheidsniveau(
        $self->session->{_digid}->{betrouwbaarheidsniveau}
    );

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

