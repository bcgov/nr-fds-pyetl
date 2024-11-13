# Intro

Describes how to configure python environment locally for debugging the code
in this repo.  It currently only applies to the data load scripts.  A ticket has
been created to allow both the sync and this dataload process to use the same
environment.

## python version

If not already installed install `pyenv`

Currently this project is using python 3.12, using pyenv make sure you are using that version.

`pyenv global 3.12`


## dependencies

Currently there are two separate processes in this repository, the `sync` scripts
which are configured to use a basic virtualenv, pip and a requirements.txt file.

The other is the data load / extraction processes that are setup to use poetry.
The purpose of data load / extraction processes is to enable an environment that
can be used to further develop and debug the `sync` process.  Once the data load
portion of this repo has been completed, the sync script will be update to use
poetry.  In the mean time the two approaches remain in place.

Install dependencies for first time

`poetry install`

## activate local env

`source $(poetry env info --path)/bin/activate`

## configure local environment variables

See the template env file `env_sample` for the different environment variables
that would need to be configured.

### Data Ingest

For the data ingestion process you should only required the following:

* `OBJECT_STORE_USER_<env>=`
* `OBJECT_STORE_SECRET_<env>`
* `OBJECT_STORE_BUCKET_<env>`
* `OBJECT_STORE_HOST_<env>`
* `ORACLE_SCHEMA_TO_SYNC_<env`

where env is either equal to `TEST` or `PROD`.  The env indicates the source of
the data that is to be loaded to the local database from object store.

#### start the docker compose

The docker compose command below will start the local version of oracle, and
will also run the data migrations creating the necessary table structures that
will be populated by subsequent scripts.

`docker compose up oracle-migrations`

#### run the data ingestion

`python data_prep/main_ingest.py <env>`

Where env is either `TEST` or `PROD`.  Env indicates which object store bucket
to load data from.

### Data Export

This process will update the data that is stored in object storage, resulting
in the next data ingestion process using the data that is created by the last
run of this process.

The export process needs to communicate with on prem databases.  To run these
processes you will need to do the following:

* configure VPN to be able to communicate with the database.
* ensure python env and dependencies are configured
* populate additional environment variables.

Again the `env_sample` is the best starting place for the environments that are
required to run this code.

That said the export requires all the envs of the Ingest process, plus the
following env vars that enable communication with the on prem database:

* `ORACLE_HOST_TEST`
* `ORACLE_PORT_TEST`
* `ORACLE_SERVICE_TEST`
* `ORACLE_SYNC_USER_TEST`
* `ORACLE_SYNC_PASSWORD_TEST`
* `ORACLE_USER_TEST`
* `ORACLE_PASSWORD_TEST`

#### Connect to VPN

At this stage connect to VPN and ensure you can ping the database host.

#### run the data ingestion

`python data_prep/main_ingest.py <env>`

Where env is either `TEST` or `PROD`.  The env indicates which on prem database
to connect to, as well as which object store bucket to write data to.
