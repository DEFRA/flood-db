-- ===============================
-- RDS Initial Setup Script
-- ===============================

-- === Step 0: Create tablespaces (only if these paths exist on your RDS instance) ===
-- CREATE TABLESPACE flood_indexes OWNER u_flood LOCATION '/srv/postgres/data/wiyby/wiyby_indexes';
-- CREATE TABLESPACE flood_tables OWNER u_flood LOCATION '/srv/postgres/data/wiyby/wiyby_tables';

-- === Step 1: Create required schemas ===
CREATE SCHEMA IF NOT EXISTS postgis AUTHORIZATION u_flood;
CREATE SCHEMA IF NOT EXISTS topology AUTHORIZATION u_flood;
CREATE SCHEMA IF NOT EXISTS u_flood AUTHORIZATION u_flood;
CREATE SCHEMA IF NOT EXISTS river_topo AUTHORIZATION u_flood;

COMMENT ON SCHEMA u_flood IS 'Flood schema';
COMMENT ON SCHEMA topology IS 'PostGIS Topology schema';

-- === Step 2: Install PostGIS extensions in the correct schemas ===
-- These should not be owned by u_flood on RDS; ownership is managed by RDS (rdsadmin)
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA topology;
CREATE EXTENSION IF NOT EXISTS postgis_raster WITH SCHEMA postgis;
CREATE EXTENSION IF NOT EXISTS pgrouting WITH SCHEMA u_flood;
CREATE EXTENSION IF NOT EXISTS postgres_fdw WITH SCHEMA u_flood;

-- === Step 3: Set the search_path for the u_flood role ===
-- This ensures any session under this role can access required schemas
ALTER ROLE u_flood SET search_path = u_flood, postgis, topology, public;

-- === Step 4: Optionally set search_path at the database level ===
-- Replace :DB_NAME with an env var at runtime via `psql --set=DB_NAME=...`
ALTER DATABASE temp_db_flood SET search_path = "$user", postgis, topology, public;

-- === Step 5: Grant basic usage/access to schemas ===
GRANT USAGE ON SCHEMA u_flood TO u_flood;
GRANT USAGE ON SCHEMA postgis TO u_flood;
GRANT USAGE ON SCHEMA topology TO u_flood;
GRANT USAGE ON SCHEMA river_topo TO u_flood;
GRANT USAGE ON SCHEMA public TO u_flood;

-- === Step 6: Grant execution on existing functions (if applicable) ===
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA u_flood TO u_flood;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO u_flood;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA postgis TO u_flood;

-- === Step 7: Grant privileges on tables/sequences (if any exist) ===
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA u_flood TO u_flood;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA u_flood TO u_flood;

-- === Step 8: Set default privileges for future objects ===
ALTER DEFAULT PRIVILEGES IN SCHEMA u_flood
ALTER DEFAULT PRIVILEGES IN SCHEMA postgis GRANT EXECUTE ON FUNCTIONS TO u_flood;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO u_flood;

-- === Step 9: Create helper function (optional, matches remote) ===
CREATE OR REPLACE FUNCTION postgis.exec(text) RETURNS text
LANGUAGE plpgsql
AS $$
BEGIN
  EXECUTE $1;
  RETURN $1;
END;
$$;

-- === Step 10: Workaround for Liquibase sequencing (if needed) ===
CREATE MATERIALIZED VIEW IF NOT EXISTS fwa_mview AS SELECT 1 WITH DATA;

-- ===============================
-- Notes:
-- - Do NOT drop or update PostGIS extensions manually on RDS.
-- - Do NOT alter PostGIS or topology ownership — managed by AWS.
-- - Tablespaces are excluded — not supported in RDS.
-- ===============================
