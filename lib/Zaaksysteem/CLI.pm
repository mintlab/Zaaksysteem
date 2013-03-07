package Zaaksysteem::CLI;

use Moose;
use DBI;
use Term::ReadLine;

has [qw/_term is_installed config/] => (
    'is'    => 'rw',
);

sub BUILD {
    my $self    = shift;

    $self->_detect_zaaksysteem;
    $self->_load_zaaksysteem_config;
}

sub _detect_zaaksysteem {
    my $self    = shift;

    if (-f '/etc/zaaksysteem/zaaksysteem.conf') {
        return $self->is_installed(1);
    }

    $self->_term(Term::ReadLine->new('Zaaksysteem'));

    return;
}

sub _load_zaaksysteem_config {}

sub _ask_question {
    my $self    = shift;
    my ($question, $options, $default, $prefill) = @_;

    print "\n";
    my $answer;

    while (
        $answer = $self->_term->readline(
            $question . ' [' . uc($default) . '/'
                . join("/", @{ $options }[1..(scalar(@{ $options })-1)]) . '] > ',
            $prefill
        )
    ) {
        if (grep { lc($answer) eq lc($_) } @{ $options }) {
            return $answer;
        }

        print "\nOngeldig antwoord\n";
    }

    if (!$answer && $default) {
        return lc($default);
    }

    return;
}

sub headline {
    my $self    = shift;
    my $title   = shift;

    my $length  = 70;

    print "\n";
    if ($title) {
        my $newlength   = ($length - (length($title) + 2));
        my $halflength  = int($newlength / 2);

        my $textstring  = '';
        $textstring     .= "*" x $halflength;
        $textstring     .= ' ' . $title . ' ';
        $textstring     .= "*" x $halflength;

        if (length($textstring) < $length) {
            $textstring .= "*" x ($length - length($textstring));
        }

        print $textstring . "\n";
        return $textstring;
    }

    print "*" x $length;
    print "\n";
}

sub check_zaaksysteem_environment {
    my $self    = shift;

    ### Check running daemons
    my $pslist      = `ps ax`;
    my @checks      = qw/postgres clamd slapd/;

    my @found       = ();
    for my $psline (split("\n", $pslist)) {
        for my $check (@checks) {
            next if grep { $check eq $_ } @found;
            if ($psline =~ /$check/) {
                push(@found, $check)
            }
        }
    }

    my @missing;
    if (@found >= @checks) {
        return 1;
    } else {
        for my $check (@checks) {
            next if grep { $check eq $_ } @found;
            push(@missing, $check);
        }
    }

    $self->headline('ERROR');
    print "Missing required packages:\n- " . join("\n- ", @missing);
    print "\n\nZorg ervoor dat u bovengenoemde packages succesvol heeft"
          . " geinstalleerd";
    $self->headline;
    return 1;
}

sub install_zaaksysteem {
    my $self    = shift;

    #$self->install_zaaksysteem_db or return;
}

sub install_zaaksysteem_db {
    my $self    = shift;

    my $dsn     = 'dbi:Pg:dbname=template1';

    my $dbh     = DBI->connect($dsn);

    if (!$dbh) {
        $self->headline("ERROR");
        print "Kan geen verbinding maken met PostgreSQL als root";

        return;
    }

    my $sth = $dbh->prepare(
        'SELECT datname FROM pg_database WHERE datname = ?'
    );
    $sth->execute('zaaksysteem_beheer');

    if ($sth->rows) {
        $self->headline("ERROR");
        print "Database zaaksysteem_beheer bestaat al, dit is _geen_ installatie";
        return;
    }

    $sth = $dbh->prepare(
        'SELECT datname FROM pg_database WHERE datname = ?'
    );
    $sth->execute('zaaksysteem_gegevens');

    if ($sth->rows) {
        $self->headline("ERROR");
        print "Database zaaksysteem_gegevens bestaat al, dit is _geen_ installatie";
        return;
    }

    my $createdb = $dbh->prepare('CREATE DATABASE zaaksysteem_beheer');
    if ($createdb->execute) {
        print "\n[INFO] Database zaaksysteem_beheer aangemaakt";
    }

    $createdb = $dbh->prepare('CREATE DATABASE zaaksysteem_gegevens');
    if ($createdb->execute) {
        print "\n[INFO] Database zaaksysteem_gegevens aangemaakt";
    }

    ### LOAD SQL FILES HERE
    
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

