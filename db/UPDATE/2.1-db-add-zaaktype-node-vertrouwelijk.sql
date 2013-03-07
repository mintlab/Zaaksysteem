ALTER TABLE zaaktype_node ADD COLUMN zaaktype_vertrouwelijk integer;
ALTER TABLE zaaktype_node ADD COLUMN zaaktype_trefwoorden text;
ALTER TABLE zaaktype_node ADD COLUMN zaaktype_omschrijving text;
ALTER TABLE zaaktype_kenmerken ADD COLUMN date_fromcurrentdate integer;
ALTER TABLE zaaktype_kenmerken ADD COLUMN value_default text;
