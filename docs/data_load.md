# Overview

<img src="https://lh3.googleusercontent.com/pw/AP1GczMJaVEHHphmPE_w4ekcrlvD9UIGulCzzPXXIrPen7cEzwjA3CSlNLMyZMJpXrNC8ySVjEXoQra98CQSD__EQuINSi4QXiKkraBFw-1FLsV_jyKghJGFri4v9M3PKSHUeLbsgCP0Ns2GAhO0yYKAfqj6_Q=w1381-h778-s-no-gm?authuser=0" width="700px">

Instructions on how to create and configure, and ultimately load data to
a local development oracle and postgres database.  The intent is to allow  local development
without any concerns on load / data polution and or corruption to the various
on prem line of business databases, or the actual new spar database.

**Assumptions:**
1. The DDL has been extracted and configured with flyway migrations
1. Object Storage buckets have been procured
1. Data has already been extracted from LOB databases and loaded to object
    storage
1. Current version of tooling only supports tables.

# Data Load Instructions

A separate process has been created that will cache the data from the TEST and
PROD environments for a specific application to an object store bucket.
[see here](./data_extract.md)


## Define Environment Variables

To load data you must populate the following environment variables to enable
connectivity to the object store buckets, that contain the actual backup
files.  The environment variables are concluded by the environment who's
data you want to pull.  Current possible options are either `TEST` or `PROD`.

The one other environment variable is `ORACLE_SCHEMA_TO_SYNC_<env>`. This
variable defines what schema in the local environment to load the data to.  It
is recommended that this be the same schema as the original data was extracted
from.

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
