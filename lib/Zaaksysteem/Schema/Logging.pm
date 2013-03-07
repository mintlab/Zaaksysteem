package Zaaksysteem::Schema::Logging;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("logging");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('logging_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "loglevel",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "zaak_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "betrokkene_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 128,
  },
  "aanvrager_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 128,
  },
  "is_bericht",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "component",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 64,
  },
  "component_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "seen",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "onderwerp",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "bericht",
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
  "deleted_on",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("logging_pkey", ["id"]);
__PACKAGE__->belongs_to("zaak_id", "Zaaksysteem::Schema::Zaak", { id => "zaak_id" });


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qp0B9+/7qZyjZ3Y1SwFBRQ

__PACKAGE__->load_components(
    "+Zaaksysteem::DB::Component::Logging",
    __PACKAGE__->load_components()
);

__PACKAGE__->add_columns('last_modified',
    { %{ __PACKAGE__->column_info('last_modified') },
    set_on_update => 1,
    set_on_create => 1,
});

__PACKAGE__->add_columns('created',
    { %{ __PACKAGE__->column_info('created') },
    set_on_create => 1,
});

__PACKAGE__->resultset_class('Zaaksysteem::DB::ResultSet::Logging');

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
    is_auto_increment => 1,
  }
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
