# Overview

This folder contains the docs and code necessary to create a disposable local
dev environment that can be used to diagnose issues associated with the spar
sync code base.

The creation of the local environment relies heavily on the
[nr-ora-env](https://github.com/bcgov/nr-oracle-env) repo.

The basic steps to generation of a disposable database environment are:

### Create Local Oracle env:
1. Identify oracle dependencies and generate migration files to duplicate that
    environment.  The oracle migrations are placed in the ora_env folder.
    Migrations are generated using the
1. Pull data from oracle on prem databases to object store
1. Load data from object store toe on prem databases.

### Create Local Postgres env:
1. Run migrations defined in nr-spar repo
1. Pull data from postgres to object store
1. Load data from object store to local postgres.


# Generate Oracle Migrations

This step is a one off that only needs to be revisited if you want to add new
tables.

[Complete detailed description of oracle migration generation for spar](../docs/ora_migrations.md)

# Create a local oracle database

This step will execute the migration files generated in the previous step to
create a local dev environment with the actual database structure (no data yet).

```
# change the directory to the repo root directory
docker compose up oracle-migrations
```

# Extract Oracle spar data from TEST / PROD and|or Extract Postgres spar data from OC

This step uses the [nr-oracle-env repo](https://github.com/bcgov/nr-oracle-env)
and the data-population tools to create a file based data set to support local
development, that can be run locally.  Like the migrations this is a process
that can be run once and then re-used many times as the data that gets extracted
is cached in object store.

[detailed instructions on running the data extract](../docs/data_extract.md)

# Dataload a local oracle database

-- TODO: come back here once the docker stuff is sorted



...

# Fix TEST sync job

Currently something is running during the weekends that adds seedlot records
that relate to a forest client that does not exist in the TEST environment, and
causes the sync job to fail.

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


## Script Setup - Env Vars
This script requires the following env vars be populated:

### Postgres vars

* POSTGRES_USER_TEST
* POSTGRES_PASSWORD_TEST
* POSTGRES_HOST_TEST=localhost
* POSTGRES_PORT_TEST=5433
* POSTGRES_DB_TEST=nr-spar

### Oracle vars

* ORACLE_USER_TEST
* ORACLE_PASSWORD_TEST
* ORACLE_HOST_TEST
* ORACLE_PORT_TEST
* ORACLE_SERVICE_TEST
* ORACLE_SCHEMA_TO_SYNC_TEST

## Network configuration

The script needs to have access to the openshift database as well as the oracle
database.

### Cisco anyconnect VPN

Turn this on, and perform any tweaks required...
[detailed instructions here](../docs/data_extract.md#network--configure-vpn)

### Create postgres database port-forward

Connect to openshift, and setup port-forwarding...

```
oc project <spar test namespace>
oc get pods | grep database
oc port-forward <database pod name> 5433:5432
```

### Run the script

```
uv run python db_env_utils/fix_forest_client_fk_violation.py
```
