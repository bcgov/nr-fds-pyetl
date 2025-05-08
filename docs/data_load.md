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
1. The DDL for an oracle database has been generated.
1. Object Storage buckets have been procured
1. Data extract has been run and the data exists in the buckets

# Data Load Instructions

A separate process has been created that will cache the data from the TEST and
PROD environments for a specific application to an object store bucket.
[see here](./data_extract.md)


# Run data injest on Oracle db only

* requires the [data classification spreadshee](#get-data-classification-spreadsheet)
* requires [object store secrets](#object-store-environment-variables)

`docker compose up oracle-data-load`

# Run data injet on Postgres db only

1. pulls the migrations from the nr-spar repo
1. runs the migrations
1. loads the data that has been cached in object store

* requires [object store secrets](#object-store-environment-variables)

`docker compose up postgres-data-load`

## Bring up Postgres AND Oracle w/ Data

The docker compose will spin up the oracle environment, run the migrations to
create the table structures, and then finally pull the data from object store
and load it into the oracle database.

It will also create the postgres database that represents new spar, runs the
migrations, and loads the cached data from object store.

```docker compose up etl```


# Pre-requisites

Sections below are referenced via links identifying which pre-reqs are required
for different steps.

## Environment Variables

Most of these environment variables are defined in the docker compose and
therefor do not have to be populated.

### Object store Environment Variables

To load data you must populate the following environment variables to enable
connectivity to the object store buckets, that contain the actual backup
files.  Substitute TEST|PROD for <env>.  Add them to a `.env` file.


1. `OBJECT_STORE_USER_<env>`
1. `OBJECT_STORE_SECRET_<env>`
1. `OBJECT_STORE_BUCKET_<env>`
1. `OBJECT_STORE_HOST_<env>`
1. `ORACLE_SCHEMA_TO_SYNC_<env>`

Ideally these environments should be defined in a .env file in the root of this
repository.  The docker-compose is configured already to load that file to
populate environment variables in the container.

## Data Classification Spreadsheet

The data load requires access to the data classification spreadsheet which can be
downloaded [here](https://nrs.objectstore.gov.bc.ca/muyrpr/data_classification/CLIENT%20ECAS%20GAS2%20ILCR%20ISP.xlsx)

Copy the file spreadsheet to the path ./ora-env/data/temp/data_classification.xlsx
