package Zaaksysteem::SearchQuery;

#
# The purpose of this module is translate user input into storable filter settings and
# translate those into search query results. The settings are input through a set of routines,
# then serialized/deserialized into a JSON structure for storage in the database. A complex
# db structure is avoided. If a new parameter must be added, add it as a class member and at it to 
# the serialized/deserialize subs.
#
#


use strict;
use warnings;
use Scalar::Util;

use Data::Dumper;
use DateTime;
use Zaaksysteem::Constants qw/ZAAKSYSTEEM_STANDAARD_KENMERKEN ZAAKSYSTEEM_OPTIONS ZAKEN_STATUSSEN SEARCH_QUERY_TABLE_NAME/;
use File::Copy;
use Data::Serializer;

use Moose;


my $GROUPING_FIELDS = [
	{ name => 'me.zaaktype_id',    label => 'Zaaktype' },
	{ name => 'behandelaar_gm_id', label => 'Behandelaar',    grouping_field => 'behandelaar_gm_id' },
	{ name => 'vernietigen',       label => 'Te vernietigen', grouping_field => 'vernietigingstermijn' },
	{ name => 'route_ou',          label => 'Afdeling' },
	{ name => 'status',            label => 'Status' },
	{ name => 'contactkanaal',     label => 'Contactkanaal' },
];

my @SEARCH_FILTERS = qw/
	zaaktype
	kenmerk
	aanvrager
	adres
	status
	urgentie
	resultaat
	afdeling
	behandelaar
	coordinator
	periode
/;

my $zaken_statussen = ZAKEN_STATUSSEN;

### Filter deleted from zaken_statussen
$zaken_statussen    = [ grep { $_ ne 'deleted' } @{ $zaken_statussen } ];

my $FILTER_CONFIG = {
	status      => { class => 'checkbox', options => [ @{ $zaken_statussen }, 'vernietigen' ], query_field => 'me.status'},
	urgentie    => { class => 'checkbox', options => [qw/normal medium high late/], query_field => 'urgentie'},
	periode     => { class => 'period', },
	resultaat   => { class => 'checkbox', options => [
        @{ ZAAKSYSTEEM_OPTIONS->{RESULTAATTYPEN} },
        'geen resultaat'
    ], query_field => 'me.resultaat' },
	zaaktype    => { class => 'zaaktype',   query_field => 'zaaktype_node_id.zaaktype_id'},
	aanvrager   => { class => 'aanvrager',	query_field => 'me.aanvrager', ignore_empty_value => 1   },
	behandelaar => { class => 'user',       query_field => 'me.behandelaar', ignore_empty_value => 1, },
	coordinator => { class => 'user',       query_field => 'me.coordinator', ignore_empty_value => 1 },
	adres 		=> { class => 'address',    query_field => 'me.locatie_zaak'},
	afdeling    => { class => 'afdeling',   query_field => 'me.route_ou'    },
};


my @DEFAULT_SEARCH_FIELDS = qw/status id voortgang zaaktype extra_informatie aanvrager dagen/;

my $DISPLAY_FIELD_CONFIG = {
	id      			=> { class => 'zaaknummer', label => 'Zaaknr', data_field => 'me.id', sortable => '1'},
	extra_informatie 	=> {
        class       => 'subject',
        label       => 'Extra informatie',
        data_field  => 'me.onderwerp',
        sortable    => '1',
    },
	status				=> { class => 'status', sortable => '1'},
	voortgang			=> { class => 'voortgang', data_field => 'me.days_perc' },#TODO!!!!!
	zaaktype			=> { class => 'zaaktype', data_field => 'zaaktype_node_id.titel', sortable => '1' },
	aanvrager			=> { class => 'aanvrager'    , sortable => 1, data_field => 'aanvrager.naam', systeemkenmerk => 'aanvrager'},
	dagen				=> { class => 'remainingtime', sortable => 1, data_field => 'days_left'  , systeemkenmerk => 'dagen'},
	zaaknummer			=> { label => 'Zaaknr2' },
	aanvrager_email 	=> { label => 'Aanvrager E-mail' },
	behandelaar_email 	=> { label => 'Behandelaar E-mail' },
	coordinator_email 	=> { label => 'Coordinator E-mail' },
	ontvanger_email 	=> { label => 'Ontvanger E-mail' },
	aanvrager_burgerservicenummer => { label => 'Aanvrager burgerservicenummer' },
	iv3_categorie 		=> { label => 'IV3-Categorie' },
	behandelaar_tel 	=> { label => 'Behandelaar Tel.' },
	aanvrager_tel 		=> { label => 'Aanvrager Tel.' },
	ontvanger_tel 		=> { label => 'Ontvanger Tel.' },
#	aanvrager_naam 		=> { label => 'Volledige naam' }, # Ticket #1006 (verwijderen?)
	statusnaam		 	=> { label => 'Fasenaam' },
	aanvrager_voorvoegsel => { label => 'Aanvrager voorvoegsel' },
	aanvrager_woonplaats => { label => 'Aanvrager woonplaats' },
	uiterste_vernietigingsdatum => { label => 'Vernietigingsdatum' },
	aanvrager_geslachtsnaam => { label => 'Aanvrager geslachtsnaam' },
	pdc_tarief 			=> { label => 'Prijs' },
	aanvrager_geslacht 	=> { label => 'Aanvrager geslacht'},
	aanvrager_kvknummer => { label => 'Aanvrager KvK-nummer'},
	ontvanger_kvknummer => { label => 'Ontvanger KvK-nummer'},
	aanvrager_login 	=> { label => 'BedrijvenID' },
	coordinator_tel 	=> { label => 'Coordinator Tel.'},
	aanvrager_aanhef 	=> { label => 'Aanhef' },
	aanvrager_straat 	=> { label => 'Aanvrager straatnaam' },
	ontvanger_straat 	=> { label => 'Ontvanger straatnaam' },
	aanvrager_voornamen => { label => 'Aanvrager voornamen' },
	aanvrager_postcode 	=> { label => 'Aanvrager postcode' },
	aanvrager_mobiel 	=> { label => 'Aanvrager mobiel' },
    aanvrager_afdeling  => { label => 'Aanvrager afdeling' },
};


