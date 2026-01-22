-- 4.11.0 - Rebuild rainfall_stations_mview with deduplication of timestamp values
-- Fixes double-counting in 1h / 6h / 24h totals when multiple identical
-- rainfall readings exist for the same (station, region, timestamp) as identified in FSR-1564

DROP MATERIALIZED VIEW IF EXISTS stations_list_mview;
DROP MATERIALIZED VIEW IF EXISTS rainfall_stations_mview;

CREATE MATERIALIZED VIEW rainfall_stations_mview AS
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
    daysum.total AS day_total,
    sixhr.total AS six_hr_total,
    onehr.total AS one_hr_total,
    'R'::text AS type
FROM sls_telemetry_station s
JOIN (
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
) p ON s.station_reference = p.station AND s.region = p.region
JOIN (
    SELECT DISTINCT ON (telemetry_value_parent_id)
        telemetry_value_parent_id,
        NULLIF(value, 'NaN') AS value,
        value_timestamp
    FROM sls_telemetry_value
    ORDER BY telemetry_value_parent_id, value_timestamp DESC
) v ON v.telemetry_value_parent_id = p.telemetry_value_parent_id
LEFT JOIN (
    -- Day total with deduplication
    SELECT 
        p_1.station,
        p_1.region,
        SUM(dedup.value) AS total
    FROM sls_telemetry_value_parent p_1
    JOIN (
        -- Deduplicate: keep only one row per (station, region, timestamp)
        SELECT DISTINCT ON (p_2.station, p_2.region, v_1.value_timestamp)
            p_2.station,
            p_2.region,
            v_1.value_timestamp,
            NULLIF(v_1.value, 'NaN') AS value
        FROM sls_telemetry_value_parent p_2
        JOIN sls_telemetry_value v_1 ON p_2.telemetry_value_parent_id = v_1.telemetry_value_parent_id
        WHERE p_2.parameter = 'Rainfall'
        ORDER BY p_2.station, p_2.region, v_1.value_timestamp, p_2.end_timestamp DESC
    ) dedup ON dedup.station = p_1.station AND dedup.region = p_1.region
    JOIN (
        SELECT 
            p_2.region,
            p_2.station,
            MAX(v_2.value_timestamp) AS latest_timestamp
        FROM sls_telemetry_value_parent p_2
        JOIN sls_telemetry_value v_2 ON p_2.telemetry_value_parent_id = v_2.telemetry_value_parent_id
        WHERE p_2.parameter = 'Rainfall'
        GROUP BY p_2.region, p_2.station
    ) latest ON latest.region = p_1.region AND latest.station = p_1.station
    WHERE dedup.value_timestamp > (latest.latest_timestamp - '1 day'::interval)
      AND p_1.parameter = 'Rainfall'
    GROUP BY p_1.station, p_1.region
) daysum ON daysum.station = s.station_reference AND daysum.region = s.region
LEFT JOIN (
    -- 6 hour total with deduplication
    SELECT 
        p_1.station,
        p_1.region,
        SUM(dedup.value) AS total
    FROM sls_telemetry_value_parent p_1
    JOIN (
        -- Deduplicate: keep only one row per (station, region, timestamp)
        SELECT DISTINCT ON (p_2.station, p_2.region, v_1.value_timestamp)
            p_2.station,
            p_2.region,
            v_1.value_timestamp,
            NULLIF(v_1.value, 'NaN') AS value
        FROM sls_telemetry_value_parent p_2
        JOIN sls_telemetry_value v_1 ON p_2.telemetry_value_parent_id = v_1.telemetry_value_parent_id
        WHERE p_2.parameter = 'Rainfall'
        ORDER BY p_2.station, p_2.region, v_1.value_timestamp, p_2.end_timestamp DESC
    ) dedup ON dedup.station = p_1.station AND dedup.region = p_1.region
    JOIN (
        SELECT 
            p_2.region,
            p_2.station,
            MAX(v_2.value_timestamp) AS latest_timestamp
        FROM sls_telemetry_value_parent p_2
        JOIN sls_telemetry_value v_2 ON p_2.telemetry_value_parent_id = v_2.telemetry_value_parent_id
        WHERE p_2.parameter = 'Rainfall'
        GROUP BY p_2.region, p_2.station
    ) latest ON latest.region = p_1.region AND latest.station = p_1.station
    WHERE dedup.value_timestamp > (latest.latest_timestamp - '06:00:00'::interval)
      AND p_1.parameter = 'Rainfall'
    GROUP BY p_1.station, p_1.region
) sixhr ON sixhr.station = s.station_reference AND sixhr.region = s.region
LEFT JOIN (
    -- 1 hour total with deduplication
    SELECT 
        p_1.station,
        p_1.region,
        SUM(dedup.value) AS total
    FROM sls_telemetry_value_parent p_1
    JOIN (
        -- Deduplicate: keep only one row per (station, region, timestamp)
        SELECT DISTINCT ON (p_2.station, p_2.region, v_1.value_timestamp)
            p_2.station,
            p_2.region,
            v_1.value_timestamp,
            NULLIF(v_1.value, 'NaN') AS value
        FROM sls_telemetry_value_parent p_2
        JOIN sls_telemetry_value v_1 ON p_2.telemetry_value_parent_id = v_1.telemetry_value_parent_id
        WHERE p_2.parameter = 'Rainfall'
        ORDER BY p_2.station, p_2.region, v_1.value_timestamp, p_2.end_timestamp DESC
    ) dedup ON dedup.station = p_1.station AND dedup.region = p_1.region
    JOIN (
        SELECT 
            p_2.region,
            p_2.station,
            MAX(v_2.value_timestamp) AS latest_timestamp
        FROM sls_telemetry_value_parent p_2
        JOIN sls_telemetry_value v_2 ON p_2.telemetry_value_parent_id = v_2.telemetry_value_parent_id
        WHERE p_2.parameter = 'Rainfall'
        GROUP BY p_2.region, p_2.station
    ) latest ON latest.region = p_1.region AND latest.station = p_1.station
    WHERE dedup.value_timestamp > (latest.latest_timestamp - '01:00:00'::interval)
      AND p_1.parameter = 'Rainfall'
    GROUP BY p_1.station, p_1.region
) onehr ON onehr.station = s.station_reference AND onehr.region = s.region
ORDER BY s.region, s.station_name;

-- Create unique index required for CONCURRENT refresh
CREATE UNIQUE INDEX idx_rainfall_stations_mview_unique
    ON rainfall_stations_mview (telemetry_value_parent_id);

CREATE UNIQUE INDEX idx_stations_list_unique
ON u_flood.stations_list_mview USING btree (id)
TABLESPACE flood_indexes;
