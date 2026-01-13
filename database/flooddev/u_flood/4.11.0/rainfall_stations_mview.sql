-- 4.11.0 - Rebuild rainfall_stations_mview with deduplication of timestamp values
-- Fixes double-counting in 1h / 6h / 24h totals when multiple identical
-- rainfall readings exist for the same (station, region, timestamp)  as identified in FSR-1564

DROP MATERIALIZED VIEW IF EXISTS stations_list_mview;
DROP MATERIALIZED VIEW IF EXISTS rainfall_stations_mview;

CREATE MATERIALIZED VIEW rainfall_stations_mview AS

WITH dedup_values AS (
    SELECT
        p.station,
        p.region,
        p.telemetry_value_parent_id,
        v.value_timestamp,
        NULLIF(v.value, 'NaN') AS value,
        p.end_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY p.station, p.region, v.value_timestamp
            ORDER BY p.end_timestamp DESC, p.telemetry_value_parent_id DESC
        ) AS rn
    FROM sls_telemetry_value_parent p
    JOIN sls_telemetry_value v
      ON v.telemetry_value_parent_id = p.telemetry_value_parent_id
    WHERE p.parameter = 'Rainfall'
),
latest_timestamp AS (
    SELECT 
        station, 
        region,
        MAX(value_timestamp) AS latest_timestamp
    FROM dedup_values
    WHERE rn = 1
    GROUP BY station, region
),
day_total AS (
    SELECT 
        d.station,
        d.region,
        SUM(d.value) AS total
    FROM dedup_values d
    JOIN latest_timestamp lt
      ON lt.station = d.station AND lt.region = d.region
    WHERE d.rn = 1
      AND d.value_timestamp > lt.latest_timestamp - INTERVAL '1 day'
    GROUP BY d.station, d.region
),
six_hr_total AS (
    SELECT 
        d.station,
        d.region,
        SUM(d.value) AS total
    FROM dedup_values d
    JOIN latest_timestamp lt
      ON lt.station = d.station AND lt.region = d.region
    WHERE d.rn = 1
      AND d.value_timestamp > lt.latest_timestamp - INTERVAL '6 hours'
    GROUP BY d.station, d.region
),
one_hr_total AS (
    SELECT 
        d.station,
        d.region,
        SUM(d.value) AS total
    FROM dedup_values d
    JOIN latest_timestamp lt
      ON lt.station = d.station AND lt.region = d.region
    WHERE d.rn = 1
      AND d.value_timestamp > lt.latest_timestamp - INTERVAL '1 hour'
    GROUP BY d.station, d.region
),
latest_parent AS (
    SELECT DISTINCT ON (station, region)
        station,
        region,
        telemetry_value_parent_id,
        data_type,
        period,
        units
    FROM sls_telemetry_value_parent
    WHERE parameter = 'Rainfall'
    ORDER BY station, region, end_timestamp DESC
),
latest_value AS (
    SELECT DISTINCT ON (telemetry_value_parent_id)
        telemetry_value_parent_id,
        NULLIF(value, 'NaN') AS value,
        value_timestamp
    FROM sls_telemetry_value
    ORDER BY telemetry_value_parent_id, value_timestamp DESC
)
SELECT
    s.telemetry_station_id,
    s.station_reference,
    s.region,
    s.station_name,
    s.ngr,
    s.easting,
    s.northing,
    ST_Transform(
        ST_SetSRID(ST_MakePoint(s.easting::double precision, s.northing::double precision), 27700),
        4326
    ) AS centroid,
    p.data_type,
    p.period,
    p.units,
    v.telemetry_value_parent_id,
    v.value,
    v.value_timestamp,
    day_total.total AS day_total,
    six_hr_total.total AS six_hr_total,
    one_hr_total.total AS one_hr_total,
    'R'::text AS type
FROM sls_telemetry_station s
JOIN latest_parent p
  ON p.station = s.station_reference AND p.region = s.region
JOIN latest_value v
  ON v.telemetry_value_parent_id = p.telemetry_value_parent_id
LEFT JOIN day_total
  ON day_total.station = s.station_reference AND day_total.region = s.region
LEFT JOIN six_hr_total
  ON six_hr_total.station = s.station_reference AND six_hr_total.region = s.region
LEFT JOIN one_hr_total
  ON one_hr_total.station = s.station_reference AND one_hr_total.region = s.region
ORDER BY s.region, s.station_name;