my $DONT_USE_THESE_DISPLAY_FIELDS = {map {$_, 1} qw/sjabloon_aanmaakdatum aanvrager_password statusnummer startdatum/};


my $STATUS_LABELS = {
	new => 'Nieuw',
	open => 'In behandeling',
	stalled => 'Opgeschort',
    deleted => 'Vernietigd',
	resolved => 'Afgehandeld',
	vernietigen => 'Te vernietigen',
};


my $URGENTIE_LABELS = {
	normal => 'Normaal',
	medium => 'Gemiddeld',
	high => 'Hoog',
	late => 'Te laat',
};



has 'log' => (
    is  => 'rw',
);

has 'dbic'  => (
    is  => 'rw',
);


has 'filters' => (
	is => 'rw',
	default => sub { [] },
	
);

has 'kenmerken' => (
	is => 'rw',
);


my $zaaksysteem_standaard_kenmerken_hash = ZAAKSYSTEEM_STANDAARD_KENMERKEN;
my @zaaksysteem_standaard_kenmerken = @DEFAULT_SEARCH_FIELDS;
push @zaaksysteem_standaard_kenmerken, keys %$zaaksysteem_standaard_kenmerken_hash;


has 'display_fields' => (
	is => 'rw',
#	default => sub { return \@DEFAULT_SEARCH_FIELDS; },
);

has 'grouping_field' => (
	is => 'rw',
);

has 'grouping_choice' => (
	is => 'rw',
);

has 'sort_field' => (
	is => 'rw',
);

has 'sort_direction' => (
	is => 'rw',
	default => 'DESC',
);

has 'access' => (
    is => 'rw',
);


sub grouping_field_options {
	my ($self) = @_;

	return $GROUPING_FIELDS;
}


sub filter_options {
	my ($self) = @_;

	return \@SEARCH_FILTERS;
}

sub status_labels { return $STATUS_LABELS; }

sub edit_display_fields {
	my ($self) = @_;

#	$self->log->debug("def search fields: " . Dumper \@DEFAULT_SEARCH_FIELDS);

	my $display_fields = $self->display_fields || \@DEFAULT_SEARCH_FIELDS;
#	$self->log->debug("edit fp: " . scalar @$display_fields);
	my $display_fields_hash = {map {$_, 1} @$display_fields};

	my $result = [];

# for each field put in hashref with the name and 'selected'
# first put in the current selection
	foreach my $display_field (@$display_fields) {
		push @$result, { 
			value => $display_field, 
			selected => 1, 
			label => $self->_format_display_field_label($display_field) 
		};
	}
	
# then figure out the other fields
#	foreach my $field (@zaaksysteem_standaard_kenmerken) {
	foreach my $field (sort { $self->_format_display_field_label($a) cmp $self->_format_display_field_label($b) }@zaaksysteem_standaard_kenmerken) {
		next if exists $DONT_USE_THESE_DISPLAY_FIELDS->{$field};

		unless(exists $display_fields_hash->{$field}) {
			push @$result, { 
				value => $field, 
				selected => 0, 
				label => $self->_format_display_field_label($field)
			};
		}
	}


	return $result;
}


sub _format_display_field_label {
	my ($self, $field) = @_;
	
	my $config = $DISPLAY_FIELD_CONFIG->{$field} || {};
	
	my $label = ucfirst($field);
	$label =~ s|_| |gis;
	if($field =~ m|^kenmerk|) {
	    $label = $field;

        $label =~ s/\D//g;
        if (my $bib = $self->dbic->resultset('BibliotheekKenmerken')->find($label)) {
            $label = $bib->naam;
        }
	}

	return $config->{'label'} || $label;	
}


