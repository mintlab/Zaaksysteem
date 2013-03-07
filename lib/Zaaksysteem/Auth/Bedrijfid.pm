package Zaaksysteem::Auth::Bedrijfid;

use strict;
use warnings;

use Moose;

use Data::Dumper;

has [qw/authdbic log config session params c/] => (
    is      => 'rw',
);

has [qw/succes cancel error login verified_url/] => (
    is      => 'rw'
);

has 'prod' => (
    'is'        => 'rw',
);

sub BUILD {
    my $self = shift;

    ### Check for session
    if (exists($self->session->{_bedrijfid})) {
        $self->_load_session;
    }
}

sub authenticate {
    my ($self, %opts) = @_;

    ### Remove digid session
    delete($self->session->{_bedrijfid});

    return unless (
        (
            $opts{login} &&
            $opts{login} =~ /^\d+$/
        ) &&
        $opts{password}
    );

    # Search
    my $users = $self->authdbic->search(
        {
            login       => $opts{login},
            password    => $opts{password}
        }
    );

    if ($users->count) {
        my $msg = 'Bedrijfid: authenticatie request geslaagd';
        $self->log->info($msg);
    } else {
        my $msg =
            'Bedrijfid: authenticatie request mislukt:'
            . ' Geen gebruiker gevonden met deze login en password';
        $self->log->error($msg);
        $self->error( $msg );

        return;
    }

    ### Succes
    $self->session->{_bedrijfid} = {};

    ### Expire session
    #$self->c->session_expire_key('_bedrijfid' => '900');
    $self->session->{_bedrijfid}->{login} = $opts{login};

    if ($opts{verified_url}) {
        $self->session->{_bedrijfid}->{verified_url} = $opts{verified_url};
    }

    $self->_load_session;

    return $opts{verified_url} || 1;
}

sub logout {
    my ($self) = @_;

    ### Destroy session
    delete($self->session->{_bedrijfid});

    $self->$_(undef) for qw/
        succes
        verified_url
        login
    /;
}

sub _load_session {
    my ($self) = @_;

    return unless exists($self->session->{_bedrijfid}->{login});

    $self->succes(1);
    $self->verified_url(
        $self->session->{_bedrijfid}->{verified_url}
    );
    $self->login($self->session->{_bedrijfid}->{login});
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

