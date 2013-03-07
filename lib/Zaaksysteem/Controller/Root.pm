package Zaaksysteem::Controller::Root;

use strict;
use warnings;
use Data::Dumper;
use parent 'Catalyst::Controller';

use Zaaksysteem::Constants qw/
    ZAAKTYPE_KENMERKEN_ZTC_DEFINITIE
    ZAAKTYPE_KENMERKEN_DYN_DEFINITIE
/;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';


sub begin : Private {
    my ($self, $c) = @_;

    ### C::P
    if (!$c->forward('/page/begin')) { return; }
}


sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('/zaak/list');
}


sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub forbidden : Private {
    my ($self, $c) = @_;

    $c->stash->{template} = 'forbidden.tt';
    $c->detach;
}

#sub test : Local {
#    my ($self, $c)  = @_;
#
#    my $rt = ZAAKTYPE_KENMERKEN_ZTC_DEFINITIE;
#
#    my $output = "\n";
#    for my $value (@{ $rt }) {
#        $output .= "        '" . sprintf("%-32s", 'ztc_' . $value->{naam} ."'") . "=> '" .  $value->{naam} ."',\n"
#    }
#    $rt = ZAAKTYPE_KENMERKEN_DYN_DEFINITIE;
#
#    $output .= "\n\n";
#    for my $value (@{ $rt }) {
#        $output .= "        '" . sprintf("%-32s", $value->{naam} ."'") . "=> '" .  $value->{naam} ."',\n"
#    }
#
#    $c->log->debug($output);
#}
#
#sub test2 : Local {
#    my ($self, $c) = @_;
#
#    $c->log->debug(Dumper(my $url = $c->model('Plugins::Digid')->verify));
#}

# TEST CYCLE
sub test_cycle : Local {
    my ($self, $c, $todo) = @_;

    $c->res->body('rruaarrr');


#    return unless $todo;
    if ($todo eq 'empty') {
        my $zaak = $c->model('Zaak')->get(300);

        #    $c->log->debug($zaak->kenmerk->aanvrager->naam);


        #$c->model('Zaak')->get(299);
        #$c->model('Zaak')->get(298);
        #$c->model('Zaak')->get(297);
        $c->log->debug('Zaken loaded');
    } elsif ($todo eq 'zaaktype') {
        $c->model('Zaaktype')->retrieve(id => 1);
    }

}




sub end : ActionClass('RenderView') {}


sub monitor : Global {
    my ($self, $c)  = @_;

    if ($c->req->params->{false}) {
        $c->res->body('CHECKFALSE (forcefalse: geforceerd afgebroken)');
        $c->detach;
    }

    ### Prevent DOS
    my $logging = $c->model('DB::Logging')->search(
        {
            'created'   => { '>' => DateTime->now()->subtract(seconds => 180)
            },
            'onderwerp' => { 'like' => '%' . $c->req->address . '%' }
        },
        { rows => 1 }
    );

    if ($logging->count) {
        $c->res->body('CHECKOK');
        $c->detach;
    }

    my $allok   = 1;
    my @msgs    = ();
    for my $check (qw/diskspace database/) {
        my $routine = '_monitor_' . $check;

        unless ((my $msg = $c->forward($routine)) == 1) {
            $allok = undef;

            $c->log->debug('WUT: ' . $msg);
            push(@msgs, $check . ': ' . $msg);
        }
    }

    if ($allok) {
        $c->res->body('CHECKOK');
        $c->detach;
    }

    $c->res->body('CHECKFALSE (' . join(',', @msgs) . ')');
}

sub _monitor_database : Private {
    my ($self, $c) = @_;

    my $now     = DateTime->now(time_zone => 'Europe/Amsterdam');

    my $log     = $c->model('DB::Logging')->create(
        {
            component   => 'MONITOR',
            onderwerp   => 'Global monitoring check ('
                . $now->dmy . ' ' .  $now->hms . ') IP: '
                . '[' . $c->req->address . ']'
        },
    );

    unless ($log && $log->id) {
        return 'Could not write to database';
    }

    ### Raadpleeg first zaaktype
    my $logging = $c->model('DB::Logging')->search({}, { rows => 1 });

    if ($logging->count) {
        return 1;
    }

    return 'Could not read from database (or no logging found)';
}

sub _monitor_diskspace : Private {
    my ($self, $c)  = @_;

    my $dir         = $c->config->{files};
    my $minspace    = $c->config->{monitor}->{minspace} || (1024 * 1024);
    my $space       = `df $dir`;

    my ($size,$used,$avail) = $space =~ /\s+(\d+)\s+(\d+)\s+(\d+)/;

    if ($avail < $minspace) {
        return $avail . ' is less than ' . $minspace . ' bytes';
    }

    return 1;
}



sub http_error : Private {
    my ( $self, $c, %opt ) = @_;
    my @valid_types = qw/404 403 500/;

    ### Defaults to 404 handling
    $opt{type} = 404 unless $opt{type};

    ### Some security awareness in place
    $opt{type} = 500 unless grep({$opt{type} eq $_} @valid_types);

    ### Set response status
    $c->res->status($opt{type});

    ### Error handling, send template error information and set view
    $c->stash->{error} = \%opt;
    $c->stash->{template} = 'error/' . $opt{type} . '.tt';

    return $opt{type};
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

