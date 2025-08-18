\set ON_ERROR_STOP 0

-- === Step 1: Create RDS-style system roles (simulated locally) ===

DO $$
BEGIN
  CREATE ROLE rds_replication NOLOGIN;
EXCEPTION WHEN duplicate_object THEN
  RAISE NOTICE 'Role rds_replication already exists.';
END
$$;

DO $$
BEGIN
  CREATE ROLE rds_password NOLOGIN;
EXCEPTION WHEN duplicate_object THEN
  RAISE NOTICE 'Role rds_password already exists.';
END
$$;

DO $$
BEGIN
  CREATE ROLE rds_superuser NOLOGIN;
EXCEPTION WHEN duplicate_object THEN
  RAISE NOTICE 'Role rds_superuser already exists.';
END
$$;

-- Grant RDS typical role set to rds_superuser
GRANT pg_monitor, pg_signal_backend, rds_password, rds_replication TO rds_superuser;

-- === Step 2: Create u_flood user role (like RDS) ===

DO $$
BEGIN
  CREATE ROLE u_flood WITH
    LOGIN
    NOSUPERUSER
    INHERIT
    CREATEDB
    CREATEROLE
    NOREPLICATION
    PASSWORD 'secret';
EXCEPTION WHEN duplicate_object THEN
  RAISE NOTICE 'Role u_flood already exists.';
END
$$;

-- Grant rds_superuser to u_flood (as RDS allows via IAM policies or grants)
GRANT rds_superuser TO u_flood;

-- Set role's default search path like in RDS
ALTER ROLE u_flood SET search_path TO u_flood, postgis, topology, public;
