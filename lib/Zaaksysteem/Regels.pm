package Zaaksysteem::Regels;

#
# The purpose of this module is to execute user defined rules in the input flow. E.g. when subsidy is 
# applied for, the general range of subsidy will prompt different questions to be asked. The rules can
# hide questions, show others, pre-fill values, or stop the process altogether if a dead end has been
# reached.
#


use strict;
use warnings;

use Data::Dumper;
use Data::Serializer;

use Moose;

#
# required_kenmerken_complete checks if the kenmerken for thise fase are
# correctly filled, removing kenmerken which are hidden because of regels.
#
sub required_kenmerken_complete {
    my ($self, $c, $zaak, $fase, $kenmerken) = @_;

    $kenmerken ||= $zaak->zaak_kenmerken
        ->search_all_kenmerken({ fase => $fase });

    ### Make sure we have a clone
    $kenmerken  = { %{ $kenmerken } };

    $self->_execute_regels(
        $c,
        $zaak->zaaktype_node_id->id,
        $fase->status,
        $kenmerken
    );

    my $regels_info         = $c->stash->{regels_result};

    ### PAUZE?
    if ($regels_info->{pauzeer_aanvraag}) {
        my $key = [ keys %{ $regels_info->{pauzeer_aanvraag} } ]->[0];
        return {
            'succes'    => 0,
            'pauze'     => $regels_info->{pauzeer_aanvraag}->{$key},
        }
    }


    ### GEEN PAUZE, MANDATORY MISSING?
    my $search_bibliotheek  = {
        'me.is_group'                   => undef,
        'me.value_mandatory'            => 1,
    };

    if ($regels_info->{verberg_kenmerk}) {
        $search_bibliotheek->{'me.bibliotheek_kenmerken_id'}    = {
            'not in'    => [ keys %{ $regels_info->{verberg_kenmerk} } ],
        };
    }

    my $db_kenmerken = $fase->zaaktype_kenmerken->search(
        $search_bibliotheek,
        {
            'order_by'  => 'me.id',
            'prefetch'  => 'bibliotheek_kenmerken_id',
        }
    );

    ### Check required kenmerken
    while (my $db_kenmerk = $db_kenmerken->next) {
#        next unless ($db_kenmerk->bibliotheek_kenmerken_id);
    	my $bibliotheek_kenmerken_id = $db_kenmerk->bibliotheek_kenmerken_id->id;

        next unless ($bibliotheek_kenmerken_id);

#		$c->log->debug("dbkenmerk: " . $bibliotheek_kenmerken_id);
#		$c->log->debug("dbkenmerk: " . Dumper $kenmerken->{$bibliotheek_kenmerken_id});
		
		my $value = $kenmerken->{$bibliotheek_kenmerken_id};
		$value = ref $value && ref $value eq 'ARRAY' ? join "", @$value : $value;
#        $c->log->debug("value: " . $value);

        next if length($value);

        next if
            lc($db_kenmerk->bibliotheek_kenmerken_id->value_type) eq 'file';

        return {
            'succes'    => 0,
            'required'  => 1,
        };
    }

    return {
        'succes'    => 1
    };
}


sub _execute_regels {
    my ($self, $c, $zaaktype_node_id, $status, $kenmerken) = @_;

    # deserialize from JSON, the execute one by one.

    my $zaaktype_node = $c->model('DB::ZaaktypeNode')->search({
        'id' => $zaaktype_node_id,
    })->single;

    my $status_row = $zaaktype_node
        ->zaaktype_statussen
        ->search(
            {
                status  => $status,
            }
        )->first;

    my $regels = $zaaktype_node
        ->zaaktype_regels
        ->search(
            { zaak_status_id => $status_row->id },
            { order_by => 'id' }
        );

    my $serializer = Data::Serializer->new(serializer => 'JSON');

    $c->session->{regel_sjablonen} = [];

    while (my $regel = $regels->next) {

        my $regel_obj = {'naam' => $regel->naam };
        my $deserialized = $serializer->deserialize($regel->settings);
        foreach my $key (keys %$deserialized) {
            $regel_obj->{$key} = $deserialized->{$key};
        }

        $self->_execute_regel($c, $regel_obj, $kenmerken);
    }
    
    $c->session->{streefafhandeldatum_data} = $self->{wijzig_afhandeltermijn};
}


