# Target Area Update Notes

* Download the zipped TA data from the link in https://ea.sharefile.com/ provided by the External Digital Services team to the ./data directory
* Notes
  1) If you download multiple files at the same time then they will be zipped up together and will need extracting before proceeding
  1) the zipped shape files should be named according to the convention `flood_{type}_ENG_{date}.zip` where `{type}` is either 'alert' or 'warning' and `{date}` is a timestamp of the form 'yyyymmdd' (e.g. 20240211).
  1) Check the zipped shape files have read permission, sometimes unzipping tools don't set them
  1) Copy the zipped shape files to the `./data` directory
* Get a local copy of the dev db running in docker and containing a recent restore by following the instructions [here](https://github.com/DEFRA/flood-db/blob/dev/database/flooddev/u_flood/setup/docker/README.md#build-and-run-docker-db-container)

## Import the TA data into the local DB

Run the following from the `flood-db/data-load/ta-update` directory

```
# build a image containing psql and postgis
docker build -t ta-update -f TAUpdateDockerfile .

# import the target areas to the db running locally:
docker run \
  --name ta-update \
  --network cff_default \
  --rm \
  -e DB=postgres://u_flood:secret@flood-db:5432/flooddev \
  -e DATE_STAMP=20240221 \
  -v $(pwd)/data:/data \
  -v $(pwd)/scripts:/scripts \
  ta-update \
  /scripts/target-area-import.sh

```

After the above command has been run then do the following checks against the spreadsheet `FWIS_UAT_{date}.xlsx` from the file share site:

* The `target-area-import` script prints the counts for warning and alert areas before and after the import. Check these meet the counts expected from the spreadsheet 
* Using a running version of flood-app connected to the local DB, manually check a random sample of the added, deleted
and modified target areas taken from the spreadsheet to ensure the expected changes have happened.

## Export the TA data from the local DB

```
# export the target areas from the local db to a zip file
docker run \
  --name ta-update \
  --network cff_default \
  --rm \
  -e DB=postgres://u_flood:secret@flood-db:5432/flooddev \
  -e DATE_STAMP=20240221 \
  -v $(pwd)/data:/data \
  -v $(pwd)/scripts:/scripts \
  ta-update \
  /scripts/target-area-export.sh
```


## Upload the exported data to S3

After the `target-area-export` script is run then there wil be a file called `target_areas.zip` in the `./data` directory. This will needed uploading to an s3 bucket which will be accessed by the jenkins job `LFW_{env}_99_LOAD_FLOOD_ALERT_AREAS` (e.g. [LFW_DEV_99_LOAD_FLOOD_ALERT_AREAS]( https://lfwv2-jenkins.aws-int.defra.cloud/view/DEV/job/LFW_DEV_MISC_JOBS/job/LFW_DEV_99_LOAD_FLOOD_ALERT_AREAS/)) as well as other systems.

```
# check your S3 access is set up
docker run --rm -it \
  -v ~/.aws:/root/.aws \
  -v $(pwd)/data:/data \
  amazon/aws-cli \
  --profile lfw_developers_permissions-783559591987 \
  s3 ls s3://apsldnlfwsrv001/

```

Note: if you have not set up AWS access or you get a 'AWS token expired' message refer to the instructions in the appendices below on how to refresh the token before retrying the access check above

```
# upload exported TA's to S3 'archive' bucket
docker run --rm -it \
  -v ~/.aws:/root/.aws \
  -v $(pwd)/data:/data \
  amazon/aws-cli \
  --profile lfw_developers_permissions-783559591987 \
  s3 cp /data/target_areas.zip s3://apsldnlfwsrv001/202402-target-areas/ 

# upload exported TA's to S3 'shared' bucket
docker run --rm -it \
  -v ~/.aws:/root/.aws \
  -v $(pwd)/data:/data \
  amazon/aws-cli \
  --profile lfw_developers_permissions-783559591987 \
  s3 cp s3://apsldnlfwsrv001/202402-target-areas/target_areas.zip s3://apsldnlfwsrv001/liquibase/target_areas.zip
```

Note: you will need to update the date stamp 20240221 in both docker commands above to match that used in the earlier scripts 

## Update the Target Areas in the dev environment

In order to test the upload to the S3 shared bucket, run the [LFW_DEV_99_LOAD_FLOOD_ALERT_AREAS](https://lfwv2-jenkins.aws-int.defra.cloud/view/DEV/job/LFW_DEV_MISC_JOBS/job/LFW_DEV_99_LOAD_FLOOD_ALERT_AREAS/) job and repeat the checks against the spreadsheet for the dev environment.

## Regenerate the list of TA's within 8km of each river station

The scripts below will update the `data-load/station_ta_8km/station_ta_8km.sql` file to reflect the target area data changes. The changes to the `station_ta_8km.sql` file will be commited, merged into master and used when the LOAD_ALERT_AREAS Jenkins job is run.

```
# regenerate list for TA's within 8km of a river station
docker run \
  --name ta-update \
  --rm \
  --network cff_default \
   -v $(pwd)/../station_ta_8km:/scripts \
  ta-update \
  psql postgres://u_flood:secret@flood-db:5432/flooddev -f /scripts/new_generate_station_ta_8km.sql

# export the list generated above
docker run \
  --name ta-update \
  --rm \
  --network cff_default \
   -v $(pwd)/../station_ta_8km:/data \
  ta-update \
  pg_dump postgres://u_flood:secret@flood-db:5432/flooddev -a --inserts -t u_flood.station_ta_8km -f /data/station_ta_8km.sql
```

# Appendices

## Notes on AWS SSO token creation/refresh 

If you get an authorisation failure or token expired message you'll need to create/refresh the token using 

```
# refresh SSO token
docker run --rm -it \
  -v ~/.aws:/root/.aws \
  -v $(pwd)/data:/data \
  -e DATE_STAMP=20240221 \
  amazon/aws-cli \
  config sso
```

### Notes:

1) When prompted, you will need to enter the authorisation token through the page https://device.sso.eu-west-2.amazonaws.com/. You should do this action manually on a corporate device as AWS console access is secured using Active Directory which is not available when using off-net development devices.
1) Once the code has been entered return to the terminal session on your development device where you will complete the token refresh. For all prompts other than the selection of an AWS account (see below) you should accept the default value.
1) When given the list of AWS accounts to select from you should select "Apps Shared Services Cloud" (Account ID: 783559591987).
