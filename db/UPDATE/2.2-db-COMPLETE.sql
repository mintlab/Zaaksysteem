CREATE TABLE user_app_lock (
        type character(40) NOT NULL,
        type_id character(20) NOT NULL,
        create_unixtime integer NOT NULL,
        session_id character(40) NOT NULL,
        uidnumber integer NOT NULL
);

CREATE TABLE zaak_onafgerond (
        zaaktype_id integer NOT NULL,
        betrokkene character(50) NOT NULL,
        json_string text NOT NULL,
        afronden boolean,
        create_unixtime integer
);

ALTER TABLE zaak_bag
        ADD COLUMN bag_standplaats_id character varying(255),
        ADD COLUMN bag_ligplaats_id character varying(255);

ALTER TABLE zaaktype_kenmerken ALTER COLUMN date_fromcurrentdate SET DEFAULT 0;

ALTER TABLE zaaktype_regel ADD COLUMN settings text;

ALTER TABLE zaak_onafgerond ADD CONSTRAINT zaak_onafgerond_pkey PRIMARY KEY (zaaktype_id, betrokkene);

ALTER TABLE zaak_onafgerond ADD CONSTRAINT zaak_zaaktype_id_fkey FOREIGN KEY (zaaktype_id) REFERENCES zaaktype(id);
