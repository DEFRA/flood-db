DROP TABLE IF EXISTS u_flood.station_display_time_series;
DROP SEQUENCE IF EXISTS u_flood.station_display_time_series_id_seq;

CREATE SEQUENCE IF NOT EXISTS u_flood.station_display_time_series_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE u_flood.station_display_time_series_id_seq
    OWNER TO u_flood;

CREATE TABLE IF NOT EXISTS u_flood.station_display_time_series
(
    station_display_time_series_id BIGINT PRIMARY KEY DEFAULT nextval('u_flood.station_display_time_series_id_seq'),
    station_id BIGINT NOT NULL,
    direction CHAR NOT NULL,
    display_time_series BOOLEAN
);

CREATE INDEX idx_station_display_time_series_id
    ON u_flood.station_display_time_series (station_id, direction);

ALTER TABLE u_flood.station_display_time_series
    OWNER TO u_flood;
