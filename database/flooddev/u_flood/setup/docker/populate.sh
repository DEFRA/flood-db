#!/bin/bash
set -e

# -- Configuration --
REMOTE_DB_URL="$1"  # e.g. postgres://user:pass@host:5432/dbname
LOCAL_CONTAINER_NAME="flood-db"
LOCAL_DB="flooddev"
LOCAL_USER="postgres"
EXCLUDE_OPTIONS="--exclude-table-data sls_telemetry_value --exclude-table-data sls_telemetry_value_parent"

REQUIRED_SCHEMAS=("u_flood" "river_topo")

if [ -z "$REMOTE_DB_URL" ]; then
  echo "Example: ./populate-from-remote.sh postgres://user:pass@host:5432/dbname"
  exit 1
fi

# -- Wait for DB to be ready --
echo "Waiting for local flooddev database to be available..."
until docker compose exec -T $LOCAL_CONTAINER_NAME \
  psql -U $LOCAL_USER -d $LOCAL_DB -c "SELECT 1;" > /dev/null 2>&1; do
  sleep 2
done

# -- Check PostGIS extension --
echo "Checking for PostGIS..."
if ! docker compose exec -T $LOCAL_CONTAINER_NAME \
  psql -U $LOCAL_USER -d $LOCAL_DB -tAc "SELECT extname FROM pg_extension WHERE extname = 'postgis';" | grep -q postgis; then
  echo "❌ PostGIS is not installed in the local DB. Aborting."
  exit 1
fi

# -- Check required schemas exist --
echo "Verifying required schemas..."
for schema in "${REQUIRED_SCHEMAS[@]}"; do
  if ! docker compose exec -T $LOCAL_CONTAINER_NAME \
    psql -U $LOCAL_USER -d $LOCAL_DB -tAc "SELECT schema_name FROM information_schema.schemata WHERE schema_name = '$schema';" | grep -q "$schema"; then
    echo "❌ Required schema '$schema' does not exist. Aborting."
    exit 1
  fi
done

# -- Stream data --
echo "Streaming data from $REMOTE_DB_URL into local DB..."

PGPASSWORD=$(echo "$REMOTE_DB_URL" | sed -E 's/^.*:\/\/[^:]+:([^@]+)@.*$/\1/') \
pg_dump --format=plain --no-owner --no-privileges --data-only $EXCLUDE_OPTIONS "$REMOTE_DB_URL" | \
# Remove problematic SET commands
sed '/^SET transaction_timeout/d' | sed '/^SET idle_in_transaction_session_timeout/d' | \
docker compose exec -T $LOCAL_CONTAINER_NAME \
  psql -U $LOCAL_USER -d $LOCAL_DB

echo "Data successfully imported from remote."
