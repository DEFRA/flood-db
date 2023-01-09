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

## Notes

* the DB needs starting after the refresh using `docker compose up`
* the flood-service can then be run connected to the local DB using `FLOOD_SERVICE_CONNECTION_STRING=postgres://u_flood:secret@localhost/flooddev node .`
* the DB backup file for backup and restore is stored on an docker volume (`backup`) as `flood-db.bak`

