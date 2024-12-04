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



## Without Docker

The repo currently contains two python poetry configurations.  For this reason
to run the sync process locally


## With Docker


