package Zaaksysteem::Schema::ZaaktypeResultaten;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("zaaktype_resultaten");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('zaaktype_resultaten_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "zaaktype_node_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "zaaktype_status_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "resultaat",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "ingang",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "bewaartermijn",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
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
  "dossiertype",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("zaaktype_resultaten_pkey", ["id"]);
__PACKAGE__->belongs_to(
  "zaaktype_status_id",
  "Zaaksysteem::Schema::ZaaktypeStatus",
  { id => "zaaktype_status_id" },
);
__PACKAGE__->belongs_to(
  "zaaktype_node_id",
  "Zaaksysteem::Schema::ZaaktypeNode",
  { id => "zaaktype_node_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c/mFZSJ9XSmgjGPdUDA2+A

__PACKAGE__->resultset_class('Zaaksysteem::DB::ResultSet::ZaaktypeResultaten');

__PACKAGE__->add_columns('last_modified',
    { %{ __PACKAGE__->column_info('last_modified') },
    set_on_update => 1,
    set_on_create => 1,
});

__PACKAGE__->add_columns('created',
    { %{ __PACKAGE__->column_info('created') },
    set_on_create => 1,
});

# You can replace this text with custom content, and it will be preserved on regeneration
1;
