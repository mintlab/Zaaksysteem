package Zaaksysteem::Gegevens::ImportBouwHistory;

use Test::More;

BEGIN { use_ok 'Zaaksysteem::Zaken' }
BEGIN { use_ok 'Zaaksysteem::Betrokkene' }

use strict;
use warnings;

use Params::Profile;
use Data::Dumper;
use Zaaksysteem::Constants;
use File::Copy;
use Digest::MD5::File qw(dir_md5_hex file_md5_hex url_md5_hex);

use Moose;
use namespace::autoclean;

use Text::CSV;
use Unicode::String;
use Encode qw/from_to/;

use utf8;

use Data::Dumper;




has [qw/prod log dbic dbicg config files_dirs/] => (
    'weak_ref'  => 1,
    'is'    => 'rw',
);


has [qw/z_betrokkene/] => (
    'is' => 'rw'
);


use constant BH_CSV_TABLE  => [
    qw/
        BAG_ID
        NR
        OBJECTNUMMER
        KOPPEL
        BOUWADRE
        NR_CORRECTIE
        BOUWHUIS
        BOUWNR
        BOUWBTZ
        BOUWVERL
        BOUWDOOS
        BOUWFI_C
        PDFCORRESPONDENTIE
        BOUWFI_T
        PDFTEKENING
        BOUWKADA
        BOUWOPME
        BOUWSOOR
    /
];


Params::Profile->register_profile(
    method  => 'run',
    profile => {
        required            => [],
        optional            => [],
        defaults            => {

        }
    }
);




sub run {
    my $self = shift;

    $self->z_betrokkene(Zaaksysteem::Betrokkene->new(
        dbic            => $self->dbic,
        dbicg           => $self->dbicg,
        log             => $self->log,
        prod            => $self->prod,
        config          => {
           authentication   => {
                realms          => {
                    zaaksysteem     => {
                        store           => {
                            ldap_server     => 'data1.zaaksysteem.nl',
                            user_basedn     => 'o=bussum,dc=zaaksysteem,dc=nl',
                        }
                    }
                }
            }
        },
    ));

    Unicode::String->stringify_as( 'utf8' );

    my $csv = Text::CSV->new( {
        binary      => 1,
        sep_char    => ',',
        allow_whitespace => 1,
    });

    open (my $fh, '<' . $self->config->{filename}) or return;

    $csv->column_names(BH_CSV_TABLE);

    my $i = 0;
    while (my $rawrow = $csv->getline_hr($fh)) {
        $i++;

        # Overslaan van de eerste rij (Zitten de kolomnamen in)
        next if $i == 1;

        my $dv  = Params::Profile->check(params => $rawrow);
        my $row = $dv->valid;

        eval {
            $self->dbic->txn_do(sub {
                #print Dumper($rawrow);
                $self->_insert_bouwzaak($rawrow);
                die  if $i == 5;
            });
        };

        if ($@) {
            ok(0, 'Problems inserting row in BAG: ' . $@);
            done_testing();
        }

        ok(1, '------------------------------------------');
    }

    if (!$csv->eof) {
        ok($csv->eof, 'ImportBouwvergunningen: error: ' . $csv->error_diag);

        close($fh);
        done_testing();
    }

    done_testing();
    close($fh);
}





