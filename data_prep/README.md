# Overview

The `data_prep` directory contains scripts that can be used to create a local
development environment that mimics the postgres database that backs the new
spar application and is hosted on openshift, and the oracle database that backs
the old spar application which is hosted on prem.

The following summarizes the scripts that are in this directory:
* `main_ora_extract.py`: pulls data from on prem oracle databases to object storage
* `main_ora_ingest.py`: push data from object storage to containerized oracle
* `main_spar_extract.py`: pull data from openshift spar database to object storage
* `main_spar_ingest.py`: push data from object storage to containerized postgres databases

This is all to support a development environment for the sync process, and also
to enable support for debugging when trying to resolve issues that may come up
with the sync process.

The code bases between the `data_prep` and the `sync` processes are currently
completely distinct.  The only overlap is the data_prep creates a local env
that allows for development of the `sync` process.

# Local Development

## Create Local env using Docker Compose

To get the local env up and running all the fastest route is to:

1. populate the .env with the following secrets so that it can retrieve the data
   for the dataload from object store.  There are two sets of secrets, one to
   access the last dump for TEST and the other is for PROD

   Test env vars:
    * OBJECT_STORE_USER_TEST
    * OBJECT_STORE_SECRET_TEST
    * OBJECT_STORE_BUCKET_TEST
    * OBJECT_STORE_HOST_TEST

   Prod env vars:
    * OBJECT_STORE_USER_PROD
    * OBJECT_STORE_SECRET_PROD
    * OBJECT_STORE_BUCKET_PROD
    * OBJECT_STORE_HOST_PROD

2. Run the Docker compose

    `docker compose up etl`

   Bringing up the ETL service will do the following:
   * start the postgres database (mimics the nr-spar oc db)
   * retreive the migrations from the nr-spar repo
   * execute the migrations against the database
   * load the data cached in object store to postgres
   * start the oracle database (mimics the on prem ora db)
   * runs the migrations located in `data_prep/migrations_ora`
   * load the data cached in object store to oracle

## Trouble shooting

Sometimes the services don't come up cleanly.  Usually in this case just re-running
them will resolve the issue.  If this comes up try running the postgres and
oracle loads separately using:

oracle:
`docker compose up oracle-data-load`

postgres:
`docker compose up postgres-data-load`

## Run data load using python

Why?  If you are doing development of the python code this might be a useful
option, other reasons are debugging errors, running the python code through a
debugger etc.

#### Create the venv

* `uv sync`: installs or updates the dependencies in your virtual environment to
             match the versions specified in the lock file.  If the venv does
             not exist it will be created.

#### Run a script

Before you can run any script you need to populate the env variables.  See
the `env_sample` file for the various env vars that need to be populated for
different processes.

`uv run python <path to script>`

example for running oracle load...

`uv run python db_env_utils/main_ora_ingest.py TEST`

# More Info

* [Details on Data Extract / Refresh](../docs/data_extract.md)
* [Details on Data Injest / Load](../docs/data_load.md)
* [More info on local env development](../docs/local_dev.md)
