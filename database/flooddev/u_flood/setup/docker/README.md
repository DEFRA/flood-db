# Background

This directory contains all the files necessary to run the flood DB locally in a docker image.

## Prerequisites

* docker

# Build and run docker DB container

To see usage:

`./refresh-db -h`

To build the DB image from a backup from another DB use the command below:

`./refresh-db -d [database connection string]`

Without the -d option the DB image will be built from the last DB backup.

`./refresh-db`

Note: the refresh-db script will also apply any outstanding liquibase scripts which are missing from the restored DB. See also the Liquibase section below.

# Starting the DB after the refresh

The DB needs starting after the refresh using `docker compose up`.

If you want to connect to the DB from a client running on your local machine (e.g. pgAdmin or the flood-service running locally) you will need to expose a port.

To do this create a docker compose file called, for example, docker-compose-override.yml with the following contents

```
services:
  flood-db:
    ports:
      - "5432:5432"
```

Then start the DB using `docker compose -f docker-compose.yml -f docker-compose-override.yml up`

As this file is specific to your local environment it should not be committed to the repo.

Note: The port mapping you use depends on if you have Postgres installed and running on your machine.  If you do then, to avoid clashing port numbers, the port mapping should not be "5432:5432" (e.g. "5433:5432", the server name in the connection string would then be `localhost:5433`).  If not then the mapping can be as above (i.e. "5432:5432" ).

# Liquibase

The database is updated using liquibase.

  * A simple self-contained example of a liquibase update would be [PR-66](https://github.com/DEFRA/flood-db/pull/66)
  * Scripts can be applied without having to do a full restore using `docker compose -f docker-compose.yml -f docker-compose-override.yml  -f docker-compose-liquibase.yml run --rm liquibase`
  * In the integration and production environments the Jenkins job `LFW_{STAGE}_02_UPDATE_DATABASE` will apply liquibase scripts  


# To run the pgTap DB tests

[https://pgtap.org/]

## PGTap notes

* the tests are developer tests in that they (currently) only run locally on a developer machine
* the tests are dependent on a specific snapshot of the DB as contained in the backup file on s3 which is copied to the db-backups/flood-db.bak file. This will overwrite any existing db backup created by the `refresh-db` script.

```
AWS_PROFILE=[profile name] ./run-db-tests
```

# Notes

* the flood-service can then be run connected to the local DB using `FLOOD_SERVICE_CONNECTION_STRING=postgres://u_flood:secret@localhost:5432/flooddev node .` (see comments above on the port number)
* the DB backup file for backup and restore is stored on a docker volume (`backup`) as `flood-db.bak`
* in order to run one of the data-load jobs without having to have psql installed then create a docker-compose-???.yml
  file using `docker-compose-thresholds.yml` (which loads station thresholds) as a template.
