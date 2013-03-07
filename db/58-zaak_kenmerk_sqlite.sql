BEGIN;

DROP TABLE IF EXISTS zaak_kenmerk;

CREATE TABLE zaak_kenmerk (
    zaak_id   integer REFERENCES zaak(id) NOT NULL,
    bibliotheek_kenmerken_id integer REFERENCES bibliotheek_kenmerken(id) NOT NULL,
    value TEXT,
    UNIQUE(zaak_id, bibliotheek_kenmerken_id, value)
);

--ROLLBACK;

COMMIT;
