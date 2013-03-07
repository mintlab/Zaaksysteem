package Zaaksysteem::DB::ResultSet::BagGeneral;

use strict;
use warnings;

use Moose;
use Data::Dumper;

extends 'Zaaksysteem::SBUS::ResultSet::BAG';

my $BAG_HIERARCHY = [
    'bag_verblijfsobject_id',
    'bag_ligplaats_id',
    'bag_standplaats_id',
    'bag_nummeraanduiding_id',
    'bag_ligplaats_id',
    'bag_standplaats_id',
    'bag_verblijfsobject_id',
    'bag_pand_id',
    'bag_openbareruimte_id',
];

sub _retrieve_zaakbag_data {
    my  $self       = shift;
    my  $row        = shift;
    my  $opt        = shift;

    my ($bagentry);

    if ($opt && $opt->{dirty_rows}) {
        $row        = { $opt->dirty_rows };
    } elsif (blessed($row)){
        $row        = { $row->get_columns };
    }

    my %hier_done   = ();
    for my $bagobject (@{ $BAG_HIERARCHY }) {
        next if $bagentry;

        my $bagobject_type  = $bagobject;
        $bagobject_type     =~ s/_id//;
        $bagobject_type     =~ s/bag_//;

        next unless $row->{$bagobject};

        ### Retrieve ID if this is a reference
        $row->{$bagobject} = $row->{$bagobject}->id
            if ref($row->{$bagobject});

        $bagentry   = $self->_retrieve_bag_entry({
            type    => $bagobject_type,
            id      => $row->{$bagobject},
        });
    }

    my $types           = $self->_get_types_according_to($row, $bagentry, $opt);
    my $zaak_bag_row    = $self->_get_zaak_bag($bagentry, $types, $opt);

    return $zaak_bag_row;
}

sub _get_zaak_bag {
    my  $self       = shift;
    my  $entry      = shift;
    my  $types      = shift;

    my  $rv         = {};

    for my $type (keys %{ $types }) {
        if ($type eq 'bag_id') {
            $rv->{bag_id} = $types->{$type};
            next;
        }

        $rv->{'bag_' . $type . '_id'} = $types->{$type};
    }

    return $rv;
}

sub _get_types_according_to {
    my  $self       = shift;
    my  $row        = shift;
    my  $entry      = shift;
    my  $opt        = shift;
    my  $rv         = {
        verblijfsobject     => undef,
        ligplaats           => undef,
        standplaats         => undef,
        openbareruimte      => undef,
        pand                => undef,
        nummeraanduiding    => undef,
        bag_id              => undef,
    };

    return unless $entry;

    my $source_name     = lc($entry->result_source->source_name);

    if ($source_name =~ /openbareruimte/) {
        $rv->{bag_id} = $rv->{openbareruimte}   = $entry->identificatie;

        return $rv;
    }

    if ($source_name =~ /pand/) {
        $rv->{bag_id} = $rv->{pand}     = $entry->identificatie;

        if ($entry->verblijfsobject_panden->count) {
            my $verblijfsobject_id      = $entry->verblijfsobject_panden
                                            ->first
                                            ->identificatie;

            my $verblijfsobject         = $self->_retrieve_bag_entry({
                type    => 'verblijfsobject',
                id      => $verblijfsobject_id
            });

            $rv->{openbareruimte}       = $verblijfsobject->hoofdadres
                                            ->openbareruimte
                                            ->identificatie;
        }

        return $rv;
    }

    if ($source_name =~ /verblijfsobject/) {
        $rv->{bag_id} = $rv->{verblijfsobject}          = $entry->identificatie->identificatie;
        if (
            $entry->panden && $entry->panden->count &&
            ref($entry->panden->first->pand)
        ) {
            $rv->{pand}                 = $entry->panden
                                            ->first
                                            ->pand
                                            ->identificatie;
        }
        $rv->{nummeraanduiding}         = $entry->hoofdadres->identificatie;
        $rv->{openbareruimte}           = $entry->hoofdadres
                                            ->openbareruimte
                                            ->identificatie;

        return $rv;
    }

    if ($source_name =~ /ligplaats/) {
        $rv->{bag_id} = $rv->{ligplaats}          = $entry->identificatie;

        $rv->{nummeraanduiding}         = $entry->hoofdadres->identificatie;
        $rv->{openbareruimte}           = $entry->hoofdadres
                                            ->openbareruimte
                                            ->identificatie;

        return $rv;
    }

    if ($source_name =~ /standplaats/) {
        $rv->{bag_id} = $rv->{ligplaats}          = $entry->identificatie;

        $rv->{nummeraanduiding}         = $entry->hoofdadres->identificatie;
        $rv->{openbareruimte}           = $entry->hoofdadres
                                            ->openbareruimte
                                            ->identificatie;

        return $rv;
    }

    if ($source_name =~ /nummeraanduiding/) {
        $rv->{bag_id} = $rv->{nummeraanduiding}         = $entry->identificatie;
        $rv->{openbareruimte}           = $entry->openbareruimte
                                            ->identificatie;

        if ($entry->verblijfsobjecten->count) {
            $rv->{verblijfsobject}          = $entry->verblijfsobjecten
                                                ->first
                                                ->identificatie
                                                ->identificatie;

            if (
                $entry->verblijfsobjecten->first->panden &&
                $entry->verblijfsobjecten->first->panden->count &&
                ref($entry->verblijfsobjecten->first->panden->first->pand)
            ) {
                $rv->{pand}                     = $entry->verblijfsobjecten
                                                    ->first
                                                    ->panden
                                                    ->first
                                                    ->pand
                                                    ->identificatie;
            }
        } elsif ($entry->ligplaatsen->count) {
            $rv->{ligplaats}                    = $entry->ligplaatsen
                                                ->first
                                                ->identificatie;
        } elsif ($entry->standplaatsen->count) {
            $rv->{standplaats}                  = $entry->standplaatsen
                                                ->first
                                                ->identificatie;
        }

        return $rv;
    }

}

sub _retrieve_bag_entry {
    my ($self, $opts) = @_;
    my ($bag);

    die('Necessary options not given: type,id') unless (
        $opts->{type} &&
        $opts->{id}
    );

    my $resultsetname   = 'Bag' . ucfirst(lc($opts->{type}));


    unless (
        $self->result_source->schema->resultset($resultsetname) &&
        (
            $bag =
                $self->result_source
                    ->schema
                    ->resultset($resultsetname)
                    ->search({
                        'identificatie'    => $opts->{id}
                    })
        )
    ) {
        die(
            'Gegevens::BAG->retrieve: Cannot find bag of type ' .
            $opts->{type}
            . ' with bag_id: '
            . $opts->{id}
        );

        return;
    }

    return $bag->first if $bag->count;

    die(
        'Gegevens::BAG->retrieve: did not find exactly one entry'
        . ' for bagid: ' . $opts->{id} . ':' . $opts->{type}
    );

    return;

}


1;
