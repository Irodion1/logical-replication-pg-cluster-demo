#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  CREATE ROLE replicator WITH REPLICATION LOGIN ENCRYPTED PASSWORD 'repl_password';

  CREATE DATABASE groups with owner postgres;
  GRANT CONNECT ON DATABASE groups TO replicator;
  \connect groups;
  CREATE SCHEMA sch_gr;
  GRANT USAGE ON SCHEMA sch_gr to replicator;
  CREATE TABLE sch_gr.groups
  (
      id               serial PRIMARY KEY,
      group_name       VARCHAR(50) UNIQUE NOT NULL,
      description      TEXT,
      leaderboard_rank int
  );
  GRANT SELECT ON ALL TABLES IN SCHEMA sch_gr TO replicator;
  INSERT INTO sch_gr.groups(group_name, description, leaderboard_rank)
  SELECT concat('test_group_', idx),
         concat('lorum-ipsum', idx),
         idx
  FROM generate_series(1, 100) idx;
  CREATE PUBLICATION pub_gr_replicator FOR TABLES IN SCHEMA sch_gr WITH (publish = 'insert, update, delete, truncate', publish_via_partition_root = false);
  ALTER PUBLICATION pub_gr_replicator OWNER TO replicator;

  CREATE DATABASE users with owner postgres;
  GRANT CONNECT ON DATABASE users TO replicator;
  \connect users;
  CREATE SCHEMA sch_usr;
  GRANT USAGE ON SCHEMA sch_usr to replicator;
  CREATE TABLE sch_usr.users
  (
      id                serial PRIMARY KEY,
      username          VARCHAR(50) UNIQUE NOT NULL,
      some_data         TEXT,
      some_rng_variable int
  );
  GRANT SELECT ON ALL TABLES IN SCHEMA sch_usr TO replicator;
  INSERT INTO sch_usr.users(username, some_data, some_rng_variable)
  SELECT concat('user_', idx),
         concat('lorem-ipsum_', idx),
         idx
  FROM generate_series(1, 100) idx;
  CREATE PUBLICATION pub_usr_replicator FOR TABLES IN SCHEMA sch_usr WITH (publish = 'insert, update, delete, truncate', publish_via_partition_root = false);
  ALTER PUBLICATION pub_usr_replicator OWNER TO replicator;

EOSQL