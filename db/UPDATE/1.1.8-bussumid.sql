CREATE TABLE bedrijf_authenticatie (
    id                          SERIAL PRIMARY KEY,
    gegevens_magazijn_id        integer,
    login                       integer,
    password                    character varying(255),
    created                     timestamp without time zone,
    last_modified               timestamp without time zone
);
