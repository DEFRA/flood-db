#!/bin/bash

pushd /data

echo Exporting Target Areas

pg_dump "$DB" -a --inserts -t u_flood.flood_alert_area -f flood_alert_area.sql
pg_dump "$DB" -a --inserts -t u_flood.flood_warning_area -f flood_warning_area.sql

zip -q target_areas.zip flood_{alert,warning}_area.sql

rm flood_{alert,warning}_area.sql

ls

popd
