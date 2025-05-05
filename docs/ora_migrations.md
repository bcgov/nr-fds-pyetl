# Oracle Migrations

This step defines how to generate oracle migrations for the spar application.
The migration files are part of the repository and should currently  contain
all the tables used by the spar sync job contained in this repo.

You should only need to revisit these steps if you need to add new tables to the
process.

Most of the code for this work is contained in the [nr-oracle-env](https://github.com/bcgov/nr-oracle-env) repo.

# Steps:

## 1. Pre-requisites

* Ideally a semi modern version of python (>=3.12)

* UV python package manager.. [uv](https://docs.astral.sh/uv/)
    `pip install uv`


## 1. Pull The NR-ORACLE-ENV repo

This repo already has a directory for where to clone the nr-oracle-env repo.

Change the directory:
`cd ora-env`

Clone the repo
`git clone https://github.com/bcgov/nr-oracle-env nr-oracle-env`


## 2. Start the oracle struct database

First get the oracle datapump dump file.  This file is not public.  It can be
downloaded from here if you have the bucket secrets:
https://nrs.objectstore.gov.bc.ca/tivpth/dbp01_struct/dbp01-31-10-24.dmp

Place the file in the `nr-oracle-env/data` folder, and make sure to keep the
file name the same, ie dbp01-31-10-24.dmp.

```
cd nr-oracle-env
mkdir data
# copy datapump file to this directory
```

Now init the struct database and load the datapump file.  This only needs to
be done once if you preserve the docker volume that is created.  This process
takes approximately 20 minutes.

 `docker compose up oracle-dp-import`

 ## 3. Generate the migrations

 Now that the struct database is up and running we will generate migrations for
 all of the following tables:

* SEEDLOT
* SEEDLOT_GENETIC_WORTH
* SEEDLOT_OWNER_QUANTITY
* SEEDLOT_PARENT_TREE
* SEEDLOT_PARENT_TREE_GEN_QLTY
* SEEDLOT_PARENT_TREE_SMP_MIX
* SMP_MIX
* SMP_MIX_GEN_QLTY

In order to be able to communicate with the database you will need to populate
the following environment variables.

```bash
export ORACLE_USERNAME=the
export ORACLE_PASSWORD=default
export ORACLE_HOST=localhost
export ORACLE_PORT=1522
export ORACLE_SERVICE_NAME=DBDOCK_STRUCT_01
```

These are the commands that are used to generate those migrations
```
cd data-query-tool

# SEEDLOT
uv run python main.py create-migrations --seed-object SEEDLOT --schema THE --migration-folder ../../migrations/ora --migration-name seedlot

# SEEDLOT_GENETIC_WORTH
uv run python main.py create-migrations --seed-object SEEDLOT_GENETIC_WORTH --schema THE --migration-folder ../../migrations/ora --migration-name seedlot_genetic_worth

# SEEDLOT_OWNER_QUANTITY
uv run python main.py create-migrations --seed-object SEEDLOT_OWNER_QUANTITY --schema THE --migration-folder ../../migrations/ora --migration-name seedlot_owner_quantity

# SEEDLOT_PARENT_TREE
uv run python main.py create-migrations --seed-object SEEDLOT_PARENT_TREE --schema THE --migration-folder ../../migrations/ora --migration-name seedlot_parent_tree

# SEEDLOT_PARENT_TREE_GEN_QLTY
uv run python main.py create-migrations --seed-object SEEDLOT_PARENT_TREE_GEN_QLTY --schema THE --migration-folder ../../migrations/ora --migration-name seedlot_parent_tree_gen_qlty

# SEEDLOT_PARENT_TREE_SMP_MIX
uv run python main.py create-migrations --seed-object SEEDLOT_PARENT_TREE_SMP_MIX --schema THE --migration-folder ../../migrations/ora --migration-name seedlot_parent_tree_smp_mix

# SMP_MIX
uv run python main.py create-migrations --seed-object SMP_MIX --schema THE --migration-folder ../../migrations/ora --migration-name smp_mix

# SMP_MIX_GEN_QLTY
uv run python main.py create-migrations --seed-object SMP_MIX_GEN_QLTY --schema THE --migration-folder ../../migrations/ora --migration-name smp_mix_gen_qlty
```

Having run all the commands above should result in the population of the
migrations folder with migration files.

Next step is to [extract data from on prem data bases](data_extract.md)... OR if you have already
done that then move onto [injesting the data from object store](data_load.md)

 ## 4. Adding new tables

 If new tables are required you can generate migrations for them and all their
 dependencies using

```
uv run python main.py create-migrations --seed-object <INPUT OBJECT NAME> --schema THE --migration-folder ../../migrations/ora --migration-name <INPUT MIGRATION NAME>
```
