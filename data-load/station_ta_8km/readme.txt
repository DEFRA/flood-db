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

	For progress reporting, run generate_station_ta_8km_with_progress.sql instead
	of new_generate_station_ta_8km.sql (do not run both):

	psql -h lfw-dev-rds.aws-int.defra.cloud -U u_flood -d flooddev -v ON_ERROR_STOP=1 -f generate_station_ta_8km_with_progress.sql

	Alternatively, from this directory using your connection string:

	/usr/lib/postgresql/15/bin/psql "$FLOOD_SERVICE_CONNECTION_STRING" -v ON_ERROR_STOP=1 -f ./generate_station_ta_8km_with_progress.sql

	Use psql -f to execute the rebuild. pg_dump only exports existing data;
	it does not run the rebuild or produce progress notices. Never redirect
	pg_dump output into either generate script: > overwrites the script.
	Export to station_ta_8km.sql only after rebuilding and checking the results.

	The progress script produces output like:

	NOTICE:  Starting station_ta_8km rebuild for 250 stations; truncating destination (may wait for a lock).
	NOTICE:  Processed 100/250 stations; last 100 took 00:00:12; total elapsed 00:00:12.1; inserted 400 alert and 900 warning relationships.
	NOTICE:  Processed 200/250 stations; last 100 took 00:00:13; total elapsed 00:00:25.1; inserted 800 alert and 1800 warning relationships.
	NOTICE:  Processed 250/250 stations; final 50 took 00:00:06; total elapsed 00:00:31.1.
	NOTICE:  Completed station_ta_8km rebuild: 250 stations; 1000 alert and 2250 warning relationships inserted (3250 total); total runtime 00:00:31.1.
	DO

	Counts and timings above are illustrative. Each processed station means one row
	from telemetry_context_mview checked against both alert and warning areas,
	even if it has no matches. Notices are sent to the terminal every 100 stations,
	with a final notice for any remaining stations and a completion summary.
	Timings use wall-clock time; total runtime includes the initial count and any
	wait for the TRUNCATE lock. No permanent function needs to be installed.

	The rebuild runs in a single transaction: an error or cancellation rolls back
	both the truncate and inserts, preserving the previous data. The TRUNCATE lock
	is held until the transaction ends and can block readers during the rebuild.
	Progress notices do not indicate committed batches. With the command above,
	successful completion of the DO statement commits the rebuild; if you wrap it
	in an explicit transaction, you must commit that transaction yourself.
	This adds progress reporting, not a speed optimisation; processing stations
	individually can be slower than the previous set-based inserts.

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
