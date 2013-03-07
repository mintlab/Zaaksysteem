DROP TABLE IF EXISTS zaaktype_regel;


CREATE TABLE zaaktype_regel (
    id                          SERIAL,
    zaaktype_node_id            integer REFERENCES zaaktype_node(id),
    zaak_status_id              integer REFERENCES zaaktype_status(id),
    naam                        TEXT,
    settings                    TEXT,
    created                     timestamp without time zone,
    last_modified               timestamp without time zone
);
