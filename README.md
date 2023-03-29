# flood-db

This is the database configuration for the service refresh application for the digital flood service.

The database source control is based around liquibase https://www.liquibase.org/

# Pre requisites

The database has been copied from the production live flood warnings application, so either a snapshot of that database is required or the installation instructions need following

# Installation
(these have not been tested recently, and have been copied from the legacy database installation)

## tablespaces

```
CREATE TABLESPACE flood_indexes
  OWNER u_flood
  LOCATION '/srv/postgres/data/wiyby/wiyby_indexes';

CREATE TABLESPACE flood_tables
  OWNER u_flood
  LOCATION '/srv/postgres/data/wiyby/wiyby_tables';
```

## flooddev database
Create a new database `flooddev` owned by `u_flood` with default tablespace set to `flood_tables`;

## schemas & postgis

The following assumes that postgis is installed and available to your vm/rds, if not follow installation guide: http://postgis.net/docs/postgis_installation.html#install_short_version

### If creating an RDS use the following script

```
psql -h ${DB_HOST} -U ${DB_USER} -d ${DB_NAME} -f lfw/database/flooddev/u_flood/setup/rds_initial_setup.sql
```

### If an installation of postgres on a VM use this script

```
psql -h ${DB_HOST} -U ${DB_USER} -d ${DB_NAME} -f lfw/database/flooddev/u_flood/setup/non_rds_initial_setup.sql
```

## liquibase properties

Ensure that liquibase.properies has the correct connection details for the database

```
driver=org.postgresql.Driver
changeLogFile=./changelog/db.changelog-master.xml
username=u_flood
password={{DB_PWD}}
defaultSchemaName=u_flood
contexts={{ENV}}
url=jdbc:postgresql://{{DB_CONN_STR}}
```


## liquibase update
Then in the dir database/flooddev/u_flood/ from within a terminal run

```
liquibase update
```

# Seeding data
Once the database is set up and up to date with the latest schema and scripts the following datasets need loading:

- england_10k
- flood_alert_areas
- flood_warning_areas
- thresholds
- river_stations

All of the details for loading these data sets can be found in the appropriate jenkins job.

Following these data sets, lfw-data data integration tier will need to be deployed and running to feed data into the database. station-process will probably need running as a one off to load the station context data.

# Updating Rivers and Stations in River Stations list

After receiving updated 'river-stations.csv' and "rivers.csv"

Convert rivers.csv to .tsv

ensure columns in files are in the following order "river-stations.csv" (slug,station_id,order), "rivers.tsv" (slug,local_name,qualified_name)

replace existing files located in data-load/river_stations

to apply to environment run job LFW_DEV_99_LOAD_RIVER_STATIONS in the LFW_DEV_MISC_JOBS folder in Jenkins
