psql -f /db-init-scripts/roles.sql
psql -f /db-init-scripts/tablespaces.sql
psql -f /db-init-scripts/database.sql 
psql -f /db-init-scripts/non_rds_initial_setup.sql

# change 'secret' below to your prefered password
psql -c "ALTER USER u_flood WITH PASSWORD 'secret';"

# Note: need to use --database rather than PGDATABASE as the
# earlier scripts will fail otherwise
psql --dbname flooddev -f /backup/flood-db.bak

psql --dbname flooddev -f /db-init-scripts/refresh-telemetry-function.sql

echo "Database refresh complete"
