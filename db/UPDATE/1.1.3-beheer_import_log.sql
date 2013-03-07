alter table beheer_import_log add column action character varying(255);
ALTER TABLE beheer_import_log ADD FOREIGN KEY (import_id) REFERENCES beheer_import(id);
