-- tablespace definitions for flood db running in docker image

CREATE TABLESPACE flood_indexes
  OWNER u_flood
  LOCATION '/wiyby/wiyby_indexes';

CREATE TABLESPACE flood_tables
  OWNER u_flood
  LOCATION '/wiyby/wiyby_tables';

