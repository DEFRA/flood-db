-- Note that this is a refactored version of original which originally took 4 to 6 hours depending on the size of the database
truncate table u_flood.station_ta_8km;
insert into u_flood.station_ta_8km
select tc.rloi_id,a.fws_tacode from u_flood.telemetry_context_mview tc inner join u_flood.flood_alert_area a on st_dwithin(tc.geography,a.geom, 8000);

insert into u_flood.station_ta_8km
select tc.rloi_id,a.fws_tacode from u_flood.telemetry_context_mview tc inner join u_flood.flood_warning_area a on st_dwithin(tc.geography,a.geom, 8000);
