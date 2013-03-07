package Zaaksysteem::Schema::ZaakOnafgerond;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("zaak_onafgerond");
__PACKAGE__->add_columns(
  "zaaktype_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "betrokkene",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 0,
    size => 50,
  },
  "json_string",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "afronden",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "create_unixtime",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("zaaktype_id", "betrokkene");
__PACKAGE__->add_unique_constraint("zaak_onafgerond_pkey", ["zaaktype_id", "betrokkene"]);
__PACKAGE__->belongs_to(
  "zaaktype_id",
  "Zaaksysteem::Schema::Zaaktype",
  { id => "zaaktype_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c/krd1sXB/6l7+u2nM5/KQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
