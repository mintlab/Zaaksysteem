alter table bibliotheek_categorie add column pid INTEGER REFERENCES bibliotheek_categorie(id);
alter table zaaktype_categorie add column pid INTEGER REFERENCES zaaktype_categorie(id);
alter table zaaktype_resultaten add column dossiertype character varying(50);
