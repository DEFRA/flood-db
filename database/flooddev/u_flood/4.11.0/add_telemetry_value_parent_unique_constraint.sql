-- 4.11.0 - Remove duplicate Rainfall values and prevent recurrence (FSR-1564)

-- Step 1: if there are duplicate parent rows for the same stream,
-- keep the most recently imported one.
-- Then point child values at that kept parent row.
WITH ranked_parent AS (
        SELECT
                p.telemetry_value_parent_id,
                ROW_NUMBER() OVER (
                        PARTITION BY p.station, p.region, COALESCE(p.qualifier, ''), p.start_timestamp, p.end_timestamp
                        ORDER BY p.imported DESC, p.telemetry_value_parent_id DESC
                ) AS rn,
                FIRST_VALUE(p.telemetry_value_parent_id) OVER (
                        PARTITION BY p.station, p.region, COALESCE(p.qualifier, ''), p.start_timestamp, p.end_timestamp
                        ORDER BY p.imported DESC, p.telemetry_value_parent_id DESC
                ) AS keep_parent_id
        FROM u_flood.sls_telemetry_value_parent p
        WHERE lower(p.parameter) = 'rainfall'
), duplicate_parent AS (
        SELECT telemetry_value_parent_id AS duplicate_parent_id, keep_parent_id
        FROM ranked_parent
        WHERE rn > 1
)
UPDATE u_flood.sls_telemetry_value v
SET telemetry_value_parent_id = dp.keep_parent_id
FROM duplicate_parent dp
WHERE v.telemetry_value_parent_id = dp.duplicate_parent_id;

-- Step 2: remove the now-unused duplicate parent rows.
WITH ranked_parent AS (
        SELECT
                p.telemetry_value_parent_id,
                ROW_NUMBER() OVER (
                        PARTITION BY p.station, p.region, COALESCE(p.qualifier, ''), p.start_timestamp, p.end_timestamp
                        ORDER BY p.imported DESC, p.telemetry_value_parent_id DESC
                ) AS rn
        FROM u_flood.sls_telemetry_value_parent p
        WHERE lower(p.parameter) = 'rainfall'
)
DELETE FROM u_flood.sls_telemetry_value_parent p
USING ranked_parent rp
WHERE p.telemetry_value_parent_id = rp.telemetry_value_parent_id
    AND rp.rn > 1;

-- Step 3: clean up duplicate rainfall values (same station/region/timestamp).
-- Keep the latest row by id.
WITH ranked AS (
        SELECT
                v.telemetry_value_id,
                ROW_NUMBER() OVER (
                        PARTITION BY p.station, p.region, v.value_timestamp
                        ORDER BY v.telemetry_value_id DESC
                ) AS rn
        FROM u_flood.sls_telemetry_value_parent p
        JOIN u_flood.sls_telemetry_value v
            ON v.telemetry_value_parent_id = p.telemetry_value_parent_id
        WHERE p.parameter = 'Rainfall'
)
DELETE FROM u_flood.sls_telemetry_value v
USING ranked r
WHERE v.telemetry_value_id = r.telemetry_value_id
    AND r.rn > 1;

-- Step 4: add a partial unique index so duplicate rainfall parent streams
-- cannot be inserted again.
CREATE UNIQUE INDEX idx_sls_tvp_rainfall_unique_stream
ON u_flood.sls_telemetry_value_parent
(
                station,
                region,
                COALESCE(qualifier, ''),
                start_timestamp,
                end_timestamp
)
WHERE lower(parameter) = 'rainfall';
