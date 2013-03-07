package Zaaksysteem::Schema::BeheerImport;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("beheer_import");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('beheer_import_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "importtype",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 256,
  },
  "succesvol",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "finished",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "import_create",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "import_update",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "error",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "error_message",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "entries",
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
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("beheer_import_pkey", ["id"]);
__PACKAGE__->has_many(
  "beheer_import_logs",
  "Zaaksysteem::Schema::BeheerImportLog",
  { "foreign.import_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BgAQPG1dbQ8H6pDP9PsEHQ

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
