-- View: u_flood.stations_list_mview

DROP MATERIALIZED VIEW u_flood.stations_list_mview;

CREATE MATERIALIZED VIEW u_flood.stations_list_mview
TABLESPACE flood_tables
AS
SELECT *,  row_number() OVER () AS id
FROM (
 SELECT rivers_mview.river_id,
    rivers_mview.river_name,
    rivers_mview.navigable,
    rivers_mview.view_rank,
    rivers_mview.rank,
    rivers_mview.rloi_id,
    rivers_mview.up,
    rivers_mview.down,
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
 SELECT 'rainfall-'::text || rainfall_stations_mview.region AS river_id,
    'Rainfall '::text || rainfall_stations_mview.region AS river_name,
    false AS navigable,
    5 AS view_rank,
    NULL::bigint AS rank,
    NULL::integer AS rloi_id,
    NULL::integer AS up,
    NULL::integer AS down,
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
  ORDER BY 4, 1, 5, 13
) as list
WITH DATA;

ALTER TABLE u_flood.stations_list_mview
    OWNER TO u_flood;


CREATE INDEX idx_stations_list_mview_geom_gist
    ON u_flood.stations_list_mview USING gist
    (centroid)
    TABLESPACE flood_indexes;
CREATE INDEX idx_stations_list_mview_river_id
    ON u_flood.stations_list_mview USING btree
    (river_id COLLATE pg_catalog."default")
    TABLESPACE flood_indexes;
	-- Index: idx_stations_list_unique

-- DROP INDEX u_flood.idx_stations_list_unique;

CREATE UNIQUE INDEX idx_stations_list_unique
    ON u_flood.stations_list_mview USING btree
    (id ASC NULLS LAST)
    TABLESPACE flood_indexes;
