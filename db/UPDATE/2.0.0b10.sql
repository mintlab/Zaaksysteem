ALTER TABLE zaak DROP COLUMN child_because;
ALTER TABLE zaak DROP COLUMN related_because;
ALTER TABLE zaak DROP COLUMN vervolg_because;

CREATE TABLE zaak_meta (
    id                  SERIAL PRIMARY KEY,
    zaak_id             integer REFERENCES zaak(id),
    verlenging          character varying(255),
    opschorten          character varying(255),
    deel                character varying(255),
    gerelateerd         character varying(255),
    vervolg             character varying(255),
    afhandeling         character varying(255)
);
