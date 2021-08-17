-- View: u_flood.impact_mview

DROP MATERIALIZED VIEW u_flood.impact_mview;

CREATE MATERIALIZED VIEW u_flood.impact_mview
TABLESPACE flood_tables
AS
 SELECT i.id AS impactid,
    (tc.wiski_river_name || ' at '::text) || tc.agency_name AS gauge,
    i.rloi_id AS rloiid,
    i.value,
    i.units,
    i.geom,
    st_asgeojson(i.geom) AS coordinates,
    i.comment,
    i.short_name AS shortname,
    i.description,
    i.type,
    i.obs_flood_year AS obsfloodyear,
    i.obs_flood_month AS obsfloodmonth,
    i.source,
    s.processed_value AS telemetrylatest,
    s.processed_value >= i.value AS telemetryactive,
    ffoi.value AS forecastmax,
    ffoi.value >= i.value AND fs.rloi_id IS NOT NULL AS forecastactive
   FROM impact i
     JOIN telemetry_context tc ON i.rloi_id = tc.rloi_id
     LEFT JOIN (select distinct on (rloi_id) * from stations_overview_mview) s ON s.rloi_id = i.rloi_id AND s.direction = 'u'::text
     LEFT JOIN ffoi_max ffoi ON ffoi.telemetry_id = s.telemetry_id
     LEFT JOIN ffoi_station fs ON i.rloi_id = fs.rloi_id
  WHERE tc.status = 'Active'::text
WITH DATA;

ALTER TABLE u_flood.impact_mview
    OWNER TO u_flood;
	
-- Index: idx_impact_unique

-- DROP INDEX u_flood.idx_impact_unique;

CREATE UNIQUE INDEX IF NOT EXISTS idx_impact_unique
    ON u_flood.impact_mview USING btree
    (impactid ASC NULLS LAST)
    TABLESPACE flood_indexes;
	