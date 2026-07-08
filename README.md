# flood-db

This is the database configuration for the service refresh application for the digital flood service.

The database source control is based around liquibase https://www.liquibase.org/

Note: a lot of the detail below is redundant if you are running the DB locally using docker. The instructions in [this](database/flooddev/u_flood/setup/docker/README.md) readme are probably more relevant.

# Updated (2025)

## Initialize database (Jenkins)

WebOps created a temporary database under the dev environment RDS cluster (`temp_flood_db`). A service request will need to be created in the future once they delete the temporary database.

### 1. Run Setup Job

Job: **LFW_DEV_99_DATABASE_SETUP_PIPELINE**

1. Configure _Properties Content_:
    - Set `PG_DATABASE` to the temporary database

This will create the schemas, roles and configure privleges on them so once the tables are added, `u_flood` and the incoming sql files will have the correct permissions.

### 2. Run Update Job

Nothing to change here, unless changes have been made on branches.

`DB_REPO_BRANCH` - points to the repo containing the Liquibase files

`CONFIG_REPO_BRANCH` - points to the liquibase config that sets the postgres url (this will contain a hardcoded database name, so creating a branch with the temporary database is advised)

#### Checksums

If a change has been made to an old changelog sql file or ordering has been changed, this will cause a `checksum` error in the Jenkins job.

This will look something like:

```bash
changelog/db.changelog-0.4.1.xml::3::username was: 9:d969a0b04f0b1c582d04774622630636 but is now: 9:b41459975317ac437f2c2b9985ac6141
```

To fix this, either:

#### Update the checksum manually:

1. Copy the "is now" checksum output from the Jenkins job error
2. Log in to that environments database (via a postgres client) and open the `databasechangelog` table
3. Find the row that the above will correspond to:
    - column: filename - `changelog/db.changelog-0.4.1.xml`
    - column: id - `3`
    - column: author - `username`
4. Update column `md5sum` with the new checksum and save the changes
5. Run the Jenkins update job again

#### Clear the checksums

1. In the GitLab repo `flood-pipelines/jenkins/database/updateDatabaseJenkinsfile`, add the line above the `mvn liquibase:update` command:

```bash
mvn -Denvironment=rds liquibase:clearCheckSums -f ${DB_REPO_DIRECTORY}/database/flooddev/u_flood/pom.xml
```
2. Run the Jenkins update job

## Create database (local)

Use the instructions in the [Docker README](database/flooddev/u_flood/setup/docker/README.md) to create a local containerised database from a
snapshot of a cloud database.

---

# Legacy Pre requisites (DO NOT USE - information retained for historical reference only)

The database has been copied from the production live flood warnings application, so either a snapshot of that database is required or the installation instructions need following

# Legacy Installation (DO NOT USE - information retained for historical reference only)
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
