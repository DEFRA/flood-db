#!/bin/bash
set -e

echo "Waiting for PostGIS extension to be available..."

DB_URL="postgres://$DB_USER:$DB_PASSWORD@$DB_HOST:5432/$DB_NAME"

until pg_isready -h $DB_HOST -p 5432 -U $DB_USER >/dev/null 2>&1 && \
      psql "$DB_URL" -c "SELECT postgis_full_version();" >/dev/null 2>&1 && \
      psql "$DB_URL" -c "SELECT st_makepoint(0, 0);" >/dev/null 2>&1; do
  echo "Waiting for PostGIS..."
  sleep 3
done

echo "PostGIS is ready!"
