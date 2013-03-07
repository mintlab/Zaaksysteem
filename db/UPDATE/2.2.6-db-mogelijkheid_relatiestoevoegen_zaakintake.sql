ALTER TABLE zaaktype_node ADD COLUMN extra_relaties_in_aanvraag boolean;
ALTER TABLE zaak_betrokkenen ADD COLUMN rol TEXT;
ALTER TABLE zaak_betrokkenen ADD COLUMN magic_string_prefix TEXT;
ALTER TABLE zaak_betrokkenen ADD COLUMN deleted timestamp without time zone;
