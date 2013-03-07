package Zaaksysteem::Zaken::ResultSetZaak;

use strict;
use warnings;

use Moose;
use Data::Dumper;

use Zaaksysteem::Constants qw/
    ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_HIGH
    ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_MEDIUM
    ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_LATE
/;

extends 'DBIx::Class::ResultSet';

with
    'Zaaksysteem::Zaken::Roles::ZaakSetup';

my $SPECIAL_WHERE_CLAUSES   = {
    'urgentie'  => '
        abs(ROUND(100 *(
            date_part(\'epoch\', COALESCE(me.afhandeldatum, NOW()) - me.registratiedatum )
            /
            GREATEST(date_part(\'epoch\', me.streefafhandeldatum - me.registratiedatum), 1)
         ) ))
    '
};

### Prevent division by zero (date_part(\'epoch\', me.streefafhandeldatum - me.registratiedatum) + 1)
my $SPECIAL_SELECTS         = {
    'days_left'     => 'date_part(\'days\', me.streefafhandeldatum - COALESCE(me.afhandeldatum, NOW()))',
    'days_perc'     => 'ROUND( 100 *(
            date_part(\'epoch\', COALESCE(me.afhandeldatum, NOW()) - me.registratiedatum )
            /
            GREATEST(date_part(\'epoch\', me.streefafhandeldatum - me.registratiedatum), 1)
         ) )
    ',
    'days_running'  => 'date_part(\'days\', COALESCE(me.afhandeldatum, NOW()) - me.registratiedatum )',
};

sub search {
    my $self    = shift;

    unless ([ caller(1) ]->[3] =~ /_prepare_search/) {
        return $self->_prepare_search(@_);
    }

    if (
        $_[1] &&
        UNIVERSAL::isa($_[1], 'HASH') &&
        (my $order_by = $_[1]->{order_by})
    ) {
        if (UNIVERSAL::isa($order_by, 'HASH')) {
            while (my ($key, $order_by) = each %{ $order_by }) {
                if ($SPECIAL_SELECTS->{$order_by}) {
                    $_[1]->{order_by}->{$key} = $SPECIAL_SELECTS->{$order_by};
                }
            }
        } else {
            if ($SPECIAL_SELECTS->{$order_by}) {
                $_[1]->{order_by} = $SPECIAL_SELECTS->{$order_by};
            }
        }
    }

    $self->next::method(@_);
}

sub _prepare_search {
    my $self                = shift;
    my $where               = shift;
    my $additional_options  = {};

    ## Additional options
    unless ($self->{attrs}->{ran}) {
        $additional_options->{'join'}   = [
            #'zaak_betrokkenen',
            {
                zaaktype_node_id    => 'zaaktype_definitie_id',
#               zaak_kenmerken      => 'zaak_kenmerken_values',
            }
        ];

        $additional_options->{'prefetch'}   = [
            'aanvrager',
            'behandelaar',
            {
                zaaktype_node_id    => 'zaaktype_definitie_id',
                #zaak_kenmerken      => 'zaak_kenmerken_values',
                #zaak_kenmerken      => 'bibliotheek_kenmerken_id',
            }
        ];

        $additional_options->{'+select'}    = [];
        for my $key (sort keys %{ $SPECIAL_SELECTS }) {
            my $value = $SPECIAL_SELECTS->{$key};
            push(
                @{ $additional_options->{'+select'} },
                \$value
            );
        }

#        $additional_options->{'+select'}    = [
#            [ \'date_part(\'days\', NOW() - me.registratiedatum )' ],
#            [ \'date_part(\'days\', me.streefafhandeldatum - NOW())'],
#            [ \'ROUND( 100 *(
#                    date_part(\'epoch\', NOW() - me.registratiedatum )
#                    /
#                    date_part(\'epoch\', me.streefafhandeldatum - me.registratiedatum)
#                 ) )
#            '],
#        ];

        # ROUND(100 * (EXTRACT( EPOCH FROM( AGE( NOW(), me.registratiedatum ) ) )
        # ) / EXTRACT( EPOCH FROM( AGE( me.streefafhandeldatum,
        # me.registratiedatum ) ) )) as percentage_complete

        $additional_options->{'+as'}        = [
            sort keys %{ $SPECIAL_SELECTS }
        ];
    }

    $self->{attrs}->{ran} = 1;

    my $rs = $self->search({}, $additional_options);


    ### SPECIAL CONSTRUCT FOR URGENT!
    while (my ($column, $definition)    = each %{ $SPECIAL_WHERE_CLAUSES }) {
        next unless UNIVERSAL::isa($where, 'HASH') && $where->{$column};

        my @where_clauses;
        if (UNIVERSAL::isa($where->{$column}, 'ARRAY')) {
            push(@where_clauses, @{ $where->{$column} });
        } else {
            push(@where_clauses, $where->{$column});
        }

        my @sql;
        for my $where_clause (@where_clauses) {
            if ($where_clause && UNIVERSAL::isa($where_clause, 'HASH')) {
                push(@sql, $definition .
                    [ keys(%{ $where_clause }) ]->[0] .
                    [ values(%{ $where_clause }) ]->[0]
                );
            } elsif (
                grep { $_ eq lc($where_clause) } qw/normal medium high late/
            ) {
                if (lc($where_clause) eq 'normal') {
                    push(@sql, $definition . '<' .
                        (100 - (ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_MEDIUM * 100))
                    );
                } elsif ( lc($where_clause) eq 'medium') {
                    push(@sql, $definition . ' < ' .
                        (100 - (ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_HIGH * 100)) .
                        ' AND ' .
                        $definition . ' >= ' .
                        (100 - (ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_MEDIUM * 100))
                    );
                } elsif ( lc($where_clause) eq 'high') {
                    push(@sql, $definition . ' >= ' .
                        (100 - (ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_HIGH * 100))
                        . ' AND ' .
                        $definition . ' < ' .
                        (ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_LATE * 100)
                    );
                } elsif ( lc($where_clause) eq 'late') {
                    push(@sql, $definition . ' >= ' .
                        (ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_LATE * 100)
                    );
                }
            } else {
                die(
                    'ERROR: Special Z::Zaken::ZaakResultSet where '
                    . 'column "' . $column . '" needs HASH/ARRAY as parameter.'
                );
            }
        }
        #my $sql = ' ( me.status != \'resolved\' AND me.status != \'stalled\' AND
        #me.status != \'deleted\' AND ( ' . join(' ) OR ( ', @sql) . ') )';
        my $sql = ' ( ( ' . join(' ) OR ( ', @sql) . ') )';
        $rs = $rs->search(\[ $sql ]);

        delete($where->{$column});
    }

    #$rs->{attrs}->{ran} = 1;

    return $rs->search($where, @_);
}

sub search_extended {
    my $self                    = shift;

    my $rs                      = $self->search(@_);

    if (
        $self->{attrs}->{current_user} &&
        $self->{attrs}->{current_user}->uidnumber
    ) {
        my $user_id                 = $self->{attrs}->{current_user}->uidnumber;
        my $secure_zaaktype_list    = $self->result_source->schema
            ->source('Zaaktype')->resultset->search({
                'zaaktype_node_id.zaaktype_vertrouwelijk'   => 1,
                'me.deleted'                                => undef,
            },
            {
                join        => 'zaaktype_node_id',
            }
        );

        my $ou_id       = $self->{attrs}->{current_user}->user_ou->get_value('l');
        my @role_ids    = map { $_->get_value('gidNumber') }
            $self->{attrs}->{current_user}->get_roles;

        warn('OU,ROLES: ' . Dumper([$ou_id, \@role_ids]));

        my $auth_list               = $self->result_source->schema
            ->source('ZaaktypeAuthorisation')->resultset->search(
                {
                    zaaktype_id     => {
                        -in     => $secure_zaaktype_list->get_column('me.id')->as_query,
                    },
                    role_id             => {
                        -in     => [ @role_ids ],
                    },
                    ou_id               => $ou_id,
                }
            );

        ### Make sure vertrouwelijke zaken komen niet naar voren
        $rs  = $rs->search({
            '-or'   => [
                { 'zaaktype_node_id.zaaktype_vertrouwelijk' => undef },
                { 'zaaktype_node_id.zaaktype_vertrouwelijk' => 0 },
                { '-and'    => [
                        { 'zaaktype_node_id.zaaktype_vertrouwelijk'   => 1 },
                        { '-or'   => [
                                { 'me.zaaktype_id'   => {
                                        -in => $auth_list->get_column('zaaktype_id')->as_query
                                    },
                                },
                                { 'me.aanvrager_gm_id'    => $user_id },
                                { 'me.behandelaar_gm_id'  => $user_id },
                                { 'me.coordinator_gm_id'  => $user_id },
                            ],
                        }
                    ],
                }
            ]
        });
    }

    $rs         = $rs->search({
        'me.registratiedatum'   => { '<'    => DateTime->now() }
    });

    return $rs;
}

sub with_progress {
    my $self                            = shift;

    return $self->search(@_);
}

sub search_grouped {
    my $self    = shift;
    my $group   = pop;

    #$group = 'zaak_betrokkenen.gegevens_magazijn_id';

#    while (my ($key, $value) = each %{ $self->{attrs} }) {
#        next if $key eq 'betrokkene_model';
#        next if $key eq 'c';
#        warn($key . ' => ' . Dumper($value));
#    }
    my $search = $self->search(@_);
#    while (my ($key, $value) = each %{ $search->{attrs} }) {
#        next if $key eq 'betrokkene_model';
#        next if $key eq 'c';
#        warn($key . ' => ' . Dumper($value));
#    }

    ### Ok, het ziet er uit als een hack, en ja, dat is het ook. Punt is dat
    ### de prefetch functie ons problemen geeft bij het vinden van de me
    ### (zaak) tabel.
    ###
    ### De attrs +select en +as zijn voor het weergeven van extra kolommen
    ### welke uiteraard uit moeten staan: we willen immers alleen een count

    delete($search->{attrs}->{'+select'});
    delete($search->{attrs}->{'+as'});
    delete($search->{attrs}->{'prefetch'});

#    while (my ($key, $value) = each %{ $search->{attrs} }) {
#        next if $key eq 'betrokkene_model';
#        warn($key . ' => ' . Dumper($value));
#    }

    my $search_opts = {};

    my $attrs       = {
        as          => [ 'group_naam', 'group_count' ],
        group_by    => [ $group ],
    };

    if ($group eq 'behandelaar') {
        $search_opts->{'me.behandelaar'} = \'= zaak_betrokkenen.id';
        $attrs->{group_by} = [ 'zaak_betrokkenen.gegevens_magazijn_id' ];
        $attrs->{select} = [ 'zaak_betrokkenen.gegevens_magazijn_id', { count => { distinct => 'me.id'} } ],
    } else {
        $attrs->{select} = [ $group, { count => { distinct => 'me.id'} } ],
    }

    return $search->search($search_opts,$attrs);
}

sub overlapt {
    my $self        = shift;
    my $startdt     = shift;
    my $stopdt      = shift;

    $startdt    = $startdt->datetime;
    $stopdt     = $stopdt->datetime;

    $startdt    =~ s/T/ /;
    $stopdt    =~ s/T/ /;

    return $self->search(\[
            "(DATE('" . $startdt . "'), DATE('" . $stopdt . "'))"
                . " OVERLAPS " .
            "(me.registratiedatum, me.afhandeldatum)"
    ]);

    return $self;
}

sub _group_geregistreerd_data {
    my $self                        = shift;
    my ($startdatum, $einddatum)    = @_;
    my $interval = '1 day';
    my $interval_label = 'day';

    if (!$startdatum) {
        #delete($self->{attrs}->{'group_by'});
        my $zaken = $self->search(
            {},
            {
                order_by => { '-asc' => 'registratiedatum' },
                group_by => undef,
                select   => ['me.registratiedatum'],
                'as'     => ['registratiedatum'],
            }
        );

        my $startzaak = $zaken->first;

        return (undef,undef) unless $startzaak;

        $startdatum = $startzaak->registratiedatum;
    }


    if (!$einddatum) {
        my $zaken = $self->search(
            {},
            {
                order_by => { '-desc' => 'registratiedatum' },
                group_by => undef,
                select   => ['registratiedatum'],
                'as'     => ['registratiedatum'],
            }
        );
        delete($zaken->{attrs}->{'group_by'});

        my $eindzaak = $zaken->first;

        return (undef,undef) unless $eindzaak;

        $einddatum = $eindzaak->registratiedatum;
    }

    ### Do some checks
    if (($einddatum->epoch - $startdatum->epoch) > ((31*86400) * 3)) {
        $interval = '1 month';
        $interval_label = 'month';
    } elsif (($einddatum->epoch - $startdatum->epoch) > (31 * 86400) ) {
        ### groter dan 3 maanden, interval 1 week
        $interval = '1 week';
        $interval_label = 'week';
    } elsif (($einddatum->epoch - $startdatum->epoch) < 3600) {
        $interval = '1 minute';
        $interval_label = 'minute';
    } elsif (($einddatum->epoch - $startdatum->epoch) < 86400) {
        $interval       = '1 hour';
        $interval_label = 'hour';
    }

    return (
        DateTime->new(
            day => $startdatum->day,
            month => $startdatum->month,
            year => $startdatum->year,
        ),
        DateTime->new(
            day     => $einddatum->day,
            month   => $einddatum->month,
            year    => $einddatum->year,
            hour    => 23,
            minute  => 59,
            second  => 59
        ),
        $interval,
        $interval_label
    );
}

sub _group_geregistreerd_resultset {
    my $self        = shift;
    my $replace     = shift;
    my $interval    = shift;

    my ($query, @bindargs);

    my $queryobject   = $self->search({}, {
        select      => { 'distinct' => 'me.id' },
        group_by    => undef,
        order_by    => undef,
    })->as_query;

    ($query, @bindargs)  = @{ ${ $queryobject } };

    ### Overwrite definition
    my $source                 =
        $self->result_source->schema->source('ZaakGrafiek' . ucfirst($replace));

    my $new_definition      = $source->view_definition_template;
    $new_definition         =~ s/INNERQUERY/$query/;
    $new_definition         =~ s/INTERVAL/\'$interval\'/g;

    #$new_definition         =~ s/DATAREPL/\'$interval\'/g;

    $source->view_definition(
        $new_definition
    );

    return ($source, @bindargs);
}

sub group_geregistreerd {
    my $self        = shift;

# select period.date as period, count(zaak.id) as zaken from (select
# generate_series('2011-07-01'::timestamp, '2011-07-30'::timestamp, '1 week')
# as date) as period left outer join zaak on zaak.created between period.date
# AND (date(period.date) + interval '1 week') and zaak_id IN (QUERY) group by period.date order by period.date;
    delete($self->{attrs}->{'+as'});
    delete($self->{attrs}->{'+select'});
    delete($self->{attrs}->{'prefetch'});
    delete($self->{attrs}->{'order_by'});

    my ($startdatum,$einddatum,$interval, $interval_label)     = $self->_group_geregistreerd_data(@_);

    return unless ($startdatum && $einddatum);

    ### Define defintion
    my ($geregistreerd_resultset, $afgehandeld_resultset);

    my ($regsource, $afsource, @extraargs);

    ($regsource, @extraargs) = $self->_group_geregistreerd_resultset('geregistreerd', $interval);


    ### Get clean resultset
    my $resultset_registratie = $regsource->resultset->search(
        {},
        {
            bind    => [$startdatum,$einddatum, @extraargs],
            order_by => { '-asc' => 'periode' },
        }
    );

    ($afsource, @extraargs) = $self->_group_geregistreerd_resultset('afgehandeld', $interval);
    my $resultset_afhandeling = $afsource->resultset->search(
        {},
        {
            bind    => [$startdatum,$einddatum, @extraargs]
        }
    );

    my $axis    = $self->_define_axis($resultset_registratie, $interval_label);

    return ($resultset_registratie,$resultset_afhandeling, $axis);
}

sub _define_axis {
    my $self        = shift;
    my $resultset   = shift;
    my $interval    = shift;

    my $axis        = {
        x   => [],
    };

    warn('Defining AXIS for: ' . $interval);

    my $counter = 0;
    while (my $row = $resultset->next) {
        $counter++;

        my $x;

        if ($interval eq 'month') {
            $row->periode->set_locale('nl_NL');
            if (
                $counter == 1 ||
                $counter == $resultset->count ||
                $row->periode->month == 1
            ) {
                $x = $row->periode->year . ': ' . $row->periode->month_name;
            } else {
                $x = $row->periode->month_name;
            }
        } elsif ($interval eq 'week') {
            if (
                $counter == 1 ||
                $counter == $resultset->count ||
                $row->periode->week == 1
            ) {
                $x = $row->periode->year . ': ' . $row->periode->week
            } else {
                $x = $row->periode->week;
            }
        } elsif ($interval eq 'minute') {
            $x = $row->periode->hour . ':' . $row->periode->minute;
        } elsif ($interval eq 'hour') {
            if (
                $counter == 1 ||
                $counter == $resultset->count ||
                $row->periode->hour == 0
            ) {
                $x = $row->periode->hour . "\n(" . $row->periode->day . '-' .
                $row->periode->month . ')';
            } else {
                $x = $row->periode->hour;
            }
        } elsif ($interval eq 'day') {
            $row->periode->set_locale('nl_NL');
            $x = $row->periode->day . '-' . $row->periode->month;
        }

        push(@{ $axis->{x} }, $x);
    }

    warn('AXIS: ' . Dumper($axis));
    $resultset->reset;

    return $axis;
}

sub group_binnen_buiten_termijn {
    my $self        = shift;

    delete($self->{attrs}->{'+as'});
    delete($self->{attrs}->{'+select'});
    delete($self->{attrs}->{'prefetch'});
    delete($self->{attrs}->{'order_by'});

    ## Clean up attributes
    return $self->search({}, {
        select      => [
            {
                sum => 'CASE WHEN (
                    me.afhandeldatum is not null AND
                    me.afhandeldatum < me.streefafhandeldatum
                ) THEN 1 ELSE 0 END',
                -as => 'binnen',
            },
            {
                sum => 'CASE WHEN (
                    (
                        NOW() > me.streefafhandeldatum AND me.afhandeldatum is null
                    ) OR me.afhandeldatum > me.streefafhandeldatum
                ) THEN 1 ELSE 0 END',
                '-as' => 'buiten'
            },
        ],
        'as'      => [qw/binnen buiten/],
    });

    return $self;
}

sub betrokkene_model {
    my $self    = shift;

    #warn(Dumper($self));
    return $self->{attrs}->{betrokkene_model};
}

sub gegevens_model {
    my $self    = shift;

    #warn(Dumper($self));
    return $self->{attrs}->{dbic_gegevens};
}

sub config {
    my $self    = shift;

    #warn(Dumper($self));
    return $self->{attrs}->{config};
}

sub current_user {
    my $self    = shift;

    return unless $self->{attrs}->{current_user};

    return $self->betrokkene_model->get(
        {
            extern  => 1,
            type    => 'medewerker',
        },
        $self->{attrs}->{current_user}->uidnumber
    );
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

