package Zaaksysteem::Controller::Plugins::Ogone;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use Data::Dumper;




#sub test : Local {
#    my ($self, $c) = @_;
#
#    unless ($c->req->params->{zaaknr}) {
#        $c->res->body('Do not forget: ?zaaknr=RANDOMNR');
#        $c->detach;
#    }
#
#    $c->stash->{ogone}      = $c->model('Plugins::Ogone');
#    $c->stash->{ogone}->start_payment(
#        amount          => '5000',
#        omschrijving    => 'Test betaling 50 eurie',
#        zaaknr          => $c->req->params->{zaaknr},
#        shapass         => $c->customer_instance->{start_config}
#            ->{'Model::Plugins::Ogone'}
#            ->{'shapass'},
#    );
#
#    $c->stash->{template}   = 'plugins/ogone/test_betaling.tt';
#}

sub base : Chained('/') : PathPart('plugins/ogone/api'): CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{nowrapper} = 1;
    $c->log->debug(Dumper($c->req->params));

    $c->stash->{template}       = 'plugins/ogone/mislukt.tt';
    $c->stash->{ogone_error}    = 'Uw betaling is mislukt.';

    ### Loop over given parameters
    $c->stash->{ogone}      = $c->model('Plugins::Ogone');

    #$c->log->debug(Dumper($c->req->query_params));

    $c->stash->{ogone}->verify_payment(
        %{ $c->req->query_params },
        shapass         => $c->customer_instance->{start_config}
            ->{'Model::Plugins::Ogone'}
            ->{'shapass'},
    );

    $c->detach unless $c->stash->{ogone}->verified;

    ### Extra check. Make sure the amount is correct
    my $orderid     = $c->stash->{ogone}->orderid;

    my ($zaaknr)    = $orderid =~ /z(\d+)/;

    $c->stash->{zaak} = $c->model('DB::Zaak')->find($zaaknr);

    unless ($c->stash->{zaak}) {
        $c->log->error(
            'Z::C::P::Ogone->base: zaak not found'
        );

        $c->detach;
    }
}

sub betaling : Private {
    my ($self, $c) = @_;

    ### Able to pay?
    {
        ### Zaak aangemaakt?
        return unless $c->stash->{zaak};

        ### Betaling ok? XXX
        #return unless $c->stash->{zaak}->definitie->online_betaling;

        ### Benodigde PDC informatie aanwezig?
        return unless
            $c->stash->{_online_betaling_kosten} ||
            (
                $c->stash->{zaak}->zaaktype_node_id->zaaktype_definitie_id->pdc_tarief
            );
    }

    unless (
        $c->stash->{zaak}->status('stalled') &&
        $c->stash->{zaak}->reden_opschorten
            =~ /wachten.*betaling/i
    ) {
        return;
    }

    $c->stash->{ogone}      = $c->model('Plugins::Ogone');

    my $amount              =
        $c->stash->{_online_betaling_kosten} ||
        $c->stash->{zaak}->zaaktype_node_id->zaaktype_definitie_id->pdc_tarief;

    $c->stash->{ogone_amount} = $amount;

    my $omschrijving        = (
        $c->stash->{zaak}->onderwerp ||
        $c->stash->{zaak}->zaaktype_node_id->titel
    );

    ### Remove number seperator
    my $human_amount = $amount;

    $amount =~ s/\.//g;

    $c->stash->{ogone}->start_payment(
        amount          => $amount,
        omschrijving    => $omschrijving,
        zaaknr          => $c->stash->{zaak}->id,
        shapass         => $c->customer_instance->{start_config}
            ->{'Model::Plugins::Ogone'}
            ->{'shapass'},
    );

    ### Put zaak on opgeschort
    $c->stash->{zaak}->status('stalled');
    $c->stash->{zaak}->reden_opschorten(
        'Wachten op betaling'
    );
    $c->stash->{zaak}->update;
    $c->stash->{zaak}->logging->add({
        'component'     => 'zaak',
        'onderwerp'     => 'Zaak opgeschort: '
            . 'Wachten op betaling (EUR: ' . $human_amount . ')'
    });


    $c->stash->{nowrapper} = undef;
    $c->stash->{template}   = 'plugins/ogone/betaling.tt';
}

sub accept : Chained('base') : PathPart('accept'): Args(0) {
    my ($self, $c) = @_;

    unless ($c->stash->{ogone}->succes) {
        $c->log->error(
            'Z::C::P::Ogone->accept: not succesfull transaction'
        );

        $c->detach;
    }

    ### XXX Watch: met bijvoorbeeld parkeervergunningen is dankzij de plugin
    ### e.e.a. aan kosten dynamisch, dit halen we dus niet uit zaaktype beheer.
    ### Aanname: wanneer er geen amount is bij zaaktype beheer, controleren we
    ### niet het bedrag.
    if ($c->stash->{zaak}->zaaktype_node_id->zaaktype_definitie_id->pdc_tarief) {
        my $amount      =
            $c->stash->{zaak}
                ->zaaktype_node_id
                ->zaaktype_definitie_id
                ->pdc_tarief;

        $amount =~ s/\.//g;

        if ($amount ne $c->stash->{ogone}->amount) {
            $c->log->error(
                'Z::C::P::Ogone->accept: amount error:'
                . ' amount in return from ogone and in zaak are not the same'
                . ' O: ' . $c->stash->{ogone}->amount
                . ' Z: ' . $amount
            );

            $c->detach;
        }
    }

    my $human_amount = sprintf("%.2f", ($c->stash->{ogone}->amount / 100));

    if ($c->stash->{zaak}->status eq 'stalled') {
        $c->stash->{zaak}->status('new');
        $c->stash->{zaak}->update;

        # Skipped notifications, now is time to send
        {
            $c->stash->{notificatie}    = {
                'status'        => 1
            };

            $c->forward('/zaak/mail/notificatie');
        }
    }

    $c->stash->{zaak}->reden_opschorten('');
    $c->stash->{zaak}->logging->add({
        'component'     => 'zaak',
        'onderwerp'     => 'Betaling via ogone ontvangen: EUR '
            . $human_amount
    });


    $c->stash->{zaaktype}   = $c->stash->{zaak}->zaaktype_node_id;
    $c->stash->{nowrapper}  = 1;

    $c->stash->{template}   = 'form/finish.tt';
}

sub decline : Chained('base') : PathPart('decline'): Args(0) {
    my ($self, $c) = @_;

    $c->stash->{zaak}->status('deleted');
    $c->stash->{zaak}->deleted(DateTime->now());
    $c->stash->{zaak}->update;
}

sub exception : Chained('base') : PathPart('exception'): Args(0) {
    my ($self, $c) = @_;

    #$c->stash->{zaak}->status('deleted');
}

sub cancel : Chained('base') : PathPart('cancel'): Args(0) {
    my ($self, $c) = @_;

    $c->stash->{zaak}->status('deleted');
    $c->stash->{zaak}->deleted(DateTime->now());
    $c->stash->{zaak}->update;
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

