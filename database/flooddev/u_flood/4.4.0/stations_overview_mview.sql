DROP MATERIALIZED VIEW IF EXISTS u_flood.stations_list_mview;
DROP MATERIALIZED VIEW IF EXISTS u_flood.impact_mview;
DROP MATERIALIZED VIEW IF EXISTS u_flood.rivers_mview;
DROP MATERIALIZED VIEW IF EXISTS u_flood.stations_overview_mview;

-- View: u_flood.stations_overview_mview
CREATE MATERIALIZED VIEW IF NOT EXISTS u_flood.stations_overview_mview
TABLESPACE pg_default
AS
WITH all_values AS (
  SELECT
	tvp.rloi_id,
    tvp.parameter,
    tvp.qualifier,
    tvp.units,
	tv.telemetry_value_id,
    tv.telemetry_value_parent_id,
    tv.value,
    tv.processed_value,
    tv.value_timestamp,
    tv.error,
    rank() OVER (PARTITION BY tv.telemetry_value_parent_id ORDER BY tv.value_timestamp DESC) AS value_rank
  FROM sls_telemetry_value tv
  JOIN sls_telemetry_value_parent tvp ON tv.telemetry_value_parent_id = tvp.telemetry_value_parent_id
	WHERE lower(tvp.parameter) = 'water level'::text 
	AND lower(tvp.units) !~~ '%deg%'::text 
	AND lower(tvp.qualifier) !~~ '%height%'::text 
),
latest_value AS (
  SELECT * FROM all_values WHERE value_rank = 1
),
all_value_parents AS (
SELECT
	p.rloi_id,
	lv.parameter,
	lv.qualifier,
	lv.units,
	lv.telemetry_value_id,
	lv.telemetry_value_parent_id,
	lv.value,
	lv.processed_value,
	lv.value_timestamp,
	lv.error,
	lv.value_rank,
  -- need to understand partitions much more
  lag(lv.processed_value, 1) OVER (PARTITION BY p.rloi_id ORDER BY lv.value_timestamp ASC) AS previous_value,
	rank() OVER (PARTITION BY p.rloi_id, p.qualifier ORDER BY lv.value_timestamp DESC, lv.telemetry_value_id DESC) AS parent_rank
FROM latest_value lv
	JOIN sls_telemetry_value_parent p ON lv.telemetry_value_parent_id = p.telemetry_value_parent_id
WHERE lv.value_rank = 1 
	AND lower(p.parameter) = 'water level'::text
	AND lower(p.units) !~~ '%deg%'::text 
	AND lower(p.qualifier) !~~ '%height%'::text
	AND lower(p.qualifier) <> 'crest tapping'::text
),
latest_value_parents AS (
	SELECT * FROM all_value_parents WHERE all_value_parents.parent_rank = 1
),
xyz AS (
	SELECT
		s_1.rloi_id,
		s_1.qualifier
	FROM station_split_mview s_1
		JOIN sls_telemetry_value_parent p ON s_1.rloi_id = p.rloi_id AND (s_1.qualifier = 'u'::text AND lower(p.qualifier) !~~ '%downstream%'::text OR s_1.qualifier = 'd'::text AND lower(p.qualifier) ~~ '%downstream%'::text)
		JOIN sls_telemetry_value v ON p.telemetry_value_parent_id = v.telemetry_value_parent_id
	WHERE NOT v.error
		AND v.processed_value <> 'NaN'::numeric
		AND COALESCE(v.processed_value, 0::numeric) > s_1.por_max_value
		AND lower(p.parameter) = 'water level'::text
		AND lower(p.units) !~~ '%deg%'::text
		AND lower(p.qualifier) !~~ '%height%'::text
		AND lower(p.qualifier) <> 'crest tapping'::text
    GROUP BY s_1.rloi_id, s_1.qualifier
)


