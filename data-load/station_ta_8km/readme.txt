# Station to target area 8km relationship data

This dataset was added in as part of the performance testing agsinst the service refresh environment post mvp beta release.

The data set generates a cached dataset of all the river level stations and the target areas that fall within 8km of them.

The data set needs to be updated at the same time as the target area data load is performed quarterly.


# instructions

1.  Using a psql connection to the cff development database execute the script ./new_generate_station_ta_8km.sql
	e.g. psql -h lfw-dev-rds.aws-int.defra.cloud -U u_flood -d flooddev -f new_generate_station_ta_8km.sql
	Enter the password to the dev database when prompted.

	The expected output should resemble the following: 

	TRUNCATE TABLE
	INSERT 0 11158
	INSERT 0 25979

2.  Once the dataset has been generated check on the cff development front end that the auto tests are completing correctly, and that stations are showing the relevant warnings.

3.  Once tested now export the data so that it can be stored in github and loaded into other environments.
	a.  Run ./dump_station_ta_8km.sh in terminal
		If following error received: 

		pg_dump: error: server version: 15.10; pg_dump version: 13.21 (Ubuntu 13.21-1.pgdg24.04+1)
		pg_dump: error: aborting because of server version mismatch

		Prefix the run command as follows:

		/usr/lib/postgresql/15/bin/pg_dump

	b.  Check that $FLOOD_SERVICE_CONNECTION_STRING is correctly set to database
	c.  Exports file to this directory called station_ta_8km.sql

4.  Commit and push the new station_ta_8km.sql file to github repository

5.  Execute jenkins job LFW_DEV_99_LOAD_FLOOD_ALERT_AREAS
	a.  This reloads the data into dev, so is a step to confirm the exported data and load is all good
	b.  Run auto tests
	c.  Check stations for linked warnings

6.  Merge flood-db dev branch into tst

7.  Execute jenkins job LFW_TST_99_LOAD_FLOOD_ALERT_AREAS
	a.  Run auto tests on test
	b.  Check stations for linked warnings

8.  Once tested and signed off flood-db will need merging into master ready for release into production as part of the target area quarterly load.
