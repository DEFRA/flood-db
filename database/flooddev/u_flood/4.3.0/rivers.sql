-- Table: u_flood.river

CREATE TABLE IF NOT EXISTS u_flood.river
(
    id CHARACTER VARYING(200) COLLATE pg_catalog."default" primary key,
    name CHARACTER VARYING(200) COLLATE pg_catalog."default",
    qualified_name CHARACTER VARYING(250) COLLATE pg_catalog."default"
)
TABLESPACE flood_tables;

ALTER TABLE IF EXISTS u_flood.river
    OWNER to u_flood;
