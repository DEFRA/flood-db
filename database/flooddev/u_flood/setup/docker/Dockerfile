FROM postgis/postgis:13-3.1
ENV PATH=${PATH}:/scripts
COPY docker/db_setup.sh /docker-entrypoint-initdb.d/db_setup.sh
WORKDIR /db-init-scripts
COPY docker/tablespaces.sql .
COPY docker/roles.sql .
COPY docker/database.sql .
COPY ./non_rds_initial_setup.sql .
RUN mkdir -p /wiyby/wiyby_tables /wiyby/wiyby_indexes
RUN chown -R postgres:root /wiyby
RUN apt-get update && apt-get install -y postgresql-13-pgrouting
