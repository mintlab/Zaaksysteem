package Zaaksysteem::SchemaGM::Parkeergebied;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("parkeergebied");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('parkeergebied_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "bag_hoofdadres",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "postcode",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 6,
  },
  "straatnaam",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "huisnummer",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
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
  "parkeergebied_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "parkeergebied",
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
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("parkeergebied_pkey", ["id"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9vshrMnb0zdRWtBkvSkxrA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
