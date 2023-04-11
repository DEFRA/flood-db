INSERT INTO u_flood.ffoi_station(rloi_id) VALUES (8175);

INSERT INTO u_flood.ffoi_station_threshold (ffoi_station_id, fwis_code, value) VALUES
((SELECT ffoi_station_id FROM u_flood.ffoi_station WHERE rloi_id = 8175), '123FWF632', 2.2),
((SELECT ffoi_station_id FROM u_flood.ffoi_station WHERE rloi_id = 8175), '123FWF634', 2.2);
