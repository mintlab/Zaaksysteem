package Zaaksysteem::Controller::Beheer::ZaaktypeCatalogus;
use Moose;
use namespace::autoclean;

use Hash::Merge::Simple qw( clone_merge );

use Data::Dumper;

BEGIN {extends 'Catalyst::Controller'; }



sub _get_crumb_path {
    my ($self, $c, $category_id, $crumbs) = @_;

    return '' if not defined $category_id;

    my $category = $c->model('DB::BibliotheekCategorie')->find($category_id);
    my $pid = $category->get_column('pid');

    push (@{$$crumbs}, {$category->id => $category->naam});

    $self->_get_crumb_path($c, $pid, $crumbs);
}





sub _list_child_categories {
    my ($self, $c, $categorie_id) = @_;

    my $child_categories = $c->model('DB::BibliotheekCategorie')->search({'pid' => $categorie_id});

    my $element_count = $c->model($c->stash->{'list_table'})->search({'bibliotheek_categorie_id' => $categorie_id})->count();

    $c->stash->{'child_category_ids'} ||= [];
    if($categorie_id) {
        push @{$c->stash->{'child_category_ids'}}, ''. $categorie_id;
    }
    my %id_lookup = map { $_ => 1 } @{$c->stash->{'child_category_ids'}};

    while(my $row = $child_categories->next()) { 
        # protect against cyclical child/parent relationships
        next if exists $id_lookup{$row->id};

        push @{$c->stash->{'child_category_ids'}}, '' . $row->id;  # stringify using ''
        $element_count += $self->_list_child_categories($c, $row->id);
    }

    $c->stash->{'element_count'} ||= {};
    $c->stash->{'element_count'}->{$categorie_id||'root'} = $element_count;
    
    return $element_count;
}





sub _show_db_result {
    my ($self, $c, $resultset) = @_;

    my @rijen = ();
    while (my $row = $resultset->next) {
       $c->log->debug('ROW TYPE: '.ref($row));
       
        #my @cols = $resultset->result_source->columns;
        my %r = $row->get_columns;

        my $rij = {};
        while (my ($col, $value) = each (%r)) {
            $rij->{$col} = $value;
        }

        push(@rijen, $rij);
    }

    $c->log->debug('DB-Result: '.Dumper (@rijen));
}





