CREATE DATABASE flooddev
    WITH
    OWNER = u_flood
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

ALTER DATABASE flooddev SET search_path = "$user", public, postgis, topology;


