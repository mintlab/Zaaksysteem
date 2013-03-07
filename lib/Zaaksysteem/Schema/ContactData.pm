package Zaaksysteem::Schema::ContactData;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("contact_data");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('contact_data_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "gegevens_magazijn_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "betrokkene_type",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "mobiel",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "telefoonnummer",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "email",
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
__PACKAGE__->add_unique_constraint("contact_data_pkey", ["id"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YYmLNlFm3GF0AGSXo4xf2g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