sub _get_menu_tree {
    my ($self, $c, $categorie_id, $page, $textfilter) = @_;

    my $total_cats = ();

    # (select id, naam as titel, id as cat_id, 'category' as type, null as versie, pid, null as description from bibliotheek_categorie)

    # Maak een where clause NB: Bij het zoeken zonder cat_id dan zoeken in ALLE resultaten
    my $where = {};
    $where->{'pid'} = $categorie_id;

    if ((not defined $categorie_id) && $textfilter ne '') {
        $where = {};
    }

    if ($textfilter ne '') {
        $where->{'naam'} = {'ilike' => '%'.$textfilter.'%'};
    }


    my $rs_category = $c->model('DB::BibliotheekCategorie')->search(
            $where,
            {
                select => [ 'id',
                            {'' => 'naam'      , -as => 'titel'},
                            {'' => 'id'        , -as => 'cat_id'},
                            {'' => "'zaaktypefolder'", -as => 'type'},
                            {'' => "''"        , -as => 'versie'},
                            'pid',
                            {'' => "ARRAY[]::text[]"       , -as => 'description'}
                          ],
                as => [qw/id titel cat_id type versie pid description/]
            }
        )->as_subselect_rs;

    my $rs_category2 = $rs_category->search(undef,
        {
                select => [qw/id titel::text cat_id type::text versie::text pid description/],
                as => [qw/id titel cat_id type versie pid description/]
        }
        );


    #    (SELECT 
    #    DISTINCT ON( titel) (titel ) AS titel, 
    #    ( zaaktypes.id ) AS id, 
    #    ( titel ) AS titel, 
    #    ( bibliotheek_categorie_id ) AS cat_id, 
    #    ( 'zaaktype' ) AS type, 
    #    ( ztn.version ) AS versie, 
    #    ( (SELECT me.pid FROM bibliotheek_categorie me WHERE ( id = zaaktypes.bibliotheek_categorie_id )) ) AS pid, ARRAY( (SELECT ( array_to_string(ARRAY((SELECT bk.naam FROM bibliotheek_kenmerken bk LEFT JOIN zaaktype_kenmerken zaaktype_kenmerkens ON zaaktype_kenmerkens.bibliotheek_kenmerken_id = bk.id WHERE ( zaaktype_kenmerkens.zaaktype_node_id = zt.zaaktype_node_id ))), ', ') || '<strong><br/><br/>Sjablonen:<br/></strong>' || array_to_string(ARRAY((SELECT bs.naam FROM bibliotheek_sjablonen bs LEFT JOIN zaaktype_sjablonen zaaktype_sjablonens ON zaaktype_sjablonens.bibliotheek_sjablonen_id = bs.id WHERE ( zaaktype_sjablonens.zaaktype_node_id = zt.zaaktype_node_id ))), ', ') ) FROM zaaktype zt WHERE ( zt.zaaktype_node_id = ztn.id )) ) AS description 
    #    ,ztn.version
    #    ,ztn.id
    #   FROM zaaktype_node ztn 
    #   LEFT JOIN zaaktype zaaktypes 
    #   ON zaaktypes.zaaktype_node_id = ztn.id 
    #   WHERE ( 
    #   ( 
    #   ( ztn.zaaktype_trefwoorden ILIKE '%verni%' OR ztn.zaaktype_omschrijving ILIKE '%verni%' OR titel ILIKE '%verni%' ) 
    #   AND zaaktypes.bibliotheek_categorie_id IS NOT NULL 
    #   AND zaaktypes.deleted IS NULL 
    #   )
    #   ) ORDER BY titel, ztn.id DESC)

    # Maak een where clause NB: Bij het zoeken zonder cat_id dan zoeken in ALLE resultaten
    $where = {};
    $where->{'bibliotheek_categorie_id'} = $categorie_id;

    if ((not defined $categorie_id) && $textfilter ne '') {
        $where = {};
    }

    if ((defined $categorie_id) && $textfilter ne '') {
        $c->stash->{'list_table'} = 'DB::Zaaktype';
        $total_cats = $self->_list_child_categories($c, $categorie_id);
        $where->{'bibliotheek_categorie_id'} = {'-in' => $c->stash->{'child_category_ids'}};
    }

    if ($textfilter ne '') {
        $where->{'-or'} = [
                {'ztn.zaaktype_trefwoorden'  => {'ilike' => '%'.$textfilter.'%'}},
                {'ztn.zaaktype_omschrijving' => {'ilike' => '%'.$textfilter.'%'}},
                {'titel'                     => {'ilike' => '%'.$textfilter.'%'}}
            ];
    }

    $where->{'zaaktypes.deleted'}                  = undef;
    $where->{'zaaktypes.bibliotheek_categorie_id'} = {'IS NOT' => undef};


    #select 
    #    ARRAY(select naam from bibliotheek_kenmerken bk inner join zaaktype_kenmerken ztk on bk.id = ztk.bibliotheek_kenmerken_id 
    #        where ztk.zaaktype_node_id = zt.zaaktype_node_id) as kenmerk, 
    #
    #    ARRAY(select naam from bibliotheek_sjablonen bs inner join zaaktype_sjablonen zts on bs.id = zts.bibliotheek_sjablonen_id 
    #        where zts.zaaktype_node_id = zt.zaaktype_node_id) as sjabloon
    #from
    #    zaaktype zt
    #where
    #    zt.zaaktype_node_id = 804


    my $rs_kenm = $c->model('DB::BibliotheekKenmerken')->search(
            {
                'zaaktype_kenmerkens.zaaktype_node_id' => { '=' => { -ident => 'zt.zaaktype_node_id' }},
                'bk.deleted'   => undef,
            },
            {
                select => ['naam'],
                alias  => 'bk',
                join   => 'zaaktype_kenmerkens'
            }
    );


    my $rs_sjabl = $c->model('DB::BibliotheekSjablonen')->search (
            {
                'zaaktype_sjablonens.zaaktype_node_id' => { '=' => { -ident => 'zt.zaaktype_node_id' }},
                'bs.deleted'   => undef,

            },
            {
                select => ['naam'],
                alias  => 'bs',
                join   => 'zaaktype_sjablonens'
            }
    );


    my $test  = $rs_kenm->as_query;
    my $test2 = $rs_sjabl->as_query;


    my $str_kenm = 'array_to_string(ARRAY('.$$test->[0].'), \', \')';
    my $str_sjabl = $str_kenm.' || \'<strong><br/><br/>Sjablonen:<br/></strong>\' || array_to_string(ARRAY('.$$test2->[0].'), \', \')';

    my $rs_desc = $c->model('DB::zaaktype')->search(
            {
                'zt.zaaktype_node_id' => { '=' => { -ident => 'ztn.id'}}
            },
            {
                select => [ {'' => \$str_sjabl} ],
                alias => 'zt'
            }
        );




    my $rs_pid = $c->model('DB::BibliotheekCategorie');
    my $rs_zaaktype = $c->model('DB::ZaaktypeNode')->search(
            $where,
            {
                select => [ {'distinct on' => 'titel) (titel', -as => 'titel'},
                            {'' => 'zaaktypes.id'      , -as => 'id'},
                            {'' => 'bibliotheek_categorie_id', -as => 'cat_id'},
                            {'' => "'zaaktype'", -as => 'type'},
                            {'' => 'ztn.version'       , -as => 'versie'},
                            {'' => $rs_pid->search({'id' => { '=' => { -ident => 'zaaktypes.bibliotheek_categorie_id' } }}, {select => ['pid']})->as_query, -as => 'pid'},
                            {'ARRAY' => $rs_desc->as_query, -as => 'description'}
                          ],
                as => [qw/zaaktype_id id titel cat_id type versie pid description/],
                alias => 'ztn',
                join => 'zaaktypes',
                order_by => ['titel', { -desc => [qw/ztn.id/] }]
            }
        )->as_subselect_rs;

    my $rs_zaaktype2 = $rs_zaaktype->search(undef,
        {
                select => [qw/id titel::text cat_id type::text versie::text pid description/],
                as => [qw/id titel cat_id type versie pid description/]
        }
        );




    #(select bk.id as id, bk.naam as titel, bibliotheek_categorie_id as cat_id, 'kenmerk' as type, 1 as versie, 
    #(select pid from bibliotheek_categorie where id = bk.bibliotheek_categorie_id) as pid
    #, array_to_string(ARRAY(
    #    select distinct zn.titel from zaaktype_kenmerken ztk 
    #    inner join zaaktype_node zn on ztk.zaaktype_node_id = zn.id 
    #    where ztk.bibliotheek_kenmerken_id = bk.id), ', ') as description 
    #from bibliotheek_kenmerken bk)

    # Maak een where clause NB: Bij het zoeken zonder cat_id dan zoeken in ALLE resultaten
    $where = {};
    $where->{'bibliotheek_categorie_id'} = $categorie_id;

    if ((not defined $categorie_id) && $textfilter ne '') {
        $where = {};
    }

    if ((defined $categorie_id) && $textfilter ne '') {
        $c->stash->{'list_table'} = 'DB::BibliotheekKenmerken';
        $total_cats = $self->_list_child_categories($c, $categorie_id);
        $where->{'bibliotheek_categorie_id'} = {'-in' => $c->stash->{'child_category_ids'}};
    }

    if ($textfilter ne '') {
        $where->{'naam'} = {'ilike' => '%'.$textfilter.'%'};
    }


# Zoek alle zaaktypen die dit kenmerk gebruiken (!!!NB: Kijken in de laatste versie van het zaaktype!!!)
#    select distinct ztn.titel
#    from zaaktype_node ztn
#    join zaaktype_kenmerken ztk
#    on ztn.id = ztk.zaaktype_node_id
#    where ztk.bibliotheek_kenmerken_id = 42
#    and ztn.id in (select id from (select DISTINCT ON (ztn.titel) ztn.titel as titel, ztn.id from zaaktype_node ztn order by ztn.titel, ztn.id desc) bla)
#    order by titel


    my $rs_zt_sub_sub = $c->model('DB::ZaaktypeNode')->search(
            undef,
            {
                select => [ {'distinct on' => 'titel) (titel', -as => 'titel'},
                            {'' => 'me.id', -as => 'id'}
                          ],
                order_by => ['titel', {-desc => 'id'}]
            }
        )->as_subselect_rs;

    my $rs_zt_sub = $rs_zt_sub_sub->search(undef, {select => ['id']});


    $rs_desc = $c->model('DB::ZaaktypeNode')->search(
            {
                'zaaktype_kenmerken.bibliotheek_kenmerken_id' => { '=' => { -ident => 'bk.id' } },
                'me.id' => {IN => $rs_zt_sub->as_query}
            },
            {
                select => [ {'distinct' => 'titel'} ],
                join => 'zaaktype_kenmerken',
                order_by => ['titel'],
            }
        );


    my $rs_kenmerken = $c->model('DB::BibliotheekKenmerken')->search(
            {
                %{ $where },
                'bk.deleted'    => undef,
            },
            {
                select => [ 'id',
                            {'' => 'naam'      , -as => 'titel'},
                            {'' => 'bibliotheek_categorie_id'        , -as => 'cat_id'},
                            {'' => "'kenmerk'", -as => 'type'},
                            {'' => '1'       , -as => 'versie'},
                            {'' => $rs_pid->search({'id' => { '=' => { -ident => 'bk.bibliotheek_categorie_id' } }}, {select => ['pid']})->as_query, -as => 'pid'},
                            {'ARRAY' => $rs_desc->as_query, -as => 'description'}
                          ],
                as => [qw/id titel cat_id type versie pid description/],
                alias => 'bk',
            }
        )->as_subselect_rs;
    
    my $rs_kenmerken2 = $rs_kenmerken->search(undef,
        {
                select => [qw/id titel::text cat_id type::text versie::text pid description/],
                as => [qw/id titel cat_id type versie pid description/]
        }
        );

    
    #(select bs.id as id, bs.naam as titel, bibliotheek_categorie_id as cat_id, 'sjabloon' as type, 1 as versie, (select pid from bibliotheek_categorie where id = bs.bibliotheek_categorie_id) as pid 
    #, array_to_string(ARRAY(
    #    select distinct zn.titel from zaaktype_sjablonen zts 
    #    inner join zaaktype_node zn on zts.zaaktype_node_id = zn.id 
    #    where zts.bibliotheek_sjablonen_id = bs.id), ', ') as description 
    #from bibliotheek_sjablonen bs)

    # Maak een where clause NB: Bij het zoeken zonder cat_id dan zoeken in ALLE resultaten
    $where = {};
    $where->{'bibliotheek_categorie_id'} = $categorie_id;

    if ((not defined $categorie_id) && $textfilter ne '') {
        $where = {};
    }

    if ((defined $categorie_id) && $textfilter ne '') {
        $c->stash->{'list_table'} = 'DB::BibliotheekSjablonen';
        $total_cats = $self->_list_child_categories($c, $categorie_id);
        $where->{'bibliotheek_categorie_id'} = {'-in' => $c->stash->{'child_category_ids'}};
    }

    if ($textfilter ne '') {
        $where->{'naam'} = {'ilike' => '%'.$textfilter.'%'};
    }


    $rs_zt_sub_sub = $c->model('DB::ZaaktypeNode')->search(
            undef,
            {
                select => [ {'distinct on' => 'titel) (titel', -as => 'titel'},
                            {'' => 'me.id', -as => 'id'}
                          ],
                order_by => ['titel', {-desc => 'id'}]
            }
        )->as_subselect_rs;

    $rs_zt_sub = $rs_zt_sub_sub->search(undef, {select => ['id']});


    $rs_desc = $c->model('DB::ZaaktypeNode')->search(
            {
                'zaaktype_sjablonen.bibliotheek_sjablonen_id' => { '=' => { -ident => 'bs.id' } },
                'me.id' => {IN => $rs_zt_sub->as_query}
            },
            {
                select => [ {'distinct' => 'titel'} ],
                join => 'zaaktype_sjablonen',
                order_by => ['titel'],
            }
        );

    my $rs_sjablonen = $c->model('DB::BibliotheekSjablonen')->search(
            {
                %{ $where },
                'bs.deleted'    => undef,
            },
            {
                select => [ 'id',
                            {'' => 'naam'      , -as => 'titel'},
                            {'' => 'bibliotheek_categorie_id'        , -as => 'cat_id'},
                            {'' => "'sjabloon'", -as => 'type'},
                            {'' => '1'       , -as => 'versie'},
                            {'' => $rs_pid->search({'id' => { '=' => { -ident => 'bs.bibliotheek_categorie_id' } }}, {select => ['pid']})->as_query, -as => 'pid'},
                            {'ARRAY' => $rs_desc->as_query, -as => 'description'}
                          ],
                as => [qw/id titel cat_id type versie pid description/],
                alias => 'bs'
            }
        )->as_subselect_rs;
    
    my $rs_sjablonen2 = $rs_sjablonen->search(undef,
        {
                select => [qw/id titel::text cat_id type::text versie::text pid description/],
                as => [qw/id titel cat_id type versie pid description/]
        }
        );

        $_->result_class('DBIx::Class::ResultClass::HashRefInflator')
#        $_->result_class('Zaaksysteem::Schema::ZaaktypeNode')
           for ($rs_category2, $rs_zaaktype2, $rs_kenmerken2, $rs_sjablonen2);


    my $resultset = $rs_zaaktype2->union_all([$rs_category2, $rs_kenmerken2, $rs_sjablonen2])->search(
        {
            cat_id   => {'IS NOT' => undef},
        }, 
        {
            page     => $page,
            rows     => 10,
            order_by => [{-desc => 'type'}, 'titel'],
        }
    ) ;


#        $resulset->search ({pid => $categorie_id});
    
#    select a.id, a.cat_id, a.type, a.titel, versie, pid, description from
#    (
#    (select id, naam as titel, id as cat_id, 'category' as type, null as versie, pid, null as description from bibliotheek_categorie)
#    union all
#    (select DISTINCT ON (ztn.zaaktype_id) ztn.zaaktype_id as id, ztn.titel as titel, zt.bibliotheek_categorie_id as cat_id, 'zaaktype' as type, ztn.version as versie, (select pid from bibliotheek_categorie where id = zt.bibliotheek_categorie_id) as pid 
#    , null as description
#    from zaaktype_node ztn
#    left join zaaktype zt on zt.zaaktype_node_id = ztn.id
#    where ztn.version is not null
#    order by ztn.zaaktype_id, ztn.version DESC)
#    union all
#    (select bk.id as id, bk.naam as titel, bibliotheek_categorie_id as cat_id, 'kenmerk' as type, 1 as versie, (select pid from bibliotheek_categorie where id = bk.bibliotheek_categorie_id) as pid
#    , array_to_string(ARRAY(select distinct zn.titel from zaaktype_kenmerken ztk inner join zaaktype_node zn on ztk.zaaktype_node_id = zn.id where ztk.bibliotheek_kenmerken_id = bk.id), ', ') as description 
#    from bibliotheek_kenmerken bk)
#    union all
#    (select bs.id as id, bs.naam as titel, bibliotheek_categorie_id as cat_id, 'sjabloon' as type, 1 as versie, (select pid from bibliotheek_categorie where id = bs.bibliotheek_categorie_id) as pid 
#    , array_to_string(ARRAY(select distinct zn.titel from zaaktype_sjablonen zts inner join zaaktype_node zn on zts.zaaktype_node_id = zn.id where zts.bibliotheek_sjablonen_id = bs.id), ', ') as description 
#    from bibliotheek_sjablonen bs)
#    ) a
#    where cat_id is not null
#    and cat_id = 12
#    order by cat_id, type

    return $resultset;
}





