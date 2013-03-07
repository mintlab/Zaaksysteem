package Zaaksysteem::Schema::ZaakGrafiekGeregistreerd;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');


__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("zaak_grafiek_geregistreerd");
__PACKAGE__->add_columns(
  "periode",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "zaken",
  {
    data_type => "integer",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);

__PACKAGE__->result_source_instance->mk_classdata('view_definition_template');

__PACKAGE__->result_source_instance->view_definition_template(
    "
    select period.date periode, count(zaak.id) as zaken from
        (
            select generate_series(?::timestamp, ?::timestamp, INTERVAL)
                as date
        ) as period left outer join zaak on zaak.registratiedatum between period.date
        AND (
            period.date + interval INTERVAL
        )
        AND zaak.id IN INNERQUERY
        group by period.date order by period.date
    "
);

__PACKAGE__->result_source_instance->view_definition(
    __PACKAGE__->result_source_instance->view_definition_template
);

__PACKAGE__->result_source_instance->is_virtual(1);


1;
