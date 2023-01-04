-- Additional initialistation setup for use when running the db in a postgis docker container
-- This script was created empirically by adding role creation statements using pgAdmin everytime 
-- a 'role not found' error occured on DB restore until there were no more errors.
-- pg_dumpall would be a better way to go but the only credentials dev have access to are for the
-- u_flood user not postgres which generates a permissions error when trying to dump roles

-- there is almost certainly a better ways of doing this

\set ON_ERROR_STOP 0

-- Role: rds_replication
-- DROP ROLE IF EXISTS rds_replication;

CREATE ROLE rds_replication WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION;

-- Role: rds_password
-- DROP ROLE IF EXISTS rds_password;

CREATE ROLE rds_password WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION;

CREATE ROLE rds_superuser WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION;

GRANT pg_monitor, pg_signal_backend, rds_password, rds_replication TO rds_superuser WITH ADMIN OPTION;

-- Role: u_flood
-- DROP ROLE IF EXISTS u_flood;

CREATE ROLE u_flood WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  CREATEDB
  CREATEROLE
  NOREPLICATION
  VALID UNTIL 'infinity';

GRANT rds_superuser TO u_flood;

ALTER ROLE u_flood SET search_path TO u_flood, postgis, topology, public;
