ALTER TABLE u_flood.river_stations
  ADD COLUMN IF NOT EXISTS river_id integer,
  ADD COLUMN IF NOT EXISTS qualified_name character varying(200);

CREATE INDEX IF NOT EXISTS idx_river_id
    ON u_flood.river_stations USING btree
    (river_id ASC NULLS LAST)
    TABLESPACE flood_indexes;
