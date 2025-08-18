-- ========================================
-- Create database if it doesn't exist (local setup)
-- ========================================

-- Set this at the top or via command-line: psql -v DB_NAME=temp_db_flood
\set ON_ERROR_STOP 1

-- Only run CREATE DATABASE if it doesn't already exist
SELECT format(
  'CREATE DATABASE %I
     WITH
     OWNER = u_flood
     ENCODING = ''UTF8''
     LC_COLLATE = ''en_US.utf8''
     LC_CTYPE = ''en_US.utf8''
     TABLESPACE = pg_default
     CONNECTION LIMIT = -1
     IS_TEMPLATE = false;',
  :'DB_NAME'
)
WHERE NOT EXISTS (
  SELECT 1 FROM pg_database WHERE datname = :'DB_NAME'
)\gexec

-- Optional: confirmation message
\echo Checked database :DB_NAME (created if it didnt exist)

ALTER DATABASE :'DB_NAME' SET search_path = u_flood, public, postgis, topology;