sub list : Chained('/') : Regex('beheer/zaaktype_catalogus/?(\d*)') {
    my ( $self, $c,  ) = @_;
    my ($categorie_id) = @{ $c->req->captures };

    $c->session->{'categorie_id'}     = $categorie_id;

    undef $categorie_id if $categorie_id eq '';

    # Cree‘r een hash met alle soorten types die in een overzicht moeten komen
    my $types = {
        'zaaktypen' => {
            'NAME'            => 'zaaktypen',
            'DB'              => 'DB::Zaaktype',
            'CATEGORIES_DB'   => 'DB::BibliotheekCategorie',
        },
        'kenmerken' => {
            'NAME'                 => 'kenmerken',
            'MODEL'                => 'Bibliotheek::Kenmerken',
            'DB'                   => 'DB::BibliotheekKenmerken',
            'MAGIC_STRING_DEFAULT' => 'doc_variable',
            'CATEGORIES_DB'        => 'DB::BibliotheekCategorie',
        },
        'sjablonen' => {
            'NAME'          => 'sjablonen',
            'MODEL'         => 'Bibliotheek::Sjablonen',
            'DB'            => 'DB::BibliotheekSjablonen',
            'CATEGORIES_DB' => 'DB::BibliotheekCategorie',
        },
    };


    $c->stash->{'list_types'} = $types;

    my $params     = $c->req->params();
    my $page       = $params->{'page'} || 1;
    my $textfilter = $params->{'textfilter'} || '';

    # In geval er een verschil in textfilter is de page op 1 zetten;
    # zodat we de results zien (indien de page niet op 1 stond)!
    my $session_textfilter = $c->session->{'textfilter'} || '';
    if ($session_textfilter ne $textfilter) {
        $page = 1;

        # Voor de template pager2.tt
        $c->req->params->{'page'} = $page;
    }

    $c->session->{'textfilter'} = $textfilter;


    my $resultset = $self->_get_menu_tree($c, $categorie_id, $page, $textfilter);


    my @all_table_lists;
    my @total_elements;
    # Van alle soorten (Zaaktype/kenmerken/sjablonen) de hoeveelheden ophalen
    while (my ($list_id, $list_data) = each (%{ $types })) {
        $c->stash->{'list_table'} = $list_data->{'DB'};
        $c->log->debug($list_id.' - '.$c->stash->{'list_table'});

        #$c->stash->{'total_elements'} = $self->_list_child_categories($c, $categorie_id);
        push (@total_elements, $self->_list_child_categories($c, $categorie_id));
        push (@all_table_lists, $c->stash->{'element_count'});

        $c->stash->{'element_count'}      = undef;
        $c->stash->{'child_category_ids'} = undef;
        $c->stash->{'list_table'}         = undef;
    }

    # Alle totalen bij elkaar optellen
    # Zet een lijst in een array en tel de andere lijsten er bij op
    my $total_list = pop (@all_table_lists);

    for my $list_total (@all_table_lists) {
        while (my ($id, $total) = each(%{ $list_total })) {
            $total_list->{$id} += $total;
        }
    }
    $c->stash->{'element_count'} = $total_list;


    # Toevoegen van een algemene trail voor de zaaktype catalogus
    $c->add_trail(
        {
            uri     => $c->uri_for('/beheer/zaaktype_catalogus'),
            label   => 'ZTC'
        }
    );


    # In geval we in een sub-categorie zitten even een trail toevoegen
    if ((defined $categorie_id) && $categorie_id =~ m/^\d+$/) {
        $c->stash->{'categorie'} = $c->model('DB::BibliotheekCategorie')->find($categorie_id);

        my $crumbs = ();
        $self->_get_crumb_path($c, $categorie_id, \$crumbs);

        while (my $crumb = pop(@{$crumbs})) {
            my ($cat_id, $cat_naam) = each(%{$crumb});

            $c->add_trail(
                {
                    uri     => $c->uri_for('/beheer/zaaktype_catalogus/' . $cat_id),
                    label   => $cat_naam,
                }
            );
        }
    }

    $c->stash->{'items'}     = $resultset;

    $c->stash->{'template'} = 'widgets/beheer/bibliotheek/list.tt';
}



__PACKAGE__->meta->make_immutable;



__END__
#    my @rijen = ();
#    while (my $row = $resultset->next) {
#        $c->log->debug('ROW TYPE: '.ref($row));
#        
#        #my @cols = $resultset->result_source->columns;
#        my %r = $row->get_columns;
#        
##        my @cols = keys %r;
##
##            my $rij = {};
##            foreach my $col (@cols) {
##                $rij->{$col} = $row->get_column($col);
##            }
#
#        push(@rijen, %r);
#    }

#$c->log->debug('wwaaaaaahhhhhhh!!!!!!!: '.Dumper (@rijen));

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

