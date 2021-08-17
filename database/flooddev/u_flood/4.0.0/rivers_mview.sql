-- View: u_flood.rivers_mview

DROP MATERIALIZED VIEW u_flood.rivers_mview CASCADE;

CREATE MATERIALIZED VIEW u_flood.rivers_mview
TABLESPACE flood_tables
AS
 SELECT
 		row_number() OVER () AS id,
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
    rs.calc_rank AS rank,
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
     LEFT JOIN ( SELECT rs1.id,
            rs1.name,
            rs1.rloi_id,
            rs1.rank,
            rank() OVER (PARTITION BY rs1.id ORDER BY rs1.rank) AS calc_rank
           FROM river_stations rs1
             JOIN telemetry_context tc ON rs1.rloi_id = tc.rloi_id) rs ON rs.rloi_id = ss.rloi_id
     LEFT JOIN ( SELECT rs1.id,
            rs1.name,
            rs1.rloi_id,
            rs1.rank,
            rank() OVER (PARTITION BY rs1.id ORDER BY rs1.rank) AS calc_rank
           FROM river_stations rs1
             JOIN telemetry_context tc ON rs1.rloi_id = tc.rloi_id) up ON rs.id::text = up.id::text AND up.calc_rank = (rs.calc_rank - 1)
     LEFT JOIN ( SELECT rs1.id,
            rs1.name,
            rs1.rloi_id,
            rs1.rank,
            rank() OVER (PARTITION BY rs1.id ORDER BY rs1.rank) AS calc_rank
           FROM river_stations rs1
             JOIN telemetry_context tc ON rs1.rloi_id = tc.rloi_id) down ON rs.id::text = down.id::text AND down.calc_rank = (rs.calc_rank + 1)
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
	-- Index: idx_rivers_unique

-- DROP INDEX u_flood.idx_rivers_unique;

CREATE UNIQUE INDEX idx_rivers_unique
    ON u_flood.rivers_mview USING btree
    (id ASC NULLS LAST)
    TABLESPACE flood_indexes;
