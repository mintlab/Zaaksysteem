package Zaaksysteem::Zaken::ResultSetZaakKenmerken;

use Moose;
use Data::Dumper;

extends 'DBIx::Class::ResultSet';

sub create_kenmerken {
    my $self        = shift;
    my $kenmerken   = shift;

    die(
        'Zaken::Kenmerken->create_kenmerken: input $kenmerken not an array'
    ) unless UNIVERSAL::isa($kenmerken, 'ARRAY');

    for my $kenmerk (@{ $kenmerken }) {
        die(
            'Zaken::Kenmerken->create_kenmerken: '
            . ' $kenmerk not a HASHREF: ' . Dumper($kenmerk)
        ) unless UNIVERSAL::isa($kenmerk, 'HASH');

        ### Key => Value pair
        if (scalar(keys(%{ $kenmerk })) == 1) {
            my ($key, $val) = each %{ $kenmerk };

            $kenmerk = {
                naam    => $key,
                value   => $val,
            }
        }

        $self->_create_kenmerk($kenmerk, @_);
    }
}


sub _create_kenmerk {
    my $self        = shift;
    my $kenmerk     = shift;
warn "oldschool version kenmerk: " . Dumper $kenmerk;
    ### DO SOME VALIDATION
    my $searchkey   = $kenmerk->{bibliotheek_kenmerken_id} || $kenmerk->{naam};
    my $value       = $kenmerk->{value};

    delete($kenmerk->{ $_ }) for qw/naam bibliotheek_kenmerken_id value/;

    my $bibliotheek_kenmerk = $self->_get_bibliotheek_object( $searchkey );

    my $row = $self->new_result({})->_kenmerk_find_or_create(
        $bibliotheek_kenmerk,
    );

    $row = $row->insert;

    $row->set_value(
        $value,
        $kenmerk
    );
}

sub by_naam {
    my  $self       = shift;
    my  $naam       = shift;

    die('ZaakKenmerken->by_naam: no name given') unless $naam;

    my $bibliotheek_kenmerk = $self->_get_bibliotheek_object(
        $naam
    );

    return $self->new_result({})->_kenmerk_find_or_create(
        $bibliotheek_kenmerk
    );
}

sub by_bibliotheek_id {
    my  $self       = shift;
    my  $id         = shift;

    $self->by_naam($id);
}

sub by_id {
    my  $self       = shift;
    my  $id         = shift;

    return $self->find($id);
}

sub _get_bibliotheek_object {
    my $self        = shift;
    my $key         = shift;

#die "fggfgfgfg";
    my $search = {};

    if ($key =~ /^\d+$/) {
        $search->{id}   = $key;
    } else {
        $search->{naam} = $key;
    }

    ### Get accessor from bibliotheek_kenmerken
    my $bibliotheek_kenmerken = $self->result_source->schema
        ->resultset('BibliotheekKenmerken')->search(
            $search
        );

    my $bibliotheek_kenmerk = $bibliotheek_kenmerken->first;

    die(
        'Zaken::Kenmerken->get_bibliotheek_object: '
        . $key . ' is not a kenmerk'
    ) unless $bibliotheek_kenmerk;

    return $bibliotheek_kenmerk;
}

sub search_all_kenmerken {
    my $self        = shift;
    my $fase        = shift;
#die "obsolete";
    my $kenmerken   = $self->search(
        {},
        {
            prefetch        => [
                'zaak_kenmerken_values',
                'bibliotheek_kenmerken_id'
            ],
        }
    );

    if (scalar(@_)) {
        return $kenmerken->search(@_);
    }

    my %values;
    while (my $kenmerk = $kenmerken->next) {
        $values{
            $kenmerk->bibliotheek_kenmerken_id->id
        } = $kenmerk->value;
    }

    return \%values;

    #return $kenmerken;
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

