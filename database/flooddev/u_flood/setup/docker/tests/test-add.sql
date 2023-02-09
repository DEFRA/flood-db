BEGIN;
  SELECT plan(5);
  SELECT has_materialized_view('stations_overview_mview');
  SELECT has_column( 'stations_overview_mview', 'value' );
  SELECT has_column( 'stations_overview_mview', 'value_timestamp' );
  /* SELECT has_column( 'stations_list_mview', 'previous_value' ); */
  SELECT results_eq('SELECT count(*) FROM stations_overview_mview', ARRAY[ 2721::BIGINT ], 'stations_list_mview result count');
  SELECT results_eq(
    'SELECT rloi_id, value, value_timestamp FROM stations_overview_mview WHERE rloi_id IN (8121, 3246) ORDER BY rloi_id',
    $$VALUES
     (3246, 0.612, TO_TIMESTAMP('2023-02-06 13:00:00+00','YYYY-MM-DD HH24:MI:SS')),
     (8121, 0.486, TO_TIMESTAMP('2023-02-06 13:15:00+00','YYYY-MM-DD HH24:MI:SS'))
    $$,
    'stations_list_mview results');
SELECT * FROM finish();
ROLLBACK;
