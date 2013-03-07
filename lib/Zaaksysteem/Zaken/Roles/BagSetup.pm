package Zaaksysteem::Zaken::Roles::BagSetup;

use Moose::Role;
use Data::Dumper;

around '_create_zaak' => sub {
    my $orig            = shift;
    my $self            = shift;
    my ($opts)          = @_;

    $self->log->info('Role [BagSetup]: started');

    { # ARRAY
        if ($opts->{bag}) {
            my $bag_info = $self->_load_bag_items($opts->{bag});

            if ($bag_info) {
                $opts->{locatie_zaak}   = $bag_info->{locatie_zaak}
                    if ($bag_info->{locatie_zaak});

                $opts->{locatie_correspondentie}    =
                    $bag_info->{locatie_correspondentie}
                        if $bag_info->{locatie_correspondentie};
            }
        }
    }

    { # SINGLE FIELDS
        for my $update_field (qw/locatie_zaak locatie_correspondentie/) {
            my $value   = $opts->{$update_field};
            delete($opts->{$update_field});
            next unless $value;

            $self->log->info('Adding bag item: ' . $update_field);

            my $bag     = $self->_load_bag_item( $value );

            unless ($bag) {
                $self->log->error('BagSetup->_load_bag_item returned false
                    for: ' . Dumper($value)
                );
                next;
            }

            $self->log->info('Changed option: ' . $update_field . 'to:' .
                $bag->id
            );
            $opts->{$update_field} = $bag->id;
        }
    }

    my $zaak    = $self->$orig(@_);

    ### After creation of zaak, check if aanvrager is also zaak_locatie
    if ( my $verblijfsobject = $zaak->aanvrager_object->verblijfsobject ) {
        my $verblijfsobject_id = (
            ref($verblijfsobject->identificatie)
                ? $verblijfsobject->identificatie->identificatie
                : $verblijfsobject->identificatie
            );

        my $bag_credentials = {
            bag_id                  => $verblijfsobject_id,
            bag_type                => 'verblijfsobject',
            bag_verblijfsobject_id  => $verblijfsobject_id,
        };

        if ($zaak->zaaktype_node_id->adres_andere_locatie) {
            my $zaak_bag = $zaak->zaak_bags->create_bag($bag_credentials);
            $zaak->locatie_zaak($zaak_bag->id);
        }
    }

    return $zaak;
};

# bagopts = {
#   bag_type  => 'nummeraanduiding',
#   bag_id    => '3232323292892034',
#   __OPTIONEEL__
#   bag_pand_id => '23423423423423',
#   bag_verblijfsobject_id => '23423423423423',
#   bag_nummeraanduiding_id => '23423423423423',
#   bag_openbareruimte_id => '23423423423423',
# }

sub _load_bag_item {
    my $self        = shift;
    my $bagobject   = shift;
    my $bag;

    return unless UNIVERSAL::isa($bagobject, 'HASH');

    $self->log->debug('Adding bagobject');

    ### Openbare ruimte is altijd beschikbaar
#    unless ($bagobject->{bag_openbareruimte_id}) {
#        ### ZOEK DIT UIT
#    } else {
        my @columns         = $self->result_source->schema->resultset('ZaakBag')
                            ->result_source->columns;

        my $bagdata         = {};
        for (@columns) {
            next unless $bagobject->{ $_ };
            $bagdata->{ $_ }    = $bagobject->{ $_ };
        }

        $bag = $self->result_source->schema->resultset('ZaakBag')->create_bag(
            $bagdata
        );
#    }

    return $bag;
}

sub _load_bag_items {
    my $self    = shift;
    my $bagopts = shift;
    my ($rv, @bag_objecten);

    if (UNIVERSAL::isa($bagopts, 'ARRAY')) {
        @bag_objecten    = @{ $bagopts };
    } else {
        push(@bag_objecten, $bagopts);
    }

    for my $bagobject (@bag_objecten) {
        my $rv  = $self->_load_bag_item($bagobject);

        if ($bagobject->{locatie_zaak}) {
            $rv->{locatie_zaak}                 = $rv->id;
        }
        if ($bagobject->{locatie_correspondentie}) {
            $rv->{locatie_correspondentie}      = $rv->id;
        }
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

