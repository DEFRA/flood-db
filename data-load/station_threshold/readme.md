# Station thresholds

Importing station threshold data from the Incident Management Threshold Database (IMTD) API and storing in the CFF database.

# Loading Instructions

Briefly, the loading process flow is as follows.  Threshold data for each station is requested from the IMTD API and then stored in a csv file. That csv file is then copied into the `station_threshold` table in the CFF database.

1.  Clone this repo and then change directory to `/data-load/station_threshold`. Then run:

    `npm i`


2.  Then execute the data import script:

    `node get-imtd-api-threshold.js`

    The node/js script `get-imtd-api-thresholds.js` issues http GET requests to the IMTD API for each station currently in the `rivers_mview` table. Threshold values for the station are then extracted from the returned JSON response and written to the csv file - `station-threshold.csv`.


3.  Check the `station-threshold.csv` file produced in step 2 has a valid header and rows look valid. Then merge the file into the `flood-db dev` branch


4.  Load the data into the development database by running Jenkins job - `LFW_DEV_MISC_JOBS/job/LFW_DEV_99_LOAD_THRESHOLDS`.

    This job takes the file created in step 1 and runs the `data-load/station_threshold/station-threshold-copy-statement` sql script that updates the `station_threshold` table.


5.  Test that the that threshold values are displayed on the CFF station page in the development environment.

    The values will appear under the `How levels here could affect nearby areas` section. The values will have the following accompanying text appearing alongside:
    
    * Property flooding is possible above this level. One or more flood warnings may be issued
    * Low lying land flooding is possible above this level. One or more flood alerts may be issued


6.  On successful completion of step 5, load the data into the test database.
    
    First merge `flood-db dev` branch into `tst` so the `station_threshold.csv` file created in step 1 is referenced.
    
    Then run Jenkins job `LFW_TST_MISC_JOBS/job/LFW_TST_99_LOAD_THRESHOLDS`.


7.  Repeat the tests performed in step 5 but now in the test environment.


8.  Once tested and signed off flood-db will need merging into master ready for release into production.
