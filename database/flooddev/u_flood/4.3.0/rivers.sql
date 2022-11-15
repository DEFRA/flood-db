-- Table: u_flood.river

DROP TABLE IF EXISTS u_flood.river;

CREATE TABLE IF NOT EXISTS u_flood.river
(
    id INTEGER PRIMARY KEY,
    name CHARACTER VARYING(200) COLLATE pg_catalog."default",
    qualified_name CHARACTER VARYING(250) COLLATE pg_catalog."default",
    river_id CHARACTER VARYING(200) COLLATE pg_catalog."default"
)
TABLESPACE flood_tables;

ALTER TABLE IF EXISTS u_flood.river
    OWNER to u_flood;
