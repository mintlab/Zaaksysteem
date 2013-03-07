package Zaaksysteem::General;

use strict;
use warnings;
use Zaaksysteem::Constants;
use Data::Dumper;
use Scalar::Util qw/blessed/;
use Net::LDAP;

use base qw/
    Zaaksysteem::General::Authentication
/;



sub add_trail {
    my ($c, $opts) = @_;

    if (!$c->stash->{trail}) {
        $c->stash->{trail} = [];
        $c->stash->{trail}->[0] = {
            'uri'   => $c->uri_for('/'),
            'label' => 'Dashboard',
        };
    }

    push(@{ $c->stash->{trail} }, $opts);
}


sub zvalidate {
    my ($c, $dv) = @_;

    unless (defined($dv)) {
        $dv = $c->check(params => $c->req->params, method => [caller(1)]->[3]);
    }

    die('Definition not found for: ' . [caller(1)]->[3]) unless ref($dv);

    $c->stash->{last_validation} = $dv;

    if (
        $c->req->header("x-requested-with") &&
        $c->req->header("x-requested-with") eq 'XMLHttpRequest') {
        # Do some JSON things
        my $json = {
            success     => $dv->success,
            missing     => [ $dv->missing ],
            invalid     => [ $dv->invalid ],
            unknown     => [ $dv->unknown ],
            valid       => [ $dv->valid ],
            msgs        => $dv->msgs,
        };

        $c->zcvalidate($json);
    }

    if ($dv->success) { return $dv; }

    ### Go log something
    my $errmsg = "Problems validating profile:";
    $errmsg .= "\n        Missing params:\n        * " .
                join("\n        * ", $dv->missing)
                if $dv->has_missing;
    $errmsg .= "\n        Invalid params:\n        * " .
                join("\n        * ", $dv->invalid)
                if $dv->has_invalid;
    $errmsg .= "\n        Unknown params:\n        * " .
                join("\n        * ", $dv->unknown)
                if $dv->has_unknown;
    $c->log->debug($errmsg);

    return;
}


sub zcvalidate {
    my ($c, $opts) = @_;
    my ($json);

    return unless (
        $c->req->header("x-requested-with") &&
        $c->req->header("x-requested-with") eq 'XMLHttpRequest'
    );

    unless (
        $opts->{success} ||
        ($opts->{invalid} && UNIVERSAL::isa($opts->{invalid}, 'ARRAY'))
    ) {
        return;
    }
    $json->{invalid}    = $opts->{invalid};

    $json->{success}    = $opts->{success} || undef;
    $json->{missing}    = $opts->{missing} || [];
    $json->{unknown}    = $opts->{invalid} || [];
    $json->{valid}      = $opts->{valid}   || [];
    $json->{msgs}       = $opts->{msgs}    || [];


    $c->stash->{json} = $json;
    $c->log->debug('JSON RESPONSE: ' . Dumper($c->stash->{json}));
    $c->forward('Zaaksysteem::View::JSON');
}

sub is_externe_aanvraag {
    my $c   = shift;

    return if $c->user_exists;

    return 1;
}

sub about {
    my $c   = shift;

    return {
        applicatie      => ZAAKSYSTEEM_NAAM,
        omschrijving    => ZAAKSYSTEEM_OMSCHRIJVING,
        leverancier     => ZAAKSYSTEEM_LEVERANCIER,
        versie          => $c->config->{SVN_VERSION},
        startdatum      => ZAAKSYSTEEM_STARTDATUM,
        licentie        => ZAAKSYSTEEM_LICENSE
    };
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

