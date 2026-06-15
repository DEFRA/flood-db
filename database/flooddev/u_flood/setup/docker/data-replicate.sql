INSERT INTO sls_telemetry_value (telemetry_value_parent_id, value, processed_value, value_timestamp, error)
SELECT 
    t1.telemetry_value_parent_id,
    t1.value,
    t1.processed_value,
    t1.value_timestamp - interval '5 day' * gs.n as value_timestamp,
    t1.error
FROM 
    sls_telemetry_value t1
CROSS JOIN 
    generate_series(0, 5) as gs(n)
WHERE 
    t1.value_timestamp >= current_date - interval '30 day';
