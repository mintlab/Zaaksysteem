BEGIN;

-- Vernietig nooit gebruikte kolommen
ALTER TABLE zaaktype_betrokkenen DROP COLUMN active;

ALTER TABLE zaaktype_definitie DROP COLUMN webform_authenticatie;
ALTER TABLE zaaktype_definitie DROP COLUMN webform_toegang;

ALTER TABLE zaaktype_authorisation DROP COLUMN group_id;

ALTER TABLE zaaktype_notificatie DROP COLUMN rcpt_content;

ALTER TABLE zaaktype_node DROP COLUMN zaaktype_categorie_id;
ALTER TABLE zaaktype_node DROP COLUMN org_eenheid_id;

ALTER TABLE zaaktype DROP COLUMN zaaktype_categorie_id;

ALTER TABLE zaaktype_relatie DROP COLUMN mandatory;

ALTER TABLE zaaktype_status DROP COLUMN omschrijving;
ALTER TABLE zaaktype_status DROP COLUMN help;
ALTER TABLE zaaktype_status DROP COLUMN mail_subject;
ALTER TABLE zaaktype_status DROP COLUMN mail_message;
ALTER TABLE zaaktype_status DROP COLUMN betrokkene;
ALTER TABLE zaaktype_status DROP COLUMN betrokkene_rol;
ALTER TABLE zaaktype_status DROP COLUMN afhandeltijd;

ALTER TABLE zaaktype_kenmerken DROP COLUMN description;
ALTER TABLE zaaktype_kenmerken DROP COLUMN document_categorie;

ALTER TABLE zaaktype_sjablonen DROP COLUMN label;
ALTER TABLE zaaktype_sjablonen DROP COLUMN description;
ALTER TABLE zaaktype_sjablonen DROP COLUMN mandatory;

ALTER TABLE bibliotheek_kenmerken DROP COLUMN value_mandatory;
ALTER TABLE bibliotheek_kenmerken DROP COLUMN value_length;
ALTER TABLE bibliotheek_kenmerken DROP COLUMN value_constraint;
ALTER TABLE bibliotheek_kenmerken DROP COLUMN speciaal_kenmerk;
ALTER TABLE bibliotheek_kenmerken DROP COLUMN besluit;


ALTER TABLE checklist_vraag DROP COLUMN status_id;
ALTER TABLE checklist_vraag DROP COLUMN depends_on_option;
ALTER TABLE checklist_vraag DROP COLUMN help;
ALTER TABLE checklist_vraag DROP COLUMN ja;
ALTER TABLE checklist_vraag DROP COLUMN nee;

ALTER TABLE zaaktype_resultaten DROP COLUMN vernietigingstermijn;
ALTER TABLE zaaktype_resultaten DROP COLUMN active;

-- Vernietig obsolte tables

DROP TABLE auth_users;
ALTER TABLE zaaktype_checklist_vraag DROP CONSTRAINT "zaaktype_checklist_vraag_depends_on_option_fkey";
--ALTER TABLE checklist_vraag DROP CONSTRAINT "checklist_vraag_depends_on_option_fkey";
DROP TABLE checklist_mogelijkheden;
DROP TABLE checklist_status;
DROP TABLE checklist_zaak;
DROP TABLE medewerker;
DROP TABLE org_eenheid;
DROP TABLE zaaktype_values;
DROP TABLE zaaktype_attributen;
DROP TABLE zaaktype_categorie;
DROP TABLE zaaktype_checklist_mogelijkheden;
DROP TABLE zaaktype_checklist_vraag;
DROP TABLE zaaktype_checklist_status;
DROP TABLE zaaktype_checklist;
DROP TABLE zaaktype_ztc_documenten;
DROP TABLE betrokkene;

COMMIT;
