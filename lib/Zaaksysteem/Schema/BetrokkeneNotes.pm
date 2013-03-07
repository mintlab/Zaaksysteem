package Zaaksysteem::Schema::BetrokkeneNotes;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("betrokkene_notes");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('betrokkene_notes_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "betrokkene_exid",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "betrokkene_type",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "betrokkene_from",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "ntype",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "subject",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "message",
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
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("betrokkene_notes_pkey", ["id"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5u4c9EjxPTkIXg5w1LrzOA

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
