-- clear data so script is idempotent
DELETE FROM u_flood.ffoi_station_threshold st
USING  u_flood.ffoi_station s
WHERE s.ffoi_station_id = st.ffoi_station_id AND s.rloi_id = 8175;
DELETE FROM u_flood.ffoi_station WHERE rloi_id = 8175;

-- insert station and thresholds
INSERT INTO u_flood.ffoi_station(rloi_id) VALUES (8175);
INSERT INTO u_flood.ffoi_station_threshold (ffoi_station_id, fwis_code, value) VALUES
((SELECT ffoi_station_id FROM u_flood.ffoi_station WHERE rloi_id = 8175), '123FWF632', 2.2),
((SELECT ffoi_station_id FROM u_flood.ffoi_station WHERE rloi_id = 8175), '123FWF634', 2.2);
