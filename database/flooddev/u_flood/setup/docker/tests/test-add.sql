BEGIN;
  SELECT plan(13);
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
    'SELECT rloi_id, direction, processed_value, value_timestamp, previous_value, trend FROM stations_overview_mview WHERE rloi_id IN (1001,1006,1009,1018,2116,3287) ORDER BY rloi_id, direction',
    $$VALUES
     (1001, 'u', 1.458, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 1.556, 'falling'),
     -- differences are to 2 dp
     (1006, 'u', 0.441, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 0.44, 'steady'),
     (1009, 'u', 0.066, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 0.066, 'steady'),
     (1018, 'u', 1.546, TO_TIMESTAMP('2023-02-06 12:00:00+00','YYYY-MM-DD HH24:MI:SS'), 1.536, 'rising'),
     -- 2116 is a multi-gauge station
     (2116, 'd', -0.432, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), -0.431, 'steady'),
     (2116, 'u', 0.106, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 0.106, 'steady'),
     -- 3287 is an example of a station with a batch of telemetry values under a single telemetry value parent
     -- which was previously returning the wrong trend value
     (3287, 'u', 0.312, TO_TIMESTAMP('2023-02-06 06:00:00+00','YYYY-MM-DD HH24:MI:SS'), 0.312, 'steady')
    $$,
    'stations_overview_mview results');
  SELECT results_eq(
    'SELECT rloi_id, value, value_timestamp, trend FROM rivers_mview WHERE rloi_id IN (1001,1009,1018) ORDER BY rloi_id',
    $$VALUES
     (1001, 1.458, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'falling'),
     (1009, 0.066, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'steady'),
     (1018, 1.546, TO_TIMESTAMP('2023-02-06 12:00:00+00','YYYY-MM-DD HH24:MI:SS'), 'rising')
    $$,
    'rivers_mview results');
  SELECT results_eq(
    'SELECT rloi_id, value, value_timestamp, trend FROM stations_list_mview WHERE rloi_id IN (1001,1009,1018) ORDER BY rloi_id',
    $$VALUES
     (1001, 1.458, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'falling'),
     (1009, 0.066, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'steady'),
     (1018, 1.546, TO_TIMESTAMP('2023-02-06 12:00:00+00','YYYY-MM-DD HH24:MI:SS'), 'rising')
    $$,
    'stations_list_mview results');
  SELECT results_eq(
    'SELECT rloi_id, value, status, value_timestamp, trend FROM stations_list_mview WHERE rloi_id IN (9302) ORDER BY rloi_id',
    $$VALUES
     (9302, 78.8, 'Suspended', TO_TIMESTAMP('2023-02-06 10:00:00+00','YYYY-MM-DD HH24:MI:SS'), 'rising')
    $$,
    'stations_list_mview should populate trend for suspended groundwater station');
  SELECT results_eq(
    $$SELECT river_id, value, value_timestamp, trend FROM stations_list_mview WHERE river_id = 'rainfall-North East' and telemetry_id = '075233'$$,
    $$VALUES
     ('rainfall-North East', 0.0, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'), 'n/a')
    $$,
    'stations_list_mview should set trend to n/a for rainfall stations');
SELECT * FROM finish();
ROLLBACK;
