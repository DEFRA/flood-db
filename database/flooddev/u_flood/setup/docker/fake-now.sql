CREATE SCHEMA if not exists override;

-- function to override the system now() function so that, for example, getting telemetry
-- data using the get_telemetry() function will still work even with data from a backup
-- made >5 days ago. The return value just needs to be set to a suitable point in time.
CREATE OR REPLACE FUNCTION override.now()
  RETURNS timestamptz AS
$$
BEGIN
  return TO_TIMESTAMP('2023-02-06 14:00:00+00','YYYY-MM-DD HH24:MI:SS');
  /* return max(value_timestamp) + '1 minute' from stations_overview_mview; */
  /* return pg_catalog.now(); */
END
$$ language plpgsql;

ALTER role u_flood set search_path = override, pg_catalog, u_flood, postgis, topology, public;

-- to ignore the override now() function uncomment this line
-- ALTER role u_flood set search_path = u_flood, postgis, topology, public;
