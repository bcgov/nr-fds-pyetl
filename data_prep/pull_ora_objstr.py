"""
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

"""

import oracledb

import pandas as pd
import sqlalchemy
from sqlalchemy.exc import SQLAlchemyError
import yaml
import logging
import logging.config
import os
import csv
import queue
from pypika import Table
from pypika import OracleQuery as Query

import oradb_lib

from concurrent import futures

LOGGER = logging.getLogger(__name__)


class AsyncLoader:
    """
    adapter from https://github.com/andrewvillazon/quickly-load-data-db-python/blob/master/loadcsv.py
    """

    def __init__(self, connection: oracledb.Connection):
        self.multi_row_insert_limit = 1000
        self.workers = 6
        self.connection = connection

    def execute_query(self, q):
        cursor = self.connection.cursor()

        cursor.execute(q)
        self.connection.commit()

        self.connection.close()

    def read_csv(self, csv_file):
        with open(csv_file, encoding="utf-8", newline="") as in_file:
            reader = csv.reader(in_file, delimiter="|")
            next(reader)  # Header row

            for row in reader:
                yield row

    def multi_row_insert(self, batch, table_name):
        row_expressions = []

        for _ in range(batch.qsize()):
            row_data = tuple(batch.get())
            row_expressions.append(row_data)

        table = Table(table_name)
        # oracle doesn't support inserting more than one row at a time, need to create the multiple
        # insert statements... thinking doing this would make more sense,
        insert_into = Query.into(table).insert(*row_expressions)
        LOGGER.debug(f"Insert query: {insert_into}")
        self.execute_query(str(insert_into))

    def process_row(self, row, batch, table_name):
        batch.put(row)

        if batch.full():
            self.multi_row_insert(batch, table_name)

        return batch

    def load_data(self, table_name, import_parquet_file):
        #         pandas_df = pd.read_parquet(import_file)

        batch = queue.Queue(self.multi_row_insert_limit)

        with futures.ThreadPoolExecutor(max_workers=self.workers) as executor:
            todo = []
            pandas_df = pd.read_parquet(import_parquet_file)
            for row in pandas_df.iterrows():
                # LOGGER.debug(f"row: {row}")
                future = executor.submit(
                    self.process_row, row, batch, table_name
                )
                todo.append(future)

            for future in futures.as_completed(todo):
                result = future.result()

        # Handle left overs
        if not result.empty():
            self.multi_row_insert(result, table_name)


class ReadDockerCompose:
    def __init__(self, path=None):
        """
        if the path is not supplied assumption is made that docker-compose is in the current
        directory

        :param path: The path to the docker-compose to read
        :type path: str, path
        """
        self.path = path

        if self.path is None:
            self.path = "docker-compose.yml"
        with open(self.path, "r") as fh:
            self.docker_comp = yaml.safe_load(fh)

    def get_ora_conn_params(self):
        """
        get the oracle connection parameters from the docker-compose file
        :return: a dictionary with the connection parameters
        """
        ora_params = {}
        ora_params["username"] = self.docker_comp["x-oracle-vars"]["APP_USER"]
        ora_params["password"] = self.docker_comp["x-oracle-vars"][
            "APP_USER_PASSWORD"
        ]
        ora_params["host"] = "localhost"
        ora_params["port"] = self.docker_comp["services"]["oracle"]["ports"][
            0
        ].split(":")[0]
        ora_params["service_name"] = self.docker_comp["x-oracle-vars"][
            "ORACLE_DATABASE"
        ]
        return ora_params


if __name__ == "__main__":

    curdir = os.path.join(os.path.dirname(__file__))
    datadir = os.path.join(curdir, "data")
    if not os.path.exists(datadir):
        os.makedirs(datadir)

    # configure logging
    log_config_path = os.path.join(curdir, "logging.config")
    logging.config.fileConfig(log_config_path, disable_existing_loggers=False)
    logger_name = os.path.splitext(os.path.basename(__file__))[0]
    print(f"logger name: {logger_name}")
    LOGGER = logging.getLogger(logger_name)
    LOGGER.info("Starting pull_ora_objstr")

    # read the docker-compose file to get the connection parameters, then
    # connect to docker compose database to get a table list
    dcr = ReadDockerCompose()
    local_ora_params = dcr.get_ora_conn_params()
    local_docker_db = oradb_lib.OracleDatabase(**local_ora_params)
    # table_schema = os.getenv("ORACLE_SCHEMA_TO_SYNC")
    tables_to_export = local_docker_db.get_tables(
        local_docker_db.schema2Sync, omit_tables=["FLYWAY_SCHEMA_HISTORY"]
    )

    # configure output directory

    # # connect to the remote database and dump the data to object store
    remote_ora_db = (
        oradb_lib.OracleDatabase()
    )  # use the environment variables for connection parameters
    remote_ora_db.get_connection()
    for table in tables_to_export:
        export_file = os.path.join(datadir, f"{table}.parquet")
        remote_ora_db.extract_data(table, export_file)

    # testing the load
    # local_docker_db.load_data(
    #     "BEC_ZONE_CODE", "data_prep/data/BEC_ZONE_CODE.parquet", purge=True
    # )
