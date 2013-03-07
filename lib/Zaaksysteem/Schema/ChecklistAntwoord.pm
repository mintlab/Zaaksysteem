package Zaaksysteem::Schema::ChecklistAntwoord;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("checklist_antwoord");
__PACKAGE__->add_columns(
  "zaak_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "mogelijkheid_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "antwoord",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "vraag_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "id",
  {
    data_type => "integer",
    default_value => "nextval('checklist_antwoord_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("checklist_antwoord_pkey", ["id"]);
__PACKAGE__->add_unique_constraint("checklist_antwoord_id_key", ["id"]);
__PACKAGE__->belongs_to("zaak_id", "Zaaksysteem::Schema::Zaak", { id => "zaak_id" });


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jqK3Vj3pZUWzyDcaPzbh/A

__PACKAGE__->resultset_class('Zaaksysteem::Zaken::ResultSetChecklistAntwoord');

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
