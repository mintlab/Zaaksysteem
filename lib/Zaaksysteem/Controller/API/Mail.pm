package Zaaksysteem::Controller::API::Mail;

use strict;
use warnings;

use MIME::Parser;
use MIME::Head;
use File::Path;
use File::Copy;
use File::Basename;

use Data::Dumper;
use Encode qw/from_to/;

use HTML::TreeBuilder;

use parent 'Catalyst::Controller';

my $YUCAT_CONFIG = {
    'problemen' => {
        'Zwerfvuil'                 => 'Zwerfvuil op straat',
        'Hondenpoep'                => 'Hondenpoep',
        'Losse stoeptegel'          => 'Losse stoeptegel',
        'Slecht wegdek'             => 'Slecht wegdek',
        'Onkruid'                   => 'Onkruid',
        'Kapotte straatverlichting' => 'Kapotte straatverlichting',
        'Graffiti'                  => 'Graffiti & beplakking',
        'Kapot speeltoestel'        => 'Kapot speeltoestel',
        'Ongedierte'                => 'Ongedierte',
        'Idee, wens'                => 'Idee, wens',
        'Overig'                    => 'Overig',
    },
    'melding'   => {
        'table_nr'  => 0,
        Probleem        => {
            'kenmerk'   => 'Mor_categorie'
        },
        Omschrijving    => {
            'kenmerk'   => 'Mor_omschrijving'
        },
        Adres           => {
            'kenmerk'   => 'Mor_locatie_adres',
            'filter'    => sub {
                my $value   = shift;
                my $result  = shift;
                my $c       = shift;

                my $woonplaats = (
                    $c->customer_instance->{start_config}->{customer_info}->{woonplaats}
                        ? $c->customer_instance->{start_config}->{customer_info}->{woonplaats}
                        : ''
                );

                $result->{'Mor_locatie_map'} = 'Netherlands, ' . $woonplaats
                    . ', ' . $value;

                return $value;
            }
        },
        Foto            => {
            'kenmerk'   => 'Mor_foto',
            'handler'   => sub {
                my $element = shift;

                my ($img) = $element->look_down('_tag','a');

                return $img->attr('href');
            }
        },
        'Datum en tijd' => {
            'kenmerk'   => 'Mor_datum',
            'filter'    => sub {
                my $value   = shift;
                my $result  = shift;

                my %MAP = (
                    januari     => '01',
                    februari    => '02',
                    maart       => '03',
                    april       => '04',
                    mei         => '05',
                    juni        => '06',
                    juli        => '07',
                    augustus    => '08',
                    september   => '09',
                    oktober     => '10',
                    november    => '11',
                    december    => '12',
                );

                # donderdag 21 juli 2011 17:11
                my ($dag, $maand_name, $jaar) = $value =~ /(\d+) (\w+) (\d{4})/;

                return $dag . '-' . $MAP{$maand_name} . '-' . $jaar;
            }
        },
    },
    'melder'    => {
        'table_nr'  => 1,
        Naam            => {
            'kenmerk'   => 'Mor_melder_naam'
        },
        Adres           => {
            'kenmerk'   => 'Mor_melder_adres'
        },
        'Postcode en plaats' => {
            'kenmerk'   => 'Mor_melder_postcode',
            'filter'    => sub {
                my $value   = shift;
                my $result  = shift;

                my ($postcode, $plaats) = $value =~ /^(\d{4} ?\w{2}) (.+)/;

                return unless $postcode;

                $result->{'melder plaats'} = $plaats;

                return $postcode;
            }
        },
        'Contact per telefoon'  => {
            'kenmerk'   => 'Mor_melder_telefoongewenst',
            'filter'    => sub {
                my $value   = shift;
                my $result  = shift;

                return 'Ja' if $value =~ /Ja/;
                return 'Nee';
            }
        },
        Telefoonnummer  => {
            'kenmerk'   => 'Mor_melder_telefoonnummer'
        },
        'E-mailadres'   => {
            'kenmerk'   => 'Mor_melder_email',
            'filter'    => sub {
                my $value = shift;

                return lc($value);
            }
        },
    },
};

