package Zaaksysteem::Schema::UserAppLock;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("user_app_lock");
__PACKAGE__->add_columns(
  "type",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 0,
    size => 40,
  },
  "type_id",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "create_unixtime",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "session_id",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 0,
    size => 40,
  },
  "uidnumber",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
);
__PACKAGE__->set_primary_key("uidnumber", "type", "type_id");
__PACKAGE__->add_unique_constraint("user_app_lock_pkey", ["uidnumber", "type", "type_id"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ed+0/OpN7pvL7AP1eX6wsg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
