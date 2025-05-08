# Create / Update Extracted Data

Describes setup procedures required to complete a data extract for both oracle
and postgres/spar data.

In both cases the script will cache local versions of the data in
directory called `ora-env` which is then organized
by environment / database type (ora)

# Setup / Prerequisites

## Python

make sure you have python >= 3.12...  `python --version`

Install uv globally for python... `pip install uv`

if you don't have python 3.12 look into installing
[pyenv](https://github.com/pyenv/pyenv) and using it to help manage multiple
python versions.

## Clone nr-oracle-env repo

if you don't already have a directory called ora-env, then create one... The
navigate and clone...

```
cd ora-env
git clone https://github.com/bcgov/nr-oracle-env
```


## Environment Variables

Not all these environment variables are required for every extract.  The
subsections will identify where they are used.

In order to run the oracle data extraction you will need a oracle account or
proxy that has access to the various spar database objects that are referenced
by this app.

The extraction uses separate environment variables to differentiate between
TEST and PROD.  The following is a list of the environment variables required
to complete an oracle extract.  In the following list substitute <env> for
TEST and PROD.

**Note**: you can populate the env_sample file and then rename to .env to facilitate
loading env vars.  You can load the .env file to the environemnt using:

`set -a; source .env; set +a`

### **Object Store Parameters**
Object store buckets are where the extracted data gets cached, allowing subsequent
injest processes to pull data without connecting to the source databases.

* OBJECT_STORE_USER_<env> - object store user id
* OBJECT_STORE_SECRET_<env> - object store secret
* OBJECT_STORE_BUCKET_<env> - object store bucket
* OBJECT_STORE_HOST_<env> - object store host

### **Oracle Database Parameters - Destination**
Configure the following environment variables for connection to local database
that contains the tables and other structure created by the database migrations.

If you are using the database created by the docker-compose.yml you should
be able to go with these parameters.

* ORACLE_HOST_LOCAL
* ORACLE_PORT_LOCAL
* ORACLE_SERVICE_LOCAL
* ORACLE_SYNC_USER_LOCAL
* ORACLE_SYNC_PASSWORD_LOCAL
* ORACLE_SCHEMA_TO_SYNC_LOCAL

### **Oracle Database Parameters - Source**
Configure the following environment variables for the source on prem database
who's data you would like to extract.  Substitue in either PROD or TEST for
<env>

* ORACLE_HOST_<env> - oracle host
* ORACLE_PORT_<env> - oracle database port
* ORACLE_SERVICE_<env> - oracle service name
* ORACLE_SCHEMA_TO_SYNC_<env> - the schema in local database where tables are found
* ORACLE_USER_<env> - username used for oracle connection
* ORACLE_PASSWORD_<env> - password used for oracle connection

### **Postgres Database Parameters - Source**

The postgres database export will query the source database to identify all the
tables in the `spar` schema that need to be extracted.  The extract process only
needs to know about openshift, and have an openshift token that can establish
a port-forward.  This is all handled automatically in the code.  Substitute
<env> with either TEST | PROD.

* OC_URL=https://api.silver.devops.gov.bc.ca:6443
* OC_LICENSE_PLATE_<env>=
* OC_TOKEN_<env>

### **Directory Parameters**

* LOCAL_DATA_DIR=../../data
* OBJECT_STORE_DATA_DIRECTORY - default value for this is py_etl

## Cached data

Scripts will extract and cache data locally before pushing to object store.  If
the data exists locally then the assumption is made that it does not need to be
extracted.

The following directories are created:
* ora-env/data/PROD/ORA - prod oracle data extract
* ora-env/data/TEST/ORA - test oracle data extract
* ora-env/data/PROD/OC_POSTGRES - prod postgres extract
* ora-env/data/TEST/OC_POSTGRES - test postgres extract
* ora-env/data/temp - mostly where the data-classification.xlsx ss is cached.

## Network / Configure VPN

This script needs to communicate with the on prem oracle database that exists
within the government firewall.  In order to run you need to activate the cisco
VPN, or run from a physical location that can communicate with the database
hosts.

### WSL config

If you are running WSL, it introduces some additional network connectivity
issues that need to be resolved for WSL instances to be able to communicate
through the VPN.

1. Turn on the VPN on the windows side
2. Run the following command in an administrative powershell command prompt:

    `Get-NetAdapter | Where-Object {$_.InterfaceDescription -Match "Cisco AnyConnect"} | Set-NetIPInterface -InterfaceMetric 6000`
3. Get the ip's for DNS entries.

    `(Get-NetAdapter | Where-Object InterfaceDescription -like "Cisco AnyConnect*" | Get-DnsClientServerAddress).ServerAddresses`

4. Add these ip's to the `/etc/resolv.conf` file, example (**NOT THESE IP'S THOUGH**):

Example of what resolv.conf looks like:

    ```
    GuyLafleur@Habs:$ cat /etc/resolv.conf
        nameserver 10.10.0.124
        nameserver 10.10.0.132
    ```

### Test connectivity

Before runing the script ensure you can ping the database server that you are
attempting to connect to:L

`ping <database host>`

## Retrieve a copy of the data classification spreadsheet

If you have access to the fds object store bucket then pull the SS down from
this directory:
https://nrs.objectstore.gov.bc.ca/muyrpr/data_classification

and copy to `ora-env/nr-oracle-env/data-population/data/temp/data_classification.xlsx`


# ORACLE - THE/Spar extract

Having addressed:
1. [source oracle db env vars](#oracle-database-parameters---source)
1. [destination oracle db env vars](#oracle-database-parameters---destination)
1. [data cache directory env vars](#directory-parameters)
1. [python / uv requirements](#python)
1. [network config to be communicate with db](#network--configure-vpn)
1. [clone the nr-oracle-env repo to use db tooling](#clone-nr-oracle-env-repo)

You can now run the scripts.

Navigate to the data-population folder in the nr-oracle-env directory, (where
the nr-oracle-env was cloned)
 `cd ora-env/nr-oracle-env/data-population`

`uv run python db_env_utils/main_extract.py ORA <env>`

**Note** running the script through uv will automatically build you .venv and
install any dependencies, and / or re-use an existing environment.

# Run Postgres - spar2 extract

In order to run the spar / postgres database extract you will need to address
the following config:

1. [openshift env vars](#postgres-database-parameters---source)
1. [object store secrets](#object-store-parameters)
1. [python config](#python)
1. [directory parameters](#directory-parameters)
1. [clone the nr-oracle-env repo](#clone-nr-oracle-env-repo)

Then run the script (sub env for TEST|PROD):

```
cd ora-env/nr-oracle-env/data-population
uv run python db_env_utils/main_extract.py OC_POSTGRES <env>
```