sub _execute_regel {
    my ($self, $c, $regel_obj, $kenmerken) = @_;

    my $voorwaarde_result = $self->_execute_regel_check_voorwaarden($c, $regel_obj, $kenmerken);
#    $c->log->debug("Executing regel " . $regel_obj->{naam} . ", resultaat: " . $voorwaarde_result);
#    $c->log->debug("Kenmerken: " . Dumper $kenmerken);

    if($voorwaarde_result) {
#        $c->log->debug("acties: " . Dumper $regel_obj->{acties});
        $self->_execute_acties($c, $regel_obj, $regel_obj->{acties}, 'actie');
    } else {
#        $c->log->debug("anders: " . Dumper $regel_obj->{anders});
        $self->_execute_acties($c, $regel_obj, $regel_obj->{anders}, 'ander');
    }
}


sub _execute_acties {
    my ($self, $c, $regel_obj, $acties, $prefix) = @_;    

    return unless($acties);

    $c->stash->{regels_result} ||= {};
#    $c->log->debug("acties: " . $acties);
    $acties = $self->_assert_array($acties);
    my $session_kenmerken = $c->session->{_zaak_create}->{form}->{kenmerken};
    
    ### wijzig_afhandeltermijn 1 Delete possible streefafhandeldatum
    delete($c->session->{_zaak_create}->{streefafhandeldatum_data})
        if ($c->session->{_zaak_create}->{streefafhandeldatum_data});

#    $c->log->debug('session: ' . Dumper $c->session->{_zaak_create});

    foreach my $index (@$acties) {
#        $c->log->debug('index: ' . $index. ' ' . Dumper $regel_obj);

        my $actie = $self->_filter_hash($regel_obj, "${prefix}_${index}_"); 
        my $actie_type = $regel_obj->{"${prefix}_${index}"};

        my $kenmerk_id = $actie->{kenmerk};
        if($actie_type eq 'toon_kenmerk') {
            # set the hide property to 0 -- maybe once again. the rules are supposed to be executed 
            # in order. so the last rule has the last say - and the rules behave predictable
#            $c->log->debug("unhiding $kenmerk_id as a result of $actie_type");
            #$c->stash->{regels}->{$kenmerk_id} = {};
        } elsif($actie_type eq 'verberg_kenmerk') {
#            $c->log->debug("hiding $kenmerk_id as a result of $actie_type");
            $c->stash->{regels_result}->{'verberg_kenmerk'}->{$kenmerk_id} = {actie => 'verberg_kenmerk'};

            # need to erase the value from this kenmerk, so hiding can be propagated.
            delete $session_kenmerken->{ $kenmerk_id };
        } elsif($actie_type eq 'pauzeer_aanvraag') {
            $actie->{'actie'} = 'pauzeer_aanvraag';
            $c->stash->{regels_result}->{'pauzeer_aanvraag'}->{ $c->stash->{last_kenmerk} } = $actie;
            $c->stash->{zaak_afhandeling_beeindigd} = 1;

            if($actie->{zaaktype_id}) {
                my $zaaktype_node = $c->model('DB::ZaaktypeNode')->search(
                    zaaktype_id => $actie->{zaaktype_id}, 
                    {'order_by' => { -desc => 'id' }, 'rows' => 1} 
                );
                $actie->{zaaktype_node} = $zaaktype_node->first;
            }
        } elsif($actie_type eq 'vul_waarde_in') {        
            # enter the value
            $session_kenmerken->{$kenmerk_id} = $actie->{value};

            # and make the field read only
            $c->stash->{regels_result}->{'vul_waarde_in'}->{$kenmerk_id} = $actie;
        } elsif($actie_type eq 'wijzig_afhandeltermijn') {
            $self->{wijzig_afhandeltermijn} = {
                termijn => $actie->{afhandeltermijn},
                type    => $actie->{afhandeltermijntype},
            };

        } elsif($actie_type eq 'sjabloon_genereren') {      
            push @{$c->session->{regel_sjablonen}}, $actie->{sjabloon};
        }
        
    }
#    $c->log->debug("result: " .Dumper($c->stash->{regels_result}));
}

