package Zaaksysteem::Schema::SbusLogging;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("sbus_logging");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('sbus_logging_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "sbus_traffic_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "pid",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "mutatie_type",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "object",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "params",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "kerngegeven",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "label",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "changes",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "error",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "error_message",
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
  "modified",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("sbus_logging_pkey", ["id"]);
__PACKAGE__->belongs_to("pid", "Zaaksysteem::Schema::SbusLogging", { id => "pid" });
__PACKAGE__->has_many(
  "sbus_loggings",
  "Zaaksysteem::Schema::SbusLogging",
  { "foreign.pid" => "self.id" },
);
__PACKAGE__->belongs_to(
  "sbus_traffic_id",
  "Zaaksysteem::Schema::SbusTraffic",
  { id => "sbus_traffic_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ehiStIYvf10zwrizgevIaw

__PACKAGE__->add_columns('modified',
    { %{ __PACKAGE__->column_info('modified') },
    set_on_update => 1,
    set_on_create => 1,
});

__PACKAGE__->add_columns('created',
    { %{ __PACKAGE__->column_info('created') },
    set_on_create => 1,
});

# You can replace this text with custom content, and it will be preserved on regeneration
1;
