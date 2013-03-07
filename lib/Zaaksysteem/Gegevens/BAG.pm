package Zaaksysteem::Gegevens::BAG;

use strict;
use warnings;

use Params::Profile;
use Data::Dumper;
use Zaaksysteem::Constants;

use Moose;
use namespace::autoclean;

use constant BAG_PREFIX   => 'bag_';

with __PACKAGE__ . '::Import';


has [qw/config prod log dbicg bag_current_table active_xpath_load/] => (
    'is'    => 'rw',
);



{
    Params::Profile->register_profile(
        method  => 'retrieve',
        profile => {
            required        => [ qw/
                id
            /],
            'optional'      => [ qw/
                type
            /],
            'constraint_methods'    => {
                'id'    => qr/^(?:\w+-)?\d+$/,
                'type'  => qr/^\w+$/,
            },
        }
    );

    sub retrieve {
        my $self    = shift;
        my %opts;

        if (UNIVERSAL::isa($_[0], 'HASH')) {
            %opts = %{ $_[0] };
        } else {
            %opts = @_;
        }

        my $dv = Params::Profile->check(
            params  => \%opts
        );


        do {
            $self->log->error(
                'Zaaktype->retrieve: invalid options'
            );
            return;
        } unless $dv->success;

        ### Retrieve bag i
        my $bagid   = $dv->valid('id');
        my $bagtype = $dv->valid('type');

        if ($bagid =~ /-/) {
            ($bagtype, $bagid)  = $bagid  =~ /(\w+)-(\d+)$/;
        }

        do {
            $self->log->error(
                'Zaakbagtype->retrieve: invalid options: no bagtype given'
            );
            return;
        } unless $bagtype;

        my $bag = $self->_retrieve_bag_entry($bagid, $bagtype);

        return $bag;
    }

    sub _retrieve_bag_entry {
        my ($self, $bagid, $bagtype) = @_;
        my ($bag);

        my $resultsetname   = 'Bag' . ucfirst(lc($bagtype));
        return unless $bagid;

        unless (
            $self->dbicg->resultset($resultsetname) &&
            ($bag = $self->dbicg->resultset($resultsetname)->search(
                    'identificatie'    => $bagid)
            )
        ) {
            $self->log->error(
                'Gegevens::BAG->retrieve: Cannot find bag of type ' . $bagtype
                . ' with bag_id: '
                . $bagid
            );

            return;
        }

        return $bag->first if $bag->count;

        $self->log->error(
            'Gegevens::BAG->retrieve: dit not found exactly one entry'
            . ' for bagid: ' . $bagid
        );
        return;
    }
}

sub bag_human_view_by_id {
    my ($self, $bagid, $bagtype)  = @_;

    if (!$bagtype) {
        ($bagtype, $bagid)  = $bagid =~ /^(\w+)-(\d+)/;
    }

    $bagtype = 'nummeraanduiding' unless $bagtype;

    my $bag = $self->_retrieve_bag_entry($bagid, $bagtype)
        or return;

    if (lc($bagtype) eq 'nummeraanduiding') {
        return $bag->openbareruimte->naam . ' ' .  $bag->nummeraanduiding;
    }

    if (lc($bagtype) eq 'pand') {
        return 'Bouwjaar: ' . $bag->bouwjaar;
    }

    if (lc($bagtype) eq 'verblijfsobject') {
        return 'Oppervlakte: ' . $bag->oppervlakte;
    }

    if (lc($bagtype) eq 'standplaats') {
        return '-';
    }

    if (lc($bagtype) eq 'ligplaats') {
        return '-';
    }

    if (lc($bagtype) eq 'openbareruimte') {
        return $bag->woonplaats->naam . ' > ' . $bag->naam;
    }

    return '';
}

### RT NOTATION:
### openbareruimte,pand-234234,openbareruimte-4234234,verblijfsobject-223

