-- View: u_flood.stations_overview_mview
CREATE MATERIALIZED VIEW IF NOT EXISTS u_flood.stations_overview_mview
TABLESPACE pg_default
AS
WITH ranked_all_value_summaries AS (
  -- all values for a station ranked by the value timestamp
  -- this is used by subsequent CTE's to get the two most recent values
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
    rank() OVER (PARTITION BY tvp.rloi_id, tvp.qualifier ORDER BY tv.value_timestamp DESC, tv.telemetry_value_id DESC) AS parent_rank
  FROM sls_telemetry_value tv
    JOIN sls_telemetry_value_parent tvp ON tv.telemetry_value_parent_id = tvp.telemetry_value_parent_id
  WHERE lower(tvp.parameter) = 'water level'::text
  AND lower(tvp.units) !~~ '%deg%'::text
  AND lower(tvp.qualifier) !~~ '%height%'::text
  AND lower(tvp.qualifier) <> 'crest tapping'::text
),
latest_value_summaries_with_previous_value AS (
  -- add this intermediate CTE so we only calculate the previous value for the two most recent values.
  -- a station may have hundreds of values so this gives a significant performance benefit.
  -- parent rank needs to be 1 or 2 so that lag can get the two most recent values
  -- if we just get the most recent value (i.e. parent_rank = 1) then the previous value will always be null
  SELECT
    rloi_id,
    parameter,
    qualifier,
    units,
    telemetry_value_id,
    telemetry_value_parent_id,
    value,
    processed_value,
    value_timestamp,
    error,
    lag(processed_value, 1) OVER (PARTITION BY rloi_id, qualifier ORDER BY rloi_id, qualifier, value_timestamp ASC) AS previous_value,
    parent_rank
  FROM ranked_all_value_summaries
  WHERE parent_rank in (1,2)
),
latest_value_summary_with_trend AS (
  -- in order to calculate trend from the previous value this separate CTE is needed
  -- only need to do this for the most recent value
  SELECT
    rloi_id,
    parameter,
    qualifier,
    units,
    telemetry_value_id,
    telemetry_value_parent_id,
    value,
    processed_value,
    CASE
      WHEN ROUND(processed_value,2) > ROUND(previous_value,2) THEN 'rising'
      WHEN ROUND(processed_value,2) < ROUND(previous_value,2) THEN 'falling'
      ELSE 'steady'
    END AS trend,
    value_timestamp,
    error
  FROM latest_value_summaries_with_previous_value
  WHERE parent_rank = 1
),
record_breached AS (
  -- stations which have breached the value of their previous maximum level
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
    latest.trend,
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
     LEFT JOIN latest_value_summary_with_trend latest ON s.rloi_id = latest.rloi_id AND s.qualifier = s.qualifier
     AND (s.qualifier = 'u'::text AND lower(latest.qualifier) !~~ '%downstream%'::text
     OR s.qualifier = 'd'::text AND lower(latest.qualifier) ~~ '%downstream%'::text)
     LEFT JOIN record_breached rb ON rb.rloi_id = s.rloi_id AND rb.qualifier = s.qualifier
     LEFT JOIN ffoi_station fs ON fs.rloi_id = s.rloi_id
WITH DATA;

ALTER TABLE IF EXISTS u_flood.stations_overview_mview
    OWNER TO u_flood;


CREATE UNIQUE INDEX idx_stations_overview_unique
    ON u_flood.stations_overview_mview USING btree
    (rloi_id, direction COLLATE pg_catalog."default", parameter COLLATE pg_catalog."default", qualifier COLLATE pg_catalog."default")
    TABLESPACE flood_indexes;

