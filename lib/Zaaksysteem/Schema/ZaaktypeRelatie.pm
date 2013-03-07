package Zaaksysteem::Schema::ZaaktypeRelatie;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("zaaktype_relatie");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('zaaktype_relatie_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "zaaktype_node_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "relatie_zaaktype_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "zaaktype_status_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "relatie_type",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "eigenaar_type",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "start_delay",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "created",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "last_modified",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "status",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "kopieren_kenmerken",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "delay_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "ou_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "role_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "automatisch_behandelen",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("zaaktype_relatie_pkey", ["id"]);
__PACKAGE__->belongs_to(
  "zaaktype_node_id",
  "Zaaksysteem::Schema::ZaaktypeNode",
  { id => "zaaktype_node_id" },
);
__PACKAGE__->belongs_to(
  "relatie_zaaktype_id",
  "Zaaksysteem::Schema::Zaaktype",
  { id => "relatie_zaaktype_id" },
);
__PACKAGE__->belongs_to(
  "zaaktype_status_id",
  "Zaaksysteem::Schema::ZaaktypeStatus",
  { id => "zaaktype_status_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6ypVqMWeCl6J07NSZEspSg
__PACKAGE__->resultset_class('Zaaksysteem::DB::ResultSet::ZaaktypeRelatie');

__PACKAGE__->load_components(
    "+Zaaksysteem::DB::Component::ZaaktypeRelatie",
    __PACKAGE__->load_components()
);

__PACKAGE__->add_columns('last_modified',
    { %{ __PACKAGE__->column_info('last_modified') },
    set_on_update => 1,
    set_on_create => 1,
});

__PACKAGE__->add_columns('created',
    { %{ __PACKAGE__->column_info('created') },
    set_on_create => 1,
});

# You can replace this text with custom content, and it will be preserved on regeneration
1;
