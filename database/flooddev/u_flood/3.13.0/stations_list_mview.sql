-- View: u_flood.stations_list_mview

DROP MATERIALIZED VIEW IF EXISTS u_flood.stations_list_mview;

CREATE MATERIALIZED VIEW u_flood.stations_list_mview
TABLESPACE flood_tables
AS
	-- This mview combines the telemetry stations and rainfall stations into the same schema to be used for the
	-- river-and-sea-level list, it could also be used for the map as well so there is only one call to the database for the data.

	select *,
	-- rainfall specific values
	null as day_total,
	null as six_hr_total,
	null as one_hr_total
	from u_flood.rivers_mview
	union
	select 
	'rainfall-' || region as river_id,
	'Rainfall ' || region as river_name,
	false as navigable,
	5 as view_rank,
	null as "rank",
	null as rloi_id,
	null as up,
	null as down,
	station_reference as telemetry_id,
	region,
	null as catchment,
	null as wiski_river_name,
	station_name as agency_name,
	station_name as external_name,
	'R' as station_type,
	'Active' as status,
	null as qualifier,
	false as iswales,
	value,
	value_timestamp,
	null as value_erred,
	null as percentile_5,
	null as percentile_95,
	centroid,
	st_x(centroid) AS lon,
	st_y(centroid) AS lat,
	day_total,
	six_hr_total,
	one_hr_total
	from u_flood.rainfall_stations_mview
	where region <> 'Wales'
	order by view_rank, river_id, rank, agency_name
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