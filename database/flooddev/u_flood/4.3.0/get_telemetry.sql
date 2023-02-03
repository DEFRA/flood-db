DROP FUNCTION u_flood.get_telemetry(integer, character);

CREATE OR REPLACE FUNCTION u_flood.get_telemetry(IN _rloi_id integer, IN _qualifier character)
  RETURNS json AS
$BODY$

declare result json;

begin
	select array_to_json(array_agg(res))
	from
	(
		select 
		to_char(v.value_timestamp, 'YYYY-MM-DD"T"HH24:MIZ') as ts, --ISO8601 timestamp consumable by date.parse
		v.processed_value as _, 
		v.error as err
		From u_flood.sls_telemetry_value_parent p
		inner join u_flood.sls_telemetry_value v on v.telemetry_value_parent_id = p.telemetry_value_parent_id
		inner join u_flood.station_split_mview s on p.rloi_id = s.rloi_id and s.qualifier = _qualifier
		where p.rloi_id = _rloi_id 
		and p.start_timestamp > NOW() - INTERVAL '5 days' -- only gets readings from the last five days
		and (s.status_date is null or v.value_timestamp >= s.status_date)
		and lower(p.parameter) like 'water level' -- Only interested in waterlevel
		and (
			(_qualifier = 'u' and lower(p.qualifier) not like '%downstream%') --if upstream filter out downstream stage
			OR 
			(_qualifier = 'd' and lower(p.qualifier) like '%downstream%') --if downstream, then multistation's downstream stage needed
		    )
		and lower(p.units) not like '%deg%'
		and lower(p.qualifier) not like '%height%'
		and lower(p.qualifier) != 'crest tapping'
		--Potentially will need to add a date filter here for when we start showing more than 5 days of data.
		order by v.value_timestamp DESC
	) as res into result;
	return result;
end

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION u_flood.get_telemetry(integer, character)
  OWNER TO u_flood;
