package Zaaksysteem::Schema::Betrokkenen;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("betrokkenen");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('betrokkenen_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "btype",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "gm_natuurlijk_persoon_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "naam",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("betrokkenen_pkey", ["id"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NUu/9ZAyPLGTPgvIipMwlw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
