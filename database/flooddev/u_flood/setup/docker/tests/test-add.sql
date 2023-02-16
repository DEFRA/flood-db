BEGIN;
  SELECT plan(12);
  SELECT has_materialized_view('stations_overview_mview');
  SELECT has_column( 'stations_overview_mview', 'value' );
  SELECT has_column( 'stations_overview_mview', 'value_timestamp' );
  -- the previous_value is just for debugging, can be removed
  SELECT has_column( 'stations_overview_mview', 'previous_value' );
  SELECT has_column( 'stations_overview_mview', 'trend' );
  SELECT has_column( 'rivers_mview', 'trend' );
  SELECT has_column( 'stations_list_mview', 'trend' );
  SELECT results_eq('SELECT count(*) FROM stations_overview_mview', ARRAY[ 2721::BIGINT ], 'stations_list_mview result count');
  SELECT results_eq(
    'SELECT rloi_id, processed_value, value_timestamp, previous_value, trend FROM stations_overview_mview WHERE rloi_id IN (1001,1006,1009,3287) ORDER BY rloi_id',
    $$VALUES
     (1001, 1.458, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 1.556, 'falling'),
     (1006, 0.441, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 0.44, 'rising'),
     (1009, 0.066, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 0.066, 'steady'),
     -- 3287 is an example of a station with a batch of telemetry values under a single telemetry value parent
     -- which was previously returning the wrong trend value
     (3287, 0.312, TO_TIMESTAMP('2023-02-06 06:00:00+00','YYYY-MM-DD HH24:MI:SS'), 0.312, 'steady')
    $$,
    'stations_overview_mview results');
  SELECT results_eq(
    'SELECT rloi_id, value, value_timestamp, trend FROM rivers_mview WHERE rloi_id IN (1001,1006,1009) ORDER BY rloi_id',
    $$VALUES
     (1001, 1.458, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'falling'),
     (1006, 0.441, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'rising'),
     (1009, 0.066, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'steady')
    $$,
    'rivers_mview results');
  SELECT results_eq(
    'SELECT rloi_id, value, value_timestamp, trend FROM stations_list_mview WHERE rloi_id IN (1001,1006,1009) ORDER BY rloi_id',
    $$VALUES
     (1001, 1.458, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'falling'),
     (1006, 0.441, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'rising'),
     (1009, 0.066, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'steady')
    $$,
    'stations_list_mview results');
  SELECT results_eq(
    $$SELECT river_id, value, value_timestamp, trend FROM stations_list_mview WHERE river_id = 'rainfall-North East' and telemetry_id = '075233'$$,
    $$VALUES
     ('rainfall-North East', 0.0, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'n/a')
    $$,
    'stations_list_mview rainfall results should set trend to n/a');
SELECT * FROM finish();
ROLLBACK;
