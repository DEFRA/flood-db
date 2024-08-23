-- View: u_flood.impact_mview


CREATE MATERIALIZED VIEW IF NOT EXISTS u_flood.impact_mview
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
    sdts.display_time_series AS forecast
   FROM impact i
     JOIN telemetry_context tc ON i.rloi_id = tc.rloi_id
     LEFT JOIN ( SELECT DISTINCT ON (stations_overview_mview.rloi_id) stations_overview_mview.rloi_id,
            stations_overview_mview.telemetry_id,
            stations_overview_mview.wiski_id,
            stations_overview_mview.direction,
            stations_overview_mview.station_type,
            stations_overview_mview.agency_name,
            stations_overview_mview.area,
            stations_overview_mview.catchment,
            stations_overview_mview.status,
            stations_overview_mview.parameter,
            stations_overview_mview.qualifier,
            stations_overview_mview.units,
            stations_overview_mview.value,
            stations_overview_mview.processed_value,
            stations_overview_mview.value_timestamp,
            stations_overview_mview.error,
            stations_overview_mview.age,
            stations_overview_mview.por_max_breached,
            stations_overview_mview.at_risk,
            stations_overview_mview.forecast,
            stations_overview_mview.level,
            stations_overview_mview.percentile_5,
            stations_overview_mview.percentile_95
           FROM stations_overview_mview) s ON s.rloi_id = i.rloi_id AND s.direction = 'u'::text
     LEFT JOIN ffoi_max ffoi ON ffoi.telemetry_id = s.telemetry_id
     LEFT JOIN station_display_time_series sdts ON sdts.station_id = s.rloi_id AND sdts.direction = s.qualifier
  WHERE tc.status = 'Active'::text
WITH DATA;

ALTER TABLE IF EXISTS u_flood.impact_mview
    OWNER TO u_flood;


CREATE UNIQUE INDEX idx_impact_unique
    ON u_flood.impact_mview USING btree
    (impactid)
    TABLESPACE flood_indexes;

