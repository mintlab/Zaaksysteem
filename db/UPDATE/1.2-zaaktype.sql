CREATE TABLE zaaktype_definitie (
    id                  SERIAL PRIMARY KEY,
    --id                  INTEGER AUTO_INCREMENT PRIMARY KEY,
    openbaarheid        character varying(255),
    handelingsinitiator character varying(255),
    grondslag           character varying(255),
    procesbeschrijving  character varying(255),
    afhandeltermijn     character varying(255),
    afhandeltermijn_type character varying(255),
    iv3_categorie       character varying(255),
    besluittype         character varying(255),
    selectielijst       character varying(255),
    servicenorm         character varying(255),
    servicenorm_type    character varying(255),

    omschrijving_upl    character varying(255),
    aard                character varying(255),
    extra_informatie    character varying(255),
    pdc_voorwaarden     TEXT,
    pdc_description     TEXT,
    pdc_meenemen        TEXT,
    pdc_tarief          TEXT,
    webform_authenticatie integer,
    webform_toegang     integer
);

ALTER TABLE zaaktype_node ADD COLUMN zaaktype_definitie_id integer REFERENCES zaaktype_definitie(id);
ALTER TABLE zaaktype ADD COLUMN bibliotheek_categorie_id integer REFERENCES bibliotheek_categorie(id);

ALTER TABLE zaaktype_status ADD COLUMN fase character varying(255);

ALTER TABLE checklist_status ADD COLUMN zaaktype_checklist_id integer REFERENCES zaaktype_checklist(id);
ALTER TABLE zaaktype_checklist ADD COLUMN zaaktype_status_id integer REFERENCES zaaktype_status(id);


ALTER TABLE checklist_vraag ADD COLUMN zaaktype_status_id integer REFERENCES zaaktype_status(id);
ALTER TABLE checklist_vraag ADD COLUMN zaaktype_node_id integer REFERENCES zaaktype_node(id);

alter table zaaktype_node add column adres_aanvrager integer;
alter table zaaktype_node add column adres_andere_locatie integer;

ALTER TABLE checklist_antwoord ADD COLUMN vraag_id integer REFERENCES zaaktype_vraag;
ALTER TABLE checklist_vraag ADD COLUMN vraag_id integer REFERENCES zaaktype_vraag;
ALTER TABLE checklist_antwoord DROP COLUMN mogelijkheid_id;
-- ALTER TABLE checklist_antwoord ADD COLUMN vraag_id integer REFERENCES zaaktype_vraag;
--ALTER TABLE zaaktype_definitie ADD COLUMN omschrijving_upl character varying(255);
--ALTER TABLE zaaktype_definitie ADD COLUMN aard character varying(255);
--ALTER TABLE zaaktype_definitie ADD COLUMN extra_informatie character varying(255);
