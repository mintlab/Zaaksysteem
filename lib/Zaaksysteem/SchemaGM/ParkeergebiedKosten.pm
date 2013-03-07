package Zaaksysteem::SchemaGM::ParkeergebiedKosten;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("parkeergebied_kosten");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('parkeergebied_kosten_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "betrokkene_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 128,
  },
  "parkeergebied",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "parkeergebied_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "aanvraag_soort",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "geldigheid",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "prijs",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
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
__PACKAGE__->add_unique_constraint("parkeergebied_kosten_pkey", ["id"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:z8+hiv8HHJruQYnBc9tnmQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
