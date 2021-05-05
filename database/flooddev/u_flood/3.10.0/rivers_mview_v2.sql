-- View: u_flood.rivers_mview

DROP MATERIALIZED VIEW u_flood.rivers_mview;

CREATE MATERIALIZED VIEW u_flood.rivers_mview
TABLESPACE flood_tables
AS
 SELECT
        CASE
            WHEN rs.id IS NOT NULL THEN rs.id::text
            ELSE
            CASE
                WHEN ss.station_type = 'C'::bpchar THEN 'Sea Levels'::text
                WHEN ss.station_type = 'G'::bpchar THEN 'Groundwater Levels'::text
                ELSE 'orphaned-'::text || ss.wiski_river_name
            END
        END AS river_id,
        CASE
            WHEN rs.name IS NOT NULL THEN rs.name::text
            ELSE
            CASE
                WHEN ss.station_type = 'C'::bpchar THEN 'Sea Levels'::text
                WHEN ss.station_type = 'G'::bpchar THEN 'Groundwater Levels'::text
                ELSE 'orphaned-'::text || ss.wiski_river_name
            END
        END AS river_name,
        CASE
            WHEN rs.name IS NOT NULL THEN true
            ELSE false
        END AS navigable,
        CASE
            WHEN rs.id IS NOT NULL THEN 1
            ELSE
            CASE
                WHEN ss.station_type = 'C'::bpchar THEN 2
                WHEN ss.station_type = 'G'::bpchar THEN 3
                ELSE 4
            END
        END AS view_rank,
    rs.calc_rank as "rank",
    ss.rloi_id,
    up.rloi_id AS up,
    down.rloi_id AS down,
    ss.telemetry_id,
    ss.region,
    ss.catchment,
    ss.wiski_river_name,
    ss.agency_name,
    ss.external_name,
    ss.station_type,
    ss.status,
    ss.qualifier,
    lower(ss.region) = 'wales'::text OR (ss.rloi_id = ANY (ARRAY[4162, 4170, 4173, 4174, 4176])) AS iswales,
    so.processed_value AS value,
    so.value_timestamp,
    so.error AS value_erred,
    so.percentile_5,
    so.percentile_95,
    ss.centroid,
    st_x(ss.centroid) AS lon,
    st_y(ss.centroid) AS lat
   FROM station_split_mview ss
     JOIN stations_overview_mview so ON ss.rloi_id = so.rloi_id AND ss.qualifier = so.direction
	 LEFT JOIN (select rs1.*, RANK() OVER(PARTITION BY id ORDER BY rs1.rank) as calc_rank
				from u_flood.river_stations rs1 --order by id, calc_rank
				inner join u_flood.telemetry_context tc on rs1.rloi_id = tc.rloi_id --handles deleted stations
			   ) as rs on rs.rloi_id = ss.rloi_id 
	 -- Need to get the next less than rank if station exists
	 LEFT JOIN (select rs1.*, RANK() OVER(PARTITION BY id ORDER BY rs1.rank) as calc_rank
			from u_flood.river_stations rs1 --order by id, calc_rank
			inner join u_flood.telemetry_context tc on rs1.rloi_id = tc.rloi_id --handles deleted stations
		   ) as up on rs.id::text = up.id::text and up.calc_rank = (rs.calc_rank - 1)
	 -- Need to get the next greater than rank
	 LEFT JOIN (select rs1.*, RANK() OVER(PARTITION BY id ORDER BY rs1.rank) as calc_rank
		from u_flood.river_stations rs1 --order by id, calc_rank
		inner join u_flood.telemetry_context tc on rs1.rloi_id = tc.rloi_id --handles deleted stations
	   ) as down on rs.id::text = down.id::text and down.calc_rank = (rs.calc_rank + 1)
  WHERE lower(ss.status) <> 'closed'::text AND (lower(ss.region) <> 'wales'::text OR (ss.catchment = ANY (ARRAY['Dee'::text, 'Severn Uplands'::text, 'Wye'::text])))
  ORDER BY (
        CASE
            WHEN rs.id IS NOT NULL THEN 1
            ELSE
            CASE
                WHEN ss.station_type = 'C'::bpchar THEN 2
                WHEN ss.station_type = 'G'::bpchar THEN 3
                ELSE 4
            END
        END), (
        CASE
            WHEN rs.id IS NOT NULL THEN rs.id::text
            ELSE
            CASE
                WHEN ss.station_type = 'C'::bpchar THEN 'Sea Levels'::text
                WHEN ss.station_type = 'G'::bpchar THEN 'Groundwater Levels'::text
                ELSE 'orphaned-'::text || ss.wiski_river_name
            END
        END), rs.rank, ss.external_name, ss.qualifier DESC
WITH DATA;

ALTER TABLE u_flood.rivers_mview
    OWNER TO u_flood;


CREATE INDEX idx_rivers_mview_geom_gist
    ON u_flood.rivers_mview USING gist
    (centroid)
    TABLESPACE flood_indexes;
CREATE INDEX idx_rivers_mview_river_id
    ON u_flood.rivers_mview USING btree
    (river_id COLLATE pg_catalog."default")
    TABLESPACE flood_indexes;