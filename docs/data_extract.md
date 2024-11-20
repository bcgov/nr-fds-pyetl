# Update Extract Data

Describes setup procedures required to complete a data extract for both oracle
and postgres/spar data.

In both cases the script will cache local versions of the data in the root
directory of the repository in a folder called `data` which is then organized
by environment / database type (ora)

# ORACLE - THE/Spar extract

## Environment Variables

In order to run the oracle data extraction you will need a oracle account or
proxy that has access to the various spar database objects that are referenced
by this app.

The extraction uses separate environment variables to differentiate between
TEST and PROD.  The following is a list of the environment variables required
to complete an oracle extract.  In the following list substitute <env> for
TEST and PROD.

**Object Store Parameters**

* OBJECT_STORE_USER_<env> - object store user id
* OBJECT_STORE_SECRET_<env> - object store secret
* OBJECT_STORE_BUCKET_<env> - object store bucket
* OBJECT_STORE_HOST_<env> - object store host


**Oracle Database Parameters**

* ORACLE_HOST_<env> - oracle host
* ORACLE_PORT_<env> - oracle database port
* ORACLE_SERVICE_<env> - oracle service name
* ORACLE_SCHEMA_TO_SYNC_<env> - the schema in local database where tables are found
* ORACLE_USER_<env> - username used for oracle connection
* ORACLE_PASSWORD_<env> - password used for oracle connection

## Delete any cached data

Delete the `data` directory from the root directory of the repo if it exists.
This will ensure new data is generated and uploaded to object storage.

## Configure VPN

This script needs to communicate with the on prem oracle database that exists
within the government firewall.  In order to run you need to activate the cisco
VPN.

### WSL config

If you are running WSL, it introduces some additional network connectivity
issues that need to be resolved for WSL instances to be able to communicate
through the VPN.

1. Turn on the VPN on the windows side
2. Run the following command in an administrative powershell command prompt:

    `Get-NetAdapter | Where-Object {$_.InterfaceDescription -Match "Cisco AnyConnect"} | Set-NetIPInterface -InterfaceMetric 6000`
3. Get the ip's for DNS entries.

    `(Get-NetAdapter | Where-Object InterfaceDescription -like "Cisco AnyConnect*" | Get-DnsClientServerAddress).ServerAddresses`

4. Add these ip's to the `/etc/resolv.conf` file, example:
    ```
    GuyLafleur@Habs:$ cat /etc/resolv.conf
        nameserver 10.10.0.124
        nameserver 10.10.0.132
    ```

### Test connectivity

Before runing the script ensure you can ping the database server that you are
attempting to connect to:L

`ping <database host>`

## Install Dependencies and Activate Environment

```bash
poetry install
source $(poetry env info --path)/bin/activate
```

## Run the script

`python data_prep/main_ora_extract.py TEST`

# POSTGRES - spar2 extract

## Environment Variables

The only environment variable required for this script to run is a openshift
api key / token.  The script will use that key to retrieve the various credentials
it requires, and it will also use access to the namespace to build the required
port forward tunnel for pulling the data from postgres in openshift.

* OC_TOKEN_TEST - populate this with an api key that has permissions required to
                  configure a port-forward tunnel.  Easiest way is to populate this
                  with the developer token you can retrieve for your openshift
                  account.

                  This is the token that is used for test.

* OC_TOKEN_PROD - ditto as above except this is the key that will be used to
                  extract the data from prod.

The following are the env vars required to connect to object storage.  The
env can be either TEST|PROD, depending on which env is being extracted:

* OBJECT_STORE_USER_<env>
* OBJECT_STORE_SECRET_<env>
* OBJECT_STORE_BUCKET_<env>
* OBJECT_STORE_HOST_<env>


## Install / configure dependencies

Install dependencies using poetry
`poetry install`

Activate the poetry environment.
`source $(poetry env info --path)/bin/activate`

## Running script

`python data_prep/main_spar_extract.py <env: TEST|PROD>`
