package Zaaksysteem::Schema::BibliotheekCategorie;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("bibliotheek_categorie");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('bibliotheek_categorie_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "naam",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 256,
  },
  "label",
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
  "help",
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
  "system",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "pid",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("bibliotheek_categorie_pkey", ["id"]);
__PACKAGE__->belongs_to(
  "pid",
  "Zaaksysteem::Schema::BibliotheekCategorie",
  { id => "pid" },
);
__PACKAGE__->has_many(
  "bibliotheek_categories",
  "Zaaksysteem::Schema::BibliotheekCategorie",
  { "foreign.pid" => "self.id" },
);
__PACKAGE__->has_many(
  "bibliotheek_kenmerkens",
  "Zaaksysteem::Schema::BibliotheekKenmerken",
  { "foreign.bibliotheek_categorie_id" => "self.id" },
);
__PACKAGE__->has_many(
  "bibliotheek_sjablonens",
  "Zaaksysteem::Schema::BibliotheekSjablonen",
  { "foreign.bibliotheek_categorie_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktypes",
  "Zaaksysteem::Schema::Zaaktype",
  { "foreign.bibliotheek_categorie_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zNEKxq4VhpWz/qk+LsEgsA

__PACKAGE__->load_components(
    "+Zaaksysteem::DB::Component::BibliotheekCategorie",
    __PACKAGE__->load_components()
);

__PACKAGE__->has_many(
  "categorien",
  "Zaaksysteem::Schema::BibliotheekCategorie",
  { "foreign.pid" => "self.id" },
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
