package Zaaksysteem::Schema::ZaaktypeNode;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("zaaktype_node");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('zaaktype_node_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "zaaktype_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "zaaktype_rt_queue",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "code",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "trigger",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "titel",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 128,
  },
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
  "webform_toegang",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "webform_authenticatie",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "adres_relatie",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "aanvrager_hergebruik",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "automatisch_aanvragen",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "automatisch_behandelen",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "toewijzing_zaakintake",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "toelichting",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 128,
  },
  "online_betaling",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "zaaktype_definitie_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "adres_andere_locatie",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "adres_aanvrager",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "bedrijfid_wijzigen",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "zaaktype_vertrouwelijk",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "zaaktype_trefwoorden",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "zaaktype_omschrijving",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "extra_relaties_in_aanvraag",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("zaaktype_node_pkey", ["id"]);
__PACKAGE__->has_many(
  "checklist_vraags",
  "Zaaksysteem::Schema::ChecklistVraag",
  { "foreign.zaaktype_node_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaks",
  "Zaaksysteem::Schema::Zaak",
  { "foreign.zaaktype_node_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktypes",
  "Zaaksysteem::Schema::Zaaktype",
  { "foreign.zaaktype_node_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_authorisations",
  "Zaaksysteem::Schema::ZaaktypeAuthorisation",
  { "foreign.zaaktype_node_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_betrokkenens",
  "Zaaksysteem::Schema::ZaaktypeBetrokkenen",
  { "foreign.zaaktype_node_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_kenmerkens",
  "Zaaksysteem::Schema::ZaaktypeKenmerken",
  { "foreign.zaaktype_node_id" => "self.id" },
);
__PACKAGE__->belongs_to(
  "zaaktype_id",
  "Zaaksysteem::Schema::Zaaktype",
  { id => "zaaktype_id" },
);
__PACKAGE__->belongs_to(
  "zaaktype_definitie_id",
  "Zaaksysteem::Schema::ZaaktypeDefinitie",
  { id => "zaaktype_definitie_id" },
);
__PACKAGE__->has_many(
  "zaaktype_notificaties",
  "Zaaksysteem::Schema::ZaaktypeNotificatie",
  { "foreign.zaaktype_node_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_regels",
  "Zaaksysteem::Schema::ZaaktypeRegel",
  { "foreign.zaaktype_node_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_relaties",
  "Zaaksysteem::Schema::ZaaktypeRelatie",
  { "foreign.zaaktype_node_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_resultatens",
  "Zaaksysteem::Schema::ZaaktypeResultaten",
  { "foreign.zaaktype_node_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_sjablonens",
  "Zaaksysteem::Schema::ZaaktypeSjablonen",
  { "foreign.zaaktype_node_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_statuses",
  "Zaaksysteem::Schema::ZaaktypeStatus",
  { "foreign.zaaktype_node_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XR3CcVpvGE2pqxF4J3q3Lg

__PACKAGE__->resultset_class('Zaaksysteem::DB::ResultSet::ZaaktypeNode');

__PACKAGE__->load_components(
    "+Zaaksysteem::DB::Component::ZaaktypeNode",
    __PACKAGE__->load_components()
);

__PACKAGE__->add_columns('last_modified',
    { %{ __PACKAGE__->column_info('last_modified') },
    set_on_update => 1,
    set_on_create => 1,
});

__PACKAGE__->add_columns('created',
    { %{ __PACKAGE__->column_info('created') },
    set_on_create => 1,
});


### Some relaties can be better

__PACKAGE__->has_many(
  "zaaktype_statussen",
  "Zaaksysteem::Schema::ZaaktypeStatus", 
  { "foreign.zaaktype_node_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_attributen",
  "Zaaksysteem::Schema::ZaaktypeAttributen",
  { "foreign.zaaktype_node_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_betrokkenen",
  "Zaaksysteem::Schema::ZaaktypeBetrokkenen",
  { "foreign.zaaktype_node_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_authorisaties",
  "Zaaksysteem::Schema::ZaaktypeAuthorisation",
  { "foreign.zaaktype_node_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_kenmerken",
  "Zaaksysteem::Schema::ZaaktypeKenmerken",
  { "foreign.zaaktype_node_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_resultaten",
  "Zaaksysteem::Schema::ZaaktypeResultaten",
  { "foreign.zaaktype_node_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_sjablonen",
  "Zaaksysteem::Schema::ZaaktypeSjablonen",
  { "foreign.zaaktype_node_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_relaties",
  "Zaaksysteem::Schema::ZaaktypeRelatie",
  { "foreign.zaaktype_node_id" => "self.id" },
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
