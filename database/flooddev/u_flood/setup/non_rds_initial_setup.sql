-- Connect to the database
\connect :"DB_NAME"

-- === Step 1: Create schemas ===
CREATE SCHEMA IF NOT EXISTS u_flood AUTHORIZATION u_flood;
COMMENT ON SCHEMA u_flood IS 'Flood schema';

CREATE SCHEMA IF NOT EXISTS postgis AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS topology AUTHORIZATION postgres;

-- === Step 2: Set search_path to avoid defaulting to u_flood during extension creation ===
SET search_path = postgis;

-- === Step 3: Install PostGIS in 'postgis' schema ===
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA postgis;

-- === Step 4: Install postgis_topology in 'topology' schema ===
CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA topology;

-- === Step 5: Grant schema-level usage ===
GRANT USAGE ON SCHEMA u_flood TO u_flood;
GRANT USAGE ON SCHEMA public TO u_flood;
GRANT USAGE ON SCHEMA postgis TO u_flood;
GRANT USAGE ON SCHEMA topology TO u_flood;

-- === Step 6: Grant object-level privileges ===
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO u_flood;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA u_flood TO u_flood;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO u_flood;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA u_flood TO u_flood;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA postgis TO u_flood;

-- === Step 7: Default privileges for new objects ===
ALTER DEFAULT PRIVILEGES IN SCHEMA u_flood
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO u_flood;
ALTER DEFAULT PRIVILEGES IN SCHEMA postgis GRANT EXECUTE ON FUNCTIONS TO u_flood;

-- === Step 8: Set search paths ===
ALTER DATABASE :"DB_NAME" SET search_path = u_flood, public, postgis, topology;
ALTER ROLE u_flood SET search_path = u_flood, public, postgis, topology;
