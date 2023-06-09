#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  CREATE DATABASE dwh_test with owner postgres;
  \connect dwh_test
  CREATE SCHEMA sch_gr;
  CREATE TABLE sch_gr.groups
  (
      id               serial PRIMARY KEY,
      group_name       VARCHAR(50) UNIQUE NOT NULL,
      description      TEXT,
      leaderboard_rank int
  );

  CREATE SCHEMA sch_usr;
  CREATE TABLE sch_usr.users
  (
      id                serial PRIMARY KEY,
      username          VARCHAR(50) UNIQUE NOT NULL,
      some_data         TEXT,
      some_rng_variable int
  );

  CREATE SUBSCRIPTION sub_usr CONNECTION 'host=pg-master port=5432 user=replicator dbname=users password=repl_password' PUBLICATION pub_usr_replicator WITH (create_slot=true);
  CREATE SUBSCRIPTION sub_groups CONNECTION 'host=pg-master port=5432 user=replicator dbname=groups password=repl_password' PUBLICATION pub_gr_replicator WITH (create_slot=true);
EOSQL