#!/usr/bin/perl

use warnings;
use strict;

use lib '../lib';

use Zaaksysteem::CLI;

$|++;
system $^O eq 'MSWin32' ? 'cls' : 'clear';

### Load CLI object
my $cli     = Zaaksysteem::CLI->new;

sub install {
    $cli->headline('INSTALLATIE');
    print "=> Het ziet er naar uit dat zaaksysteem.nl nog niet is geinstalleerd"
        ." op het huidige systeem.\n"
        ."=> We kunnen een lege installatie klaarzetten";

    my $result = $cli->_ask_question('Wilt u zaaksysteem.nl installeren?', [ 'y','n' ], 'y');

    if ($result eq 'y') {
        print "\n[CHECK] Zaaksysteem installatie wordt gecontroleerd";
        if ($cli->check_zaaksysteem_environment) {
            $cli->install_zaaksysteem;
        } else {

        }
    }
}

sub main {
    `clear`;
    print "Zaaksysteem installatie script. We controleren uw zaaksysteem...\n\n";

    if (!$cli->is_installed) {
        install();
    } else {
        upgrade();
    }

    print "\nWerkzaamheden uitgevoerd, enjoy!!";
}

main();
print "\n";
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

