package Zaaksysteem::Schema::ZaaktypeKenmerken;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("zaaktype_kenmerken");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('zaaktype_kenmerken_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "bibliotheek_kenmerken_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "value_mandatory",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "label",
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
  "zaaktype_node_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "zaak_status_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "pip",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "zaakinformatie_view",
  { data_type => "integer", default_value => 1, is_nullable => 1, size => 4 },
  "bag_zaakadres",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "is_group",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "besluit",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "date_fromcurrentdate",
  { data_type => "integer", default_value => 0, is_nullable => 1, size => 4 },
  "value_default",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("zaaktype_kenmerken_pkey", ["id"]);
__PACKAGE__->belongs_to(
  "zaak_status_id",
  "Zaaksysteem::Schema::ZaaktypeStatus",
  { id => "zaak_status_id" },
);
__PACKAGE__->belongs_to(
  "zaaktype_node_id",
  "Zaaksysteem::Schema::ZaaktypeNode",
  { id => "zaaktype_node_id" },
);
__PACKAGE__->belongs_to(
  "bibliotheek_kenmerken_id",
  "Zaaksysteem::Schema::BibliotheekKenmerken",
  { id => "bibliotheek_kenmerken_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZGMzBF8dQ1wUMVJe8Hu0eA

#__PACKAGE__->add_columns(value_default => { 
#    data_type => "text",
#    default_value => undef,
#    is_nullable => 1,
#    size => undef,
#    accessor => '_value_default', 
#});

__PACKAGE__->resultset_class('Zaaksysteem::DB::ResultSet::ZaaktypeKenmerken');

__PACKAGE__->load_components(
    "+Zaaksysteem::DB::Component::ZaaktypeKenmerken",
    __PACKAGE__->load_components()
);

__PACKAGE__->belongs_to(
  "bibliotheek_kenmerken_id",
  "Zaaksysteem::Schema::BibliotheekKenmerken",
  { id => "bibliotheek_kenmerken_id" },
  { join_type   => 'left' },
);

__PACKAGE__->belongs_to(
  "zaaktype_sjablonen",
  "Zaaksysteem::Schema::ZaaktypeSjablonen",
  { 'zaaktype_node_id' => "zaaktype_node_id" },
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
