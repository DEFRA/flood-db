-- Table: u_flood.river_stations

-- DROP MATERIALIZED VIEW IF EXISTS u_flood.stations_list_mview;
-- DROP MATERIALIZED VIEW IF EXISTS u_flood.rivers_mview;
DROP TABLE IF EXISTS u_flood.river_stations;

CREATE TABLE IF NOT EXISTS u_flood.river_stations
(
    id character varying(200) COLLATE pg_catalog."default",
    rloi_id integer,
    rank integer,
    river_id integer
)

TABLESPACE flood_tables;

ALTER TABLE IF EXISTS u_flood.river_stations
    OWNER to u_flood;
-- Index: idx_river_id

-- DROP INDEX IF EXISTS u_flood.idx_river_id;

CREATE INDEX IF NOT EXISTS idx_river_id
    ON u_flood.river_stations USING btree
    (river_id ASC NULLS LAST)
    TABLESPACE flood_indexes;
-- Index: idx_river_stations_id

-- DROP INDEX IF EXISTS u_flood.idx_river_stations_id;

CREATE INDEX IF NOT EXISTS idx_river_stations_id
    ON u_flood.river_stations USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE flood_indexes;
-- Index: idx_river_stations_rloi_id

-- DROP INDEX IF EXISTS u_flood.idx_river_stations_rloi_id;

CREATE INDEX IF NOT EXISTS idx_river_stations_rloi_id
    ON u_flood.river_stations USING btree
    (rloi_id ASC NULLS LAST)
    TABLESPACE flood_indexes;
