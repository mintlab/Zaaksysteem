package Zaaksysteem::Schema::ZaakKenmerken;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("zaak_kenmerken");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('zaak_kenmerken_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "zaak_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "bibliotheek_kenmerken_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "value_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 128,
  },
  "naam",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 128,
  },
  "multiple",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("zaak_kenmerken_pkey", ["id"]);
__PACKAGE__->belongs_to(
  "bibliotheek_kenmerken_id",
  "Zaaksysteem::Schema::BibliotheekKenmerken",
  { id => "bibliotheek_kenmerken_id" },
);
__PACKAGE__->belongs_to("zaak_id", "Zaaksysteem::Schema::Zaak", { id => "zaak_id" });
__PACKAGE__->has_many(
  "zaak_kenmerken_values",
  "Zaaksysteem::Schema::ZaakKenmerkenValues",
  { "foreign.zaak_kenmerken_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RpgbNaJuN3Ur5uuScVz7Cg

__PACKAGE__->resultset_class('Zaaksysteem::Zaken::ResultSetZaakKenmerken');

__PACKAGE__->load_components(
    "+Zaaksysteem::Zaken::ComponentZaakKenmerken",
    __PACKAGE__->load_components()
);

__PACKAGE__->belongs_to(
  "zaak",
  "Zaaksysteem::Schema::Zaak",
  { id => "zaak_id" },
  { join_type   => 'left' },
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
