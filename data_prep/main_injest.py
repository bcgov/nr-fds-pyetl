"""

Load / Injest data from cached parquet files in objectstorage.

Setup Steps:

A) Start the docker database
-------------------------
Need to start the local database as that is the database that this script will
load with data.

B) Create / Activate the poetry environment
----------------------------------------
poetry install - to create
source $(poetry env info --path)/bin/activate - to activate

Populate the following environment variables

The script needs to be able to support the following environments,
DEV / TEST / PROD
which corresponds to which database the data that is being loaded originates
from.  If the script is run without arguements it will default to env=TEST
--------------------------------------------
ORACLE_USER_<env> - user to connect to the database with
ORACLE_PASSWORD_<env> - password for that user
ORACLE_HOST_<env> - host for the database
ORACLE_PORT_<env> - port for the database
ORACLE_SERVICE_<env> - database service

Run the script
--------------
python data_prep/main_injest.py

reference: https://www.andrewvillazon.com/quickly-load-data-db-python/

"""

import logging
import logging.config
import pathlib
import sys

import constants
import docker_parser
import env_config
import object_store
import oradb_lib

LOGGER = logging.getLogger(__name__)


if __name__ == "__main__":
    # dealing with args
    # NOTE: if this gets more complex use a CLI framework
    env_str = "TEST"
    if len(sys.argv) > 1:
        env_str = sys.argv[1]
    env_obj = env_config.Env(env_str)

    curdir = pathlib.Path(__file__).parents[0]
    datadir = pathlib.Path(curdir, constants.DATA_DIR)
    if not datadir.exists():
        datadir.mkdir(parents=True)

    # configure logging
    log_config_path = pathlib.Path(curdir, "logging.config")
    logging.config.fileConfig(log_config_path, disable_existing_loggers=False)
    logger_name = pathlib.Path(__file__).stem
    LOGGER = logging.getLogger(logger_name)
    LOGGER.info("Starting pull_ora_objstr")

    # read the docker-compose file to get the connection parameters, then
    # connect to docker compose database to get a table list
    dcr = docker_parser.ReadDockerCompose()
    local_ora_params = dcr.get_ora_conn_params()
    local_ora_params.schema_to_sync = env_obj.get_schema_to_sync()
    local_docker_db = oradb_lib.OracleDatabase(local_ora_params)
    tables_to_import = local_docker_db.get_tables(
        local_docker_db.schema2Sync,
        omit_tables=["FLYWAY_SCHEMA_HISTORY"],
    )

    # pull the data down from object store
    ostore_params = env_obj.get_ostore_constants()
    ostore = object_store.OStore(conn_params=ostore_params)
    ostore.get_data_files(tables_to_import, env_obj.env)

    local_docker_db.purge_data(table_list=tables_to_import)

    local_docker_db.load_data_retry(
        data_dir=datadir,
        table_list=tables_to_import,
        env_str=env_obj.env,
        purge=False,
    )
