package Zaaksysteem::SchemaGM::BagNummeraanduiding;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("bag_nummeraanduiding");
__PACKAGE__->add_columns(
  "identificatie",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 16,
  },
  "begindatum",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 14,
  },
  "einddatum",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 14,
  },
  "huisnummer",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "officieel",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 1,
  },
  "huisletter",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
  "huisnummertoevoeging",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 4,
  },
  "postcode",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "woonplaats",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 4,
  },
  "inonderzoek",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 1,
  },
  "openbareruimte",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 16,
  },
  "type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "documentdatum",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 14,
  },
  "documentnummer",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "status",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 80,
  },
  "correctie",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("identificatie", "begindatum", "correctie");
__PACKAGE__->add_unique_constraint(
  "pk_nummeraanduiding",
  ["identificatie", "begindatum", "correctie"],
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zl8w8i2dqIY8L2D6tiQGjQ

__PACKAGE__->resultset_class('Zaaksysteem::DB::ResultSet::BagGeneral');

__PACKAGE__->load_components(
    "+Zaaksysteem::DB::Component::BagNummeraanduiding",
    __PACKAGE__->load_components()
);

__PACKAGE__->belongs_to(
  "openbareruimte",
  "Zaaksysteem::SchemaGM::BagOpenbareruimte",
  { "identificatie" => "openbareruimte" },
);

__PACKAGE__->has_many(
  "standplaatsen",
  "Zaaksysteem::SchemaGM::BagStandplaats",
  { "foreign.hoofdadres" => "self.identificatie" },
);

__PACKAGE__->has_many(
  "ligplaatsen",
  "Zaaksysteem::SchemaGM::BagLigplaats",
  { "foreign.hoofdadres" => "self.identificatie" },
);

__PACKAGE__->has_many(
  "verblijfsobjecten",
  "Zaaksysteem::SchemaGM::BagVerblijfsobject",
  { "foreign.hoofdadres" => "self.identificatie" },
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
