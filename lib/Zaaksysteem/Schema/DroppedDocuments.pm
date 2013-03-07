package Zaaksysteem::Schema::DroppedDocuments;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("dropped_documents");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('dropped_documents_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "filename",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "filesize",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "mimetype",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "betrokkene_id",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "load_time",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
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
__PACKAGE__->add_unique_constraint("dropped_documents_pkey", ["id"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2/XRaEZKavPpuLM8EU7sWw

__PACKAGE__->add_columns(
    "load_time",
    {
        %{ __PACKAGE__->column_info('load_time') },
        set_on_create => 1,
    }
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

__PACKAGE__->has_many(
    'logging',
    'Zaaksysteem::Schema::Logging',
    'component_id',
    {
        where   => {
            'component'     => 'dropped_document'
        }
    },
);


# You can replace this text with custom content, and it will be preserved on regeneration
1;
