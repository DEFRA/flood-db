-- Table: u_flood.river_stations

CREATE TABLE IF NOT EXISTS u_flood.river_stations
(
    river_id character varying(200) COLLATE pg_catalog."default",
    rloi_id integer,
    rank integer
)

TABLESPACE flood_tables;

ALTER TABLE IF EXISTS u_flood.river_stations
    OWNER to u_flood;

CREATE INDEX IF NOT EXISTS idx_river_stations_river_id
    ON u_flood.river_stations USING btree
    (river_id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE flood_indexes;

CREATE INDEX IF NOT EXISTS idx_river_stations_rloi_id
    ON u_flood.river_stations USING btree
    (rloi_id ASC NULLS LAST)
    TABLESPACE flood_indexes;
