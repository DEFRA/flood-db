CREATE OR REPLACE FUNCTION adjust_telemetry_timestamps() RETURNS VOID AS $$
DECLARE 
    time_shift INTERVAL;
BEGIN
    -- Compute the time difference
    SELECT NOW() - MAX(value_timestamp) INTO time_shift FROM sls_telemetry_value;

    -- Display the time shift value for diagnostic purposes
    RAISE NOTICE 'Adjusting telemetry, it may take a minute or two. (Time shift: %)', time_shift;

    -- Update sls_telemetry_value
    UPDATE sls_telemetry_value
    SET value_timestamp = value_timestamp + time_shift;

    -- Update sls_telemetry_value_parent
    UPDATE sls_telemetry_value_parent
    SET 
        imported = imported + time_shift,
        start_timestamp = start_timestamp + time_shift,
        end_timestamp = end_timestamp + time_shift;
END;
$$ LANGUAGE plpgsql;
