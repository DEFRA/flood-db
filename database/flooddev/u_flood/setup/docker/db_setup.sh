psql -f /db-init-scripts/roles.sql
psql -f /db-init-scripts/tablespaces.sql
psql -f /db-init-scripts/database.sql 
psql -f /db-init-scripts/non_rds_initial_setup.sql

# change 'secret' below to your prefered password
psql -c "ALTER USER u_flood WITH PASSWORD 'secret';"

psql --dbname flooddev -f /backup/flood-db.bak

echo "Database refresh complete"