sub set_display_fields {
	my ($self, $new_selection) = @_;

	die "need arrayref" unless(ref $new_selection && ref $new_selection eq 'ARRAY');
#	$self->log->debug("new selection" . scalar @$new_selection);
	die "need new selection" unless(defined $new_selection);
	
#		$self->display_fields(\@DEFAULT_SEARCH_FIELDS);
#		return;
#	}

	$self->display_fields($new_selection);
}


sub get_display_fields {
	my ($self, $opts) = @_;
	
	my $display_fields = $self->display_fields || \@DEFAULT_SEARCH_FIELDS;
	
	my @results = ();
	foreach my $display_field (@$display_fields) {
        if (
            $opts->{pip} &&
            (
                $display_field eq 'extra_informatie' ||
                $display_field eq 'aanvrager'
            )
        ) {
            next;
        }
		my $config = $DISPLAY_FIELD_CONFIG->{$display_field} || {};
		if($display_field =~ m|^kenmerk|) {
		    $config->{'class'} = 'kenmerk';
		}
		push @results, {
			fieldname => $config->{'data_field'} || $display_field,
			label     => $self->_format_display_field_label($display_field),
			class     => $config->{'class'} || 'text',
			sortable  => $config->{'sortable'},
            systeemkenmerk => $config->{systeemkenmerk} || $config->{'data_field'} || $display_field
		}
	}
	return \@results;
}


sub results {
	my ($self, $c, $page, $get_total) = @_;

	my $display_params = {
    	page => $page,
    };

	my $where = $self->_build_where_clause($c);

	if($self->sort_field && $self->sort_direction) {
		$display_params->{order_by} = { '-' .$self->sort_direction => $self->sort_field };
	}

    my $resultset = $c->model('DB::Zaak')->search_extended($where, $display_params);
    $resultset = $self->_search_kenmerken($c, $resultset);

    foreach my $filter (@{$self->filters}) {
		my $config = $FILTER_CONFIG->{$filter->{'type'}};
		my $period_filter = $self->_unserialize_hashref($filter->{value});

        next unless ($config->{'class'} eq 'period'); 
        my $start_date = $period_filter->{'start_date'};
        my $end_date   = $period_filter->{'end_date'};
        my $period_type = $period_filter->{'period_type'};
        
        if($period_type eq 'this_week') {
            my $week    = DateTime->now()->truncate('to' => 'week');
            $resultset  = $resultset->overlapt(
                $week,
                $week->add(
                    'days'  => 7
                )
            );
        }
        if($period_type eq 'last_week') {
            my $prev_week   = DateTime->now->clone->subtract(weeks => 1);
            my $last_week   = $prev_week->clone->subtract(days => ($prev_week->dow - 1));

            $resultset = $resultset->overlapt($last_week,
                $last_week->clone->add(days => 7)
            );
        }
        if($period_type eq 'this_month') {
            my $now     = DateTime->now();
            $resultset  = $resultset->overlapt(
                DateTime->new(
                    day     => 1,
                    month   => $now->month,
                    year    => $now->year
                ),
                DateTime->last_day_of_month(
                    year    => $now->year,
                    month   => $now->month,
                )
            );
        }
        if($period_type eq 'last_month') {
            my $prev_month  = DateTime->now->clone->subtract(months => 1);
            my $last_month  = DateTime->new(
                year    => $prev_month->year,
                month   => $prev_month->month,
                day     => 1
            );
            $resultset = $resultset->overlapt(
                $last_month,
                $last_month->clone->add(months => 1)
            );
        }
        if($period_type eq 'specific') {
            $start_date ||= '01-01-1900';
            $end_date ||= '31-12-3000';
            $resultset = $resultset->overlapt($self->_parsedate($start_date), $self->_parsedate($end_date));
        }
    }

    # for the purpose of total counts, bypass the grouping mechanism. we're interested in the number of 
    # results, not in the number of groups found.
    if($get_total) {
        return $resultset;
    }
    
    if($self->grouping_field && !$get_total) {
        if($self->grouping_choice) {
            my $grouping_choice = $self->grouping_choice eq 'empty' ? undef : $self->grouping_choice;
            if ($self->grouping_field eq 'behandelaar') {
                $resultset =
                $resultset->search({'zaak_betrokkenen.gegevens_magazijn_id' => $grouping_choice})->with_progress();
            } else {
                $resultset = $resultset->search({$self->grouping_field => $grouping_choice})->with_progress();
            }
        } else {
            $resultset = $resultset->search_grouped($where, $display_params, $self->grouping_field);
        }
    }

    return $resultset;
}



