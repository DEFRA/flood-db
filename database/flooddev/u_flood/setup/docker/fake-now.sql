CREATE SCHEMA if not exists override;

CREATE OR REPLACE FUNCTION override.now()
  RETURNS timestamptz AS
$$
BEGIN
  /* return TO_TIMESTAMP('2023-02-06 14:00:00+00','YYYY-MM-DD HH24:MI:SS'); */
  return max(value_timestamp) + '1 minute' from stations_overview_mview;
  /* return pg_catalog.now(); */
END
$$ language plpgsql;

ALTER role u_flood set search_path = override, pg_catalog, u_flood, postgis, topology, public;
