package Zaaksysteem::Schema::BibliotheekKenmerken;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("bibliotheek_kenmerken");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('bibliotheek_kenmerken_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "naam",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 256,
  },
  "value_type",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "value_default",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "label",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "help",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "magic_string",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
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
  "bibliotheek_categorie_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "document_categorie",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "system",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "type_multiple",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "deleted",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("bibliotheek_kenmerken_pkey", ["id"]);
__PACKAGE__->belongs_to(
  "bibliotheek_categorie_id",
  "Zaaksysteem::Schema::BibliotheekCategorie",
  { id => "bibliotheek_categorie_id" },
);
__PACKAGE__->has_many(
  "bibliotheek_kenmerken_values",
  "Zaaksysteem::Schema::BibliotheekKenmerkenValues",
  { "foreign.bibliotheek_kenmerken_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaak_kenmerks",
  "Zaaksysteem::Schema::ZaakKenmerk",
  { "foreign.bibliotheek_kenmerken_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaak_kenmerkens",
  "Zaaksysteem::Schema::ZaakKenmerken",
  { "foreign.bibliotheek_kenmerken_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaak_kenmerken_values",
  "Zaaksysteem::Schema::ZaakKenmerkenValues",
  { "foreign.bibliotheek_kenmerken_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_kenmerkens",
  "Zaaksysteem::Schema::ZaaktypeKenmerken",
  { "foreign.bibliotheek_kenmerken_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:E6fo62s1cV5dqrYXWSU2sA

__PACKAGE__->load_components(
    "+Zaaksysteem::DB::Component::BibliotheekKenmerken",
    __PACKAGE__->load_components()
);


# You can replace this text with custom content, and it will be preserved on regeneration
1;
