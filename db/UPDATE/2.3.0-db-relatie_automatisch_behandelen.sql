BEGIN;
alter table zaaktype_relatie add column automatisch_behandelen boolean;
COMMIT;
