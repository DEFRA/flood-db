-- 4.11.0 - Ensure idx_stations_list_unique is dropped and recreated to avoid conflicts
-- This script should be run after stations_list_mview and rainfall_stations_mview are recreated

DROP INDEX IF EXISTS u_flood.idx_stations_list_unique;
CREATE UNIQUE INDEX idx_stations_list_unique
    ON u_flood.stations_list_mview USING btree (id)
    TABLESPACE flood_indexes;
