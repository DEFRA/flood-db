-- View: u_flood.stations_list_mview

CREATE MATERIALIZED VIEW IF NOT EXISTS u_flood.stations_list_mview
TABLESPACE flood_tables
AS
SELECT 
    list.river_id,
    list.river_name,
    list.river_qualified_name,
    list.navigable,
    list.view_rank,
    list.rank,
    list.rloi_id,
    list.up,
    list.up_station_type,
    list.down,
    list.down_station_type,
    list.telemetry_id,
    list.region,
    list.catchment,
    list.wiski_river_name,
    list.agency_name,
    list.external_name,
    list.station_type,
    list.status,
    list.qualifier,
    list.iswales,
    list.value,
    list.value_timestamp,
    list.value_erred,
    list.trend,
    list.percentile_5,
    list.percentile_95,
    list.centroid,
    list.lon,
    list.lat,
    list.day_total,
    list.six_hr_total,
    list.one_hr_total,
    row_number() OVER () AS id
FROM (
    SELECT 
        rivers_mview.river_id,
        rivers_mview.river_name,
        rivers_mview.river_qualified_name,
        rivers_mview.navigable,
        rivers_mview.view_rank,
        rivers_mview.rank,
        rivers_mview.rloi_id,
        rivers_mview.up,
        rivers_mview.up_station_type,
        rivers_mview.down,
        rivers_mview.down_station_type,
        rivers_mview.telemetry_id,
        rivers_mview.region,
        rivers_mview.catchment,
        rivers_mview.wiski_river_name,
        rivers_mview.agency_name,
        rivers_mview.external_name,
        rivers_mview.station_type,
        rivers_mview.status,
        rivers_mview.qualifier,
        rivers_mview.iswales,
        rivers_mview.value,
        rivers_mview.value_timestamp,
        rivers_mview.value_erred,
        rivers_mview.trend,
        rivers_mview.percentile_5,
        rivers_mview.percentile_95,
        rivers_mview.centroid,
        rivers_mview.lon,
        rivers_mview.lat,
        NULL::numeric AS day_total,
        NULL::numeric AS six_hr_total,
        NULL::numeric AS one_hr_total
    FROM rivers_mview
    UNION
    SELECT 
        'rainfall-'::text || rainfall_stations_mview.region AS river_id,
        'Rainfall '::text || rainfall_stations_mview.region AS river_name,
        NULL::text AS river_qualified_name,
        false AS navigable,
        5 AS view_rank,
        NULL::bigint AS rank,
        NULL::integer AS rloi_id,
        NULL::integer AS up,
        NULL::text AS up_station_type,
        NULL::integer AS down,
        NULL::text AS down_station_type,
        rainfall_stations_mview.station_reference AS telemetry_id,
        rainfall_stations_mview.region,
        NULL::text AS catchment,
        NULL::text AS wiski_river_name,
        rainfall_stations_mview.station_name AS agency_name,
        rainfall_stations_mview.station_name AS external_name,
        'R'::bpchar AS station_type,
        'Active'::text AS status,
        NULL::text AS qualifier,
        false AS iswales,
        rainfall_stations_mview.value,
        rainfall_stations_mview.value_timestamp,
        false AS value_erred,
        'n/a'::text AS trend,
        NULL::numeric AS percentile_5,
        NULL::numeric AS percentile_95,
        rainfall_stations_mview.centroid,
        st_x(rainfall_stations_mview.centroid) AS lon,
        st_y(rainfall_stations_mview.centroid) AS lat,
        rainfall_stations_mview.day_total,
        rainfall_stations_mview.six_hr_total,
        rainfall_stations_mview.one_hr_total
    FROM rainfall_stations_mview
    WHERE rainfall_stations_mview.region <> 'Wales'::text
) list
ORDER BY 
    list.view_rank, 
    list.river_id, 
    list.rank, 
    list.wiski_river_name
WITH DATA;

ALTER TABLE IF EXISTS u_flood.stations_list_mview
    OWNER TO u_flood;

CREATE INDEX idx_stations_list_mview_geom_gist
    ON u_flood.stations_list_mview USING gist
    (centroid)
    TABLESPACE flood_indexes;

CREATE INDEX idx_stations_list_mview_river_id
    ON u_flood.stations_list_mview USING btree
    (river_id COLLATE pg_catalog."default")
    TABLESPACE flood_indexes;

CREATE UNIQUE INDEX idx_stations_list_unique
    ON u_flood.stations_list_mview USING btree
    (id)
    TABLESPACE flood_indexes;
