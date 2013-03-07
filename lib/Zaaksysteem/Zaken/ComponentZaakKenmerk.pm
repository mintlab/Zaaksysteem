package Zaaksysteem::Zaken::ComponentZaakKenmerk;

use Moose;

use Data::Dumper;
use Zaaksysteem::Constants qw/
    ZAAKSYSTEEM_CONSTANTS
/;

extends 'DBIx::Class';

#has 'value'         => (
#    'is'        => 'ro',
#    'lazy'      => 1,
#    'default'   => sub {
#        my $self        = shift;
#
#        my $values   = $self->zaak_kenmerken_values->search(
#            undef,
#            {
#                order_by    => 'id',
#            }
#        );
#
#        return unless $values->count;
#
#        unless ($self->multiple || $self->bibliotheek_kenmerken_id->type_multiple) {
#            return $values->first->value;
#        }
#
#        my $rv = [];
#        while (my $value = $values->next) {
#            push(@{ $rv }, $value->value);
#        }
#
#        return $rv;
#    },
#);

has 'human_value'   => (
    'is'        => 'ro',
    'lazy'      => 1,
    'default'   => sub {
        my $self        = shift;
        my $definition  = $self->_get_veldoptie_definition($self->value_type);

        return $self->value unless $definition->{filter};

        my @values      = $self->value;

        for my $value (@values) {


        }

        if ($self->multiple) {



        }
    },
);

#not used
# sub has_empty_value {
#     my $self    = shift;
# 
#     my $value   = $self->value;
# 
#     if (UNIVERSAL::isa($value, 'ARRAY')) {
#         return 1 if (scalar(@{ $value }) < 1);
#     } else {
#         return 1 unless $value;
#     }
# 
#     return;
# }


sub set_value {
    my ($self, $new, $extra_row_data) = @_;

    if ($self->bibliotheek_kenmerken_id->type_multiple) {
        my @values;
        if (UNIVERSAL::isa($new, 'ARRAY')) {
            @values = @{ $new };
        } else {
            @values = ($new);
        }

        if ($self->_set_multiple_value(\@values, $extra_row_data)) {
            $self->zaak_id->touch;

            return [ @values ];
        }
    } else {
        die(
            'ZaakKenmerken->value: '
            .'cannot add multiple values to single value kenmerk: '
            . $self->naam
        ) if ref($new);

        if ($self->_set_single_value($new, $extra_row_data)) {

            $self->zaak_id->touch;

            ### CHECK BESLUIT KENMERK
            $self->_set_besluit($new);

            return $new;
        }
    }
}

sub _initiate_triggers {
    my ($self, $new) = @_;

    my $extra_opts          = {};

    ($new, $extra_opts)     = $self->_initiate_bag($new, $extra_opts);

    return ($new, $extra_opts);
}

sub _initiate_bag {
    my ($self, $new, $extra_opts) = @_;

    return ($new, $extra_opts) unless (
        $new &&
        $self->bibliotheek_kenmerken_id->value_type =~ /bag/
    );

    my ($bag_type, $bag_id) = $new =~ /(\w+)-(\d+)/;

    my $bagid   = $self->result_source->schema->resultset('ZaakBag')->create_bag(
        {
            zaak_id                     => $self->zaak_id->id,
            bag_type                    => $bag_type,
            'bag_' . $bag_type . '_id'  => $bag_id,
            bag_id                      => $bag_id,
        }
    );

    ### Extra option to value
    $extra_opts->{zaak_bag_id} = $bagid->id;

    ###
    my $zaaktkenmerk    = $self->zaak_id->zaaktype_node_id->zaaktype_kenmerken->search(
        {
            'bibliotheek_kenmerken_id'  => $self->bibliotheek_kenmerken_id->id,
        }
    )->first;

    if ($zaaktkenmerk && $zaaktkenmerk->bag_zaakadres) {
        $self->zaak_id->locatie_zaak($bagid->id);
        $self->zaak_id->update;
    }

    return ($new, $extra_opts);
}

