# Overview

This folder contains the init scripts used when local oracle envs are created

The creation of the local environment relies heavily on the
[nr-ora-env](https://github.com/bcgov/nr-oracle-env) repo.

The basic steps to generation of a disposable database environment are
identified in the [root readme](../README.md) for this repo.

# Fix TEST sync job

A script used to exist in this folder is used to identify fk constraint
issues that exist between the data in the postgres database that will be
loaded to oracle.

The most likely culprit for the failures is from the following applicant info
that is defined in one of the integration tests.

The following is the common culprit:
```
    applicant_client_number = '00149081' and
    applicant_locn_code = '22'
```

The data is TEST data so the easiest way to fix this is to run the following
sql:

``` sql
update seedlot
set
    applicant_client_number = '00196805',
    applicant_locn_code = '02';
where
    applicant_client_number = '00149081' and
    applicant_locn_code = '22'
```

If this does not resolve the issue a script has been created that compares the
data in postgres with the data in oracle to identify the problem record.

# Run the Script to identify offending records

The following describes all the setup required to run the script...

## Script Setup - Env Vars
This script requires the following env vars be populated:

### Postgres vars
These are the env vars used to connect to the openshift postgres database.

* POSTGRES_USER_TEST
* POSTGRES_PASSWORD_TEST
* POSTGRES_HOST_TEST=localhost
* POSTGRES_PORT_TEST=5433
* POSTGRES_DB_TEST=nr-spar

### Oracle vars
These are the env vars used to connect to the oracle database.

* ORACLE_USER_TEST
* ORACLE_PASSWORD_TEST
* ORACLE_HOST_TEST
* ORACLE_PORT_TEST
* ORACLE_SERVICE_TEST
* ORACLE_SCHEMA_TO_SYNC_TEST

## Network configuration

The script needs to have access to the openshift database as well as the oracle
database.

### Oracle network config - Cisco anyconnect VPN

Turn this on, and perform any tweaks required...
[detailed instructions here](../docs/data_extract.md#network--configure-vpn)

### Postgres network config - Create postgres database port-forward

Connect to openshift, and setup port-forwarding...

```
oc project <spar test namespace>
oc get pods | grep database
oc port-forward <database pod name> 5433:5432
```

### Run the script

If the nr-oracle-env repo hasn't already been cloned do so:
`cd ora-env; git clone https://github.com/bcgov/nr-oracle-env`

```
cd ora-env/nr-oracle-env/data-population
uv run python db_env_utils/fix_forest_client_fk_violation.py
```
