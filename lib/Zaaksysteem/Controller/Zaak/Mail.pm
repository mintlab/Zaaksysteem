package Zaaksysteem::Controller::Zaak::Mail;

use strict;
use warnings;
use Data::Dumper;
use parent 'Catalyst::Controller';

use Email::Valid;

use Zaaksysteem::Constants qw/
    ZAAKSYSTEEM_GM_AUTHENTICATEDBY_DIGID
/;




sub notificatie : Private {
    my ($self, $c) = @_;

    my $notificatie = $c->stash->{notificatie}
        or return;

    $c->log->debug(
        'Z::Mail->notificatie with arguments:'
        . Dumper($notificatie)
    );

    if ($notificatie->{message}) {
        # Forward directly to message handler
        return $self->send(
            $c,
            %{ $notificatie->{message} }
        );
    }

    ### Retrieve information about this zaak
    my $notificaties    = $c->stash->{zaak}
        ->zaaktype_node_id
        ->zaaktype_notificaties
        ->search(
            {
                'zaak_status_id.status' => $c->stash->{notificatie}->{status},
            },
            {
                join    => 'zaak_status_id',
            }
        );

    $c->log->debug('Notificatie: ' . $notificaties->count);

    my %send_args;
    while (my $notificatie = $notificaties->next) {
        $send_args{rcpt} = $notificatie->rcpt;

        if ($notificatie->rcpt eq 'behandelaar') {
            if ($notificatie->email) {
                $send_args{ztc_aanvrager_id} = $notificatie->email;
            } else {
                if (
                    $c->stash->{zaak}->behandelaar &&
                    $c->stash->{zaak}->behandelaar_object->email
                ) {
                    $send_args{ztc_aanvrager_id} =
                        $c->stash->{zaak}->behandelaar_object->rt_setup_identifier
                } else {
                    $c->log->error(
                        'No proper rcpt found'
                    );
                    next;
                }
            }
        } elsif ($notificatie->rcpt eq 'overig') {
            $send_args{email} = $notificatie->email;

            $send_args{email} = $c->model('Bibliotheek::Sjablonen')->_replace_kenmerken(
                $c->stash->{zaak}->nr,
                $send_args{email}
            );
        }

        $send_args{bericht} = $notificatie->bericht;
        $send_args{onderwerp} = $notificatie->onderwerp;
        $send_args{intern_block} = $notificatie->intern_block;

        unless (
            !$send_args{email} || (
                $send_args{email} && Email::Valid->address($send_args{email})
            )
        ) {
            next;
        }

        $c->log->debug('Sending email: ' . Dumper(\%send_args));

        $self->send(
            $c,
            %send_args
        );
    }

}

sub notificatie_test : Local {
    my ($self, $c) = @_;

    $c->stash->{zaak} = $c->model('Zaak')->get(43);

    $c->stash->{notificatie}    = {
        status  => 3,
    };

    $c->forward('notificatie');
}

sub send {
    my ($self, $c, %args) = @_;

    if ($args{rcpt} eq 'aanvrager') {
        $args{rcpt} = undef;
        if (
            $c->stash->{zaak}->aanvrager &&
            $c->stash->{zaak}->aanvrager_object->email
        ) {
            $args{rcpt} = $c->stash->{zaak}->aanvrager_object->email;
        }
    } elsif ($args{rcpt} eq 'behandelaar') {
        # Get behandelaar
        $args{rcpt} = undef;
        if ($args{ztc_aanvrager_id}) {
            my ($bid) = $args{ztc_aanvrager_id} =~ /(\d+)$/;

            my $bo      = $c->model('Betrokkene')->get(
                {
                    extern  => 1,
                    type    => 'medewerker',
                },
                $bid
            );

            if (
                $bo &&
                $bo->email
            ) {
                $args{rcpt} = $bo->email
            }
        }
    } elsif ($args{rcpt} eq 'coordinator') {
        $args{rcpt} = undef;
        if (
            $c->stash->{zaak}->coordinator &&
            $c->stash->{zaak}->coordinator_object->email
        ) {
            $args{rcpt} = $c->stash->{zaak}->coordinator_object->email;
        }
    } elsif ($args{rcpt} eq 'overig') {
        $args{rcpt} = undef;
        if (
            $args{email}
        ) {
            #$args{rcpt} = $args{email};

            $args{rcpt} = $c->model('Bibliotheek::Sjablonen')->_replace_kenmerken(
                $c->stash->{zaak}->nr,
                $args{email}
            );
        }
    } else {
        return;
    }

    return unless $args{rcpt};

    ### Special case: when block_intern is set, do _NOT_ send out this message
    ### when zaak is not webform marked
    if (
        $c->stash->{zaak} &&
        $args{intern_block} &&
        lc($c->stash->{zaak}->contactkanaal)
            ne 'webform'
    ) {
        return;
    }

    eval {
        my $body = $self->parse_special_vars($c, $args{bericht});
        my $onderwerp = $self->parse_special_vars($c, $args{onderwerp});

        $c->stash->{email} = {
            from    => $args{from} || $c->config->{gemeente}->{zaak_email},
            to      => $args{rcpt},
            subject => $onderwerp,
            body    => $body
        };

        $c->log->debug('mailstash: ' . Dumper($c->stash->{email}));

        if ($body && $onderwerp) {
            eval {
                $c->forward( $c->view('Email') );
            };

            if (!$@) {
                # Record email
                my %add_args = (
                    zaak_id      => $c->stash->{zaak}->id,
                    zaakstatus   => $c->stash->{'zaak'}->milestone,
                    filename     => $args{rcpt},
                    documenttype => 'mail',
                    category     => '',
                    subject      => $onderwerp,
                    message      => $body,
                    rcpt         => $args{rcpt},
                );

                if ($c->user_exists) {
                    $add_args{betrokkene_id} = 'betrokkene-medewerker-'
                        . $c->user->uidnumber;
                } else {
                    $add_args{betrokkene_id} =
                        $c->stash->{zaak}->aanvrager_object->rt_setup_identifier;
                }

                $c->log->debug('Going to add mail as document to zaak: '
                    . Dumper(\%add_args)
                );

                $c->model('Documents')->add(
                    \%add_args
                );
            }
        } else {
            $c->log->error(
                'C:Z:Mail: Body or Onderwerp empty?' .
                (
                    $c->stash->{zaak}
                        ? ' Zaak: ' . $c->stash->{zaak}->nr
                        : ''
                )
            );
        }
    };

    if ($@) {
       $c->log->debug(
           'Something went wrong sending email: ' . $@
        );
    }
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Zaaksysteem::Controller::Zaak::Mail in Zaak::Mail.');
}