sub _retrieve_mail_object {
    my ($self, $opts) = @_;

    return unless $opts->{message};

    my $mail    = Mail::Internet->new(
        [
            split /\n/, $opts->{message}
        ]
    );

    my ($parser, @files)   = $self->_retrieve_files( $opts->{message} );

    return ($mail, $parser, @files);
}

sub _retrieve_afzender_subject {
    my ($self, $mail_object) = @_;

    my $from    = $mail_object->head->get('From');
    $from       =~ s/.*?<(.*?)\@(.*?)>/$1\@$2/g;

    my $subject = $mail_object->head->get('Subject');

    chomp($subject);
    chomp($from);

    return ($from, $subject);
}

sub _retrieve_files {
    my ($self, $message) = @_;

    my $parser = new MIME::Parser;

    $parser->extract_uuencode(1);

    my $entity = $parser->parse_data($message);

    return ($parser, $entity->parts_DFS);
}

sub _handle_part {
    my ($self, $part) = @_;

    my $raw_filename = $part->head->recommended_filename;
    if (!$raw_filename) {
        $raw_filename = $part->bodyhandle->path;
    }

    my ($filename, $dir, $ext) = fileparse($raw_filename, '\.[^.]*');

    return ($filename, $part->bodyhandle);
}

sub _finish_message {



}

sub input : Local {
    my ($self, $c) = @_;

    die('No message found') unless $c->req->params->{message};

    $c->log->debug(
        'API::Mail->input: '
        .'Found message, proceed'
    );

    my ($mail_object, $parser, @files)   = $self->_retrieve_mail_object({
        message => $c->req->params->{message}
    });

    my ($from, $subject)        = $self->_retrieve_afzender_subject(
        $mail_object
    );

    $c->log->debug(
        'API::Mail->input: '
        .'Processing message from [' . $from . '], Subject: ' . $subject
    );

    my $yucat;
    foreach my $part (@files) {
        next if (!$part->bodyhandle);

        my ($filename, $fh) = $self->_handle_part($part);

        $c->log->debug(
            'API::Mail->input: '
            .'Found attached file [' . $filename . ']'
        );

        #$c->log->debug('Body input: ' . $part->bodyhandle->as_string);
        if ($fh->as_string =~ /meldingprod\.yucat\.com/) {
            $c->log->debug('Found YUCAT string, send to yucat engine');
            $self->yucat($c, $fh->as_string);
        }

        #move($fh->path, $photofile . '.jpg');

    }

    $self->_finish_message($c->req->params->{message});

    $parser->filer->purge;

    $c->res->body('ok');
}

sub yucatit : Local {
    my $self    = shift;
    my $c       = shift;

    open(my $FH, '</opt/msg-12131-2.html') or
        die('cannot find file');

    my $string = '';
    while (<$FH>) {
        chomp;
        $string .= $_ . "\n";
    }

    close($FH);

    $self->yucat($c, $string);

    $c->res->body('Zaak: ' . $c->stash->{zaak}->id);

}

