-- Index: idx_stations_overview_unique

-- DROP INDEX u_flood.idx_stations_overview_unique;

CREATE UNIQUE INDEX IF NOT EXISTS idx_stations_overview_unique
    ON u_flood.stations_overview_mview USING btree
    (rloi_id ASC NULLS LAST, direction COLLATE pg_catalog."default" ASC NULLS LAST, parameter COLLATE pg_catalog."default" ASC NULLS LAST, qualifier COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE flood_indexes;
	
-- Index: idx_rainfall_stations_unique

-- DROP INDEX u_flood.idx_rainfall_stations_unique;

CREATE UNIQUE INDEX IF NOT EXISTS idx_rainfall_stations_unique
    ON u_flood.rainfall_stations_mview USING btree
    (telemetry_station_id ASC NULLS LAST)
    TABLESPACE flood_indexes;


-- Index: idx_telemetry_context_unique

-- DROP INDEX u_flood.idx_telemetry_context_unique;

CREATE UNIQUE INDEX IF NOT EXISTS idx_telemetry_context_unique
    ON u_flood.telemetry_context_mview USING btree
    (rloi_id ASC NULLS LAST)
    TABLESPACE flood_indexes;

-- Index: idx_station_split_unique

-- DROP INDEX u_flood.idx_station_split_unique;

CREATE UNIQUE INDEX IF NOT EXISTS idx_station_split_unique
    ON u_flood.station_split_mview USING btree
    (rloi_id ASC NULLS LAST, qualifier COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE flood_indexes;


