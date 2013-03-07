package Zaaksysteem::Schema::Zaaktype;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("zaaktype");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('zaaktype_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "zaaktype_node_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "version",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "active",
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
  "deleted",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "bibliotheek_categorie_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("zaaktype_pkey", ["id"]);
__PACKAGE__->has_many(
  "zaaks",
  "Zaaksysteem::Schema::Zaak",
  { "foreign.zaaktype_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaak_onafgeronds",
  "Zaaksysteem::Schema::ZaakOnafgerond",
  { "foreign.zaaktype_id" => "self.id" },
);
__PACKAGE__->belongs_to(
  "zaaktype_node_id",
  "Zaaksysteem::Schema::ZaaktypeNode",
  { id => "zaaktype_node_id" },
);
__PACKAGE__->belongs_to(
  "bibliotheek_categorie_id",
  "Zaaksysteem::Schema::BibliotheekCategorie",
  { id => "bibliotheek_categorie_id" },
);
__PACKAGE__->has_many(
  "zaaktype_authorisations",
  "Zaaksysteem::Schema::ZaaktypeAuthorisation",
  { "foreign.zaaktype_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_nodes",
  "Zaaksysteem::Schema::ZaaktypeNode",
  { "foreign.zaaktype_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_relaties",
  "Zaaksysteem::Schema::ZaaktypeRelatie",
  { "foreign.relatie_zaaktype_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5bGocFFd2ZtToDDI/ZqS9w

__PACKAGE__->resultset_class('Zaaksysteem::DB::ResultSet::Zaaktype');

__PACKAGE__->add_columns('last_modified',
    { %{ __PACKAGE__->column_info('last_modified') },
    set_on_update => 1,
    set_on_create => 1,
});

__PACKAGE__->add_columns('created',
    { %{ __PACKAGE__->column_info('created') },
    set_on_create => 1,
});

__PACKAGE__->has_many(
  "zaaktype_authorisaties",
  "Zaaksysteem::Schema::ZaaktypeAuthorisation",
  { "foreign.zaaktype_id" => "self.id" },
);



# You can replace this text with custom content, and it will be preserved on regeneration
1;
