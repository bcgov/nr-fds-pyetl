"""Wrapper to oracle functions.

Assumptions:

When parameters are not sent to the constructor the class will look in the
following environment variables in order to create a database connection.
--------------------------------------------
ORACLE_USER - user to connect to the database with
ORACLE_PASSWORD - password for that user
ORACLE_HOST - host for the database
ORACLE_PORT - port for the database
ORACLE_SERVICE - database service
"""

from __future__ import annotations

import logging
import logging.config
import os
import pathlib

import oracledb
import pandas as pd
import sqlalchemy

LOGGER = logging.getLogger(__name__)


class OracleDatabase:
    """
    Wrapper to access oracle databases.

    By default will attempt to get the following parameters from the
    environment:

    username: ORACLE_USER
    password: ORACLE_PASSWORD
    host: ORACLE_HOST
    port: ORACLE_PORT
    service_name: ORACLE_SERVICE
    """

    def __init__(
        self,
        username: str | None = None,
        password: str | None = None,
        host: str | None = None,
        port: str | None = None,
        service_name: str | None = None,
        schema_to_sync: str | None = None,
    ) -> None:
        self.username = username
        self.password = password
        self.host = host
        self.port = port
        self.service_name = service_name
        self.schema2Sync = schema_to_sync

        # if the parameters are not supplied attempt to get them from the environment
        if self.username is None:
            self.username = os.getenv("ORACLE_USER")
        if self.password is None:
            self.password = os.getenv("ORACLE_PASSWORD")
        if self.host is None:
            self.host = os.getenv("ORACLE_HOST")
        if self.port is None:
            self.port = os.getenv("ORACLE_PORT")
        if self.service_name is None:
            self.service_name = os.getenv("ORACLE_SERVICE")
        if self.schema2Sync is None:
            self.schema2Sync = os.getenv("ORACLE_SCHEMA_TO_SYNC")

        self.connection = None
        self.sql_alchemy_engine = None

    def get_connection(self) -> None:
        """
        Create a connection to the database.

        Creates a connection to the database using class variables that are
        populated by the object constructor.
        """
        if self.connection is None:
            self.connection = oracledb.connect(
                user=self.username,
                password=self.password,
                host=self.host,
                port=self.port,
                service_name=self.service_name,
            )
            LOGGER.debug("connected to database")

    def get_sqlalchemy_engine(self):
        """
        Populate the sqlalchemy engine.

        Using the sql alchemy connection string created in the constructor
        creates a sql_alchemy engine.
        """
        if self.sql_alchemy_engine is None:
            dsn = f"oracle+oracledb://{self.username}:{self.password}@{self.host}:{self.port}/?service_name={self.service_name}"
            self.sql_alchemy_engine = sqlalchemy.create_engine(
                dsn,
                arraysize=1000,
            )

    def get_tables(
        self,
        schema: str,
        omit_tables: list[str] | None = None,
    ) -> list[str]:
        """
        Return a list of tables in the provided schema.

        Gets a list of tables that exist in the provided schema arguement.  Any
        tables defined in the omit_tables parameter will be exculded from the
        returned list.

        :param schema: the schema who's tables should be returned
        :type schema: str
        :param omit_tables: list of tables that should be excluded from the list
            of tables that is returned.  Default is []
        :type omit_tables: list, optional
        :return: a list of table names for the given schema
        :rtype: list[str]
        """
        # TODO: Get the correct order to load the data, starting with outer tables and
        #       working inwards
        if omit_tables is None:
            omit_tables = []
        if omit_tables:
            omit_tables = [table.upper() for table in omit_tables]
        self.get_connection()
        cursor = self.connection.cursor()
        query = "select table_name from all_tables where owner = :schema"
        LOGGER.debug("query: %s", query)
        cursor.execute(query, schema=schema.upper())
        tables = [
            row[0].upper()
            for row in cursor
            if row[0].upper() not in omit_tables
        ]
        cursor.close()
        LOGGER.debug(f"tables: {tables}")
        return tables

    def get_table_object(self, table_name: str) -> sqlalchemy.Table:
        """
        Get a SQLAlchemy Table object for an existing database table.

        :param table_name: the name of the table to get a SQLAlchemy Table
            object for
        :type table_name: str
        :return: returns a SQLAlchemy Table object for the table
        :rtype: sqlalchemy.Table
        """
        self.get_sqlalchemy_engine()
        metadata = sqlalchemy.MetaData()
        return sqlalchemy.Table(
            table_name,
            metadata,
            autoload_with=self.sql_alchemy_engine,
            schema=self.schema2Sync,
        )

    def extract_data(self, table: str, export_file: str) -> None:
        """
        Extract a table from the database to a parquet file.

        :param table: the name of the table who's data will be copied to the
            parquet file
        :type table: str
        :param export_file: the full path to the file that will be created, and
            populated with the data from the table.
        :type export_file: str
        """
        table_obj = self.get_table_object(table)
        select_obj = sqlalchemy.select(table_obj)

        # data_query_sql = f"select * from {self.schema2Sync}.{table}"  # noqa: ERA001
        LOGGER.debug("data_query_sql: %s", select_obj)
        LOGGER.debug("reading the %s", table)
        self.get_sqlalchemy_engine()
        df_orders = pd.read_sql(select_obj, self.sql_alchemy_engine)

        LOGGER.debug("writing to parquet file: %s ", export_file)
        df_orders.to_parquet(export_file)

    def get_tmp_file(self) -> str:
        """
        Return a temporary file name.

        :return: the temporary file name
        :rtype: str
        """
        tmp_file_name = "tmp_file"
        if pathlib.Path.exists(tmp_file_name):
            pathlib.Path(tmp_file_name).unlink()
        return tmp_file_name

    def truncate_table(self, table: str) -> None:
        """
        Delete all the data from the table.

        :param table: the table to delete the data from
        """
        self.get_connection()
        cursor = self.connection.cursor()
        cursor.execute(f"truncate table {self.schema2Sync}.{table}")
        self.connection.commit()
        cursor.close()

    def load_data(
        self,
        table: str,
        import_file: str,
        *,
        purge: bool = False,
    ) -> None:
        """
        Load the data from the file into the table.

        :param table: the table to load the data into
        :type table: str
        :param import_file: the file to read the data from
        :type import_file: str
        :param purge: if True, delete the data from the table before loading.
        :type purge: bool
        """
        # debugging to view the data before it gets loaded
        pandas_df = pd.read_parquet(import_file)
        tmp_file = self.get_tmp_file()
        LOGGER.debug("tmp_file: %s", str(tmp_file))
        pandas_df.to_csv(tmp_file, sep="|", index_label=None)

        LOGGER.debug("table: %s", table)

        self.get_sqlalchemy_engine()
        if purge:
            self.truncate_table(table.lower())
        pandas_df.to_sql(
            table.lower(),
            self.sql_alchemy_engine,
            schema="THE",
            if_exists="append",
            index=False,
        )