sub get_rt_kenmerk_trigger {
    my ($self, $value) = @_;

    my ($bagtype, $bagid)  = $value =~ /^(\w+)-(\d+)/;

    $self->log->error(
        'G::BAG->get_rt_kenmerk_trigger: ' . $value
    );

    unless ($bagtype) {
        $self->log->error(
            'G::BAG->get_rt_kenmerk_trigger: '
            . 'Bagtype not given for [BAGTYPE-NR] value: ' .  $value
        );
        return;
    }

    my $bag = $self->_retrieve_bag_entry($bagid, $bagtype)
        or do {
            $self->log->error(
                'G::BAG->get_rt_kenmerk_trigger: '
                . 'Did not find ' . $bagtype . ' for value: ' .  $value
            );
            return;
        };

    my $rv  = $bagtype . ',' . $bagtype . '-' . $bagid;

    my ($pand, $vo, $na, $or);
    if ($bagtype eq 'verblijfsobject') {
        if ($bag->panden->count) {
            $pand    = $bag->panden->first;
        };

        $na = $bag->hoofdadres;

        $or = $na->openbareruimte;
    } elsif ($bagtype eq 'nummeraanduiding') {
        if ($bag->verblijfsobjecten->count) {
            $vo  = $bag->verblijfsobjecten->first;
        }

        if ($vo->panden->count) {
            $pand    = $vo->panden->first;
        };

        $or = $bag->openbareruimte;
    }

    # PAND
    $rv .= ',pand-' . $pand->pand->identificatie
        if ($pand && $pand->pand && $pand->pand && $bagtype ne 'pand');

    # NUMMERAANDUIDING
    $rv .= ',nummeraanduiding-' . $na->identificatie
        if ($na && $bagtype ne 'nummeraanduiding');

    # VERBLIJFSOBJECT
    $rv .= ',verblijfsobject-' . $vo->identificatie
        if ($vo && $bagtype ne 'verblijfsobject');

    # OPENBARERUIMTE
    $rv .= ',openbareruimte-' . $or->identificatie
        if ($or && $bagtype ne 'openbareruimte');
    return $rv;

}

sub remove_rt_kenmerk_trigger {
    my ($self, $value) = @_;

    my @fields      = split(/,/, $value);
    my $objecttype  = shift(@fields);

    my @desired_object = grep(/^$objecttype/, @fields);

    return shift(@desired_object);
}

sub import_bag {
    my ($self) = @_;


    #my $bag_id    = $self->config->{'bag_dir'};
    #my $plaats_id = $self->config->{'plaats_id'};

    my $bag_dir           = '/home/zaaksysteem/bussum/import';
    my $bag_extract_dir = '/tmp/BAG';
    my $plaats_id         = '1331';

    my $bag_file = $self->get_bag_import_file($bag_dir) or return;

    $self->process_bag_zip($bag_dir,$bag_file, $plaats_id, $bag_extract_dir);
}


sub get_bag_import_file {
    my ($self, $bag_dir) = @_;

    # Uitlezen bag_dir en laatste import bestand pakken
    my $filedate = 0;
    my $import_file = '';
    opendir(IMD, $bag_dir) || die("Cannot open directory");
    while ( defined (my $file = readdir IMD) ) { 
        next if $file !~ /(\d+)\.zip$/; 
        
        $import_file = $file if ($filedate < $1);
    }

    return $import_file unless ($import_file eq '');
    
    $self->log->error('Import BAG: Geen import bestand kunnen vinden!');
    
    return;
}


sub process_bag_zip {
    my ($self, $bag_dir, $bag_file, $plaats_id, $bag_extract_dir) = @_;

    use Archive::Zip;

    my $plaatsen_zip = Archive::Zip->new();
    unless ( $plaatsen_zip->read( $bag_dir.'/'.$bag_file ) == Archive::Zip::AZ_OK ) {
        die 'read error';
    }

    my @plaatsen_zip_namen = $plaatsen_zip->memberNames();
    my $plaats_zip_naam = '';

    foreach $plaats_zip_naam (@plaatsen_zip_namen) {
        next if $plaats_zip_naam !~ /^$plaats_id/;

        my $full_path_plaats_zip = $self->extract_zip_member_to_dir ($plaatsen_zip, $plaats_zip_naam, $bag_extract_dir);

        $self->process_plaats_zip($full_path_plaats_zip);
    }
    
    $self->log->error('Import BAG: Geen plaats-zip gevonden in import bestand!') if ($plaats_zip_naam eq '');
    
    return;
}