# sub _search_kenmerken {
#     my ($self, $c, $resultset) = @_;
# 
# 	my $kenmerken = $self->kenmerken || [];
# 	
# 	my $join_tables = [];
# 	my $search_map = {};
# 	my $i = 1; # yes. i.
# 	foreach my $kenmerk (@$kenmerken) {
# 
#         my $kenmerken_table_name = $i > 1 ? 'zaak_kenmerken_' . $i : 'zaak_kenmerken';
#         my $kenmerken_values_table_name = $i > 1 ? 'zaak_kenmerken_values_' . $i : 'zaak_kenmerken_values';
# 
#         my $operator = $kenmerk->{'operator'};
# 
#         my $value_clause;
#     
#         if($operator eq 'like') {
#             $value_clause = { 'ilike' => '%'.$kenmerk->{'data'}.'%' };
#         } elsif($operator eq 'not_like') {
#             $value_clause = { 'not_ilike' => '%'.$kenmerk->{'data'}.'%' };
#         } else {
#             if(ref $kenmerk->{'data'} && ref $kenmerk->{'data'} eq 'ARRAY') {
#                 $value_clause = {'-in' => $kenmerk->{'data'} };
#             } else {
#                 #$value_clause = { 'ilike' => $kenmerk->{'data'} };
#                 $operator ||= 'ilike';
# 
#                 ### Valuta workaround:
#                 my $value       = $kenmerk->{'data'};
# 
#                 if (
#                     $value =~ /\d+,00/ &&
#                     (
#                         $operator eq '=' ||
#                         $operator eq '!='
#                     )
#                 ) {
#                     my $altvalue = $value;
#                     $altvalue    =~ s/,00$//;
# 
#                     if ($operator eq '=') {
#                         $value = [
#                             { $operator    => $value },
#                             { $operator    => $altvalue },
#                         ];
#                     }
#                 }
#                 
#                 # enable numeric matching on text fields. first eliminate non-numeric records, then typecast and filter
#                 if($operator eq 'text>' || $operator eq 'text<') {
#                     my $sql_operator = $operator;
#                     $value =~ s|,|.|gis;
#                     $sql_operator =~ s|text||is;
#                     $search_map->{'CAST('.$kenmerken_values_table_name. '.value as numeric)'} = { $sql_operator => $value };
# #                    $search_map->{$kenmerken_values_table_name.'.value'} = {'~' => '^[0-9\.]+$'};
#                     $search_map->{$kenmerken_values_table_name.'.value'} = {'~' => '^([0-9]+|[0-9]+\\.[0-9]*|[0-9]*\\.[0-9]+)$'};
#                 }
# 
#                 $value_clause = { $operator => $value };
#             }
#         }
# 
# # from the DBIx::Class docs:
# # Joining to the same table twice
# # There is no magic to this, just do it. The table aliases will automatically be numbered:
# # join => [ 'room', 'room' ]
# # The aliases are: room and room_2.
#         
#         $search_map->{$kenmerken_table_name.'.bibliotheek_kenmerken_id'} = $kenmerk->{'id'};
#         $search_map->{$kenmerken_values_table_name.'.bibliotheek_kenmerken_id'} = $kenmerk->{'id'};
#         $search_map->{$kenmerken_values_table_name.'.value'} ||= $value_clause;
#         push @$join_tables, {'zaak_kenmerken', 'zaak_kenmerken_values' };
#  
#         $i++;
# 	}
#     
# 
#     if($kenmerken) {
#         $resultset = $resultset->search($search_map, {join => $join_tables});
#     }
# 
#     return $resultset;
# }


sub _search_kenmerken {
    my ($self, $c, $resultset) = @_;

	my $kenmerken = $self->kenmerken || [];
	my $and_clauses = [];

	foreach my $kenmerk (@$kenmerken) {
        $c->log->debug("kenmerk filter: " . Dumper $kenmerk);
        
        push @$and_clauses, $self->_create_kenmerk_clause($c, $kenmerk);
    }

    my $sql = join ' and ', @$and_clauses;
    $c->log->debug("SQL for kenmerk search: " . $sql);
    return $resultset->search(\[ $sql ]);
    
    
    return $resultset;
}



