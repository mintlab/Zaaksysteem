package Zaaksysteem::Zaken::ResultSetZaakKenmerk;

use Moose;
use Data::Dumper;
use Params::Profile;

use Zaaksysteem::Constants;

extends 'DBIx::Class::ResultSet';


{
    Params::Profile->register_profile(
        method  => 'create_kenmerken',
        profile => {
            required => [ qw/zaak_id kenmerken/],
        }
    );


    sub create_kenmerken {
        my ($self, $params) = @_;
    
        my $dv = Params::Profile->check(params  => $params);
        die "invalid options" unless $dv->success;
    
        my $zaak_id = $params->{zaak_id};
        my $kenmerken = $params->{kenmerken};
    
        die(
            'create_kenmerken: input $kenmerken not an array'
        ) unless UNIVERSAL::isa($kenmerken, 'ARRAY');
    
        for my $kenmerk (@$kenmerken) {
            die(
                'create_kenmerken: '
                . ' $kenmerk not a HASHREF: ' . Dumper($kenmerk)
            ) unless UNIVERSAL::isa($kenmerk, 'HASH');
    
            die "create kenmerken incorrect format " . Dumper ($kenmerk) 
                unless (scalar keys %$kenmerk == 1);
    
            my ($bibliotheek_kenmerken_id, $values) = each %$kenmerk;
    
            $self->create_kenmerk({
                zaak_id                     => $zaak_id, 
                bibliotheek_kenmerken_id    => $bibliotheek_kenmerken_id, 
                values                      => $values
            });
        }
    }
}
    

{
    Params::Profile->register_profile(
        method  => 'create_kenmerk',
        profile => {
            required => [ qw/zaak_id bibliotheek_kenmerken_id values/],
        }
    );
    
    sub create_kenmerk {
        my ($self, $params) = @_;

# TODO check values param, is arrayref, no worky
#warn "options: " . Dumper $params;
#        my $dv = Params::Profile->check(params  => $params);
#        die "invalid options" .Dumper ($dv) unless $dv->success;

        my $values = $params->{values};
        $values = UNIVERSAL::isa($values, 'ARRAY') ? $values : [$values];
    
        foreach my $value (@$values) {
#warn "value: " . $value;
            my $row = $self->create({
                zaak_id                     => $params->{zaak_id},
                bibliotheek_kenmerken_id    => $params->{bibliotheek_kenmerken_id},
                value                       => $value
            });
            
            $row->set_value($value);
    
        }
    }

}


{
    Params::Profile->register_profile(
        method  => 'search_all_kenmerken',
        profile => {
            optional => [ qw/fase/ ],
        }
    );


    sub search_all_kenmerken {
        my ($self, $params) = @_;

		$params ||= {};
        my $dv = Params::Profile->check(params  => $params);
        die "invalid options for search_all_kenmerken" unless $dv->success;

        my $fase = $params->{fase};    

        my $kenmerken   = $self->search(
            {},
            {
                prefetch        => [
                    'bibliotheek_kenmerken_id'
                ],
            }
        );
        
        my $kenmerk_values  = {};

        my $veldopties      = ZAAKSYSTEEM_CONSTANTS->{veld_opties};
    
        while (my $kenmerk = $kenmerken->next) {
            next unless $kenmerk->bibliotheek_kenmerken_id;

            my $bibliotheek_kenmerken_id = $kenmerk->bibliotheek_kenmerken_id->id;

#            warn "kenmerk_value: " . Dumper($kenmerk->value);
            next unless(length $kenmerk->value);

            if (
                $kenmerk->bibliotheek_kenmerken_id->type_multiple ||
                $veldopties->{
                    $kenmerk->bibliotheek_kenmerken_id->value_type
                }->{'multiple'}
            ) {
                $kenmerk_values->{$bibliotheek_kenmerken_id} = []
                    unless $kenmerk_values->{$bibliotheek_kenmerken_id};

                push(
                    @{ $kenmerk_values->{$bibliotheek_kenmerken_id} },
                    $kenmerk->value
                );
            } else {
                $kenmerk_values->{$bibliotheek_kenmerken_id} = $kenmerk->value;
            }
        }

        return $kenmerk_values;
    }

}



{
    Params::Profile->register_profile(
        method  => 'get',
        profile => {
        	required => [ qw/bibliotheek_kenmerken_id/ ]
        }
    );


	sub get {
		my ($self, $params) = @_;
	
		my $dv = Params::Profile->check(params  => $params);
		die "invalid options for get" unless $dv->success;
		
		my $bibliotheek_kenmerken_id = $params->{bibliotheek_kenmerken_id};
	
		my $kenmerken   = $self->search(
			{
				bibliotheek_kenmerken_id => $bibliotheek_kenmerken_id
			},
			{
				prefetch        => [
					'bibliotheek_kenmerken_id'
				],
			}
		);
	
		return $kenmerken->first();
	}
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

