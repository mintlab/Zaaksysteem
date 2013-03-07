package Zaaksysteem::Schema::ZaakBag;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("zaak_bag");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('zaak_bag_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "pid",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "zaak_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "bag_type",
  {
    data_type => "zaaksysteem_bag_types",
    default_value => undef,
    is_nullable => 1,
    size => 4,
  },
  "bag_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "bag_verblijfsobject_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "bag_openbareruimte_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "bag_nummeraanduiding_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "bag_pand_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "bag_standplaats_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "bag_ligplaats_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("zaak_bag_pkey", ["id"]);
__PACKAGE__->has_many(
  "zaak_locatie_zaaks",
  "Zaaksysteem::Schema::Zaak",
  { "foreign.locatie_zaak" => "self.id" },
);
__PACKAGE__->has_many(
  "zaak_locatie_correspondenties",
  "Zaaksysteem::Schema::Zaak",
  { "foreign.locatie_correspondentie" => "self.id" },
);
__PACKAGE__->belongs_to("pid", "Zaaksysteem::Schema::ZaakBag", { id => "pid" });
__PACKAGE__->has_many(
  "zaak_bags",
  "Zaaksysteem::Schema::ZaakBag",
  { "foreign.pid" => "self.id" },
);
__PACKAGE__->belongs_to("zaak_id", "Zaaksysteem::Schema::Zaak", { id => "zaak_id" });
__PACKAGE__->has_many(
  "zaak_kenmerken_values",
  "Zaaksysteem::Schema::ZaakKenmerkenValues",
  { "foreign.zaak_bag_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gvNWzULP23BYZwzF2E2f0w

__PACKAGE__->resultset_class('Zaaksysteem::Zaken::ResultSetBag');

__PACKAGE__->load_components(
    "+Zaaksysteem::Zaken::ComponentBag",
    __PACKAGE__->load_components()
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
