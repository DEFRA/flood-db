#!/bin/bash

# Note: ENV VAR DB must have been set

get-counts() {
  local FAA_COUNT=$(psql $DB -t -c "select count(1) from u_flood.flood_alert_area;")
  local FWA_COUNT=$(psql $DB -t -c "select count(1) from u_flood.flood_warning_area;")
  echo "FWA Count:$FWA_COUNT FAA Count:$FAA_COUNT"
}

process() {
    local TYPE="$1"
    local SHAPE_FILE="flood_${TYPE}_ENG_${DATE_STAMP}.shp" 
    local TABLE="u_flood.flood_${TYPE}_area"

    psql "$DB" -t -c "truncate table $TABLE"
    shp2pgsql -s 4326 -a "$SHAPE_FILE" "$TABLE" | psql "$DB"
}

pushd /data

unzip flood_warning_ENG_${DATE_STAMP}.zip
unzip flood_alert_ENG_${DATE_STAMP}.zip

PRE_COUNTS=$(get-counts)

{
  process alert
  process warning
  psql $DB -t -c "REFRESH MATERIALIZED VIEW u_flood.fwa_mview;"
} > /data/process.log

echo "log summary"
sort /data/process.log | uniq -c
rm /data/process.log


POST_COUNTS=$(get-counts)

echo "Pre: $PRE_COUNTS"
echo "Post: $POST_COUNTS"

rm "flood_alert_ENG_${DATE_STAMP}".*
rm "flood_warning_ENG_${DATE_STAMP}".*

ls

popd
