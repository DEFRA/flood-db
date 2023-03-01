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

# To run the pgTap DB tests

[https://pgtap.org/]

## Notes

* the tests are developer tests in that they (currently) only run locally on a developer machine
* the tests are dependent on a specific snapshot of the DB as contained in the backup file on s3 which is copied to the db-backups/flood-db.bak file. This will overwrite any existing db backup created by the `refresh-db` script.

```
mkdir -p db-backups
aws --profile [profile name here] s3 cp s3://lfw-rloi/cff-performance-test-resources/flood-db-060220231348.bak.gz db-backups/flood-db.bak.gz
gunzip db-backups/flood-db.bak.gz
./refresh-db
docker compose -f docker-compose.yml up -d
docker compose -f docker-compose.yml -f docker-compose-pgtap.yml run --rm db_check
```

# Notes

* the flood-service can then be run connected to the local DB using `FLOOD_SERVICE_CONNECTION_STRING=postgres://u_flood:secret@localhost:5432/flooddev node .` (see comments above on the port number)
* the DB backup file for backup and restore is stored in a host directory which is bind mounted (`db-backup/flood-db.bak`) by the `docker-compose-restore.yml` file
