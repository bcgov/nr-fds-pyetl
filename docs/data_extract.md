# Update Extract Data

Describes setup procedures required to complete a data extract for both oracle
and postgres/spar data.

In both cases the script will cache local versions of the data in the root
directory of the repository in a folder called `data` which is then organized
by environment / database type (ora)

# ORACLE - THE/Spar extract

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

## Install / configure dependencies

Install dependencies using poetry
`poetry install`

Activate the poetry environment.
`source $(poetry env info --path)/bin/activate`

## Running script

`python data_prep/main_spar_extract.py <env: TEST|PROD>`
