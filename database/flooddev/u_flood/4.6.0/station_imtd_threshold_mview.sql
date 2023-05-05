--Create materialized view if not exists
CREATE MATERIALIZED VIEW IF NOT EXISTS u_flood.imtd_thresholds_mview AS
SELECT station_threshold_id, station_id, fwis_code, fwis_type, direction, value
FROM u_flood.imtd_niki;

ALTER TABLE u_flood.imtd_thresholds_mview
    OWNER TO u_flood;

--Add existing index to materialized view
CREATE UNIQUE INDEX IF NOT EXISTS imtd_thresholds_mview_pkey
  ON u_flood.imtd_thresholds_mview
  USING btree
  (station_threshold_id)
  TABLESPACE  flood_tables;

--Refresh the materialized view
REFRESH MATERIALIZED VIEW u_flood.imtd_thresholds_mview;
