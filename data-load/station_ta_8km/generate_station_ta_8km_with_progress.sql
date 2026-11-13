-- Rebuild atomically, reporting progress after every 100 telemetry-context rows.
DO $$
DECLARE
    station record;
    total_stations bigint;
    processed_stations bigint := 0;
    inserted_rows bigint;
    alert_rows bigint := 0;
    warning_rows bigint := 0;
    started_at timestamptz := clock_timestamp();
    batch_started_at timestamptz;
    reported_at timestamptz;
BEGIN
    PERFORM set_config('client_min_messages', 'notice', true);

    SELECT count(*) INTO total_stations
    FROM u_flood.telemetry_context_mview;

    RAISE NOTICE 'Starting station_ta_8km rebuild for % stations; truncating destination (may wait for a lock).',
        total_stations;
    TRUNCATE TABLE u_flood.station_ta_8km;
    batch_started_at := clock_timestamp();

    FOR station IN
        SELECT tc.rloi_id, tc.geography
        FROM u_flood.telemetry_context_mview tc
    LOOP
        INSERT INTO u_flood.station_ta_8km (rloi_id, fws_tacode)
        SELECT station.rloi_id, a.fws_tacode
        FROM u_flood.flood_alert_area a
        WHERE st_dwithin(station.geography, a.geom, 8000);
        GET DIAGNOSTICS inserted_rows = ROW_COUNT;
        alert_rows := alert_rows + inserted_rows;

        INSERT INTO u_flood.station_ta_8km (rloi_id, fws_tacode)
        SELECT station.rloi_id, a.fws_tacode
        FROM u_flood.flood_warning_area a
        WHERE st_dwithin(station.geography, a.geom, 8000);
        GET DIAGNOSTICS inserted_rows = ROW_COUNT;
        warning_rows := warning_rows + inserted_rows;

        processed_stations := processed_stations + 1;
        IF processed_stations % 100 = 0 THEN
            reported_at := clock_timestamp();
            RAISE NOTICE 'Processed %/% stations; last 100 took %; total elapsed %; inserted % alert and % warning relationships.',
                processed_stations, total_stations,
                reported_at - batch_started_at, reported_at - started_at,
                alert_rows, warning_rows;
            batch_started_at := reported_at;
        END IF;
    END LOOP;

    reported_at := clock_timestamp();
    IF processed_stations % 100 <> 0 THEN
        RAISE NOTICE 'Processed %/% stations; final % took %; total elapsed %.',
            processed_stations, total_stations, processed_stations % 100,
            reported_at - batch_started_at, reported_at - started_at;
    END IF;

    RAISE NOTICE 'Completed station_ta_8km rebuild: % stations; % alert and % warning relationships inserted (% total); total runtime %.',
        processed_stations, alert_rows, warning_rows, alert_rows + warning_rows,
        reported_at - started_at;
END;
$$;
