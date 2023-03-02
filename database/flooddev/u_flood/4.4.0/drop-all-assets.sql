-- dropping in reverse order of dependancy
DROP MATERIALIZED VIEW IF EXISTS u_flood.stations_list_mview;
DROP MATERIALIZED VIEW IF EXISTS u_flood.impact_mview, u_flood.rivers_mview;
DROP MATERIALIZED VIEW IF EXISTS u_flood.stations_overview_mview;