sub process_plaats_zip {
    my ($self, $full_path_plaats_zip) = @_;
    
    $full_path_plaats_zip =~ /(.+)\.zip$/;
    my $extract_dir = $1;

    unless (-d $extract_dir) {
        $self->log->info("Extract dir $extract_dir bestond niet en wordt aangemaakt!");
        mkdir ($extract_dir, 0777); 
    }

    # Eerst extracten van de plaats-zip
    my $plaats_zip = Archive::Zip->new();

    unless ( $plaats_zip->read( $full_path_plaats_zip ) == Archive::Zip::AZ_OK ) {
        die 'read error';
    }

    my @plaats_data_namen = $plaats_zip->memberNames();

    my %zip_files = ();
    for my $plaats_data_naam (@plaats_data_namen) {
        my $xml_file = $plaats_data_naam;
        $xml_file =~ s/(\d*([[:alpha:]]+).*)\.zip$/$1\.xml/;

        $zip_files{$2} = $self->extract_zip_member_to_dir($plaats_zip, $plaats_data_naam, $extract_dir);
    }
    
    # Doorlopen en extracten van de zip-bestanden gevonden in de plaats-zip
    my $xml_files = {};
    while (my ($table, $zip_file) = each(%zip_files)){
        my $table_zip = Archive::Zip->new();

        unless ( $table_zip->read( $zip_file ) == Archive::Zip::AZ_OK ) {
            die 'read error';
        }

        my @plaats_data_namen = $table_zip->memberNames();


        for my $plaats_data_naam (@plaats_data_namen) {
            my $extracted_xml_file = $self->extract_zip_member_to_dir($table_zip, $plaats_data_naam, substr($zip_file,0,-4));
            push (@{ $xml_files->{$table} }, $extracted_xml_file);
        }
    }


    my $bagtables = {
        WPL => 'BagWoonplaats',
        LIG => 'BagLigplaats',
        NUM => 'BagNummeraanduiding',
        OPR => 'BagOpenbareruimte',
        PND => 'BagPand',
        STA => 'BagStandplaats',
        VBO => 'BagVerblijfsobject'
    };

    use XML::LibXML::XPathContext;

    eval {
        $self->dbicg->txn_do(sub {
            while (my ($table, $xml_files) = each(%{ $xml_files })){
                # Set member variable 'bag_current_table'
                $self->bag_current_table($bagtables->{$table});

                use XML::SAX;
                my ($handler, $parser); 

                if ($table eq 'WPL') {
                    use Zaaksysteem::Gegevens::ImportWoonplaatsXml;
                    $handler = Zaaksysteem::Gegevens::ImportWoonplaatsXml->new(prod => $self->prod, log => $self->log, dbicg => $self->dbicg);
                    $handler->set_db_columns();
                    $parser = XML::SAX::ParserFactory->parser(Handler => $handler);
                    for my $xml_file (@{ $xml_files }) {
                        $parser->parse_uri("$xml_file");
                    }
                }

                if ($table eq 'NUM') {
                    use Zaaksysteem::Gegevens::ImportNummeraanduidingXml;
                    $handler = Zaaksysteem::Gegevens::ImportNummeraanduidingXml->new(prod => $self->prod, log => $self->log, dbicg => $self->dbicg);
                    $handler->set_db_columns();
                    $parser = XML::SAX::ParserFactory->parser(Handler => $handler);
                    for my $xml_file (@{ $xml_files }) {
                        $parser->parse_uri("$xml_file");
                    }
                }

                if ($table eq 'LIG') {
                    use Zaaksysteem::Gegevens::ImportLigplaatsXml;
                    $handler = Zaaksysteem::Gegevens::ImportLigplaatsXml->new(prod => $self->prod, log => $self->log, dbicg => $self->dbicg);
                    $handler->set_db_columns();
                    $parser = XML::SAX::ParserFactory->parser(Handler => $handler);
                    for my $xml_file (@{ $xml_files }) {
                        $parser->parse_uri("$xml_file");
                    }
                }

                if ($table eq 'OPR') {
                    use Zaaksysteem::Gegevens::ImportOpenbareruimteXml;
                    $handler = Zaaksysteem::Gegevens::ImportOpenbareruimteXml->new(prod => $self->prod, log => $self->log, dbicg => $self->dbicg);
                    $handler->set_db_columns();
                    $parser = XML::SAX::ParserFactory->parser(Handler => $handler);
                    for my $xml_file (@{ $xml_files }) {
                        $parser->parse_uri("$xml_file");
                    }
                }

                if ($table eq 'PND') {
                    use Zaaksysteem::Gegevens::ImportPandXml;
                    $handler = Zaaksysteem::Gegevens::ImportPandXml->new(prod => $self->prod, log => $self->log, dbicg => $self->dbicg);
                    $handler->set_db_columns();
                    $parser = XML::SAX::ParserFactory->parser(Handler => $handler);
                    for my $xml_file (@{ $xml_files }) {
                        $parser->parse_uri("$xml_file");
                    }
                }

                if ($table eq 'STA') {
                    use Zaaksysteem::Gegevens::ImportStandplaatsXml;
                    $handler = Zaaksysteem::Gegevens::ImportStandplaatsXml->new(prod => $self->prod, log => $self->log, dbicg => $self->dbicg);
                    $handler->set_db_columns();
                    $parser = XML::SAX::ParserFactory->parser(Handler => $handler);
                    for my $xml_file (@{ $xml_files }) {
                        $parser->parse_uri("$xml_file");
                    }
                }

                if ($table eq 'VBO') {
                    # Tabel Verblijfsobject
                    use Zaaksysteem::Gegevens::ImportVerblijfsobjectXml;
                    $handler = Zaaksysteem::Gegevens::ImportVerblijfsobjectXml->new(prod => $self->prod, log => $self->log, dbicg => $self->dbicg);
                    $handler->set_db_columns();
                    $handler->set_db_columns();
                    $parser = XML::SAX::ParserFactory->parser(Handler => $handler);
                    for my $xml_file (@{ $xml_files }) {
                        $parser->parse_uri("$xml_file");
                    }

                        # Tabel VerblijfsobjectGebruikersdoel
                    use Zaaksysteem::Gegevens::ImportVerblijfsobjectGebruiksdoelXml;
                    $handler = Zaaksysteem::Gegevens::ImportVerblijfsobjectGebruiksdoelXml->new(prod => $self->prod, log => $self->log, dbicg => $self->dbicg);
                    $handler->set_db_columns();
                    $handler->set_db_columns();
                    $parser = XML::SAX::ParserFactory->parser(Handler => $handler);
                    for my $xml_file (@{ $xml_files }) {
                        $parser->parse_uri("$xml_file");
                    }

                    # Tabel VerblijfsobjectPand
                    use Zaaksysteem::Gegevens::ImportVerblijfsobjectPandXml;
                    $handler = Zaaksysteem::Gegevens::ImportVerblijfsobjectPandXml->new(prod => $self->prod, log => $self->log, dbicg => $self->dbicg);
                    $handler->set_db_columns();
                    $parser = XML::SAX::ParserFactory->parser(Handler => $handler);
                    for my $xml_file (@{ $xml_files }) {
                        $parser->parse_uri("$xml_file");
                    }
                }
            }
        });
    };

    if ($@) {
        $self->log->error('Error: ' . $@);
        die("ERROR IN (code binnen) TRANSACTION!");
    } else {
        $self->log->info('Zaaktype aangemaakt');
    }
}





sub extract_zip_member_to_dir {
    my ($self, $zip_file, $member_name, $extract_dir) = @_;
    
    unless (-d $extract_dir) {
        $self->log->info("Extract dir $extract_dir bestond niet en wordt aangemaakt!");
        mkdir ($extract_dir, 0777); 
    }

    #$zipfile->
    unless ( $zip_file->extractMember($member_name, "$extract_dir/$member_name") == Archive::Zip::AZ_OK ) {
        die 'extract error';
    }
    
    return "$extract_dir/$member_name";
}


__PACKAGE__->meta->make_immutable;

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

