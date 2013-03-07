package Zaaksysteem::Schema::BibliotheekSjablonenMagicString;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("bibliotheek_sjablonen_magic_string");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('bibliotheek_sjablonen_magic_string_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "bibliotheek_sjablonen_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "value",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("bibliotheek_sjablonen_magic_string_pkey", ["id"]);
__PACKAGE__->belongs_to(
  "bibliotheek_sjablonen_id",
  "Zaaksysteem::Schema::BibliotheekSjablonen",
  { id => "bibliotheek_sjablonen_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JeIDZY8s+8p/bE2aCqjOcg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
