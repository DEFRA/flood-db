CREATE OR REPLACE FUNCTION adjust_telemetry_timestamps() RETURNS VOID AS $$
DECLARE 
    time_shift INTERVAL;
BEGIN
    SET search_path TO u_flood;

    -- shift the time stamps up relative to the nearest quarter hour to now
    -- e.g if now is 10:07am 18Feb2025 the all time stamps need to relative 
    -- to 10:00 18Feb2025 max time stamp needs be equal to it and all other 
    -- timestamps should be pulled forward by the same amount
    SELECT
        date_trunc('hour', NOW() - MAX(value_timestamp)) 
        + INTERVAL '15 minutes' * ROUND(EXTRACT(MINUTE FROM (NOW() - MAX(value_timestamp))) / 15.0) 
    INTO time_shift
    FROM sls_telemetry_value;

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

    RAISE NOTICE 'Adjustment done, refreshing materialized views';

    REFRESH MATERIALIZED VIEW stations_overview_mview;
    REFRESH MATERIALIZED VIEW rivers_mview;
    REFRESH MATERIALIZED VIEW rainfall_stations_mview;
    REFRESH MATERIALIZED VIEW stations_list_mview;
END;
$$ LANGUAGE plpgsql;

CREATE EXTENSION pg_cron;
SELECT cron.schedule('telemetry-refresh', '0,15,30,45 * * * *', 'SELECT adjust_telemetry_timestamps();');
UPDATE cron.job SET active = FALSE WHERE jobname = 'telemetry-refresh';
