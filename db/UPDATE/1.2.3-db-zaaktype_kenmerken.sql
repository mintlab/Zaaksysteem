ALTER TABLE bibliotheek_kenmerken ADD COLUMN speciaal_kenmerk character varying(32);
ALTER TABLE bibliotheek_kenmerken ADD COLUMN besluit integer;
ALTER TABLE zaaktype_kenmerken ADD COLUMN is_group integer;
