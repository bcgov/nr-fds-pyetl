# Overview

This folder contains the sync script that is used to replicate data between old
and new spar applications.

# Running locally.
## Environment Variables:

* TEST_MODE - if only want to test set to 'Y'
* RUN_ENV = if absent assumes is running on openshift and will then use the
            encrypted listener to communicate with oracle.  If set to 'LOCAL'
            will use the standard oracle 1521 non encrypted port to chat with
            Larry. - hang on thinking if the port is 1521  is all we need
* EXECUTION_ID
* POSTGRES_HOST
* POSTGRES_PORT
* POSTGRES_USER
* POSTGRES_PASSWORD
* POSTGRES_DB
* ORACLE_PORT
* ORACLE_HOST
* ORACLE_SERVICE
* ORACLE_SYNC_USER
* ORACLE_SYNC_PASSWORD


## Option 1. Run sync script directly

Start by starting the local versions of the oracle and postgres databases.

```bash
docker compose up etl
```

Wait for the compose process to complete.

The repo currently contains two python poetry configurations.  For this reason
to run the sync process locally you need run from the sync directory.

```bash
cd sync
poetry install
# activate env
source $(poetry env info --path)/bin/activate
# run the script
python src/main.py
```


## Option 2. Run sync script through docker compose

```bash
docker compose up sync
```
