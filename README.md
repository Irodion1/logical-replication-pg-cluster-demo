## Introduction
This project contains a docker-compose setup for a master-replica PostgreSQL cluster with logical replication. 
It was created only to test several approaches for handling DDL changes with logical replication from a separate-DB instance to a separate-schema instance.
Please, don't consider it to be an example of a proper setup in production use, its main goal is to simplify the next action cycle:
1. Run a clean cluster with predefined users, schema, initial data, and publications configured
2. Run manual DDL changes (e.g. `CREATE TABLE ...` or `ALTER TABLE ADD COLUMN ...`) alongside DDL handling approaches
3. Check results
4. Delete container and volumes to start again hoping the next approach will be better :)

> You can use this simple setup if you just to test something new in the cluster and have a way to restart clean fast.

## Details
#### Configuration
We have very basic handling of pg configurations separately for master and slave.
It is needed as logical replication requires at least to configure `wal_level`. 
There is a way to do it with CLI, but we decided to keep options to easily modify configurations separately in files instead of bit strings

#### Changed settings in `postgresql.conf`
- `wal_level`: `logical` for master, `replica` for replica
- `max_wal_senders = 6` on master
- `max_replication_slots = 6` on master

#### Initialization

The cluster has initially: 
- `groups` and `users` dbs on master, `dwh_test` db on replica
- One schema for each db: `sch_gr` and `sch_usr` both on master/replica
- One table for each schema: `groups` and `users` both on master/replica
- Some initial data through `generate_series` only on master
- `replicator` user with minimum rights as owner of publications on master with hardcoded password `repl_password`
- Publications on master for each schema
- _Probably_ subscriptions on the replica. It works mostly, but sometimes can fail if pg starts too slowly on master.
We don't care about it enough to pay attention to fixing it. In case it happens, just run 
`CREATE SUBSCRIPTION ...` commands for replica manually

### Notes 
> - `docker-compose` should be run from the root folder of the project as a working directory in order for relative paths to work properly
> - Make sure you specified a location of `.env` file, it contains the password for `postgres` users 
> - pgAdmin is accessible on the 5050 port, auth `admin_user@example.com:admin`. It is NOT configured for created DBs.
> But all configurations will persist when you recreate PG containers/volumes
