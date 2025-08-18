FROM postgis/postgis:15-3.5
RUN apt-get update && apt-get install -y postgresql-15-pgrouting
ENV PATH=${PATH}:/scripts
COPY docker/db_setup.sh /docker-entrypoint-initdb.d/db_setup.sh
WORKDIR /db-init-scripts
COPY docker/tablespaces.sql .
COPY docker/roles.sql .
COPY docker/database.sql .
COPY docker/refresh-telemetry-function.sql .
COPY ./non_rds_initial_setup.sql .
RUN mkdir -p /wiyby/wiyby_tables /wiyby/wiyby_indexes
RUN chown -R postgres:root /wiyby
