-- ========================================
-- Tablespace setup for local Docker-based Postgres (not for RDS)
-- ========================================

-- === Tablespace: flood_indexes ===
SELECT 'CREATE TABLESPACE flood_indexes OWNER u_flood LOCATION ''/wiyby/wiyby_indexes'''
WHERE NOT EXISTS (
  SELECT 1 FROM pg_tablespace WHERE spcname = 'flood_indexes'
)\gexec

-- === Tablespace: flood_tables ===
SELECT 'CREATE TABLESPACE flood_tables OWNER u_flood LOCATION ''/wiyby/wiyby_tables'''
WHERE NOT EXISTS (
  SELECT 1 FROM pg_tablespace WHERE spcname = 'flood_tables'
)\gexec
