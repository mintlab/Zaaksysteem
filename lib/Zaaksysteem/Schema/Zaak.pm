package Zaaksysteem::Schema::Zaak;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("zaak");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('zaak_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "pid",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "relates_to",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "zaaktype_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "zaaktype_node_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "status",
  {
    data_type => "zaaksysteem_status",
    default_value => undef,
    is_nullable => 0,
    size => 4,
  },
  "milestone",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "contactkanaal",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 128,
  },
  "aanvraag_trigger",
  {
    data_type => "zaaksysteem_trigger",
    default_value => undef,
    is_nullable => 0,
    size => 4,
  },
  "onderwerp",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 256,
  },
  "resultaat",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "besluit",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "coordinator",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "behandelaar",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "aanvrager",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "route_ou",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "route_role",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "locatie_zaak",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "locatie_correspondentie",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "streefafhandeldatum",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "registratiedatum",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 0,
    size => 8,
  },
  "afhandeldatum",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "vernietigingsdatum",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "created",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 0,
    size => 8,
  },
  "last_modified",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 0,
    size => 8,
  },
  "deleted",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "vervolg_van",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "aanvrager_gm_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "behandelaar_gm_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "coordinator_gm_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("zaak_pkey", ["id"]);
__PACKAGE__->has_many(
  "checklist_antwoords",
  "Zaaksysteem::Schema::ChecklistAntwoord",
  { "foreign.zaak_id" => "self.id" },
);
__PACKAGE__->has_many(
  "documents",
  "Zaaksysteem::Schema::Documents",
  { "foreign.zaak_id" => "self.id" },
);
__PACKAGE__->has_many(
  "loggings",
  "Zaaksysteem::Schema::Logging",
  { "foreign.zaak_id" => "self.id" },
);
__PACKAGE__->belongs_to(
  "relates_to",
  "Zaaksysteem::Schema::Zaak",
  { id => "relates_to" },
);
__PACKAGE__->has_many(
  "zaak_relates_toes",
  "Zaaksysteem::Schema::Zaak",
  { "foreign.relates_to" => "self.id" },
);
__PACKAGE__->belongs_to("pid", "Zaaksysteem::Schema::Zaak", { id => "pid" });
__PACKAGE__->has_many(
  "zaak_pids",
  "Zaaksysteem::Schema::Zaak",
  { "foreign.pid" => "self.id" },
);
__PACKAGE__->belongs_to(
  "behandelaar",
  "Zaaksysteem::Schema::ZaakBetrokkenen",
  { id => "behandelaar" },
);
__PACKAGE__->belongs_to(
  "zaaktype_node_id",
  "Zaaksysteem::Schema::ZaaktypeNode",
  { id => "zaaktype_node_id" },
);
__PACKAGE__->belongs_to(
  "vervolg_van",
  "Zaaksysteem::Schema::Zaak",
  { id => "vervolg_van" },
);
__PACKAGE__->has_many(
  "zaak_vervolg_vans",
  "Zaaksysteem::Schema::Zaak",
  { "foreign.vervolg_van" => "self.id" },
);
__PACKAGE__->belongs_to(
  "locatie_zaak",
  "Zaaksysteem::Schema::ZaakBag",
  { id => "locatie_zaak" },
);
__PACKAGE__->belongs_to(
  "zaaktype_id",
  "Zaaksysteem::Schema::Zaaktype",
  { id => "zaaktype_id" },
);
__PACKAGE__->belongs_to(
  "coordinator",
  "Zaaksysteem::Schema::ZaakBetrokkenen",
  { id => "coordinator" },
);
__PACKAGE__->belongs_to(
  "locatie_correspondentie",
  "Zaaksysteem::Schema::ZaakBag",
  { id => "locatie_correspondentie" },
);
__PACKAGE__->belongs_to(
  "aanvrager",
  "Zaaksysteem::Schema::ZaakBetrokkenen",
  { id => "aanvrager" },
);
__PACKAGE__->has_many(
  "zaak_bags",
  "Zaaksysteem::Schema::ZaakBag",
  { "foreign.zaak_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaak_betrokkenens",
  "Zaaksysteem::Schema::ZaakBetrokkenen",
  { "foreign.zaak_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaak_kenmerks",
  "Zaaksysteem::Schema::ZaakKenmerk",
  { "foreign.zaak_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaak_kenmerkens",
  "Zaaksysteem::Schema::ZaakKenmerken",
  { "foreign.zaak_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaak_metas",
  "Zaaksysteem::Schema::ZaakMeta",
  { "foreign.zaak_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:x5t9hveNrTqZWtuVSduKFg

__PACKAGE__->resultset_class('Zaaksysteem::Zaken::ResultSetZaak');

__PACKAGE__->load_components(
    "+Zaaksysteem::Zaken::ComponentZaak",
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

__PACKAGE__->mk_group_accessors('column' => 'days_running');
__PACKAGE__->mk_group_accessors('column' => 'days_left');
__PACKAGE__->mk_group_accessors('column' => 'days_perc');

### Language
__PACKAGE__->has_many(
    "zaak_kenmerken",
    "Zaaksysteem::Schema::ZaakKenmerk",
    { "foreign.zaak_id" => "self.id" },
);

__PACKAGE__->has_many(
  "zaak_betrokkenen",
  "Zaaksysteem::Schema::ZaakBetrokkenen",
  { "foreign.zaak_id" => "self.id" },
);

__PACKAGE__->has_many(
  "zaak_relatives",
  "Zaaksysteem::Schema::Zaak",
  { "foreign.relates_to" => "self.id" },
);

__PACKAGE__->has_many(
  "zaak_parents",
  "Zaaksysteem::Schema::Zaak",
  { "foreign.pid" => "self.id" },
);

__PACKAGE__->belongs_to(
  "zaaktype_node_id",
  "Zaaksysteem::Schema::ZaaktypeNode",
  { id => "zaaktype_node_id" },
  { join_type   => 'left' },
);
__PACKAGE__->belongs_to(
  "relates_to",
  "Zaaksysteem::Schema::Zaak",
  { id => "relates_to" },
  { join_type   => 'left' },
);
__PACKAGE__->has_many(
  "zaak_relates_toes",
  "Zaaksysteem::Schema::Zaak",
  { "foreign.relates_to" => "self.id" },
  { join_type   => 'left' },
);
__PACKAGE__->belongs_to(
  "zaaktype_id",
  "Zaaksysteem::Schema::Zaaktype",
  { id => "zaaktype_id" },
  { join_type   => 'left' },
);
__PACKAGE__->belongs_to(
  "zaaktype_node_id",
  "Zaaksysteem::Schema::ZaaktypeNode",
  { id => "zaaktype_node_id" },
  { join_type   => 'left' },
);
__PACKAGE__->belongs_to(
  "coordinator",
  "Zaaksysteem::Schema::ZaakBetrokkenen",
  { id => "coordinator" },
  { join_type   => 'left' },
);
__PACKAGE__->belongs_to(
  "behandelaar",
  "Zaaksysteem::Schema::ZaakBetrokkenen",
  { id => "behandelaar" },
  { join_type   => 'left' },
);
__PACKAGE__->belongs_to(
  "aanvrager",
  "Zaaksysteem::Schema::ZaakBetrokkenen",
  { id => "aanvrager" },
  { join_type   => 'left' },
);
__PACKAGE__->belongs_to(
  "locatie_zaak",
  "Zaaksysteem::Schema::ZaakBag",
  { id => "locatie_zaak" },
  { join_type   => 'left' },
);
__PACKAGE__->belongs_to(
  "locatie_correspondentie",
  "Zaaksysteem::Schema::ZaakBag",
  { id => "locatie_correspondentie" },
  { join_type   => 'left' },
);
__PACKAGE__->has_many(
  "documents",
  "Zaaksysteem::Schema::Documents",
  { "foreign.zaak_id" => "self.id" },
);
__PACKAGE__->has_many(
  "logging",
  "Zaaksysteem::Schema::Logging",
  { "foreign.zaak_id" => "self.id" },
);
__PACKAGE__->has_many(
  "checklist",
  "Zaaksysteem::Schema::ChecklistAntwoord",
  { "foreign.zaak_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaak_relaties",
  "Zaaksysteem::Schema::Zaak",
  { "foreign.relates_to" => "self.id" },
);
__PACKAGE__->has_many(
  "zaak_vervolgers",
  "Zaaksysteem::Schema::Zaak",
  { "foreign.vervolg_van" => "self.id" },
);
__PACKAGE__->has_many(
  "zaak_children",
  "Zaaksysteem::Schema::Zaak",
  { "foreign.pid" => "self.id" },
);
__PACKAGE__->has_many(
  "zaak_meta",
  "Zaaksysteem::Schema::ZaakMeta",
  { "foreign.zaak_id" => "self.id" },
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
