package Zaaksysteem::Schema::ZaaktypeSjablonen;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("zaaktype_sjablonen");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('zaaktype_sjablonen_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "zaaktype_node_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "bibliotheek_sjablonen_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "help",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "zaak_status_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
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
  "automatisch_genereren",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("zaaktype_sjablonen_pkey", ["id"]);
__PACKAGE__->belongs_to(
  "zaak_status_id",
  "Zaaksysteem::Schema::ZaaktypeStatus",
  { id => "zaak_status_id" },
);
__PACKAGE__->belongs_to(
  "bibliotheek_sjablonen_id",
  "Zaaksysteem::Schema::BibliotheekSjablonen",
  { id => "bibliotheek_sjablonen_id" },
);
__PACKAGE__->belongs_to(
  "zaaktype_node_id",
  "Zaaksysteem::Schema::ZaaktypeNode",
  { id => "zaaktype_node_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:53S76pecCdrts2go2ZDI2g
__PACKAGE__->resultset_class('Zaaksysteem::DB::ResultSet::ZaaktypeSjablonen');

__PACKAGE__->load_components(
    "+Zaaksysteem::DB::Component::ZaaktypeSjablonen",
    __PACKAGE__->load_components()
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
