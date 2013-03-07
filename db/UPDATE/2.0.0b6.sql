alter table zaak_kenmerken_values add column zaak_bag_id integer REFERENCES zaak_bag(id);