sub _create_kenmerk_clause {
    my ($self, $c, $kenmerk) = @_;

    my $kenmerk_clause = { value_field => 'value' };
    my $operator = $kenmerk->{'operator'};
    my $additional_clause = '';

    my $bibliotheek_kenmerk = $c->model("DB::BibliotheekKenmerken")->find($kenmerk->{id});
    my $kenmerk_type = $bibliotheek_kenmerk->value_type;
    $c->log->debug("kenmerk_type: " . $kenmerk_type);
    $c->log->debug("multiple: " . $bibliotheek_kenmerk->type_multiple);
    
    if($operator eq 'like' && $kenmerk->{data}) {
        $kenmerk_clause->{operator} = 'ILIKE';
        $kenmerk_clause->{value} = "'" .'%'.$kenmerk->{'data'}.'%' . "'";
    } elsif($operator eq 'not_like' && $kenmerk->{data}) {
        $kenmerk_clause->{operator} = 'NOT ILIKE';
        $kenmerk_clause->{value} = "'" . '%'.$kenmerk->{'data'}.'%' . "'";
    } else {
    
        # determine if the value should be operated on as a number.

        my $numeric = 0;
        if(
            $operator eq 'text>' || 
            $operator eq 'text<' || 
            $kenmerk_type eq 'valuta' || 
            $kenmerk_type eq 'valuta_ex' || 
            $kenmerk_type eq 'valuta_in'
        ) {
            $numeric = 1;
        }
        

        # enable numeric matching on text fields. first eliminate non-numeric 
        # records, then typecast and filter
        if($numeric) {
            $c->log->debug("numeric operator");
            my $sql_operator = $operator;
            $kenmerk_clause->{value} = $kenmerk->{data} || 0;
            $kenmerk_clause->{value} =~ s|,|.|gis;
            $sql_operator =~ s|text||is;
            $kenmerk_clause->{value_field} = 'CAST(zaak_kenmerk.value as numeric)';
            $additional_clause = " AND zaak_kenmerk.value ~ '" .     '^([0-9]+|[0-9]+\\.[0-9]*|[0-9]*\\.[0-9]+)$' ."'";
            $kenmerk_clause->{operator} = $sql_operator;

        } elsif($operator) {
$c->log->debug("op: " . $operator . ', da: ' . Dumper $kenmerk);
            $kenmerk_clause->{operator} = $operator;
            $kenmerk_clause->{value} = "'" . $kenmerk->{data} . "'";

        } else {
            # no operator, must be checkbox or literal input
            my $kenmerk_data = $kenmerk->{data};
            $kenmerk_data = [$kenmerk_data] unless ref $kenmerk_data;

            # a series of values, indicating checkboxes
            $kenmerk_clause->{operator} = 'IN';
            $kenmerk_clause->{value} = join ',', map { "'$_'" } @$kenmerk_data;     
        }
    }

#         
#         if($kenmerk_type eq 'valuta' || $kenmerk_type eq 'valuta_ex' || $kenmerk_type eq 'valuta_in') {
#             ### Valuta workaround:
#             my $value = $kenmerk->{'data'};
#     
#             if (
#                 $value =~ /\d+,00/ &&
#                 (
#                     $operator eq '=' ||
#                     $operator eq '!='
#                 )
#             ) {
#                 my $altvalue = $value;
#                 $altvalue    =~ s/,00$//;
#     
#                 if ($operator eq '=') {
#                     $value = [
#                         { $operator    => $value },
#                         { $operator    => $altvalue },
#                     ];
#                 }
#             }
#         } 
        

    my $and_clause =  'exists (select 1 from zaak_kenmerk '.
        'where zaak_id = me.id and bibliotheek_kenmerken_id = '.
        $kenmerk->{id}.
        ' and '. $kenmerk_clause->{value_field} . ' ' . 
        $kenmerk_clause->{operator}. ' ('. 
        $kenmerk_clause->{value} .') ' . $additional_clause . ')';

    return $and_clause;

}


sub _parsedate {
    my ($self, $date) = @_;

    die "illegal date format : $date" unless($date =~ m|^(\d\d)[-/](\d\d)[-/](\d\d\d\d)$|);
    my ($day, $month, $year) = split /[\/-]/, $date;
    
    die "illegal month ($date)" unless $month > 0 && $month <= 12;
    die "illegal day ($date)" unless $day > 0 && $day <= 31;

    return DateTime->new('day'=> $day, 'month' => $month, 'year' => $year);
}