sub yucat {
    my $self    = shift;
    my $c       = shift;
    my $string  = shift;

    my $t       = HTML::TreeBuilder->new;
    $t->parse_content($string);

    my @tables  = $t->look_down('_tag','table', 'class', 'innerInfo');

    $c->log->debug($_->as_HTML()) for @tables;


    my $melding = $self->_yucat_get_kenmerken(
        $c,
        $YUCAT_CONFIG->{melding},
        @tables
    );

    my $melder  = $self->_yucat_get_kenmerken(
        $c,
        $YUCAT_CONFIG->{melder},
        @tables
    );

    my $kenmerken = {
        %{ $melding },
        %{ $melder },
    };

    my ($kaart_url) = $t->look_down(
        'alt',
        'Kaart kan niet geladen worden'
    );

    if ($kenmerken->{'Mor_categorie'}) {
        for my $identifier (keys %{ $YUCAT_CONFIG->{problemen} }) {
            unless (lc($kenmerken->{'Mor_categorie'}) =~ /$identifier/i) {
                next;
            }

            $kenmerken->{'Mor_categorie'} =
                $YUCAT_CONFIG->{problemen}->{$identifier};

        }
    }

#    my ($point)     = $kaart_url->attr('src') =~
#        /points=(.*?)&/;
#
#    $kenmerken = {
#        %{ $kenmerken },
#        'melding locatie'   => $point,
#    };


    ## BAG
    $c->log->debug(
        'Searching for adres in Bag:' .
        $kenmerken->{'Mor_locatie_adres'}
    );

    if ($kenmerken->{'Mor_locatie_adres'})
    {
        my ($straat, $huisnummer) =
            $kenmerken->{'Mor_locatie_adres'} =~ /(.*?)\s+(\d+)/;

        $c->log->debug(
            '  Straat: ' . $straat . " / Huisnummer: " .
            $huisnummer
        );

        my $openbareruimtes = $c->model('DBG::BagOpenbareruimte')->search(
            naam    => $straat
        );

        if ($openbareruimtes->count) {
            my $openbareruimte = $openbareruimtes->first;

            my $hoofdadressen = $openbareruimte->hoofdadressen->search(
                'huisnummer'    => $huisnummer
            );

            if ($hoofdadressen->count) {
                my $bagid = $hoofdadressen->first->identificatie;

                $kenmerken->{'Mor_locatie_bag'} =
                    'nummeraanduiding-' . $bagid;
            }
        }
    }

    ### Insert zaak
    $self->insert_zaak($c, $kenmerken)
}

sub insert_zaak {
    my $self                = shift;
    my $c                   = shift;
    my $kenmerken_by_name   = shift;

    my $tf  = HTML::TagFilter->new(allow => {});

    ### Get rtkeys for kenmerken, and filter potential harmful data
    my $kenmerken = [];
    for my $key (keys %{ $kenmerken_by_name }) {
        my $kenmerk = $c->model('DB::BibliotheekKenmerken')->search(
            naam    => $key
        )->first;

        next unless $kenmerk;

        my $value               = $kenmerken_by_name->{$key};
        from_to($value, "iso-8859-1", "utf8");

        $c->log->debug(Dumper([$kenmerk->id, $kenmerken]));
        push(@{ $kenmerken },
            {   $kenmerk->id => $tf->filter(
                    $value
                )
            }
        );
    }

    ### Create zaak
    my $zaak_opts = {
        aanvraag_trigger    => 'extern',
        contactkanaal       => 'email',
        onderwerp           => 'BuitenBeter',
        zaaktype_id         => $c->customer_instance
            ->{start_config}->{'Z::Plugins::Yucat'}
            ->{zaaktype_id},
        aanvragers          => [
            {
                betrokkene  => 'betrokkene-bedrijf-'
                    .  $c->customer_instance
                        ->{start_config}->{'Z::Plugins::Yucat'}
                        ->{buitenbeter_bedrijf_betrokkene_id},
                verificatie => 'medewerker',
            },
        ],
        kenmerken           => $kenmerken,
        registratiedatum    => DateTime->now(),
    };

    my $zaak = $c->model('Zaken')->create($zaak_opts) or return;

    ### Notificatie
    $c->stash->{notificatie}    = {
        'status'        => 1
    };

    $c->stash->{zaak} = $zaak;

    $c->model('Bibliotheek::Sjablonen')->touch_zaak($c->stash->{zaak});

    $c->forward('/zaak/mail/notificatie');
}

sub _yucat_get_kenmerken {
    my $self        = shift;
    my $c           = shift;
    my $definitie   = shift;
    my @tables      = @_;

    my $rv          = {};

    for my $tr ($tables[$definitie->{table_nr}]->look_down('_tag','tr')) {
        ### Get spans
        my ($td_key, $td_value) = $tr->look_down('_tag','td');

        my $key                 = $td_key->as_text;

        #next if $key eq 'table_nr';
        next unless grep {$key eq $_ } keys %{ $definitie };

        my $value;
        if ($definitie->{$key}->{'handler'}) {
            $value = $definitie->{$key}->{'handler'}->(
                $td_value
            );
        } else {
            $value = $td_value->as_text;
        }

        $value = $definitie->{$key}->{filter}->(
            $value,
            $rv,
            $c
        ) if $definitie->{$key}->{filter};
        $rv->{ $definitie->{$key}->{kenmerk} } = $value;
    }

    return $rv;
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

