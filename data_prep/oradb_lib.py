"""
Wrapper to oracle functions.

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
from dataclasses import dataclass

import constants
import oracledb
import pandas as pd
import sqlalchemy
from env_config import ConnectionParameters
from oracledb.exceptions import DatabaseError

LOGGER = logging.getLogger(__name__)


@dataclass
class TableConstraints:
    """
    Data class for storing constraints.

    Model / types for storing database constraints when queried from the
    database.
    """

    constraint_name: str
    table_name: str
    column_name: str
    r_constraint_name: str
    referenced_table: str
    referenced_column: str


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
        connection_params: ConnectionParameters | None = None,
    ) -> None:
        """
        Construct for the OracleDatabase class.

        Recieves a ConnectionParameters object and a schema to sync.  Extracts
        parameters from the ConnectionParameters, then if they are empty or null
        checks for the parameters in the environment.

        :param connection_params: Parameters that define connection to database,
            defaults to None
        :type connection_params: ConnectionParameters | None, optional
        :param schema_to_sync: The schema that contains the objects that are to
            be extracted or loaded to.  If the property is not populated the
            script will look in the env var: ORACLE_SCHEMA_TO_SYNC,
            defaults to None
        :type schema_to_sync: None | str, optional
        """
        if connection_params is None:
            connection_params = ConnectionParameters
        self.username = connection_params.username
        self.password = connection_params.password
        self.host = connection_params.host
        self.port = connection_params.port
        self.service_name = connection_params.service_name
        self.schema_2_sync = connection_params.schema_to_sync

        # if the parameters are not supplied attempt to get them from the
        # environment
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

        self.connection = None
        self.sql_alchemy_engine = None

    def get_connection(self) -> None:
        """
        Create a connection to the database.

        Creates a connection to the database using class variables that are
        populated by the object constructor.
        """
        if self.connection is None:
            LOGGER.info("connecting the oracle database: %s", self.service_name)
            self.connection = oracledb.connect(
                user=self.username,
                password=self.password,
                host=self.host,
                port=self.port,
                service_name=self.service_name,
            )
            LOGGER.debug("connected to database")

    def get_sqlalchemy_engine(self) -> None:
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
        if omit_tables is None:
            omit_tables = []
        if omit_tables:
            omit_tables = [table.upper() for table in omit_tables]
        self.get_connection()
        cursor = self.connection.cursor()
        LOGGER.debug("schema to sync: %s", schema)
        query = "select table_name from all_tables where owner = :schema"
        LOGGER.debug("query: %s", query)
        cursor.execute(query, schema=schema.upper())
        tables = [
            row[0].upper()
            for row in cursor
            if row[0].upper() not in omit_tables
        ]
        cursor.close()
        LOGGER.debug("tables: %s", tables)
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
        LOGGER.debug("schema2Sync is: %s", self.schema_2_sync)
        return sqlalchemy.Table(
            table_name.lower(),
            metadata,
            autoload_with=self.sql_alchemy_engine,
            schema=self.schema_2_sync.lower(),
        )

    def extract_data(
        self,
        table: str,
        export_file: pathlib.Path,
        *,
        overwrite: bool = False,
    ) -> bool:
        """
        Extract a table from the database to a parquet file.

        :param table: the name of the table who's data will be copied to the
            parquet file
        :type table: str
        :param export_file: the full path to the file that will be created, and
            populated with the data from the table.
        :type export_file: str
        :param overwrite: if True the file will be overwritten if it exists,
        :return: True if the file was created, False if it was not
        :rtype: bool
        """
        file_created = False
        table_obj = self.get_table_object(table)
        select_obj = sqlalchemy.select(table_obj)

        # check that the directory for export file exists
        export_file.parent.mkdir(parents=True, exist_ok=True)

        if not export_file.exists() or overwrite:
            if export_file.exists():
                export_file.unlink()
                # delete the file if it exists
            LOGGER.debug("data_query_sql: %s", select_obj)
            LOGGER.debug("reading the %s", table)
            self.get_sqlalchemy_engine()
            df_orders = pd.read_sql(select_obj, self.sql_alchemy_engine)

            LOGGER.debug("writing to parquet file: %s ", export_file)
            df_orders.to_parquet(export_file)
            file_created = True
        else:
            LOGGER.info("file exists: %s, not re-exporting", export_file)
        return file_created

    def get_tmp_file(self) -> pathlib.Path:
        """
        Return a temporary file name.

        :return: the temporary file name
        :rtype: str
        """
        tmp_file_name = pathlib.Path("tmp_file")
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
        LOGGER.debug("truncating table: %s", table)
        cursor.execute(f"truncate table {self.schema_2_sync}.{table}")
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
        self.get_connection()  # make sure there is an oracle connection

        LOGGER.debug("loading data for table: %s", table)

        self.get_sqlalchemy_engine()
        if purge:
            self.truncate_table(table.lower())
        with self.sql_alchemy_engine.connect() as connection:
            with connection.begin():
                pandas_df.to_sql(
                    table.lower(),
                    con=connection,
                    schema="THE",
                    if_exists="append",
                    index=False,
                )
                # now verify data
        sql = f"Select count(*) from {self.schema_2_sync}.{table}"
        cur = self.connection.cursor()
        cur.execute(sql)
        result = cur.fetchall()
        rows_loaded = result[0][0]
        if not rows_loaded:
            LOGGER.error("no rows loaded to table %s", table)
        LOGGER.debug("rows loaded to table %s are:  %s", table, rows_loaded)
        cur.close()

    def load_data_retry(
        self,
        table_list: list[str],
        data_dir: pathlib.Path,  # TODO(guyLafleur): get rid of this parameter if not required, which I suspect it is not
        env_str: str,
        retries: int = 1,
        max_retries: int = 6,
        purge: bool = False,
    ) -> None:
        """
        Load data defined in table_list.

        Gets a list of tables in the table_list parameter, and attempts to load
        the data defined in the data directory to that table.  The load process
        will do the following steps:
            1. Disable foreign key constraints
            1. Truncate the data from all the tables
            1. Load the data from the parquet file to the table
            1. If there is an integrity error, truncate the table and retry
                after the rest of the tables have been loaded.
            1. Enable the constraints

        :param table_list: List of tables to be loaded
        :type table_list: list[str]
        :param data_dir: the directory where the parquet files are stored
        :type data_dir: pathlib.Path
        :param retries: the number of retries that have been attempted,
            defaults to 1
        :type retries: int, optional
        :param max_retries: The maximum number of times the script should
            attempt to load data, if this number is exceeded the integrity
            constraint error will be raised, defaults to 6
        :type max_retries: int, optional
        :param env_str: The environment string, used for path calculations,
            defaults to "TEST"
        :param purge: If set to true the script will truncate the table before
            it attempt a load, defaults to False
        :type purge: bool, optional
        :raises sqlalchemy.exc.IntegrityError: If unable to resolve instegrity
            constraints the method will raise this error
        """
        if max_retries is None:
            max_retries = len(table_list) - 1

        cons_list = self.get_fk_constraints()
        self.disable_fk_constraints(cons_list)

        failed_tables = []
        LOGGER.debug("table list: %s", table_list)
        LOGGER.debug("retries: %s", retries)
        for table in table_list:
            spaces = " " * retries * 2
            import_file = constants.get_parquet_file_path(table, env_str)
            LOGGER.info("Importing table %s %s", spaces, table)
            try:
                self.load_data(table, import_file, purge=purge)
            except (
                sqlalchemy.exc.IntegrityError,
                DatabaseError,
            ) as e:

                LOGGER.exception(
                    "%s loading table %s",
                    e.__class__.__qualname__,
                    table,
                )
                LOGGER.info("Adding %s to failed tables", table)
                failed_tables.append(table)
                LOGGER.info("truncating failed load table: %s", table)
                self.truncate_table(table.lower())

        if failed_tables:
            if retries < max_retries:
                LOGGER.info("Retrying failed tables")
                retries += 1
                self.load_data_retry(
                    table_list=failed_tables,
                    data_dir=data_dir,
                    env_str=env_str,
                    retries=retries,
                    max_retries=max_retries,
                    purge=purge,
                )
            else:
                LOGGER.error("Max retries reached for table %s", table)
                self.enable_constraints(cons_list)
                raise sqlalchemy.exc.IntegrityError
        else:
            self.enable_constraints(cons_list)

    def purge_data(
        self,
        table_list: list[str],
        retries: int = 1,
        max_retries: int = 6,
    ) -> None:
        """
        Purge the data from the tables in the list.

        :param table_list: the list of tables to delete the data from
        :type table_list: list[str]
        """
        self.get_connection()
        failed_tables = []
        for table in table_list:
            try:
                self.truncate_table(table)
                LOGGER.info("purged table %s", table)
            except (  # noqa: PERF203
                sqlalchemy.exc.IntegrityError,
                DatabaseError,
            ):
                LOGGER.warning(
                    "error encountered when attempting to purge table: %s, retrying",
                    table,
                )
                failed_tables.append(table)
        if failed_tables:
            if retries < max_retries:
                retries += 1
                self.purge_data(failed_tables, retries=retries)
            else:
                LOGGER.error("Max retries reached for table %s", table)
                raise sqlalchemy.exc.IntegrityError

    def get_fk_constraints(self) -> list[TableConstraints]:
        """
        Return the foreign key constraints for the schema.

        Queries the schema for all the foreign key constraints and returns a
        list of TableConstraints objects.

        :return: a list of TableConstraints objects that are used to store the
            results of the foreign key constraint query
        :rtype: list[TableConstraints]
        """

        self.get_connection()
        query = """SELECT
                    ac.constraint_name,
                    ac.table_name,
                    acc.column_name,
                    ac.r_constraint_name,
                    arc.table_name AS referenced_table,
                    arcc.column_name AS referenced_column
                FROM
                    all_constraints ac
                    JOIN all_cons_columns acc ON ac.constraint_name =
                        acc.constraint_name
                    JOIN all_constraints arc ON ac.r_constraint_name =
                        arc.constraint_name
                    JOIN all_cons_columns arcc ON arc.constraint_name =
                        arcc.constraint_name
                WHERE
                    ac.constraint_type = 'R'
                    AND ac.owner = :schema
                    AND arc.owner = :schema
                ORDER BY
                    ac.table_name,
                    ac.constraint_name,
                    acc.POSITION"""
        self.get_connection()
        cursor = self.connection.cursor()
        cursor.execute(query, schema=self.schema_2_sync)
        constraint_list = []
        for row in cursor:
            LOGGER.debug(row)
            tab_con = TableConstraints(*row)
            constraint_list.append(tab_con)
        return constraint_list

    def disable_fk_constraints(
        self,
        constraint_list: list[TableConstraints],
    ) -> None:
        """
        Disable all foreign key constraints.

        Iterates through the list of constraints and disables them.

        :param constraint_list: a list of constraints that are to be disabled
            by this method
        :type constraint_list: list[TableConstraints]
        """
        self.get_connection()
        cursor = self.connection.cursor()

        for cons in constraint_list:
            LOGGER.info("disabling constraint %s", cons.constraint_name)
            query = (
                f"ALTER TABLE {self.schema_2_sync}.{cons.table_name} "
                f"DISABLE CONSTRAINT {cons.constraint_name}"
            )

            cursor.execute(query)
        cursor.close()

    def enable_constraints(
        self,
        constraint_list: list[TableConstraints],
    ) -> None:
        """
        Enable all foreign key constraints.

        Iterates through the list of constraints and enables them.

        :param constraint_list: list of constraints that are to be enabled
        :type constraint_list: list[TableConstraints]
        """
        self.get_connection()
        cursor = self.connection.cursor()

        for cons in constraint_list:
            LOGGER.info("enabling constraint %s", cons.constraint_name)
            query = (
                f"ALTER TABLE {self.schema_2_sync}.{cons.table_name} "
                f"ENABLE CONSTRAINT {cons.constraint_name}"
            )
            cursor.execute(query)
        cursor.close()
