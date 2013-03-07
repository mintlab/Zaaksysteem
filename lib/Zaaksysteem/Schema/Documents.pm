package Zaaksysteem::Schema::Documents;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("documents");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('documents_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "pid",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "zaak_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "betrokkene",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
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
  "documenttype",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "category",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "status",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "post_registratie",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "verplicht",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "catalogus",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "zaakstatus",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "betrokkene_id",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "ontvangstdatum",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "dagtekeningdatum",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "versie",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "help",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "pip",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "private",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "md5",
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
  "option_order",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "zaaktype_kenmerken_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "queue",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("documents_pkey", ["id"]);
__PACKAGE__->belongs_to("zaak_id", "Zaaksysteem::Schema::Zaak", { id => "zaak_id" });
__PACKAGE__->belongs_to("pid", "Zaaksysteem::Schema::Documents", { id => "pid" });
__PACKAGE__->has_many(
  "documents",
  "Zaaksysteem::Schema::Documents",
  { "foreign.pid" => "self.id" },
);
__PACKAGE__->has_many(
  "documents_mails",
  "Zaaksysteem::Schema::DocumentsMail",
  { "foreign.document_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dLTNDVhckRHSDQJ0eicpfg

__PACKAGE__->resultset_class('Zaaksysteem::Zaken::ResultSetDocumenten');

__PACKAGE__->add_columns('last_modified',
    { %{ __PACKAGE__->column_info('last_modified') },
    set_on_update => 1,
    set_on_create => 1,
});

__PACKAGE__->add_columns('created',
    { %{ __PACKAGE__->column_info('created') },
    set_on_create => 1,
});

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

__PACKAGE__->belongs_to(
    "zaak_id",
    "Zaaksysteem::Schema::Zaak", { id => "zaak_id" });

# You can replace this text with custom content, and it will be preserved on regeneration
1;