#
# loop through the voorwaarden, if they all are satisfied return 1, otherwise 0.
#
sub _execute_regel_check_voorwaarden {    
    my ($self, $c, $regel_obj, $values) = @_;

    my $voorwaarden = $self->_assert_array($regel_obj->{voorwaarden});
#    $c->log->debug("values: " . Dumper $values);

    $c->stash->{voorwaarden_kenmerken} ||= {};
    my $voorwaarde_result = 1;
    foreach my $voorwaarde_index (@$voorwaarden) {

        my $voorwaarde = $self->_filter_hash($regel_obj, "voorwaarde_${voorwaarde_index}_");

#        $c->log->debug("voorwaarde $voorwaarde_index: " . Dumper $voorwaarde);
        my $kenmerk = $voorwaarde->{kenmerk};
        $c->stash->{voorwaarden_kenmerken}->{$kenmerk} = 1;

        my $values = $self->_assert_array($values->{$kenmerk});

        unless($kenmerk eq 'aanvrager') {
            $c->stash->{last_kenmerk} = $kenmerk;
        }

# special case: empty value. Assert that no value has been entered 
# for this kenmerk
        if(!$voorwaarde->{value}) {
            $c->log->debug("regel requires empty value, seeing if there's anything of value");

            # see that there's minimally one element in the values array that
            # is not an empty string            
            $values = UNIVERSAL::isa($values, 'ARRAY') ? $values : [$values];
            my $joined_values = join '', @$values;

            if(length $joined_values) {
                $c->log->debug("non empty value found => NOT SATISFIED");
                $voorwaarde_result = 0;
                last;
            } else {
                $c->log->debug("empty value found => SATISFIED");
                $voorwaarde_result &&= 1;
                next;
            }
        }


        my $voorwaarde_values = { 
            map { $_ => 1 } 
            @{$self->_assert_array($voorwaarde->{value})} 
        };

#        $c->log->debug("kenmerk: " . Dumper( $kenmerk) . "values: " . Dumper($values));        
#        $c->log->debug("voorwaarden: " . Dumper( $voorwaarde_values));
        if($kenmerk eq 'aanvrager') {
            if($c->stash->{zaak}) {
                $values = [$c->stash->{zaak}->systeemkenmerk('aanvrager_type')];
            } else {
                my $betrokkene = $c->session->{_zaak_create}->{aanvragers}->[0]->{betrokkene};
                $c->log->debug("betrokkene: " . Dumper $c->session->{_zaak_create}->{aanvragers}->[0]);
                if($betrokkene =~ m|-natuurlijk_persoon-|) {
                    $values = ['Natuurlijk persoon'];
                } else {
                    $values = ['Niet natuurlijk persoon'];
                }
            }
        }

        foreach my $value (@$values) {
#            $c->log->debug('checking ' . $value);
            # only one checked checkbox satisfies the voorwaarde
            if(exists $voorwaarde_values->{$value}) {
#                $c->log->debug('exists');
                $voorwaarde_result &&= 1;
                last;
            }
        }    
        
        if(grep {exists $voorwaarde_values->{$_}} @$values) {
            $voorwaarde_result &&= 1;
        } else {
#            $c->log->debug('not found');
            # no hits - so it's a no
            $voorwaarde_result = 0;
        }
    }
    return $voorwaarde_result;
}


sub _assert_array {
    my ($self, $value) = @_;
    
    return [] unless $value;
    $value = [$value] unless(ref $value && ref $value eq 'ARRAY');

    return $value;
}


sub _filter_hash {
    my ($self, $source, $filter) = @_;
    
    my $result = {};
    foreach my $key (keys %$source) {
        if($key =~ m|^${filter}(.*)|) { 
            $result->{$1} = $source->{$key};
        }
    }
    return $result;
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

