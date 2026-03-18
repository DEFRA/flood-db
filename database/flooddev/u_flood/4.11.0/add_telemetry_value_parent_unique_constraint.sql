-- 4.11.0 - Remove duplicate Rainfall values and prevent recurrence (FSR-1564)
-- Duplicate key for cleanup: (station, region, value_timestamp)
-- Keep newest telemetry_value_id and delete older duplicates.

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

-- Guardrail: prevent duplicate Rainfall parent streams being created.
-- Null qualifier values are normalised via COALESCE so duplicates with NULL
-- qualifier are still blocked.
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
