CREATE TABLE station_ta_8km_2 (
    rloi_id INTEGER,
    fws_tacode TEXT
);

CREATE INDEX station_ta_8km_2_rloi_id ON station_ta_8km_2 (rloi_id);
CREATE INDEX station_ta_8km_2_fws_tacode ON station_ta_8km_2 (fws_tacode);
CREATE INDEX station_ta_8km_2_rloi_id_tacode ON station_ta_8km_2 (rloi_id, fws_tacode);

CREATE SEQUENCE station_threshold_station_threshold_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

CREATE TABLE england_010k (
    gid INTEGER GENERATED ALWAYS AS IDENTITY (START WITH 13) PRIMARY KEY,
    region_id numeric,
    reg_name VARCHAR(22),
    reg_prop_n VARCHAR(24),
    reg_addr_1 VARCHAR(25),
    reg_addr_2 VARCHAR(25),
    reg_town VARCHAR(22),
    reg_pcode VARCHAR(20),
    geom GEOMETRY
);

CREATE TABLE flood_alert_area_2 (
    gid INTEGER GENERATED ALWAYS AS IDENTITY (START WITH 1519) PRIMARY KEY,
    area VARCHAR(100),
    fws_tacode VARCHAR(50),
    ta_name VARCHAR(100),
    descrip VARCHAR(254),
    la_name VARCHAR(254),
    qdial VARCHAR(50),
    river_sea VARCHAR(254),
    geom GEOMETRY
);

CREATE TABLE flood_alert_area_20220223_backup (
    gid INTEGER,
    area VARCHAR(100),
    fws_tacode VARCHAR(50),
    ta_name VARCHAR(100),
    descrip VARCHAR(254),
    la_name VARCHAR(254),
    qdial VARCHAR(50),
    river_sea VARCHAR(254),
    geom GEOMETRY
);

CREATE TABLE flood_alert_area_20220511_backup (
    gid INTEGER,
    area VARCHAR(100),
    fws_tacode VARCHAR(50),
    ta_name VARCHAR(100),
    descrip VARCHAR(254),
    la_name VARCHAR(254),
    qdial VARCHAR(50),
    river_sea VARCHAR(254),
    geom GEOMETRY
);

CREATE TABLE flood_alert_area_valid (
    area VARCHAR(100),
    fws_tacode VARCHAR(50),
    ta_name VARCHAR(100),
    descrip VARCHAR(254),
    la_name VARCHAR(254),
    qdial VARCHAR(50),
    river_sea VARCHAR(254),
    geom GEOMETRY
);

CREATE TABLE flood_warning_area_20220223_backup (
    gid INTEGER,
    area VARCHAR(100),
    fws_tacode VARCHAR(50),
    ta_name VARCHAR(100),
    descrip VARCHAR(254),
    la_name VARCHAR(254),
    parent VARCHAR(50),
    qdial VARCHAR(50),
    river_sea VARCHAR(254),
    geom GEOMETRY
);

CREATE TABLE flood_warning_area_20220511_backup (
    gid INTEGER,
    area VARCHAR(100),
    fws_tacode VARCHAR(50),
    ta_name VARCHAR(100),
    descrip VARCHAR(254),
    la_name VARCHAR(254),
    parent VARCHAR(50),
    qdial VARCHAR(50),
    river_sea VARCHAR(254),
    geom GEOMETRY
);

CREATE TABLE river_display (
    id INTEGER,
    local_name VARCHAR,
    qualified_name VARCHAR,
    river_id VARCHAR
);

CREATE TABLE river_display_name (
    river_id TEXT,
    display TEXT
);

CREATE TABLE river_stations_list_test (
    id VARCHAR(200),
    name VARCHAR(200),
    rloi_id INTEGER,
    rank INTEGER,
    display_name TEXT
);

CREATE TABLE station_ta_8km_20220223_backup (
    rloi_id INTEGER,
    fws_tacode TEXT
);

CREATE TABLE station_ta_8km_20220512_backup (
    rloi_id INTEGER,
    fws_tacode TEXT
);

CREATE TABLE station_ta_8km_20220512_test_run (
    rloi_id INTEGER,
    fws_tacode TEXT
);

CREATE INDEX england_geom_idx ON england_010k USING gist (geom);
CREATE INDEX flood_alert_area_2_geom_gist ON flood_alert_area_2 USING gist (geom);
CREATE INDEX flood_alert_area_valid_geom_gist ON flood_alert_area_valid USING gist (geom);

-- DROP SEQUENCE IF EXISTS sls_telemetry_value_parent_telemetry_value_parent_id_seq;
-- DROP SEQUENCE IF EXISTS sls_telemetry_value_telemetry_value_id_seq;
