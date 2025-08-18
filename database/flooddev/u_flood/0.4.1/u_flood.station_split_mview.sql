-- Materialized View: u_flood.station_split_mview

-- DROP MATERIALIZED VIEW u_flood.station_split_mview;

-- Select * from u_flood.station_split_mview where rloi_id = 7206 and qualifier = 'd'

SET search_path = u_flood, postgis, topology, public;

CREATE MATERIALIZED VIEW u_flood.station_split_mview AS 

SELECT *
FROM
(

select rloi_id, station_type, 'u' as qualifier,
tc.telemetry_context_id,
    tc.telemetry_id,
    tc.wiski_id,
    tc.post_process,
    tc.subtract,
    tc.region,
    tc.area,
    tc.catchment,
    tc.display_region,
    tc.display_area,
    tc.display_catchment,
    tc.agency_name,
    tc.external_name,
    tc.location_info,
    tc.x_coord_actual,
    tc.y_coord_actual,
    tc.actual_ngr,
    tc.x_coord_display,
    tc.y_coord_display,
    tc.site_max,
    tc.wiski_river_name,
    tc.date_open,
    tc.stage_datum,
    tc.period_of_record,
    tc.por_max_value,
    tc.date_por_max,
    tc.highest_level,
    tc.date_highest_level,
    tc.por_min_value,
    tc.date_por_min,
    tc.percentile_5,
    tc.percentile_95,
    tc.comments,
    tc.status,
    tc.status_reason,
    tc.status_date,
    st_asgeojson(st_transform(st_setsrid(st_makepoint(tc.x_coord_actual::double precision, tc.y_coord_actual::double precision), 27700), 4326)) AS coordinates,
    st_transform(st_setsrid(st_makepoint(tc.x_coord_actual::double precision, tc.y_coord_actual::double precision), 27700), 4326)::geography AS geography,
    st_transform(st_setsrid(st_makepoint(tc.x_coord_actual::double precision, tc.y_coord_actual::double precision), 27700), 4326) AS centroid
FROM u_flood.telemetry_context tc
union
select rloi_id, station_type, 'd' as qualifier,
tc.telemetry_context_id,
    tc.telemetry_id,
    tc.wiski_id,
    tc.post_process,
    tc.subtract,
    tc.region,
    tc.area,
    tc.catchment,
    tc.display_region,
    tc.display_area,
    tc.display_catchment,
    tc.agency_name,
    tc.external_name,
    tc.location_info,
    tc.x_coord_actual,
    tc.y_coord_actual,
    tc.actual_ngr,
    tc.x_coord_display,
    tc.y_coord_display,
    tc.site_max,
    tc.wiski_river_name,
    tc.date_open,
    tc.d_stage_datum as stage_datum,
    tc.d_period_of_record as period_of_record,
    tc.d_por_max_value as por_max_value,
    tc.d_date_por_max as date_por_max,
    tc.d_highest_level as highest_level,
    tc.d_date_highest_level as date_highest_level,
    tc.d_por_min_value as por_min_value,
    tc.d_date_por_min as date_por_min,
    tc.d_percentile_5 as percentile_5,
    tc.d_percentile_95 as percentile_95,
    tc.d_comments as comments,
    tc.status,
    tc.status_reason,
    tc.status_date,
    st_asgeojson(st_transform(st_setsrid(st_makepoint(tc.x_coord_actual::double precision, tc.y_coord_actual::double precision), 27700), 4326)) AS coordinates,
    st_transform(st_setsrid(st_makepoint(tc.x_coord_actual::double precision, tc.y_coord_actual::double precision), 27700), 4326)::geography AS geography,
    st_transform(st_setsrid(st_makepoint(tc.x_coord_actual::double precision, tc.y_coord_actual::double precision), 27700), 4326) AS centroid
FROM u_flood.telemetry_context tc
where tc.station_type = 'M'
) as stations
WITH DATA;

ALTER TABLE u_flood.station_split_mview
  OWNER TO u_flood;