sub _build_where_clause {
	my ($self, $c) = @_;
	my $filters = $self->filters;
	my $where = { 'me.deleted' => undef, 'me.created' => { '<' => DateTime->now()} };

	foreach my $filter (@$filters) {
		my $type = $filter->{'type'};
#		$self->log->debug("type: " . $type . ", value: " . Dumper $filter->{'value'});

		my $config = $FILTER_CONFIG->{$type};
		my $query_field = $config->{'query_field'} || $type;


		if($config->{'class'} eq 'checkbox') {
		    if($type eq 'urgentie') {
		        $where->{$query_field} = [split /&/, $filter->{value}];
            } elsif ($type eq 'status' && $filter->{value} eq 'vernietigen') {
                $where->{vernietigingsdatum} = { '<' => DateTime->now };
		    } else {
                if ($filter->{value} =~ /vernietigen/) {
                    my $value = $filter->{value};
                    $value =~ s/&?vernietigen//g;
                    $where->{'-or'} = [
                        { vernietigingsdatum  => { '<' => DateTime->now } },
                    ];
                    my @parts = split /&/, $value;
                    if (scalar @parts) {
                        push (
                            @{ $where->{'-or'} },
                            {
                                $query_field      => {
                                    '-in' => \@parts
                                }
                            }
                        );
                    };
                } else {
                    if ($type eq 'resultaat' && $filter->{value} =~ /geen resultaat/) {
                        my $value       = $filter->{value};
                        $value          =~ s/&?geen resultaat//g;
                        $where->{'-or'} = [
                            { $query_field      => undef },
                            { $query_field      => { '='    => '' } },
                        ];
                        
                        my @parts = split /&/, $value; 
                        if (scalar @parts) {
                            push (
                                @{ $where->{'-or'} },
                                {
                                    $query_field      => {
                                        '-in' => \@parts
                                    }
                                }
                            );
                        }
                    } else {
                        $where->{$query_field} = { '-in' => [split /&/, $filter->{value}] };
                    }
                }
	        }
		} 
		elsif($config->{'class'} eq 'zaaktype') {
			$self->_add_where_clause($where, $query_field, $filter->{'value'});
		} 
		elsif($config->{'class'} eq 'user' || $config->{'class'} eq 'aanvrager') {
			# betrokkene-natuurlijk_persoon-22323  betrokkene-TYPE-ID
			
			my ($betrokkene_type, $betrokkene_id);
			
			
			if($config->{'class'} eq 'aanvrager') {
    			my $aanvrager_filter = $self->_unserialize_hashref($filter->{value});
                $betrokkene_type = $aanvrager_filter->{'betrokkene_type'};
                $betrokkene_id = $aanvrager_filter->{'betrokkene_id'};
			} else {
		        ($betrokkene_type, $betrokkene_id) = $filter->{'value'} =~ m|^betrokkene-(\w+)-(\d+)$|;
            }

			my $betrokkenen = $c->model('DB::ZaakBetrokkenen')->search({
				'betrokkene_type'       => $betrokkene_type,
				'gegevens_magazijn_id'  => $betrokkene_id,
			});

			$self->_add_where_clause($where, $query_field, {
				-in => $betrokkenen->get_column('id')->as_query
			});
		}
		elsif($config->{'class'} eq 'address') {
			# nummeraanding-234234234 (type-id)
			my ($bag_type, $bag_id) = $filter->{'value'} =~ m|^(\w+)-(\d+)$|;

            if ($bag_type) {
                my $addressen = $c->model('DB::ZaakBag')->search({
                    'bag_' . $bag_type . '_id'  => $bag_id
                });

                $self->_add_where_clause($where, $query_field, {
                    -in => $addressen->get_column('id')->as_query
                });
            }
		}
		elsif($config->{'class'} eq 'afdeling') {
            my $afdeling_filter = $self->_unserialize_hashref($filter->{value});
            my $ou_id = $afdeling_filter->{'ou_id'};
            if($ou_id) {
    			$self->_add_where_clause($where, 'route_ou', $ou_id);
            }
            my $role_id = $afdeling_filter->{'role_id'};
            if($role_id) {
    			$self->_add_where_clause($where, 'route_role', $role_id);
            }            
		}
		elsif($config->{'class'} eq 'period') {
		    #use overlapt function
		} else {
			die 'need to configure: ' . $config->{'class'};
		}
			
#TODO $where->{'me.route_ou'} = $filter->{'value'};
#$where->{'days_running'} = $filter->{'value'};
			
	}
	return $where;
}


sub _add_where_clause {
	my ($self, $where, $query_field, $value) = @_;

	# if this is the first element, just add it and be done with it
	unless(exists $where->{$query_field}) {
		$where->{$query_field} = $value;
		return;
	}
	
	# if we get here, there is already something there. if there is an
	# array, push it on top. otherwise make it into an array
	# be prepared for multiple filters
	unless(ref $where->{$query_field} && ref $where->{$query_field} eq 'ARRAY') {
		$where->{$query_field} = [$where->{$query_field}];
	}

	# no we should have an array ref to with with. just push.
	push @{$where->{$query_field}}, $value;
}


#
# display version of filters
#
sub get_filters {
	my ($self, $c) = @_;
		
	my $filters = $self->filters() || [];

	my $result = {};
	foreach my $filter (@$filters) {
		my $type = $filter->{type};
#		$self->log->debug("type: " . $type);
		my $config = $FILTER_CONFIG->{$type};
#		$self->log->debug(Dumper $config);
		if($config->{class} eq 'checkbox') {
			if($filter->{value}) {
				$filter->{options} = [map {$self->_format_option_label($type, $_)} 
					split /&/, $filter->{value}];
			}
		} elsif($config->{class} eq 'period' || $config->{'class'} eq 'address') {
			my $period_filter = $self->_unserialize_hashref($filter->{value});
			foreach my $key (keys %$period_filter) {
				$filter->{$key} = $period_filter->{$key};
			}
		} elsif($config->{class} eq 'afdeling') {
			my $afdeling_filter = $self->_unserialize_hashref($filter->{value});
			foreach my $key (keys %$afdeling_filter) {
				$filter->{$key} = $afdeling_filter->{$key};
			}
		} elsif($config->{class} eq 'user') {
			my $value = $filter->{value};
			($filter->{user_id}) = $value =~ m|(\d+)|is;
		} elsif($config->{class} eq 'aanvrager') {
			my $aanvrager_filter = $self->_unserialize_hashref($filter->{value});
			$self->log->debug(Dumper $aanvrager_filter);
			$filter->{'betrokkene'} =  $aanvrager_filter->{'name'};
			$filter->{'betrokkene_type'} =  $aanvrager_filter->{'betrokkene_type'};
			if($aanvrager_filter->{'betrokkene_type'} eq 'org_eenheid') {
			    my $bo = $c->model('Betrokkene')->get({
                    type    => 'org_eenheid',
                    intern  => 0,
                }, $aanvrager_filter->{'betrokkene_id'});
    			$filter->{'betrokkene'} =  $bo->naam;
			}
		}

		$filter->{class} = $config->{class} || 'text';

		$result->{$type} ||= [];
		push @{$result->{$type}}, $filter;
	}
	
#TODO sort?

	return $result;
}


