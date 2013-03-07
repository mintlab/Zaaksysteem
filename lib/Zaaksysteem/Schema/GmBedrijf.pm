package Zaaksysteem::Schema::GmBedrijf;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("gm_bedrijf");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('gm_bedrijf_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "gegevens_magazijn_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "dossiernummer",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "subdossiernummer",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 4,
  },
  "hoofdvestiging_dossiernummer",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "hoofdvestiging_subdossiernummer",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 4,
  },
  "vorig_dossiernummer",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "vorig_subdossiernummer",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 4,
  },
  "handelsnaam",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 45,
  },
  "rechtsvorm",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "kamernummer",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "faillisement",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "surseance",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "telefoonnummer",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 15,
  },
  "email",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 128,
  },
  "vestiging_adres",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 30,
  },
  "vestiging_straatnaam",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "vestiging_huisnummer",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "vestiging_huisnummertoevoeging",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 12,
  },
  "vestiging_postcodewoonplaats",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 30,
  },
  "vestiging_postcode",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "vestiging_woonplaats",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 24,
  },
  "correspondentie_adres",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 30,
  },
  "correspondentie_straatnaam",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "correspondentie_huisnummer",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "correspondentie_huisnummertoevoeging",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 12,
  },
  "correspondentie_postcodewoonplaats",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 30,
  },
  "correspondentie_postcode",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "correspondentie_woonplaats",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 24,
  },
  "hoofdactiviteitencode",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "nevenactiviteitencode1",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "nevenactiviteitencode2",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "werkzamepersonen",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "contact_naam",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 64,
  },
  "contact_aanspreektitel",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 45,
  },
  "contact_voorletters",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
  "contact_voorvoegsel",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "contact_geslachtsnaam",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 95,
  },
  "contact_geslachtsaanduiding",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
  "authenticated",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "authenticatedby",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "import_datum",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "verblijfsobject_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 16,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("gm_bedrijf_pkey", ["id"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A/HSbjm13xQbJD2sEIGjEw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
