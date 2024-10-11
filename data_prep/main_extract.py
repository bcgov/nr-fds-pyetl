"""

Extract data from the oracle database and cache in parquet files in object storage.

Start the docker database
-------------------------
docker compose up oracle-migrations

Start the VPN
-----------------------
start the VPN to allow access to the database

Resolve WSL / VPN network issues
--------------------------------
different by computer / I run the following powershell commands:
    Get-NetAdapter | Where-Object {$_.InterfaceDescription -Match "Cisco AnyConnect"} | Set-NetIPInterface -InterfaceMetric 6000
    Get-NetIPInterface -InterfaceAlias "vEthernet (WSL)" | Set-NetIPInterface -InterfaceMetric 1

Create / Activate the poetry environment
----------------------------------------
poetry install - to create
source $(poetry env info --path)/bin/activate - to activate

Populate the following environment variables
--------------------------------------------
ORACLE_USER - user to connect to the database with
ORACLE_PASSWORD - password for that user
ORACLE_HOST - host for the database
ORACLE_PORT - port for the database
ORACLE_SERVICE - database service

Run the script
--------------
python data_prep/pull_ora_objstr.py

:return: _description_
:rtype: _type_


reference: https://www.andrewvillazon.com/quickly-load-data-db-python/

"""  # noqa: E501

import logging
import logging.config
import pathlib
import sys
from concurrent import futures  # noqa: F401

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
    LOGGER.debug("schema to sync: %s", local_ora_params.schema_to_sync)
    local_docker_db = oradb_lib.OracleDatabase(local_ora_params)
    tables_to_export = local_docker_db.get_tables(
        local_docker_db.schema2Sync,
        omit_tables=["FLYWAY_SCHEMA_HISTORY"],
    )

    # configure the object store connection
    ostore_params = env_obj.get_ostore_constants()
    ostore = object_store.OStore(conn_params=ostore_params)

    # connect to the remote database and dump the data to object store
    ora_params = env_obj.get_db_env_constants()
    remote_ora_db = oradb_lib.OracleDatabase(
        ora_params,
    )  # use the environment variables for connection parameters
    remote_ora_db.get_connection()
    for table in tables_to_export:
        LOGGER.info("Exporting table %s", table)
        export_file = constants.get_parquet_file_path(table, env_obj.env)
        LOGGER.debug("export_file: %s", export_file)
        file_created = remote_ora_db.extract_data(table, export_file)

        if file_created:
            # push the file to object store
            ostore.put_data_files([export_file], env_obj.env)
