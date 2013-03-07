package Zaaksysteem::Schema::ZaakKenmerkenValues;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("zaak_kenmerken_values");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('zaak_kenmerken_values_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "zaak_kenmerken_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "bibliotheek_kenmerken_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "value",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "zaak_bag_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("zaak_kenmerken_values_pkey", ["id"]);
__PACKAGE__->belongs_to(
  "zaak_bag_id",
  "Zaaksysteem::Schema::ZaakBag",
  { id => "zaak_bag_id" },
);
__PACKAGE__->belongs_to(
  "zaak_kenmerken_id",
  "Zaaksysteem::Schema::ZaakKenmerken",
  { id => "zaak_kenmerken_id" },
);
__PACKAGE__->has_one(
  "zaak_kenmerken",
  "Zaaksysteem::Schema::ZaakKenmerken",
  { "foreign.id" => "self.zaak_kenmerken_id" },
);
__PACKAGE__->belongs_to(
  "bibliotheek_kenmerken_id",
  "Zaaksysteem::Schema::BibliotheekKenmerken",
  { id => "bibliotheek_kenmerken_id" },
);
__PACKAGE__->has_one(
  "bibliotheek_kenmerken",
  "Zaaksysteem::Schema::BibliotheekKenmerken",
  { "foreign.id" => "self.bibliotheek_kenmerken_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:umLecjhz9taqzM+1y36/0Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
