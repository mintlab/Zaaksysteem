package Zaaksysteem::Schema::SearchQueryDelen;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("search_query_delen");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('search_query_delen_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "search_query_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "ou_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "role_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("search_query_delen_pkey", ["id"]);
__PACKAGE__->belongs_to(
  "search_query_id",
  "Zaaksysteem::Schema::SearchQuery",
  { id => "search_query_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DZA4+a6ujG5JSWYe2uUqjg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
