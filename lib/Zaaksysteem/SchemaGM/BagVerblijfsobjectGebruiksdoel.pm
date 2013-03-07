package Zaaksysteem::SchemaGM::BagVerblijfsobjectGebruiksdoel;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Core");
__PACKAGE__->table("bag_verblijfsobject_gebruiksdoel");
__PACKAGE__->add_columns(
  "identificatie",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 16,
  },
  "begindatum",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 14,
  },
  "gebruiksdoel",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 80,
  },
  "correctie",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("identificatie", "begindatum", "correctie", "gebruiksdoel");
__PACKAGE__->add_unique_constraint(
  "pk_verblijfsobject_gebrdoel",
  ["identificatie", "begindatum", "correctie", "gebruiksdoel"],
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-04-03 15:22:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wdQfEpeBxlJOHXkU6aZcUw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
