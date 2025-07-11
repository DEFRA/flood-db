#!/bin/bash
set -e

echo "Waiting for PostGIS extension to be available..."

until pg_isready -h flood-db -p 5432 -U postgres >/dev/null 2>&1 && \
      psql "postgres://postgres:postgres@flood-db:5432/flooddev" -c "SELECT postgis_full_version();" >/dev/null 2>&1 && \
      psql "postgres://postgres:postgres@flood-db:5432/flooddev" -c "SELECT st_makepoint(0, 0);" >/dev/null 2>&1; do
  echo "Waiting for PostGIS..."
  sleep 5
done

echo "PostGIS is ready!"
