#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use Catalyst::Model::DBIC::Schema;
use Catalyst::Log;

use Zaaksysteem::Gegevens::ImportBouwHistory;


# Laad modules

BEGIN { use_ok 'Catalyst::Model::DBIC::Schema' }
BEGIN { use_ok 'Catalyst::Log' }
BEGIN { use_ok 'CleanDB' }


### Start logging
my $log;
{
    $log = Catalyst::Log->new();
}

### Start DATABASE
my ($dbic);
{
    Catalyst::Model::DBIC::Schema->config(
        schema_class => 'Zaaksysteem::Schema',
        connect_info => {
            dsn             => "dbi:Pg:dbname=zaaksysteem_beheer",
            pg_enable_utf8  => 1,
        }
    );

    my $db          = Catalyst::Model::DBIC::Schema->new();
    $dbic           = $db->schema;
}

my ($dbicg);
{
    Catalyst::Model::DBIC::Schema->config(
        schema_class => 'Zaaksysteem::SchemaGM',
        connect_info => {
            dsn             => "dbi:Pg:dbname=zaaksyteem_gegevens",
            pg_enable_utf8  => 1,
        }
    );

    my $db          = Catalyst::Model::DBIC::Schema->new();
    $db->schema->default_resultset_attributes->{log} = $log;

    $dbicg           = $db->schema;
}


### PREPARATION

my ($config);
{
    $config = {'filename' => 'Bouwhistorie 0.13.csv'};
}

my $files_dirs = {
                    'correspondentie_from' => 'import_bouwhistory/DOCUMENTEN',
                    'correspondentie_to'   => 'files/documents',
                    'tekeningen_from'      => 'import_bouwhistory/TEKENINGEN',
                    'tekeningen_to'        => 'files/documents',
                 };




# HIER GAAT IE DAN
my $bouwimport    = Zaaksysteem::Gegevens::ImportBouwHistory->new(
    prod            => 0,
    log             => $log,
    dbic            => $dbic,
    dbicg           => $dbicg,
    config          => $config,
    files_dirs      => $files_dirs,
);

$bouwimport->run;

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

