BEGIN;
update zaaktype_relatie set relatie_zaaktype_id = node.zaaktype_id from zaaktype_node node where node.id = zaaktype_relatie.relatie_zaaktype_id;
alter table zaaktype_relatie drop constraint zaaktype_relatie_relatie_zaaktype_id_fkey;
alter table zaaktype_relatie add constraint zaaktype_relatie_relatie_zaaktype_id_fkey FOREIGN KEY (relatie_zaaktype_id) REFERENCES zaaktype(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;
COMMIT;