SELECT s.rloi_id,
    s.telemetry_id,
    s.wiski_id,
    s.qualifier AS direction,
    s.station_type,
    s.agency_name,
    s.area,
    s.catchment,
    s.status,
    latest.parameter,
    latest.qualifier,
    latest.units,
    latest.value,
    latest.processed_value,
    latest.value_timestamp,
    latest.error,
    latest.previous_value,
    CASE
      WHEN latest.processed_value > latest.previous_value THEN 'rising'
      WHEN latest.processed_value < latest.previous_value THEN 'falling'
      ELSE 'steady'
    END AS trend,
    now() - latest.value_timestamp AS age,
    rb.rloi_id IS NOT NULL AS por_max_breached,
        CASE
            WHEN NOT latest.error AND latest.processed_value <> 'NaN'::numeric AND COALESCE(latest.processed_value, 0::numeric) >= s.percentile_5 THEN true
            ELSE false
        END AS at_risk,
    fs.rloi_id IS NOT NULL AS forecast,
        CASE
            WHEN s.station_type = 'C'::bpchar THEN ''::text
            WHEN latest.processed_value < s.percentile_95 THEN 'low'::text
            WHEN latest.processed_value >= s.percentile_5 THEN 'high'::text
            ELSE 'normal'::text
        END AS level,
    s.percentile_5,
    s.percentile_95
   FROM station_split_mview s
     LEFT JOIN latest_value_parents latest ON s.rloi_id = latest.rloi_id
	 	AND (s.qualifier = 'u'::text
		AND lower(latest.qualifier) !~~ '%downstream%'::text 
		OR s.qualifier = 'd'::text 
		AND lower(latest.qualifier) ~~ '%downstream%'::text)
     LEFT JOIN xyz rb ON rb.rloi_id = s.rloi_id AND rb.qualifier = s.qualifier
     LEFT JOIN ffoi_station fs ON fs.rloi_id = s.rloi_id
WITH DATA;

ALTER TABLE IF EXISTS u_flood.stations_overview_mview
    OWNER TO u_flood;


CREATE UNIQUE INDEX idx_stations_overview_unique
    ON u_flood.stations_overview_mview USING btree
    (rloi_id, direction COLLATE pg_catalog."default", parameter COLLATE pg_catalog."default", qualifier COLLATE pg_catalog."default")
    TABLESPACE flood_indexes;

-- View: u_flood.rivers_mview

CREATE MATERIALIZED VIEW IF NOT EXISTS u_flood.rivers_mview
TABLESPACE flood_tables
AS
 SELECT
        CASE
            WHEN rs.river_id IS NOT NULL THEN rs.river_id::text
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
            WHEN rs.river_id IS NOT NULL THEN 1
            ELSE
            CASE
                WHEN ss.station_type = 'C'::bpchar THEN 2
                WHEN ss.station_type = 'G'::bpchar THEN 3
                ELSE 4
            END
        END AS view_rank,
    rs.qualified_name AS river_qualified_name,
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
    so.trend,
    so.value_timestamp,
    so.error AS value_erred,
    so.percentile_5,
    so.percentile_95,
    ss.centroid,
    st_x(ss.centroid) AS lon,
    st_y(ss.centroid) AS lat,
    row_number() OVER () AS id
   FROM station_split_mview ss
     JOIN stations_overview_mview so ON ss.rloi_id = so.rloi_id AND ss.qualifier = so.direction
     LEFT JOIN ( SELECT rs1.river_id,
            r.name,
            r.qualified_name,
            rs1.rloi_id,
            rs1.rank,
            rank() OVER (PARTITION BY rs1.river_id ORDER BY rs1.rank) AS calc_rank
           FROM river_stations rs1
             JOIN telemetry_context tc ON rs1.rloi_id = tc.rloi_id
             JOIN river r ON rs1.river_id::text = r.id::text) rs ON rs.rloi_id = ss.rloi_id
     LEFT JOIN ( SELECT rs1.river_id,
            rs1.rloi_id,
            rs1.rank,
            rank() OVER (PARTITION BY rs1.river_id ORDER BY rs1.rank) AS calc_rank
           FROM river_stations rs1
             JOIN telemetry_context tc ON rs1.rloi_id = tc.rloi_id) up ON rs.river_id::text = up.river_id::text AND up.calc_rank = (rs.calc_rank - 1)
     LEFT JOIN ( SELECT rs1.river_id,
            rs1.rloi_id,
            rs1.rank,
            rank() OVER (PARTITION BY rs1.river_id ORDER BY rs1.rank) AS calc_rank
           FROM river_stations rs1
             JOIN telemetry_context tc ON rs1.rloi_id = tc.rloi_id) down ON rs.river_id::text = down.river_id::text AND down.calc_rank = (rs.calc_rank + 1)
  WHERE lower(ss.status) <> 'closed'::text AND (lower(ss.region) <> 'wales'::text OR (ss.catchment = ANY (ARRAY['Dee'::text, 'Severn Uplands'::text, 'Wye'::text])))
  ORDER BY (
        CASE
            WHEN rs.river_id IS NOT NULL THEN 1
            ELSE
            CASE
                WHEN ss.station_type = 'C'::bpchar THEN 2
                WHEN ss.station_type = 'G'::bpchar THEN 3
                ELSE 4
            END
        END), (
        CASE
            WHEN rs.river_id IS NOT NULL THEN rs.river_id::text
            ELSE
            CASE
                WHEN ss.station_type = 'C'::bpchar THEN 'Sea Levels'::text
                WHEN ss.station_type = 'G'::bpchar THEN 'Groundwater Levels'::text
                ELSE 'orphaned-'::text || ss.wiski_river_name
            END
        END), rs.rank, ss.external_name, ss.qualifier DESC
