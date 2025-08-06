# flood-db

This is the database configuration for the service refresh application for the digital flood service.

The database source control is based around liquibase https://www.liquibase.org/

Note: a lot of the detail below is redundant if you are running the DB locally using docker. The instructions in [this](database/flooddev/u_flood/setup/docker/README.md) readme are probably more relevant.

# Updated (2025)

## Create database

To create a database from scratch, do the following:

```bash
cd database/flooddev/u_flood/setup/docker
```

Update `DB_NAME` in the `.env` file.

Allow docker to execute the file:
```bash
chmod +x ./wait-for-postgis.sh
```

To build:
```bash
docker compose \
  -f docker-compose.yml \
  -f docker-compose-liquibase.yml \
  up --build
```

To teardown:
```bash
docker compose \
  -f docker-compose.yml \
  -f docker-compose-liquibase.yml \
  down --remove-orphans -v
```

This will create the `flood-db` and `liquibase` containers and run through the commands to setup the database, permissions and the tables.

Note: The `docker-compose.yml` file contains the setting: `platform: linux/amd64`. This may be Mac specific, so I think this can be commented out for windows machines.

### Diff

If you want to see the differences between the local and remote databases, run the below command. When it completes, go to the docker UI and follow the instructions below.

```bash
cd database/flooddev/u_flood/setup/docker

docker compose \
  -f docker-compose.yml \
  -f docker-compose-liquibase.yml \
  -f docker-compose-liquibase-diff.yml \
  run --rm liquibase-diff
```

In the Docker UI:
```
Containers > cff > liquibase-diff (press play)
```
Once its finished, click the 3 dots and "view files". The diff output can be found in: `liquibase/changelog/diff-output.xml`.

### Populate data from remote

Once the database has been re-created locally, this file will populate it, streaming data from the remote instance.

```bash
cd database/flooddev/u_flood/setup/docker

./populate.sh <remote_postgres_url>
```

### changelog-local

This changelog contains SQL tables that are missing between local and remote.

### Files Added

- `.env.example`
  - env vars used for `liquibase-diff` only
- `populate.sh`
  - used to stream data from a remote instance in to local
- `wait-for-postgis.sh`
  - when running `docker compose`, liquibase container will wait for the flood-db container to finish and have postgis installed, before running. This ensures its functions are ready to be used within the sql files
- `Dockerfile.liquibase`
  - Installs `psql` on to the liquibase container so we can check when postgis has been installed an ready
- `docker-compose-liquibase-diff.yml`
  - outputs the differences between local and remote instances

---

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

ensure columns in files are in the following order:

"river-stations.csv" (slug,station_id,order), 
"rivers.tsv" (slug,local_name,qualified_name)

replace existing files located in data-load/river_stations

to apply to environment run job LFW_DEV_99_LOAD_RIVER_STATIONS in the LFW_DEV_MISC_JOBS folder in Jenkins