sub preview : Private {
    my ($self, $c, $zaak) = @_;

    $c->stash->{mailconcept} = $c->view('TT')->render(
        $c,
        'tpl/zaak_v1/nl_NL/email/status_next.tt',
        {
            nowrapper => 1,
            %{ $c->stash }
        }
    );
}

sub registratie : Private {
    my ($self, $c) = @_;

    eval {
        $c->stash->{mailconcept} = $c->view('TT')->render(
            $c,
            'tpl/zaak_v1/nl_NL/email/registratie.tt',
            {
                nowrapper => 1,
                %{ $c->stash }
            }
        );

        $c->forward('aanvrager', [
            'Uw zaak is geregistreerd bij de ' .  $c->config->{gemeente}->{naam_lang}
        ]);
    };

    if ($@) {
        $c->log->debug('Something went wrong by sending this email: '
            . $@
        );
    }
}



sub aanvrager : Local {
    my ( $self, $c, $subject ) = @_;

    my $body    = $c->stash->{mailconcept} || $c->req->params->{'mailconcept'};
    if (!$subject) {
        $subject = $c->req->params->{'mailsubject'} || 'Status gewijzigd';
    }

    return unless (
        $body &&
        $c->stash->{zaak} &&
        $c->stash->{zaak}->kenmerk->aanvrager_email
    );

    eval {

        $body = $self->parse_special_vars($c, $body);

        $c->stash->{email} = {
            from    => $c->config->{gemeente}->{zaak_email},
            to      => $c->stash->{zaak}->kenmerk->aanvrager_email,
            subject => '[' . uc( $c->config->{gemeente}->{naam_kort}) . ' Zaak #' . $c->stash->{zaak}->nr . '] ' . $subject ,
            body    => $body,
        };

        $c->forward( $c->view('Email') );
    };

    if (!$@) {
        # Record email
        my %add_args = (
            zaakstatus   => $c->stash->{'zaak'}->kenmerk->status,
            filename     => $c->stash->{zaak}->kenmerk->aanvrager_email,
            documenttype => 'mail',
            category     => '',
            subject      => '[' . uc( $c->config->{gemeente}->{naam_kort}) . ' Zaak #' . $c->stash->{zaak}->nr . '] ' . $subject,
            message      => $body,
            rcpt         => $c->stash->{zaak}->kenmerk->aanvrager_email,
        );

        $c->stash->{zaak}->documents->add(
            \%add_args
        )
   } else {
       $c->log->debug(
           'Something went wrong sending email: ' . $@
        );
    }
}

sub parse_special_vars {
    my ( $self, $c, $body ) = @_;

    return $c->model('Bibliotheek::Sjablonen')->_replace_kenmerken(
        $c->stash->{zaak},
        $body
    );
    #return $self->_replace_kenmerken($c, $body);
}

sub document : Private {
    my ( $self, $c, $body, $onderwerp ) = @_;

    $c->stash->{email} = {
        from    => $c->config->{gemeente}->{zaak_email},
        to      => $c->stash->{rcpt},
        subject => $onderwerp,
        body    => $body,
    };
    $c->log->debug(Dumper($c->stash->{email}));

    $c->forward( $c->view('Email') );
}

