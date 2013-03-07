package Zaaksysteem::Schema::ZaaktypeAuthorisation;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("zaaktype_authorisation");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('zaaktype_authorisation_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "zaaktype_node_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "recht",
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
  "deleted",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "role_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "ou_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "zaaktype_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("zaaktype_authorisation_pkey", ["id"]);
__PACKAGE__->belongs_to(
  "zaaktype_id",
  "Zaaksysteem::Schema::Zaaktype",
  { id => "zaaktype_id" },
);
__PACKAGE__->belongs_to(
  "zaaktype_node_id",
  "Zaaksysteem::Schema::ZaaktypeNode",
  { id => "zaaktype_node_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oeDUzlLNqX7HUtVweiG4iA

__PACKAGE__->resultset_class('Zaaksysteem::DB::ResultSet::ZaaktypeAuthorisation');

# You can replace this text with custom content, and it will be preserved on regeneration
1;
