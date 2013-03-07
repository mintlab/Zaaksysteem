BEGIN;

ALTER TABLE beheer_plugins ADD PRIMARY KEY (id);
ALTER TABLE user_app_lock ADD PRIMARY KEY (uidnumber,type,type_id);
ALTER TABLE zaaktype_kenmerken ADD PRIMARY KEY (id);
ALTER TABLE zaaktype_notificatie ADD PRIMARY KEY (id);
ALTER TABLE zaaktype_regel ADD PRIMARY KEY (id);

COMMIT;