sub _replace_kenmerken {
    my ($self, $c, $body)  = @_;

    my $zaak    = $c->stash->{zaak};
    my $zt      = $zaak->definitie;

    if ($zt->kenmerken->count) {
        my $kenmerken       = $zt->kenmerken->search();

        while (my $kenmerk  = $kenmerken->next) {
            next if $kenmerk->bibliotheek_kenmerken_id->value_type eq 'file';
            my $rtkey       = $kenmerk->rtkey;
            next unless $zaak->kenmerk->$rtkey;

            my $replace_value;
            if (UNIVERSAL::isa($zaak->kenmerk->$rtkey, 'ARRAY')) {
                $replace_value = join(', ', @{ $zaak->kenmerk->$rtkey });
            } else {
                $replace_value = $zaak->kenmerk->$rtkey;
            }

            $body = $self->_kenmerk_replace(
                $body,
                $kenmerk->magic_string,
                $replace_value
            );
        }
    }

    return $self->_replace_base_kenmerken($c, $body);
}

sub _kenmerk_replace {
    my ($self, $body, $key, $value) = @_;

    $body =~ s/\[\[$key\]\]/$value/g;

    return $body;
}

sub _replace_base_kenmerken {
    my ($self, $c, $body) = @_;

    my $zaak = $c->stash->{zaak};

    # zaaknummer
    $body = $self->_kenmerk_replace(
        $body,
        'zaaknummer',
        $zaak->nr
    );

    # zaaktype
    $body = $self->_kenmerk_replace(
        $body,
        'zaaktype',
        $zaak->kenmerk->zaaktype_naam
    );

    # behandelaar
    if ($zaak->kenmerk->behandelaar) {
        $body = $self->_kenmerk_replace(
            $body,
            'behandelaar',
            $zaak->kenmerk->behandelaar->naam,
        );
        $body = $self->_kenmerk_replace(
            $body,
            'behandelaar_tel',
            $zaak->kenmerk->behandelaar->naam,
        );
    }

    # naam status
    $body = $self->_kenmerk_replace(
        $body,
        'statusnaam',
        $zaak->zaakstatus->currentnode->naam
    );

    # statusnummer
    $body = $self->_kenmerk_replace(
        $body,
        'statusnummer',
        $zaak->kenmerk->status
    );

    # contactkanaal
    $body = $self->_kenmerk_replace(
        $body,
        'contactkanaal',
        $zaak->kenmerk->contactkanaal
    );

    # besluit
    $body = $self->_kenmerk_replace(
        $body,
        'besluit',
        $zaak->kenmerk->besluit || '',
    );
    #registratiedatum
    $body = $self->_kenmerk_replace(
        $body,
        'startdatum',
        $zaak->kenmerk->registratiedatum->dmy
    ) if $zaak->kenmerk->registratiedatum;

    # streefafhandeldatum
    $body = $self->_kenmerk_replace(
        $body,
        'streefafhandeldatum',
        $zaak->kenmerk->streefafhandeldatum->dmy
    ) if $zaak->kenmerk->streefafhandeldatum;

    # resultaat
    $body = $self->_kenmerk_replace(
        $body,
        'resultaat',
        $zaak->kenmerk->resultaat || ''
    );

    # zaaktype
    if ($zaak->kenmerk->aanvrager) {
        $body = $self->_kenmerk_replace(
            $body,
            'aanvrager_naam',
            $zaak->kenmerk->aanvrager->naam
        );

        # zaaktype
        $body = $self->_kenmerk_replace(
            $body,
            'aanvrager_straat',
            $zaak->kenmerk->aanvrager->straatnaam
        );

        # zaaktype
        $body = $self->_kenmerk_replace(
            $body,
            'aanvrager_nr',
            $zaak->kenmerk->aanvrager->huisnummer
        );

        # zaaktype
        $body = $self->_kenmerk_replace(
            $body,
            'aanvrager_postcode',
            $zaak->kenmerk->aanvrager->postcode
        );

        # zaaktype
        $body = $self->_kenmerk_replace(
            $body,
            'aanvrager_plaats',
            $zaak->kenmerk->aanvrager->woonplaats
        );
        # zaaktype
        $body = $self->_kenmerk_replace(
            $body,
            'aanvrager_geslacht',
            $zaak->kenmerk->aanvrager->geslachtsaanduiding
        );
    }

    if ($zaak->kenmerk->zaakeigenaar) {
        $body = $self->_kenmerk_replace(
            $body,
            'coordinator_tel',
            $zaak->kenmerk->zaakeigenaar->telefoonnummer
        );

        # coordinator
        $body = $self->_kenmerk_replace(
            $body,
            'coordinator',
            $zaak->kenmerk->zaakeigenaar->naam
        );
    }

    return $body;
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