#
# prepare the data of a filter for editing
#
sub edit_filter {
	my ($self, $type, $value) = @_;
	
	my $config = $FILTER_CONFIG->{$type};
	
#	$self->log->debug("config: " .Dumper $config);
#	$self->log->debug("value: " .Dumper $value);
	my $data = {
		class   => $config->{class} || 'text',
		type    => $type,
		value   => $value,
	};
	
	if($config->{'class'} eq 'checkbox') {
		my $options = [];
		my %selected = map { $_ => 1 } split /&/, $value;
		foreach my $option (@{$config->{options}}) {
			my $option_hash = {
				name 		=> $option,
				checked 	=> exists $selected{$option} ? 'checked' : '',
				description => $self->_format_option_label($type, $option),
			};
			push @$options, $option_hash;
		}
		$data->{options} = $options;
	} elsif($config->{'class'} eq 'period') {
		my $period_filter = $self->_unserialize_hashref($value);
		foreach my $key (keys %$period_filter) {
			$data->{$key} = $period_filter->{$key};
		}
		$data->{'period_type'} ||= 'specific';
	} elsif($config->{'class'} eq 'aanvrager') {
		my $aanvrager_filter = $self->_unserialize_hashref($value);
		foreach my $key (keys %$aanvrager_filter) {
			$data->{$key} = $aanvrager_filter->{$key};
		}
		$data->{'betrokkene_type'} ||= 'medewerker';
	} elsif($config->{'class'} eq 'afdeling') {
		my $filter = $self->_unserialize_hashref($value);
		foreach my $key (keys %$filter) {
			$data->{$key} = $filter->{$key};
		}	    
    } elsif($config->{'class'} eq 'address') {
    	my ($bag_type, $bag_value) = split /-/, $value;
    	# retrieve bag address associated with this, same story at rendering time
    } 
    
	return $data;	
}


sub _format_option_label {
	my ($self, $type, $option) = @_;
	
	if($type eq 'status') {
		return $STATUS_LABELS->{$option} || '';
	}
	if($type eq 'urgentie') {
		return $URGENTIE_LABELS->{$option} || '';
	}
	return ucfirst($option);
}



#
# here one filter is updated.
# if the new filter is empty, don't add it. javascript should handle user feedback
# if the new filter is the same as an existing item, don't add it
#
sub update_filter {
	my ($self, $params) = @_;


#	$self->log->debug("filters before: " . Dumper($filters));

	if($params->{previous_value}) {
		$self->_remove_filter($params->{filter_type}, $params->{previous_value});
	}

	my $type = $params->{filter_type};

	my $new_filter = $self->_create_filter($type, $params);

	return unless($new_filter->{'value'});
	return if($self->_find_filter($new_filter->{type}, $new_filter->{value}));
	
	my $filters = $self->filters;
	$filters ||= [];
	push @$filters, $new_filter;
	$self->filters($filters);
}


