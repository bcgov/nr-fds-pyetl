# Overview

<img src="https://lh3.googleusercontent.com/pw/AP1GczMJaVEHHphmPE_w4ekcrlvD9UIGulCzzPXXIrPen7cEzwjA3CSlNLMyZMJpXrNC8ySVjEXoQra98CQSD__EQuINSi4QXiKkraBFw-1FLsV_jyKghJGFri4v9M3PKSHUeLbsgCP0Ns2GAhO0yYKAfqj6_Q=w1381-h778-s-no-gm?authuser=0" width="700px">

Instructions on how to create and configure, and ultimately load data to
a local development oracle and postgres database.  The intent is to allow
local development without any concerns on load / data polution and or corruption
to the various on prem line of business databases, or the new spar
database.

For most requirements this is the doc to folllow.  Re-running the extraction
should only be required if you need the latest greatest data in your dev
environment.

**Assumptions:**
1. The DDL has been extracted and executed using flyway to a dockerized oracle database
1. Object Storage buckets have been procured
1. Data has already been extracted from LOB databases and loaded to object
    storage

# Data Load Instructions

A separate process has been created that will cache the data from the TEST and
PROD environments for a specific application to an object store bucket.
[see here](./data_extract.md)

## Define Environment Variables

### Oracle environment variables

The injest process only needs to connect to the local database so configure the
following env variables.

* ORACLE_HOST_LOCAL=localhost
* ORACLE_PORT_LOCAL=1521
* ORACLE_SERVICE_LOCAL=DBDOCK_01
* ORACLE_SYNC_USER_LOCAL=THE
* ORACLE_SYNC_PASSWORD_LOCAL=default
* ORACLE_SCHEMA_TO_SYNC_LOCAL=THE


### Object store environment variables

To load data you must populate the following environment variables to enable
connectivity to the object store buckets, that contain the actual backup
files.  Substitute TEST|PROD for <env>


1. `OBJECT_STORE_USER_<env>`
1. `OBJECT_STORE_SECRET_<env>`
1. `OBJECT_STORE_BUCKET_<env>`
1. `OBJECT_STORE_HOST_<env>`
1. `ORACLE_SCHEMA_TO_SYNC_<env>`

Ideally these environments should be defined in a .env file in the root of this
repository.  The docker-compose is configured already to load that file to
populate environment variables in the container.

## Run Docker Compose

The docker compose will spin up the oracle environment, run the migrations to
create the table structures, and then finally pull the data from object store
and load it into the oracle database.

It will also create the postgres database that represents new spar, runs the
migrations, and loads the cached data from object store.

```docker compose up etl```
