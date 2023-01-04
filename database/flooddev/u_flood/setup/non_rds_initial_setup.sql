-- Schema: u_flood

--DROP SCHEMA u_flood;

CREATE SCHEMA u_flood
  AUTHORIZATION u_flood;

COMMENT ON SCHEMA u_flood
  IS 'Flood schema';

-- Schema: postgis

-- DROP SCHEMA postgis;

CREATE SCHEMA postgis
  AUTHORIZATION postgres;

GRANT ALL ON SCHEMA postgis TO u_flood;

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

ALTER DATABASE flooddev SET search_path = "$user", public, postgis, topology;

UPDATE pg_extension 
  SET extrelocatable = TRUE 
    WHERE extname = 'postgis';
 
ALTER EXTENSION postgis 
  SET SCHEMA postgis;