sub _create_filter {
	my ($self, $type, $params) = @_;

	my $new_filter = {
		type => $type,
		value => $params->{value},
	};
#$self->log->debug("create filter: " . Dumper $new_filter);
	my $config = $FILTER_CONFIG->{$type};

	if($config->{class} eq 'checkbox') {
		my @values = ();
		foreach my $option (@{$config->{options}}) {
			if(exists $params->{$option} && $params->{$option} eq 'on') {
				push @values, $option;
			}
		}
		$new_filter->{value} = join "&", @values;
	} elsif($config->{class} eq 'period') {
		my $period_filter = {
			period_type => $params->{period_type}, 
			start_date  => $params->{start_date}, 
			end_date    => $params->{end_date},
		};
		# javascript should make sure the user puts in something
		if($params->{period_type} eq 'specific') {
			die "need at least one date" unless($params->{start_date} || $params->{end_date});
		}
		$new_filter->{value} = $self->_serialize_hashref($period_filter);
	} elsif($config->{class} eq 'afdeling') {
	    my $afdeling_filter = {
	        'ou_id' => $params->{'ou_id'},
	        'role_id' => $params->{'role_id'},
	    };
		$new_filter->{value} = $self->_serialize_hashref($afdeling_filter);
	} elsif($config->{class} eq 'address') {
		$new_filter->{value} = $params->{'bag_value'};
	} elsif($config->{class} eq 'aanvrager') {
	    my $value = $params->{'betrokkene_type'} eq 'org_eenheid' ? $params->{'ztc_org_eenheid_id'} : $params->{'ztc_aanvrager_id'}; 
	
        return if (
            exists($config->{ignore_empty_value}) &&
            $config->{ignore_empty_value} &&
            !$value
        );

        my $aanvrager_filter = {
            'value'  => $value,
            'name'   => $params->{'naam_betrokkene'},
            'betrokkene_type' => $params->{'betrokkene_type'},
            'betrokkene_id' => $value =~ m|(\d+)|,
        };
		$new_filter->{value} = $self->_serialize_hashref($aanvrager_filter);
	}
	
#	$self->log->debug("VALUE: " . Dumper($new_filter->{value}));
	
	return $new_filter;
}


sub _remove_filter {
	my ($self, $filter_type, $previous_value) = @_;

	my $filters = $self->filters;

	# this is an update, remove the old item
	my $new_selection = [];
	foreach my $filter (@$filters) {		
		unless($filter->{type} eq $filter_type &&
			$filter->{value} eq $previous_value) {
			push @$new_selection, $filter;			
		}
	}
	
	$self->filters($new_selection);
}


#
# mass update, with the purpose of deletion. necessary?
# 
sub update_filters {
	my ($self, $types, $values, $kenmerken) = @_;

	die "need types arrayref" unless(ref $types && ref $types eq 'ARRAY');
	die "need values arrayref" unless(ref $values && ref $values eq 'ARRAY');

	unless($types && $values) {
		$self->filters([]);
		return;
	}

	my $filters = [];
	foreach my $type (@$types) {
		my $new_filter = {
			type => $type,
			value => shift @$values,
		};
		push @$filters, $new_filter;
	}
	
	$self->filters($filters);
	$self->kenmerken($kenmerken);
}


sub get_kenmerken {
	my ($self, $c) = @_;

	die "need c" unless($c);

	my $kenmerken = $self->kenmerken || [];
	foreach my $kenmerk (@$kenmerken) {
        my $kenmerk_item = $c->model('DB::BibliotheekKenmerken')->find($kenmerk->{'id'});
        die "unknown kenmerk type" unless($kenmerk_item);
        my $value_type = $kenmerk_item->value_type;
	}
	return $kenmerken;
}


sub update_sort_field {
	my ($self, $sort_field) = @_;
	
	my $current_sort_field = $self->sort_field || '';
	
	if($current_sort_field eq $sort_field) {
		if($self->sort_direction eq 'ASC') {
			$self->sort_direction('DESC');
		} else {
			$self->sort_direction('ASC');
		}
	} else {
		$self->sort_direction('ASC');
	}
	$self->sort_field($sort_field);
}



#
# return a serialized version of the object
#
sub serialize {
	my ($self) = @_;
	
	my $settings = {
		filters         => $self->filters,
		display_fields  => $self->display_fields,
		sort_field      => $self->sort_field,
		sort_direction      => $self->sort_direction,
		kenmerken       => $self->kenmerken,
		access          => $self->access,
	};

	return $self->_serializer->serialize($settings);
}

sub _serializer {
	return Data::Serializer->new(
		serializer => 'JSON',
	);
}


sub unserialize {
	my ($self, $serialized) = @_;

	my $settings = $self->_serializer->deserialize($serialized);

	$self->filters($settings->{'filters'});
	$self->display_fields($settings->{'display_fields'});
	$self->sort_field($settings->{'sort_field'});
	$self->sort_direction($settings->{'sort_direction'});
	$self->kenmerken($settings->{'kenmerken'});
	$self->access($settings->{'access'});
}



sub _serialize_hashref {
	my ($self, $hashref) = @_;

	my @items = ();
	foreach my $key (sort keys %$hashref) {
		my $value = $hashref->{$key};
		push @items, $key . '=' . $value;
	}

	return join "&", @items;
}


sub _unserialize_hashref {
	my ($self, $serialized) = @_;

	my $hashref = {};
	my @items = split /&/, $serialized;
	foreach my $item (@items) {
		my ($key, $value) = split /=/, $item;
		$hashref->{$key} = $value;
	}
		
	return $hashref;
}


sub _find_filter {
	my ($self, $type, $value) = @_;
	
	my $filters = $self->filters;
	$filters ||= [];

	foreach my $filter (@$filters) {
		if($filter->{type} eq $type && $filter->{value} eq $value) {
			return 1;
		}
	}
	
	return 0;
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

