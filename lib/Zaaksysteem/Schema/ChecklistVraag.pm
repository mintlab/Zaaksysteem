package Zaaksysteem::Schema::ChecklistVraag;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("checklist_vraag");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('checklist_vraag_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "nr",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "vraag",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "vraagtype",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "zaaktype_node_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "zaaktype_status_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("checklist_vraag_pkey", ["id"]);
__PACKAGE__->belongs_to(
  "zaaktype_node_id",
  "Zaaksysteem::Schema::ZaaktypeNode",
  { id => "zaaktype_node_id" },
);
__PACKAGE__->belongs_to(
  "zaaktype_status_id",
  "Zaaksysteem::Schema::ZaaktypeStatus",
  { id => "zaaktype_status_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:J+u8h4w4bi1ncGF3DI94Sg
__PACKAGE__->resultset_class('Zaaksysteem::DB::ResultSet::ChecklistVraag');

__PACKAGE__->has_many(
  "checklist_antwoords",
  "Zaaksysteem::Schema::ChecklistAntwoord",
  { "foreign.vraag_id" => "self.id" },
);



# You can replace this text with custom content, and it will be preserved on regeneration
1;
