BEGIN;
  -- Notes:
     -- all current and previous values obtained from inspecting the telemetry feed from flood-service
     -- running against the test docker db
  SELECT plan(19);
  SELECT has_materialized_view('stations_overview_mview');
  SELECT has_column( 'stations_overview_mview', 'value' );
  SELECT has_column( 'stations_overview_mview', 'value_timestamp' );
  -- the previous_value is just for debugging and should have been removed
  SELECT hasnt_column( 'stations_overview_mview', 'previous_value' );
  SELECT has_column( 'stations_overview_mview', 'trend' );
  SELECT has_column( 'rivers_mview', 'trend' );
  SELECT has_column( 'stations_list_mview', 'trend' );
  SELECT results_eq('SELECT count(*) FROM stations_overview_mview', ARRAY[ 2721::BIGINT ], 'stations_list_mview result count should be unchanged from before code changes');
  SELECT results_eq(
    'SELECT rloi_id, direction, processed_value, value_timestamp, trend FROM stations_overview_mview WHERE rloi_id IN (1001,1009,1046) ORDER BY rloi_id, direction',
    $$VALUES
     -- previous_values 1001=1.556, 1009=0.066, 1046=0.276
     (1001, 'u', 1.458, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'falling'),
     (1009, 'u', 0.066, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'steady'),
     (1046, 'u', 0.288, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'rising')
    $$,
    'stations_overview_mview should populate trend for river stations as falling, steady or rising');
  SELECT results_eq(
    'SELECT rloi_id, value, status, value_timestamp, trend FROM stations_list_mview WHERE rloi_id IN (9137) ORDER BY rloi_id',
    $$VALUES
     (9137, 44.097, 'Active', TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'steady')
    $$,
    'stations_list_mview should populate trend for groundwater');
  SELECT results_eq(
    'SELECT rloi_id, direction, processed_value, value_timestamp, trend FROM stations_overview_mview WHERE rloi_id IN (9214) ORDER BY rloi_id, direction',
    $$VALUES
     -- previous_value=1.215
     (9214, 'u', 1.192, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'falling')
    $$,
    'stations_overview_mview should populate trend for coastal stations');
  SELECT results_eq(
    $$SELECT river_id, value, value_timestamp, trend FROM stations_list_mview WHERE river_id = 'rainfall-North East' and telemetry_id = '075233'$$,
    $$VALUES
     ('rainfall-North East', 0.0, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'n/a')
    $$,
    'stations_list_mview should set trend to n/a for rainfall stations');
  SELECT results_eq(
    'SELECT rloi_id, direction, processed_value, value_timestamp, trend FROM stations_overview_mview WHERE rloi_id IN (3287) ORDER BY rloi_id, direction',
    $$VALUES
     -- 3287 is an example of a station with a batch of telemetry values under a single telemetry value parent
     -- which was previously returning the wrong trend value
     -- previous_value=0.312
     (3287, 'u', 0.312, TO_TIMESTAMP('2023-02-06 06:00:00+00','YYYY-MM-DD HH24:MI:SS'), 'steady')
    $$,
    'stations_overview_mview should populate trend correctly when multiple telemetry values are posted together');
  SELECT results_eq(
    'SELECT rloi_id, value, value_timestamp, trend FROM rivers_mview WHERE rloi_id IN (1001,1009,1018) ORDER BY rloi_id',
    $$VALUES
     (1001, 1.458, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'falling'),
     (1009, 0.066, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'steady'),
     (1018, 1.546, TO_TIMESTAMP('2023-02-06 12:00:00+00','YYYY-MM-DD HH24:MI:SS'), 'rising')
    $$,
    'rivers_mview should have a populated trend');
  SELECT results_eq(
    'SELECT rloi_id, value, value_timestamp, trend FROM stations_list_mview WHERE rloi_id IN (1001,1009,1018) ORDER BY rloi_id',
    $$VALUES
     (1001, 1.458, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'falling'),
     (1009, 0.066, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'steady'),
     (1018, 1.546, TO_TIMESTAMP('2023-02-06 12:00:00+00','YYYY-MM-DD HH24:MI:SS'), 'rising')
    $$,
    'stations_list_mview should have a populated trend');
  SELECT results_eq(
    'SELECT rloi_id, direction, processed_value, value_timestamp, trend FROM stations_overview_mview WHERE rloi_id IN (1006) ORDER BY rloi_id, direction',
    $$VALUES
     -- previous_value=0.44
     (1006, 'u', 0.441, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'steady')
    $$,
    'stations_overview_mview trend should be calculated based on a precision of 2 decimal places');
  SELECT results_eq(
    'SELECT rloi_id, direction, processed_value, value_timestamp, trend FROM stations_overview_mview WHERE rloi_id IN (7226) ORDER BY rloi_id, direction',
    $$VALUES
     -- previous_value=0.18
     (7226, 'u', 0.18, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'steady')
    $$,
    'stations_overview_mview - calculation of trend should ignore crest topping values');
  SELECT results_eq(
    'SELECT rloi_id, direction, processed_value, value_timestamp, trend FROM stations_overview_mview WHERE rloi_id IN (2116) ORDER BY rloi_id, direction',
    $$VALUES
     -- 2116 is a multi-gauge station
     -- downstream previous_value=-0.431
     -- upstream previous_value=-0.106
     (2116, 'd', -0.432, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'steady'),
     (2116, 'u', 0.106, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'steady')
    $$,
    'stations_overview_mview should return trend for both upstream and downstream for a mulitgauge station');
  SELECT results_eq(
    'SELECT rloi_id, value, status, value_timestamp, trend FROM stations_list_mview WHERE rloi_id IN (9137, 9302) ORDER BY rloi_id',
    $$VALUES
     (9137, 44.097, 'Active', TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'steady'),
     (9302, 78.8, 'Suspended', TO_TIMESTAMP('2023-02-06 10:00:00+00','YYYY-MM-DD HH24:MI:SS'), 'rising')
    $$,
    'stations_list_mview should populate trend for suspended and unsuspended stations');
SELECT * FROM finish();
ROLLBACK;
