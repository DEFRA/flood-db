-- Table: u_flood.river

DROP TABLE IF EXISTS u_flood.river CASCADE;

CREATE TABLE IF NOT EXISTS u_flood.river
(
    id CHARACTER VARYING(200) COLLATE pg_catalog."default",
    name CHARACTER VARYING(200) COLLATE pg_catalog."default",
    qualified_name CHARACTER VARYING(250) COLLATE pg_catalog."default"
)
TABLESPACE flood_tables;

ALTER TABLE IF EXISTS u_flood.river
    OWNER to u_flood;

DROP INDEX IF EXISTS idx_river_id;

CREATE INDEX IF NOT EXISTS idx_river_id
    ON u_flood.river USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE flood_indexes;
