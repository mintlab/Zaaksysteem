package Zaaksysteem::Schema::DocumentsMail;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("documents_mail");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('documents_mail_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "document_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "rcpt",
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
  "subject",
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
  "option_order",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("documents_mail_pkey", ["id"]);
__PACKAGE__->belongs_to(
  "document_id",
  "Zaaksysteem::Schema::Documents",
  { id => "document_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JqdD0sTHqN5u/7cqQNMeRA

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