sub _set_single_value {
    my $self            = shift;
    my $new             = shift;
    my $extra_row_data  = shift || {};
    my ($extra_opts);

    my $value   = $self->value;

    $self->result_source->schema->resultset('Logging')->add({
        zaak_id     => $self->zaak_id,
        component   => 'kenmerk',
        onderwerp   => substr('Kenmerk "' . $self->bibliotheek_kenmerken_id->naam . '"'
            . ' gewijzigd naar: "' . (
                length($new) > 150
                    ? substr($new,0,150) . '...'
                    : $new
                ) . '"',0,255),
        bericht     => $new,
        %{ $extra_row_data }
    });

    ($new, $extra_opts)    = $self->_initiate_triggers($new);

#     if ($value) {
#         $value->value($new);
#         return 1 if $value->update;
#     } else {
#         return 1 if $self->zaak_kenmerken_values->create(
#             {
#                 value                       => $new,
#                 bibliotheek_kenmerken_id    =>
#                     $self->bibliotheek_kenmerken_id->id,
#                 %{ $extra_opts },
#             }
#         );
#     }

    return;
}

sub _set_besluit {
    my $self    = shift;
    my $value   = shift;

    my $besluit_kenmerken   = $self->zaak_id
        ->zaaktype_node_id
        ->zaaktype_kenmerken
        ->search({
            besluit                     => 1,
            bibliotheek_kenmerken_id    => $self->bibliotheek_kenmerken_id->id,
        });

    return unless $besluit_kenmerken->count;

    my $zaak = $self->zaak_id;

    $zaak->besluit( $value );
    $zaak->update;
}

sub _set_multiple_value {
    my $self    = shift;
    my $rawvalues  = shift;
    my $extra_data = shift || {};
    my ($extra_opts);

    my @values = @{ $rawvalues };

    ### Delete old values
#    $self->zaak_kenmerken_values->delete;

    $self->result_source->schema->resultset('Logging')->add({
        zaak_id     => $self->zaak_id,
        component   => 'kenmerk',
        onderwerp   => substr('Multiple kenmerk "' . $self->bibliotheek_kenmerken_id->naam . '"'
            . ' gewijzigd naar: "' . join('","', @values) . '"'
            . ' gewijzigd naar: "' . (
                length(join('","', @values)) > 150
                    ? substr(join('","', @values),0,150) . '...'
                    : join('","', @values)
                ) . '"',0,255),
        bericht     => join('","', @values),
        %{ $extra_data }
    });

    ### Create new values
     for my $value (@values) {
         ($value, $extra_opts)   = $self->_initiate_triggers($value);
# 
#         $self->zaak_kenmerken_values->create(
#             {
#                 value                       => $value,
#                 bibliotheek_kenmerken_id    =>
#                     $self->bibliotheek_kenmerken_id->id,
#                 %{ $extra_opts },
#             }
#         );
     }

    return 1;
}

sub _get_veldoptie_definition {
    my $self    = shift;
    my $type    = shift;

    my $zaaksysteem_constants   = ZAAKSYSTEEM_CONSTANTS;

    return $zaaksysteem_constants->{veld_opties}->{$type};
}

sub _get_multiple {
    my $self    = shift;
    my $type    = shift;

    return $self->_get_veldoptie_definition(
        $self->value_type
    )->{multiple};
}

sub _kenmerk_find_or_create {
    my $self                = shift;
    my $bibliotheek_kenmerk = shift;


    ### Try to find existing kenmerk
    my $kenmerk;
    unless(ref($bibliotheek_kenmerk)) {
        $bibliotheek_kenmerk   = $self->result_source->schema
            ->resultset('BibliotheekKenmerken')->find(
                $bibliotheek_kenmerk
            );

        die(
            'Zaken::Kenmerken->_find_or_create: '
            . ' cannot find bibliotheek kenmerk by id'
        ) unless $bibliotheek_kenmerk;
    }


    my $kenmerken   = $self->result_source->schema
        ->resultset('ZaakKenmerken')->search(
            {
                bibliotheek_kenmerken_id    => $bibliotheek_kenmerk->id,
                zaak_id                     => $self->zaak_id->id,
            }
        );

    $kenmerk = $kenmerken->first if $kenmerken->count == 1;

    ### Found kenmerk, return it (this object);
    return $kenmerk if $kenmerk;

    ### Did not find existing kenmerk, finish this row
    $self->bibliotheek_kenmerken_id($bibliotheek_kenmerk->id);
    $self->naam($bibliotheek_kenmerk->naam);
    $self->value_type($bibliotheek_kenmerk->value_type);
    $self->multiple(
        (
            $self->_get_multiple ||
            $bibliotheek_kenmerk->type_multiple
        )
    );

    return $self;

}

1; #__PACKAGE__->meta->make_immutable;


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

