psql -f /db-init-scripts/roles.sql
psql -f /db-init-scripts/tablespaces.sql
psql -v DB_NAME="${DB_NAME}" -f /db-init-scripts/database.sql 
psql -v DB_NAME="${DB_NAME}" -f /db-init-scripts/non_rds_initial_setup.sql
# psql -d $DB_NAME -f /db-init-scripts/rds_initial_setup.sql

# change 'secret' below to your prefered password
psql -c "ALTER USER u_flood WITH PASSWORD 'secret';"

# Note: need to use --database rather than PGDATABASE as the
# earlier scripts will fail otherwise
psql --dbname $DB_NAME -f /backup/flood-db.bak

psql --dbname $DB_NAME -f /db-init-scripts/refresh-telemetry-function.sql

echo "Database refresh complete"
