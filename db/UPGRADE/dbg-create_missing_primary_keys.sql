BEGIN;

ALTER TABLE parkeergebied ADD PRIMARY KEY (id);
ALTER TABLE parkeergebied_kosten ADD PRIMARY KEY (id);

COMMIT;
