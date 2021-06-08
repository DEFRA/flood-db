# Impacts

This dataset provided by area teams in the form of csv/xls spreadsheets contains information about historical events.

# Loading Instructions

1.  Currently, the csv file received requires a small amount of alteration so that it is in the same format as the `u_flood/impacts` database table. This means the data can the be directly copied to the database. The most recent csv file recieved required the following actions ( n.b. keep these steps up to data in case the format of the incoming csv file or database table change):

* Remove columns `Impact Id` and `Gauge`

* Convert any embedded carriage return and line feed to spaces in the `Short Name` or `Description` columns. (Suggest using the `Edit/Find and replace` function in spreadsheet software (e.g. Excel, LibreCalc, Numbers) to perform this)

* Split column `Location (Longtitude, Latitude)` into individual `Longtitude` and `Latitude` columns. (Sugest using `Data/Text to Columns` function in spreadsheet software).

* Save the file in the `flood-db` repository as `/data-load/impacts/impacts.csv` with pipe (`|`) as the delimiter not comma. Then merge into the `flood-db` dev branch


2.  Load the data into the development database by running Jenkins job - `LFW_DEV_MISC_JOBS/job/LFW_DEV_99_LOAD_IMPACTS`. This job takes the file created in step 1 and runs the `data-load/impacts/impact-copy-statement` sql script that updates the `impacts` table and refreshes the `impacts_mview` view.


3.  Test that the that historic events are displayed correctly on the station pages in the development environment. 


4.  On successful completion of step 2, load the data into the test database. First merge `flood-db dev` branch into `tst` so the `impacts.csv` file created in step 1 is referenced. Then run Jenkins job `LFW_TST_MISC_JOBS/job/LFW_TST_99_LOAD_IMPACTS`.


5.  Repeat the tests performed in step 3 but now in the test environment.


6.  Once tested and signed off flood-db will need merging into master ready for release into production.
