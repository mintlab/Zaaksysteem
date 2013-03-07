CREATE TABLE user_app_lock
(
  type character(40) NOT NULL,
  type_id character(20) NOT NULL,
  create_unixtime integer NOT NULL,
  session_id character(40) NOT NULL,
  uidnumber integer NOT NULL,
  CONSTRAINT "PKey" PRIMARY KEY (uidnumber , type , type_id )
);