sub _insert_bouwzaak {
    my ($self, $import_array) = @_;

    # Map van input CSV naar DB kolommen
    my $BH_DB  = {
        'BAG_ID'             => '',
        'NR'                 => '',
        'OBJECTNUMMER'       => '',
        'KOPPEL'             => '',
        'BOUWADRE'           => 'Correspondentie straatnaam',
        'NR_CORRECTIE'       => '',
        'BOUWHUIS'           => 'Correspondentie huisnummer ',
        'BOUWNR'             => 'Vergunningnummer',
        'BOUWBTZ'            => 'BTZ-nummer',
        'BOUWVERL'           => 'Verleningsdatum',
        'BOUWDOOS'           => 'Archiefdoosnummer',
        'BOUWFI_C'           => 'Fichenummer correspondentie',
        'PDFCORRESPONDENTIE' => 'Document correspondentie',
        'BOUWFI_T'           => 'Fichenummer tekening',
        'PDFTEKENING'        => 'Document bouwtekening',
        'BOUWKADA'           => 'Kadastraal nummer',
        'BOUWOPME'           => 'Opmerkingen',
        'BOUWSOOR'           => 'Omschrijving',
    };

    # In de verleningsdatum staat geen eeuwaanduiding
    # DUS halen we die uit het bouwnummer!
    my $bouwnr = $import_array->{'BOUWNR'};
    my ($eeuw) = $bouwnr =~ /^\s*(19|20)/; # NB: Eeuw in deze import is alleen 1900 of 2000!!!
    if (defined $eeuw) {
        ok ($eeuw, "Gevonden eeuw in het BOUWNR: $eeuw");
    } else {
        ok ($eeuw, "Geen eeuw gevonden in het BOUWNR ".$import_array->{'BOUWNR'});
        my $eeuw = '' ;
    }
    
    # Omzetten van de Verleningsdatum naar een correct formaat
    my $oude_datum = $import_array->{'BOUWVERL'};
    $oude_datum =~ s/^(\d+)\/(\d+)\/(\d+)$/00$1-00$2-00$3/ =~ /((\d{2})\-)((\d{2})\-)(\d{2}$)/;

    if (defined $3) {
        my $corr_datum = "$1-$2-$eeuw$3";
        ok($3, "Datum omzetten van ".$import_array->{'BOUWVERL'}.' naar '.$corr_datum);
        $import_array->{'BOUWVERL'} = $corr_datum;
    } else {
        my $corr_datum = '' ;
        ok($3, "Datum ".$import_array->{'BOUWVERL'}.' is leeg of is niet een correcte datum');
    }

    my @kenmerken = ();
    while (my ($col, $val) = each(%{ $import_array })) {
        if (my $db_col = $BH_DB->{$col}) {
            push(@kenmerken, { $db_col => $val })
        }
    }

    ### Open Zaaktypen
    my $zaken           = Zaaksysteem::Zaken->new(
        dbic            => $self->dbic,
        z_betrokkene    => $self->z_betrokkene,
        log             => $self->log,
        prod            => $self->prod,
    );

    $zaken->dbic->default_resultset_attributes->{betrokkene_model} = $self->z_betrokkene;
    $zaken->dbic->default_resultset_attributes->{dbic_gegevens}    = $self->dbicg;

    ok($zaken, 'Zaken constructor succes');


    my $onderwerp = $import_array->{'BOUWADRE'}.' '.$import_array->{'BOUWHUIS'}.' - '.$import_array->{'BOUWBTZ'};


    # Kijk of er een adres is met het BAG_ID uit de csv
    $import_array->{'BAG_ID'} = 'L';
    ok(1, 'BAG_ID: '.$import_array->{'BAG_ID'});

    my $nummeraanduiding = $self->dbicg->resultset('BagNummeraanduiding')->find({'identificatie' => $import_array->{'BAG_ID'}});
    ok($nummeraanduiding, "GEVONDEN Nummeraanduiding met BAG-ID: ".$import_array->{'BAG_ID'}) if defined $nummeraanduiding;

    if (not defined $nummeraanduiding) {
        ok($nummeraanduiding, "NIET GEVONDEN: Geen nummeraanduiding gevonden met BAG-ID: ".$import_array->{'BAG_ID'}.
        " :ZAAK WORDT NIET AANGEMAAKT!!!");
        return 1;
    }


    my $zaakdata = {
        contactkanaal       => ZAAKSYSTEEM_CONTACTKANAAL_API,
        zaaktype_id         => 89,
        onderwerp           => $onderwerp,
        aanvraag_trigger    => 'extern',
        aanvragers          => [
            {
                'verificatie'           => 'medewerker',
                'betrokkene'            => 'betrokkene-natuurlijk_persoon-1',
            }
        ],
        kenmerken           => [@kenmerken],
        'locatie_zaak'      => {
            bag_type                => 'nummeraanduiding',
            bag_id                  => $import_array->{'BAG_ID'},
            bag_nummeraanduiding_id => $import_array->{'BAG_ID'},
            
        },
        streefafhandeldatum => DateTime->now()->add(months => 1),
        registratiedatum    => DateTime->now(),
    };

    my $zaak;
    eval {
        $zaak = $zaken->create($zaakdata);
    };
    
    if ($zaak) {
        ok($zaak, 'Created bouwzaak: ' . $zaak->id);
    } else {
        $self->log->_flush;
        diag('ERROR: ' . $@);
        exit;
    }


    ### Retrieve zaak again for verify
    $zaak = $zaken->find($zaak->id);
    
    if ($zaak) {
        ok($zaak, 'Zaak terug gevonden');
    } else {
        $self->log->_flush;
        diag('ERROR: ' . $@);
        exit;
    }


    # Document(en) toevoegen
    # PDFTEKENING
    # PDFCORRESPONDENTIE

    #my $zaak_id = 8574;

    my $pdf_tekening        = $import_array->{'PDFTEKENING'};
    my $pdf_correspondentie = $import_array->{'PDFCORRESPONDENTIE'};

    my $dir_tekening_from        = $self->files_dirs->{'tekeningen_from'};
    my $dir_tekening_to          = $self->files_dirs->{'tekeningen_to'};
    my $dir_correspondentie_from = $self->files_dirs->{'correspondentie_from'};
    my $dir_correspondentie_to   = $self->files_dirs->{'correspondentie_to'};

    # Process the file(s)
    # As indicated by the letter 's' between round brackets there might me more then one file!

    if ($pdf_tekening ne '') {
        my @docs = split(/;/, $pdf_tekening);

        for my $doc (@docs) {
            my ($doc_trimmed) = $doc =~ m!^\s*(.+?)\s*$!i; # trim whitspaces

            ok($doc, 'DOC TEKENEING: '.$doc_trimmed);

            $self->addDocument($zaak, $dir_tekening_from, $dir_tekening_to, $doc, $BH_DB->{'PDFTEKENING'});
        }
    }

    if ($pdf_correspondentie ne '') {
        my @docs = split(/;/, $pdf_correspondentie);

        for my $doc (@docs) {
            my ($doc_trimmed) = $doc =~ m!^\s*(.+?)\s*$!i; # trim whitspaces

            ok($doc, 'DOC CORESPONDENTIE: '.$doc_trimmed);

            $self->addDocument($zaak, $dir_correspondentie_from, $dir_correspondentie_to, $doc, $BH_DB->{'PDFCORRESPONDENTIE'});
        }
    }

#            $self->log->_flush;
    
}