WITH DATA;

ALTER TABLE IF EXISTS u_flood.rivers_mview
    OWNER TO u_flood;

CREATE INDEX idx_rivers_mview_geom_gist
    ON u_flood.rivers_mview USING gist
    (centroid)
    TABLESPACE flood_indexes;
CREATE INDEX idx_rivers_mview_river_id
    ON u_flood.rivers_mview USING btree
    (river_id COLLATE pg_catalog."default")
    TABLESPACE flood_indexes;
CREATE UNIQUE INDEX idx_rivers_unique
    ON u_flood.rivers_mview USING btree
    (id)
    TABLESPACE flood_indexes;


-- View: u_flood.stations_list_mview

CREATE MATERIALIZED VIEW IF NOT EXISTS u_flood.stations_list_mview
TABLESPACE flood_tables
AS
 SELECT list.river_id,
    list.river_name,
    list.river_qualified_name,
    list.navigable,
    list.view_rank,
    list.rank,
    list.rloi_id,
    list.up,
    list.down,
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
   FROM ( SELECT rivers_mview.river_id,
            rivers_mview.river_name,
            rivers_mview.river_qualified_name,
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
         SELECT 'rainfall-'::text || rainfall_stations_mview.region AS river_id,
            'Rainfall '::text || rainfall_stations_mview.region AS river_name,
            NULL::text AS river_qualified_name,
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
  ORDER BY 4, 1, 5, 13) list
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





-- View: u_flood.impact_mview


CREATE MATERIALIZED VIEW IF NOT EXISTS u_flood.impact_mview
TABLESPACE flood_tables
AS
 SELECT i.id AS impactid,
    (tc.wiski_river_name || ' at '::text) || tc.agency_name AS gauge,
    i.rloi_id AS rloiid,
    i.value,
    i.units,
    i.geom,
    st_asgeojson(i.geom) AS coordinates,
    i.comment,
    i.short_name AS shortname,
    i.description,
    i.type,
    i.obs_flood_year AS obsfloodyear,
    i.obs_flood_month AS obsfloodmonth,
    i.source,
    s.processed_value AS telemetrylatest,
    s.processed_value >= i.value AS telemetryactive,
    ffoi.value AS forecastmax,
    ffoi.value >= i.value AND fs.rloi_id IS NOT NULL AS forecastactive
   FROM impact i
     JOIN telemetry_context tc ON i.rloi_id = tc.rloi_id
     LEFT JOIN ( SELECT DISTINCT ON (stations_overview_mview.rloi_id) stations_overview_mview.rloi_id,
            stations_overview_mview.telemetry_id,
            stations_overview_mview.wiski_id,
            stations_overview_mview.direction,
            stations_overview_mview.station_type,
            stations_overview_mview.agency_name,
            stations_overview_mview.area,
            stations_overview_mview.catchment,
            stations_overview_mview.status,
            stations_overview_mview.parameter,
            stations_overview_mview.qualifier,
            stations_overview_mview.units,
            stations_overview_mview.value,
            stations_overview_mview.processed_value,
            stations_overview_mview.value_timestamp,
            stations_overview_mview.error,
            stations_overview_mview.age,
            stations_overview_mview.por_max_breached,
            stations_overview_mview.at_risk,
            stations_overview_mview.forecast,
            stations_overview_mview.level,
            stations_overview_mview.percentile_5,
            stations_overview_mview.percentile_95
           FROM stations_overview_mview) s ON s.rloi_id = i.rloi_id AND s.direction = 'u'::text
     LEFT JOIN ffoi_max ffoi ON ffoi.telemetry_id = s.telemetry_id
     LEFT JOIN ffoi_station fs ON i.rloi_id = fs.rloi_id
  WHERE tc.status = 'Active'::text
WITH DATA;

ALTER TABLE IF EXISTS u_flood.impact_mview
    OWNER TO u_flood;


CREATE UNIQUE INDEX idx_impact_unique
    ON u_flood.impact_mview USING btree
    (impactid)
    TABLESPACE flood_indexes;
