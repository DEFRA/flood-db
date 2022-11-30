-- Table: u_flood.station_threshold

DROP TABLE IF EXISTS u_flood.station_threshold;
DROP SEQUENCE IF EXISTS u_flood.station_threshold_station_threshold_id_seq;

-- SEQUENCE: u_flood.station_threshold_station_threshold_id_seq

CREATE SEQUENCE IF NOT EXISTS u_flood.station_threshold_station_threshold_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE u_flood.station_threshold_station_threshold_id_seq
    OWNER TO u_flood;


CREATE TABLE IF NOT EXISTS u_flood.station_threshold
(
    station_threshold_id bigint NOT NULL DEFAULT nextval('station_threshold_station_threshold_id_seq'::regclass),
    station_id bigint NOT NULL,
    fwis_code text NOT NULL,
    value numeric NOT NULL,

    CONSTRAINT pk_station_threshold_id PRIMARY KEY (station_threshold_id)
        USING INDEX TABLESPACE flood_indexes
)
WITH (
    OIDS = FALSE
)
TABLESPACE flood_tables;