sub addDocument {
    my ($self, $zaak, $files_dir_from, $files_dir_to, $filename, $kenmerk_naam) = @_;
    if (!ref($zaak)) {
        $zaak = $self->dbic->resultset('Zaak')->find($zaak);
    }

    # Opzoeken van het kenmerk_id
    my $rs_kenmerk = $self->dbic->resultset('BibliotheekKenmerken')->search(
        {
            'naam' => $kenmerk_naam
        });


    unless ($rs_kenmerk->count == 1) {
        die ('Kan kenmerk met naam '.$kenmerk_naam.' niet vinden!')
    }

    my $kenmerk    = $rs_kenmerk->first;
    my $kenmerk_id = $kenmerk->id;

    my $rs_bibkenmerk = $zaak
        ->zaaktype_node_id
        ->zaaktype_kenmerken
        ->search(
        {
            'bibliotheek_kenmerken_id.id'           => $kenmerk_id,
            'bibliotheek_kenmerken_id.value_type'   => 'file',
        },
        {
            join    => 'bibliotheek_kenmerken_id'
        }
    );

    unless ($rs_bibkenmerk->count) {
        die ('Kan kenmerk van type "file" met naam "'.$kenmerk_naam.'" niet vinden!')
    }

    my $bibkenmerk = $rs_bibkenmerk->first;

    my $extra_doc_args = {
        verplicht       => $bibkenmerk->bibliotheek_kenmerken_id->value_mandatory,
        category        => $bibkenmerk->bibliotheek_kenmerken_id->document_categorie,
        pip             => $bibkenmerk->pip,
        catalogus       => $bibkenmerk->id,
        zaak_id         => $zaak->id,
        filename        => $filename,
        documenttype    => 'file',
        actie_rename_when_exists => '1',
    };


    # Get the filesize
    my $filesize = -s $filename;

    my $zaaktype_kenmerken = $self->dbic->resultset('ZaaktypeKenmerken')->search(
            {
                bibliotheek_kenmerken_id => $kenmerk_id,
                zaaktype_node_id => $zaak->zaaktype_node_id->id
            }
    );

    if ($zaaktype_kenmerken->count > 1) {
        die('meerdere zaaktype_kenmerken gevonden!')
    }

    my $zaaktype_kenmerken_id = $zaaktype_kenmerken->first->id;

    my $cargs = { 
            'documenttype'             => $extra_doc_args->{'documenttype'},
            'betrokkene_id'            => 'betrokkene-natuurlijk_persoon-1',

            'category'                 => $extra_doc_args->{'category'},
            'filename'                 => $extra_doc_args->{'filename'},
            'document_id'              => undef,
            'zaakstatus'               => 2,
            'pid'                      => undef,
            'catalogus'                => $extra_doc_args->{'catalogus'},
            'verplicht'                => $extra_doc_args->{'verplicht'},
            'post_registratie'         => undef,
            'pip'                      => undef,
            'help'                     => undef,
            'ontvangstdatum'           => undef,
            'dagtekeningdatum'         => undef,
            'versie'                   => 1,
            'queue'                    => undef,
            'mimetype'                 => 'application/pdf',
            'filesize'                 => $filesize,
            'zaaktype_kenmerken_id'    => $zaaktype_kenmerken_id,
    };


    # Check het BAG-ID?
    # Hoort het betreffende BAG-ID bij de een relatie in het systeem...?


    my $document;
    delete($cargs->{document_id});
    if ( $document = $zaak->documents->create($cargs) ) {
        #mkdir ($files_dir_to . '/' . $document->id) unless (-d $files_dir_to . '/' . $document->id);

        # Kopieren van het bestand naar een andere plek
        unless (copy(
                $files_dir_from . '/' . $filename,
                $files_dir_to . '/' . $document->id
            )
        ) {
            ok($document, 'Probleem bij aanmaken
                document: ' . $files_dir_from . '/' . $filename . ' [' . $! . ']'
            );
            $document->delete;
            return;
        }

        ok($document, 'Create from document ' . $files_dir_from . '/' . $filename);
        ok($document, 'Create to document ' . $files_dir_to . '/' . $document->id);

        ### CREATE MD5 FROM HASH
        my $md5sum = file_md5_hex($files_dir_to . '/' .  $document->id);
        ok($md5sum, 'MD5: ' . $md5sum);
        do {
            $document->delete;
            return;
        } unless $md5sum;

        $document->md5($md5sum);
        $document->update;
    } else {
        ok($document, 'Probleem bij aanmaken document');
        return;
    }


    ### Logging
    if ($document->zaak_id) {
        $document->zaak_id->logging->add({
            'component'     => LOGGING_COMPONENT_DOCUMENT,
            'component_id'  => $document->id,
            'onderwerp'     => 'Document "'
                . $document->filename . '" ['
                . $document->id . '] succesvol '
                . 'aangemaakt'
        });
    }

    ok($document, 'Document succesvol aangemaakt');

    return $document;
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

