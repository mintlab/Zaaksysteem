--DROP TABLE IF EXISTS logging;
--CREATE TABLE logging (
--    id              INTEGER PRIMARY KEY AUTOINCREMENT,
--    loglevel        TEXT,                                   -- error,debug,warn,info
--    zaak_id         INTEGER,                                -- zaak_id, beetje redundant ivm component, maar just in case of speed
--    betrokkene_id   INTEGER REFERENCES betrokkene(id),      -- Betrokkene (ingelogde medewerker / of digid user)
--    aanvrager_id    INTEGER REFERENCES betrokkene(id),      -- Gerelateerde aanvrager (bij contact bijv)
--    is_bericht      INTEGER,                                -- Bericht, e.g. external message
--    component       TEXT,                                   -- e.g. documenten, zaakstatus, checklist, notities
--    component_id    INTEGER,                                -- id of component
--    seen            INTEGER,                                -- Gezien / aangewerkt
--    onderwerp       TEXT,                                   -- Onderwerp
--    bericht         TEXT,                                   -- Bericht
--    created         DATETIME,
--    last_modified   DATETIME,
--    deleted_on      DATETIME
--);

DROP TABLE IF EXISTS logging;
CREATE TABLE logging (
    id              SERIAL,
    loglevel        character varying(32),                  -- error,debug,warn,info
    zaak_id         INTEGER,                                -- zaak_id, beetje redundant ivm component, maar just in case of speed
    betrokkene_id   INTEGER REFERENCES betrokkene(id),      -- Betrokkene (ingelogde medewerker / of digid user)
    aanvrager_id    INTEGER REFERENCES betrokkene(id),      -- Gerelateerde aanvrager (bij contact bijv)
    is_bericht      INTEGER,                                -- Bericht, e.g. external message
    component       character varying(64),                  -- e.g. documenten, zaakstatus, checklist, notities
    component_id    INTEGER,                                -- id of component
    seen            INTEGER,                                -- Gezien / aangewerkt
    onderwerp       character varying(255),                 -- Onderwerp
    bericht         TEXT,                                   -- Bericht
    created         timestamp without time zone,
    last_modified   timestamp without time zone,
    deleted_on      timestamp without time zone
);
