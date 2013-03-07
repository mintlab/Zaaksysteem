package Zaaksysteem::Schema::ZaaktypeStatus;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("zaaktype_status");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('zaaktype_status_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "zaaktype_node_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "status",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "status_type",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "naam",
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
  "ou_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "role_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "checklist",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "fase",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "role_set",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("zaaktype_status_pkey", ["id"]);
__PACKAGE__->has_many(
  "checklist_vraags",
  "Zaaksysteem::Schema::ChecklistVraag",
  { "foreign.zaaktype_status_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_kenmerkens",
  "Zaaksysteem::Schema::ZaaktypeKenmerken",
  { "foreign.zaak_status_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_notificaties",
  "Zaaksysteem::Schema::ZaaktypeNotificatie",
  { "foreign.zaak_status_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_regels",
  "Zaaksysteem::Schema::ZaaktypeRegel",
  { "foreign.zaak_status_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_relaties",
  "Zaaksysteem::Schema::ZaaktypeRelatie",
  { "foreign.zaaktype_status_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_resultatens",
  "Zaaksysteem::Schema::ZaaktypeResultaten",
  { "foreign.zaaktype_status_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_sjablonens",
  "Zaaksysteem::Schema::ZaaktypeSjablonen",
  { "foreign.zaak_status_id" => "self.id" },
);
__PACKAGE__->belongs_to(
  "zaaktype_node_id",
  "Zaaksysteem::Schema::ZaaktypeNode",
  { id => "zaaktype_node_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:K4v+IITwzBKju3L4oe2WYQ


__PACKAGE__->resultset_class('Zaaksysteem::Zaaktypen::BaseStatus');

__PACKAGE__->load_components(
    "+Zaaksysteem::DB::Component::ZaaktypeFase",
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

__PACKAGE__->has_many(
  "zaaktype_resultaten",
  "Zaaksysteem::Schema::ZaaktypeResultaten",
  { "foreign.zaaktype_status_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_documenten",
  "Zaaksysteem::Schema::ZaaktypeZtcDocumenten",
  { "foreign.zaak_status_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_kenmerken",
  "Zaaksysteem::Schema::ZaaktypeKenmerken",
  { "foreign.zaak_status_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_sjablonen",
  "Zaaksysteem::Schema::ZaaktypeSjablonen",
  { "foreign.zaak_status_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_notificaties",
  "Zaaksysteem::Schema::ZaaktypeNotificatie",
  { "foreign.zaak_status_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_regels",
  "Zaaksysteem::Schema::ZaaktypeRegel",
  { "foreign.zaak_status_id" => "self.id" },
);
__PACKAGE__->has_many(
  "zaaktype_checklists",
  "Zaaksysteem::Schema::ChecklistVraag",
  { "foreign.zaaktype_status_id" => "self.id" },
);
# You can replace this text with custom content, and it will be preserved on regeneration
1;
