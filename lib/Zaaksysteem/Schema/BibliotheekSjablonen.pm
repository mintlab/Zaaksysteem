package Zaaksysteem::Schema::BibliotheekSjablonen;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("bibliotheek_sjablonen");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('bibliotheek_sjablonen_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "bibliotheek_categorie_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "naam",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 256,
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
  "filestore_id",
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
__PACKAGE__->add_unique_constraint("bibliotheek_sjablonen_pkey", ["id"]);
__PACKAGE__->belongs_to(
  "filestore_id",
  "Zaaksysteem::Schema::Filestore",
  { id => "filestore_id" },
);
__PACKAGE__->belongs_to(
  "bibliotheek_categorie_id",
  "Zaaksysteem::Schema::BibliotheekCategorie",
  { id => "bibliotheek_categorie_id" },
);
__PACKAGE__->has_many(
  "bibliotheek_sjablonen_magic_strings",
  "Zaaksysteem::Schema::BibliotheekSjablonenMagicString",
  { "foreign.bibliotheek_sjablonen_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_sjablonens",
  "Zaaksysteem::Schema::ZaaktypeSjablonen",
  { "foreign.bibliotheek_sjablonen_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2/OcguXLsN740oDvLKfaBw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
