from __future__ import annotations

import logging
import logging.config
from dataclasses import dataclass

import db_lib
import pandas as pd
import psycopg2
import sqlalchemy
from env_config import ConnectionParameters
from psycopg2.exceptions import DatabaseError

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

    def get_sqlalchemy_engine(self) -> None:
        """
        Populate the sqlalchemy engine.

        Using the sql alchemy connection string created in the constructor
        creates a sql_alchemy engine.
        """
        if self.sql_alchemy_engine is None:
            dsn = f"postgresql+psycopg2://{self.username}:{self.password}@{self.host}:{self.port}/{self.service_name}"
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
        # query = "select table_name from all_tables where owner = :schema"
        query = (
            "SELECT table_name FROM information_schema.tables WHERE "
            "table_schema = :schema"
        )
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
                    tc.table_schema = 'spar' and
                    ccu.table_schema = 'spar' and
                    rco.table_schema = 'spar'
                    """
        self.get_connection()
        cursor = self.connection.cursor()
        cursor.execute(query, schema=self.schema_2_sync)
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
