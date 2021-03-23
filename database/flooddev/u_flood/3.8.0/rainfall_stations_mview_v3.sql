-- View: u_flood.rainfall_stations_mview

DROP MATERIALIZED VIEW u_flood.rainfall_stations_mview;

-- select * from u_flood.rainfall_stations_mview order by value_timestamp desc;
-- REFRESH MATERIALIZED VIEW u_flood.rainfall_stations_mview WITH DATA;

CREATE MATERIALIZED VIEW IF NOT EXISTS u_flood.rainfall_stations_mview
TABLESPACE flood_tables
AS

	Select s.*,
	st_transform(st_setsrid(st_makepoint((s.easting)::double precision, (s.northing)::double precision), 27700), 4326) AS centroid, 
	p.data_type, 
	p.period,
	p.units,
	v.*,
	daysum.total as day_total,
	sixhr.total as six_hr_total,
	onehr.total as one_hr_total,
	'R' as type
	From u_flood.sls_telemetry_station s
	-- get latest Rainfall parent
	inner join (select distinct on (station, region) station, region, telemetry_value_parent_id, data_type, period, units
	from u_flood.sls_telemetry_value_parent
	where parameter = 'Rainfall'
	order by station, region, end_timestamp desc) as p on s.station_reference = p.station and s.region = p.region
	--get latest value from that parent
	inner join (
		select distinct on (telemetry_value_parent_id) telemetry_value_parent_id, nullif(value, 'NaN') as "value", value_timestamp
		from u_flood.sls_telemetry_value v 
		order by telemetry_value_parent_id, value_timestamp desc
	) v on v.telemetry_value_parent_id = p.telemetry_value_parent_id
	-- get last 24 hours values sum
	left join (
		select sum(nullif(value, 'NaN')) as total, p.station, p.region 
		from u_flood.sls_telemetry_value_parent p
		inner join u_flood.sls_telemetry_value v on p.telemetry_value_parent_id = v.telemetry_value_parent_id
		-- get latest value date so we can get sum of values since that point in time
		inner join (select p.region, p.station, max(v.value_timestamp) as latest_timestamp
			from u_flood.sls_telemetry_value_parent p
			inner join u_flood.sls_telemetry_value v on p.telemetry_value_parent_id = v.telemetry_value_parent_id
			where p.parameter = 'Rainfall'::text
			group by p.region, p.station) as latest on latest.region = p.region and latest.station = p.station
		where v.value_timestamp > (latest.latest_timestamp - '1 day'::interval) and p.parameter = 'Rainfall'
		group by p.station, p.region
	) daysum on daysum.station = s.station_reference and daysum.region = s.region
	-- get last 6 hours values sum
	left join (
		select sum(nullif(value, 'NaN')) as total, p.station, p.region 
		from u_flood.sls_telemetry_value_parent p
		inner join u_flood.sls_telemetry_value v on p.telemetry_value_parent_id = v.telemetry_value_parent_id
		-- get latest value date so we can get sum of values since that point in time
		inner join (select p.region, p.station, max(v.value_timestamp) as latest_timestamp
			from u_flood.sls_telemetry_value_parent p
			inner join u_flood.sls_telemetry_value v on p.telemetry_value_parent_id = v.telemetry_value_parent_id
			where p.parameter = 'Rainfall'::text
			group by p.region, p.station) as latest on latest.region = p.region and latest.station = p.station
		where v.value_timestamp > (latest.latest_timestamp - '6 hour'::interval) and p.parameter = 'Rainfall'
		group by p.station, p.region
	) sixhr on sixhr.station = s.station_reference and sixhr.region = s.region
    -- get last 1 hour values sum
	left join (
		select sum(nullif(value, 'NaN')) as total, p.station, p.region 
		from u_flood.sls_telemetry_value_parent p
		inner join u_flood.sls_telemetry_value v on p.telemetry_value_parent_id = v.telemetry_value_parent_id
		-- get latest value date so we can get sum of values since that point in time
		inner join (select p.region, p.station, max(v.value_timestamp) as latest_timestamp
			from u_flood.sls_telemetry_value_parent p
			inner join u_flood.sls_telemetry_value v on p.telemetry_value_parent_id = v.telemetry_value_parent_id
			where p.parameter = 'Rainfall'::text
			group by p.region, p.station) as latest on latest.region = p.region and latest.station = p.station
		where v.value_timestamp > (latest.latest_timestamp - '1 hour'::interval) and p.parameter = 'Rainfall'
		group by p.station, p.region
	) onehr on onehr.station = s.station_reference and onehr.region = s.region
	order by s.region, s.station_name

WITH DATA;

ALTER TABLE u_flood.rainfall_stations_mview
    OWNER TO u_flood;


CREATE INDEX IF NOT EXISTS idx_rainfall_stations_mview_geom_gist
    ON u_flood.rainfall_stations_mview USING gist
    (centroid)
    TABLESPACE flood_indexes;
