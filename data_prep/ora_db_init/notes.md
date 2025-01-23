# Getting started with the containerized oracle

## getting a basic database up and running 
 * user: system
 * password: default
```
docker run -d -p 1521:1521 -e ORACLE_PASSWORD=default -v oracle-volume:/home/kjnether/fsa_proj/nr-spar/sync/oradb/data gvenzl/oracle-free
```

## run db with 'THE' user/schema in it
```
docker run -d \
  -p 1521:1521 \
  -e ORACLE_PASSWORD=default \
  -e ORACLE_DATABASE=dbdock_01 \
  -e APP_USER_PASSWORD=default \
  -e APP_USER=the \
   -v oracle-volume:/home/kjnether/fsa_proj/nr-fds-pyetl/sync/oradb/data gvenzl/oracle-free
```

## connect to oracle with sqlplus
```
export ORACLE_PASSWORD=default
export ORACLE_DATABASE=dbdock_01
export APP_USER_PASSWORD=default
export APP_USER=the
sqlplus $APP_USER/$APP_USER_PASSWORD@localhost:1521/$ORACLE_DATABASE

```

## connect with sqlplus as dba
```
sqlplus sys@localhost:1521/dbdock_01 as sysdba
```

# Running SPAR ephemeral Oracle Database

```
docker compose up oracle-migrations
```

* spins up the oracle database
* runs flyway to create the database structure necessary for the SPAR -> oracle sync job.



# Tables Created

For a comprehensive list either view the migrations or spin up the database and list
the tables

```sql
select * from all_tables where owner = 'THE';
```

The followng list of tables are the ones that have been identified as having relationships
to the SEEDLOT table:

* THE.BEC_VERSION_CONTROL - Done
* THE.CONE_COLLECTION_METHOD_CODE
* THE.CLIENT_LOCATION
* THE.COLLECTION_LONGITUDE_CODE
* THE.COLLECTION_LATITUDE_CODE
* THE.COLLECTION_SOURCE_CODE
* THE.GENETIC_CLASS_CODE
* THE.GAMETIC_MTHD_CODE
* THE.INTERM_FACILITY_CODE
* THE.NAD_DATUM_CODE
* THE.NMBR_TREES_FROM_CODE
* THE.ORCHARD
* THE.ORG_UNIT
* THE.POLLEN_CONTAMINATION_MTHD_CODE
* THE.SEED_COAST_AREA_CODE
* THE.SEED_PLAN_UNIT
* THE.SEED_PLAN_ZONE_CODE
* THE.SEEDLOT_STATUS_CODE
* THE.SEEDLOT_SOURCE_CODE
* THE.SUPERIOR_PROVENANCE
* THE.VEGETATION_CODE

