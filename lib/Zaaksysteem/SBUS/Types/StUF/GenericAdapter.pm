package Zaaksysteem::SBUS::Types::StUF::GenericAdapter;

use Moose;
use Data::Dumper;

has [qw/app/] => (
    'is'    => 'rw',
);

extends 'Zaaksysteem::SBUS::Types::StUF';

sub prepare_response_parameters {
    my $self                = shift;
    my ($params, $options)  = @_;

    my $stufxml             = $params->{input};
    my $operation           = $params->{operation};

    my $entiteit            = uc(
        $stufxml
        ->{$operation}
        ->{stuurgegevens}
        ->{entiteittype}
    );

    my $xml                 = $stufxml->{$operation}->{body};

    my $stuf_options        = {
        'mutatie_type'          => $stufxml->{$operation}
            ->{stuurgegevens}->{kennisgeving}->{mutatiesoort},
        'entiteit_type'         => $entiteit,
        'traffic_object'        => $options->{traffic_object}
    };

    die('Need at least the stuf_options entiteit_type + mutatie_type')
        unless (
            $stuf_options->{entiteit_type} &&
            $stuf_options->{mutatie_type}
        );

    die('Invalid object') unless (
        $xml->{$entiteit} &&
        UNIVERSAL::isa($xml->{$entiteit}, 'ARRAY') &&
        scalar(@{ $xml->{$entiteit} })
    );

    my ($prs_xml);

    if (uc($stuf_options->{mutatie_type}) eq 'W') {
        $prs_xml    = $xml->{$entiteit}->[1];
    } else {
        $prs_xml    = $xml->{$entiteit}->[0];
    }

    my $create_params = $self->_stuf_to_params( $prs_xml, $stuf_options );

    $self->_stuf_relaties($prs_xml,$stuf_options,$create_params);

    ### Change options
    $create_params->{mutatie_type}    = $stuf_options->{mutatie_type};

    ### Hand it to database
    #$self->_stuf_to_database($create_params, $stuf_options);
    return $create_params;
}

sub generate_response_return {
    my ($self, $params, $prepared_params, $options, $result) = @_;

    my $stufxml             = $params->{input};
    my $operation           = $params->{operation};

    my $stuurgegevens       = $stufxml->{$operation}->{stuurgegevens};


    $stuurgegevens->{referentienummer}    = $options->{traffic_object}->id;
    $stuurgegevens->{tijdstipBericht}     = $options->{traffic_object}
            ->created->strftime('%Y%m%d%H%M%S00');

    $stuurgegevens->{berichtsoort}        = 'Bv01';

    return {
        'bevestiging'   => {
            stuurgegevens   => $stuurgegevens,
        }
    };
}

sub _convert_stuf_to_hash {
    my ($self, $xml, $mapping) = @_;

    return {
        map { $mapping->{ $_ } => $self->_parse_value($xml->{ $_ }) }
            grep {
                $self->_is_stuf_value($xml->{$_})
            } keys %{ $mapping }
    };
}

sub _is_stuf_value {
    my ($self, $value) = @_;

    $value  = $self->_parse_value($value);

    ### NIL value meanse waardeOnbekend
    if ($value && $value eq 'NIL') {
        return undef;
    }

    return 1;
}

sub _parse_value {
    my ($self, $value) = @_;

    ### When hash, try to find out data
    if (
        UNIVERSAL::isa($value, 'HASH') &&
        exists($value->{'_'})
    ) {
        $value = $value->{'_'};
    }

    ### First entry from array
    if (UNIVERSAL::isa($value, 'ARRAY')) {
        $value = shift @{ $value }
    }

    if (blessed($value) && $value->can('bstr')) {
        $value = $value->bstr;
    }

    if ($value && $value eq 'NIL:geenWaarde') {
        return '';
    }


    return $value;
}

sub _convert_stuf_extra_elementen_to_hash {
    my ($self, $xml) = @_;

    return unless UNIVERSAL::isa($xml, 'HASH');
    return unless UNIVERSAL::isa($xml->{seq_extraElement}, 'ARRAY');

    my $rv = {};
    for my $rawelement (@{ $xml->{seq_extraElement} }) {
        my $element = $rawelement->{extraElement};

        my $naam;
        if (
            UNIVERSAL::isa($element, 'HASH') &&
            exists($element->{'_'})
        ) {
            $naam   = $element->{naam};
        }

        my $value   = $self->_parse_value($element);

        $rv->{ $naam } = $value;
    }

    return $rv;

}


sub prepare_request_parameters {
    my $self                = shift;
    my ($params, $options)  = @_;
    my ($request_params);

    if (my $coderef = $self->can($params->{operation})) {
        $request_params = $coderef->(
            $self,
            $params->{input},
            {
                sortering       => 'adr',
                rows            => '10',
            },
            $options
        );

        $options->{dispatch_type} = 'soap';
    }

    ### Hand it to database
    #$self->_stuf_to_database($create_params, $stuf_options);
    return $request_params;
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

