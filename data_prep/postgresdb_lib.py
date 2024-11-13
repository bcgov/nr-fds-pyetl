from __future__ import annotations

import gzip
import logging
import logging.config
import os
import pathlib
import subprocess
from dataclasses import dataclass

import constants
import db_lib
import pandas as pd
import psycopg2
import pyarrow
import sqlalchemy
from env_config import ConnectionParameters
from psycopg2 import DatabaseError

LOGGER = logging.getLogger(__name__)


class PostgresDatabase(db_lib.DB):

    def get_connection(self) -> None:
        """
        Create a connection to the postgres database.

        Creates a connection to the database using class variables that are
        populated by the object constructor.
        """
        if self.connection is None:
            LOGGER.info("connecting the oracle database: %s", self.service_name)
            self.connection = psycopg2.connect(
                user=self.username,
                password=self.password,
                host=self.host,
                port=self.port,
                dbname=self.service_name,
            )
            LOGGER.debug("connected to database")

    def populate_db_type(self) -> None:
        """
        Populate the db_type variable.

        Sets the db_type variable to SPAR.
        """
        self.db_type = constants.DBType.SPAR

    def get_sqlalchemy_engine(self) -> None:
        """
        Populate the sqlalchemy engine.

        Using the sql alchemy connection string created in the constructor
        creates a sql_alchemy engine.
        """
        if self.sql_alchemy_engine is None:
            dsn = f"postgresql+psycopg2://{self.username}:{self.password}@{self.host}:{self.port}/{self.service_name}"
            LOGGER.debug("dsn: %s", dsn)
            self.sql_alchemy_engine = sqlalchemy.create_engine(
                dsn,
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
        # query = "select table_name from all_tables where owner = :schema"
        query = (
            "SELECT table_name FROM information_schema.tables WHERE "
            "table_schema = %(schema)s"
        )
        LOGGER.debug("query: %s", query)
        cursor.execute(query, {"schema": schema})
        # rows = cursor.fetchall()
        # LOGGER.debug("table query data returned: %s", rows)
        tables = [
            row[0].upper()
            for row in cursor
            if row[0].upper() not in omit_tables
        ]
        cursor.close()
        LOGGER.debug("tables: %s", tables)
        if not tables:
            LOGGER.error("no tables found in schema: %s", schema)
            raise DatabaseError("no tables found in schema")
        return tables

    def truncate_table(self, table: str) -> None:
        """
        Delete all the data from the table.

        :param table: the table to delete the data from
        """
        self.get_connection()
        cursor = self.connection.cursor()
        LOGGER.debug("truncating table: %s", table)
        LOGGER.debug("schema to sync: %s", self.schema_2_sync)
        cursor.execute(f"truncate table {self.schema_2_sync}.{table} CASCADE")
        self.connection.commit()
        cursor.close()
        LOGGER.debug("successfully truncated table: %s", table)

    def get_fk_constraints(self) -> list[db_lib.TableConstraints]:
        """
        Return the foreign key constraints for the schema.

        Queries the schema for all the foreign key constraints and returns a
        list of TableConstraints objects.

        :return: a list of TableConstraints objects that are used to store the
            results of the foreign key constraint query
        :rtype: list[TableConstraints]
        """

        query = """SELECT
                    tc.constraint_name AS fk_constraint_name,
                    tc.table_name AS from_table,
                    kcu.column_name AS from_column,
                    rco.constraint_name AS pk_constraint_name,
                    ccu.table_name AS to_table,
                    ccu.column_name AS to_column
                FROM
                    information_schema.table_constraints AS tc
                    JOIN information_schema.key_column_usage AS kcu
                    ON tc.constraint_name = kcu.constraint_name
                    AND tc.table_schema = kcu.table_schema
                    JOIN information_schema.constraint_column_usage AS ccu
                    ON ccu.constraint_name = tc.constraint_name
                    AND ccu.table_schema = tc.table_schema
                    JOIN information_schema.referential_constraints AS rc
                    ON tc.constraint_name = rc.constraint_name
                    AND tc.table_schema = rc.constraint_schema
                    JOIN information_schema.table_constraints AS rco
                    ON rc.unique_constraint_name = rco.constraint_name
                    AND rc.unique_constraint_schema = rco.constraint_schema
                WHERE
                    tc.constraint_type = 'FOREIGN KEY' and
                    tc.table_schema = %(schema)s and
                    ccu.table_schema = %(schema)s and
                    rco.table_schema = %(schema)s
                    """
        self.get_connection()
        cursor = self.connection.cursor()
        cursor.execute(query, {"schema": self.schema_2_sync})
        constraint_list = []
        for row in cursor:
            LOGGER.debug(row)
            tab_con = db_lib.TableConstraints(*row)
            constraint_list.append(tab_con)
        return constraint_list

    def disable_fk_constraints(
        self,
        constraint_list: list[db_lib.TableConstraints],
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
                f"ALTER CONSTRAINT {cons.constraint_name} NOT VALID"
            )

            # ALTER TABLE spar.seedlot_collection_method ALTER CONSTRAINT
            # seedlot_coll_met_seedlot_fk DEFERRABLE INITIALLY DEFERRED;
            query = (
                f"ALTER TABLE {self.schema_2_sync}.{cons.table_name} "
                f"ALTER CONSTRAINT {cons.constraint_name} DEFERRABLE INITIALLY DEFERRED"
            )

            LOGGER.debug("alter query: %s", query)
            cursor.execute(query)
        cursor.close()

    def enable_constraints(
        self,
        constraint_list: list[db_lib.TableConstraints],
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
                f"VALIDATE CONSTRAINT {cons.constraint_name}"
            )
            cursor.execute(query)
        cursor.close()

    def load_data(
        self,
        table: str,
        import_file: pathlib.Path,
        *,
        purge: bool = False,
    ) -> None:
        """
        Load the data from the file into the table.

        Override the default implementation to use the postgres copy command to
        speed up loading of csv data.

        :param table: the table to load the data into
        :type table: str
        :param import_file: the file to read the data from
        :type import_file: str
        :param purge: if True, delete the data from the table before loading.
        :type purge: bool
        """
        # debugging to view the data before it gets loaded
        LOGGER.debug("input parquet file to load: %s", import_file)
        if import_file.suffix == ".parquet":
            LOGGER.debug("reading parquet file, %s", import_file)
            super().load_data(table=table, import_file=import_file, purge=purge)
        else:
            LOGGER.debug("loading data from csv using COPY, %s", import_file)

            cur = self.connection.cursor()
            # cons_name = "registration_form_a_class_seedlot_fk"
            # query = (
            #     f"ALTER TABLE {self.schema_2_sync}.{table.lower()} "
            #     f"ALTER CONSTRAINT {cons_name} DEFERRABLE INITIALLY DEFERRED"
            # )
            # cur.execute(query)
            with open(import_file) as f:
                # spar.seedlot_registration_a_class_save
                cur.execute("SET search_path TO spar, public ")
                cur.copy_from(
                    f,
                    "seedlot_registration_a_class_save",
                    sep="|",
                    size=8192,
                )
            cur.close()

    def extract_data(
        self,
        table: str,
        export_file: pathlib.Path,
        *,
        overwrite: bool = False,
    ) -> bool:
        """
        Override the default implementation to use the postgres pg_dump command.

        By default will call the super class method to extract the data from the
        database and store in a parquet file.  If that process fails then the
        fallback will be to use the pg_dump command to extract the data from the
        database.

        :param table: the name of the table who's data will be copied to the
            exported data file (parquet or pg_dump format)
        :type table: str
        :param export_file: the full path to the file that will be created, and
            populated with the data from the table.
        :type export_file: str
        :param overwrite: if True the file will be overwritten if it exists,
        :return: True if the file was created, False if it was not
        :rtype: bool
        """
        file_created = False

        # check that the directory for export file exists
        export_file.parent.mkdir(parents=True, exist_ok=True)
        export_file_sql = export_file.with_suffix(constants.SQL_DUMP_SUFFIX)
        LOGGER.debug("export file is: %s", export_file)
        LOGGER.debug("export file sql is: %s", export_file_sql)

        if (
            not export_file.exists() and not export_file_sql.exists()
        ) or overwrite:

            if export_file.exists():
                export_file.unlink()  # delete dump file if exists
            if export_file_sql.exists():
                export_file_sql.unlink()
                # delete the file if it exists
            try:
                # first try the super class method to extract the data using parquet
                super().extract_data(
                    table=table,
                    export_file=export_file,
                    overwrite=overwrite,
                )
            except pyarrow.lib.ArrowNotImplementedError as e:
                # the dump to parquet failed... fail over is to us pg_dump
                LOGGER.debug("running pg_dump to extract the data")
                # copy the environment and populate the PGPASSWORD variable
                my_env = os.environ.copy()
                my_env["PGPASSWORD"] = self.password

                # setup the pg_dump command
                pg_dump_command_list = [
                    "pg_dump",
                    "-p",
                    str(self.port),
                    "--data-only",
                    "-U",
                    self.username,
                    "-h",
                    self.host,
                    "-d",
                    self.service_name,
                    "-t",
                    f"{self.schema_2_sync}.{table}",
                ]
                LOGGER.debug("command list: %s", pg_dump_command_list)
                with gzip.open(str(export_file_sql), "wb") as f:
                    popen = subprocess.Popen(
                        pg_dump_command_list,
                        stdout=subprocess.PIPE,
                        universal_newlines=True,
                        env=my_env,
                    )
                    for stdout_line in iter(popen.stdout.readline, ""):
                        f.write(stdout_line.encode("utf-8"))
                popen.stdout.close()
                popen.wait()
                LOGGER.info("pg_dump complete")
            file_created = True
        else:
            LOGGER.info("file exists: %s, not re-exporting", export_file)
        return file_created
