# HOW TO setup postgres RDS for LFW service refresh application

# 1
Create a new database on RDS/Aurora service, default name `flooddev`

##! Execute following jobs in order, checking console output for any errors as they may not show up on job run status.

# 2
LFW_{stage}_99_DATABASE_SETUP_PIPELINE   ## nb ensure database name and connection details are correct for your database

# 3
LFW_{stage}_99_ENGLAND_10k

# 4
LFW_{stage}_02_UPDATE_DATABASE
###### NOTE LFW_{stage}_02_UPDATE_DATABASE may need running twice, first time will fail, 2nd should pass. some weird race condition that can't work around.

# 5
LFW_{stage}_99_LOAD_FLOOD_ALERT_AREAS

# 6 
LFW_{stage}_99_LOAD_IMPACTS

# 7
LFW_{stage}_99_LOAD_RIVERS

Note after the database is seeded as above the FWFI pipeline needs to be deployed as per below, along with lfw-data serverless application.

After this the stationProcess lambda function needs executing to populate the telemetry_context table.

The following steps are out of scope for database setup, but necessary for the overall setup so are included for reference.

# 8
LFW_{stage}_99_UPDATE_FWFI_LOADER_PIPELINE

# 9
LFW_{stage}_99_DEPLOY_FLOOD_DATA_PIPELINE
