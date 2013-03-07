package Zaaksysteem::Schema::ZaakKenmerk;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("zaak_kenmerk");
__PACKAGE__->add_columns(
  "zaak_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "bibliotheek_kenmerken_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "value",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("zaak_id", "bibliotheek_kenmerken_id", "value");
__PACKAGE__->add_unique_constraint(
  "zaak_kenmerk_pkey",
  ["zaak_id", "bibliotheek_kenmerken_id", "value"],
);
__PACKAGE__->add_unique_constraint(
  "zaak_kenmerk_zaak_id_key",
  ["zaak_id", "bibliotheek_kenmerken_id", "value"],
);
__PACKAGE__->belongs_to(
  "bibliotheek_kenmerken_id",
  "Zaaksysteem::Schema::BibliotheekKenmerken",
  { id => "bibliotheek_kenmerken_id" },
);
__PACKAGE__->belongs_to("zaak_id", "Zaaksysteem::Schema::Zaak", { id => "zaak_id" });


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uLqLfuZawGEYTdRkVCpqfA

__PACKAGE__->resultset_class('Zaaksysteem::Zaken::ResultSetZaakKenmerk');

__PACKAGE__->load_components(
    "+Zaaksysteem::Zaken::ComponentZaakKenmerk",
    __PACKAGE__->load_components()
);



# You can replace this text with custom content, and it will be preserved on regeneration
1;
