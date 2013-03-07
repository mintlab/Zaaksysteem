ALTER TABLE gm_natuurlijk_persoon ADD COLUMN verblijfsobject_id character varying(16);
ALTER TABLE gm_bedrijf ADD COLUMN verblijfsobject_id character varying(16);

ALTER TABLE zaaktype_kenmerken ADD COLUMN bag_zaakadres integer;
