package Zaaksysteem::Schema::GmAdres;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("gm_adres");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('gm_adres_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "straatnaam",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "huisnummer",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "huisletter",
  {
    data_type => "character",
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
  "nadere_aanduiding",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 35,
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
    size => 75,
  },
  "gemeentedeel",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 75,
  },
  "functie_adres",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
  "datum_aanvang_bewoning",
  { data_type => "date", default_value => undef, is_nullable => 1, size => 4 },
  "woonplaats_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "gemeente_code",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "hash",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "import_datum",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("gm_adres_pkey", ["id"]);
__PACKAGE__->has_many(
  "gm_natuurlijk_persoons",
  "Zaaksysteem::Schema::GmNatuurlijkPersoon",
  { "foreign.adres_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:D6eHazoD1zjT6FTLeZqqIg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
