CREATE TABLE zaak_onafgerond
(
  zaaktype_id integer NOT NULL,
  betrokkene character(50) NOT NULL,
  json_string text NOT NULL,
  afronden boolean,
  create_unixtime integer,
  CONSTRAINT zaak_onafgerond_pkey PRIMARY KEY (zaaktype_id , betrokkene ),
  CONSTRAINT zaak_zaaktype_id_fkey FOREIGN KEY (zaaktype_id)
      REFERENCES zaaktype (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
