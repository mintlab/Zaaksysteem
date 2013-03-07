package Zaaksysteem::Schema::SearchQuery;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("search_query");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('search_query_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "settings",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "ldap_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 256,
  },
  "sort_index",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("search_query_pkey", ["id"]);
__PACKAGE__->has_many(
  "search_query_delens",
  "Zaaksysteem::Schema::SearchQueryDelen",
  { "foreign.search_query_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:k+q56A+V5RQydepHoXwJWg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
