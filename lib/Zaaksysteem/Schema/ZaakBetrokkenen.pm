package Zaaksysteem::Schema::ZaakBetrokkenen;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("zaak_betrokkenen");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('zaak_betrokkenen_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "zaak_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "betrokkene_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 128,
  },
  "betrokkene_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "gegevens_magazijn_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "verificatie",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 128,
  },
  "naam",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "rol",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "magic_string_prefix",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "deleted",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("zaak_betrokkenen_pkey", ["id"]);
__PACKAGE__->has_many(
  "zaak_behandelaars",
  "Zaaksysteem::Schema::Zaak",
  { "foreign.behandelaar" => "self.id" },
);
__PACKAGE__->has_many(
  "zaak_coordinators",
  "Zaaksysteem::Schema::Zaak",
  { "foreign.coordinator" => "self.id" },
);
__PACKAGE__->has_many(
  "zaak_aanvragers",
  "Zaaksysteem::Schema::Zaak",
  { "foreign.aanvrager" => "self.id" },
);
__PACKAGE__->belongs_to("zaak_id", "Zaaksysteem::Schema::Zaak", { id => "zaak_id" });


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XrJ0nFL3Tgs8FUYTjak2yA

__PACKAGE__->load_components(
    "+Zaaksysteem::Zaken::ComponentZaakBetrokkenen",
    __PACKAGE__->load_components()
);

__PACKAGE__->resultset_class('Zaaksysteem::Zaken::ResultSetBetrokkenen');

__PACKAGE__->belongs_to(
    "natuurlijk_persoon", "Zaaksysteem::Schema::GmNatuurlijkPersoon", { id => "betrokkene_id" }
);

__PACKAGE__->belongs_to(
    "bedrijf", "Zaaksysteem::Schema::GmBedrijf", { id => "betrokkene_id" }
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
