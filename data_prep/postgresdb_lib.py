"""
Implements required methods to load data to postgres database.
"""

from __future__ import annotations

import gzip
import logging
import logging.config
import os
import pathlib
import subprocess

import constants
import db_lib
import psycopg2
import sqlalchemy
from env_config import ConnectionParameters
from psycopg2 import DatabaseError

LOGGER = logging.getLogger(__name__)


class PostgresDatabase(db_lib.DB):
    """
    Postgres database class.

    :param db_lib: abstract class to inherit from
    :type db_lib: db_lib.DB
    """

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
        query = (
            "SELECT table_name FROM information_schema.tables WHERE "
            "table_schema = %(schema)s"
        )
        LOGGER.debug("query: %s", query)
        cursor.execute(query, {"schema": schema})
        tables = [
            row[0].upper()
            for row in cursor
            if row[0].upper() not in omit_tables
        ]
        cursor.close()
        LOGGER.debug("tables: %s", tables)
        if not tables:
            LOGGER.error("no tables found in schema: %s", schema)
            raise DatabaseError(schema)
        return tables

    def truncate_table(self, table: str, *, cascade: bool = False) -> None:
        """
        Delete all the data from the table.

        :param table: the table to delete the data from
        """
        self.get_connection()
        cursor = self.connection.cursor()
        LOGGER.debug("truncating table: %s", table)
        LOGGER.debug("schema to sync: %s", self.schema_2_sync)
        query = f"truncate table {self.schema_2_sync}.{table.lower()}"
        if cascade:
            query += " CASCADE"
            LOGGER.debug("truncate with cascade option.")
        try:
            cursor.execute(query)
            self.connection.commit()
            LOGGER.debug("successfully truncated table: %s", table)
        except psycopg2.errors.FeatureNotSupported:
            LOGGER.exception("truncate failed on table: %s", table)
            self.connection.rollback()
            raise
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
                    tc.table_schema = %(schema)s and
                    ccu.table_schema = %(schema)s and
                    rco.table_schema = %(schema)s
                    """
        self.get_connection()
        cursor = self.connection.cursor()
        cursor.execute(query, {"schema": self.schema_2_sync})

        # restructure the data, removing duplicates
        constraint_data = cursor.fetchall()
        cursor.close()

        constraint_data_index = {}
        for row in constraint_data:
            # can have multiple columns in from and multiple columns in to
            # definitions for a constraint.
            # 0 - foreign key constraint name
            # 1 - from table
            # 2 - from column
            # 3 - primary key constraint name
            # 4 - to table
            # 5 - to column
            constraint_name = row[0]
            if constraint_name in constraint_data_index:
                existing_record = constraint_data_index[row[0]]
                # is the incomming source table already defined for this
                # constraint and the column is not already defined
                if (
                    row[1] == existing_record.table_name
                    and row[2] not in existing_record.column_names
                ):
                    existing_record.column_names.append(row[2])
                    constraint_data_index[row[0]] = existing_record
                # is the referenced table already defined for this constraint
                # but the referenced column is not
                if (
                    row[4] == existing_record.referenced_table
                    and row[5] not in existing_record.referenced_columns
                ):
                    existing_record.referenced_columns.append(row[5])
                    constraint_data_index[row[0]] = existing_record
            else:
                cons_struct = db_lib.TableConstraints(
                    constraint_name=row[0],
                    table_name=row[1],
                    column_names=[row[2]],
                    r_constraint_name=row[3],
                    referenced_table=row[4],
                    referenced_columns=[row[5]],
                )
                constraint_data_index[constraint_name] = cons_struct

        constraint_list = list(constraint_data_index.values())
        LOGGER.debug("constraint_data_index: %s", constraint_list)
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
        # cache in memory the constraints that are being disabled
        self.fk_constraint_backup = ConstraintBackup(self)
        self.fk_constraint_backup.backup_constraints(constraint_list)

        for cons in constraint_list:
            LOGGER.info("disabling constraint %s", cons.constraint_name)
            query = self.fk_constraint_backup.get_disable_alter_statement(cons)
            LOGGER.debug("alter query: %s", query)
            try:
                cursor.execute(query)
                self.connection.commit()
            except (
                psycopg2.errors.UndefinedObject,
                psycopg2.errors.InFailedSqlTransaction,
            ) as e:
                # UndefinedObject: gets raised when constraint does not exist.
                LOGGER.warning(
                    "constraint not found: %s ... error is %s",
                    cons.constraint_name,
                    e,
                )
        LOGGER.debug("closing the cursor")
        cursor.close()

    def enable_constraints(
        self,
        constraint_list: list[db_lib.TableConstraints],
        retries: int = 0,
    ) -> None:
        """
        Enable all foreign key constraints.

        Iterates through the list of constraints and enables them.

        :param constraint_list: list of constraints that are to be enabled
        :type constraint_list: list[TableConstraints]
        """
        max_retries = 5  # could put this into constants
        self.get_connection()
        cursor = self.connection.cursor()
        failed_constraints = []
        for cons in constraint_list:
            LOGGER.info("enabling constraint %s", cons.constraint_name)
            query = self.fk_constraint_backup.get_enable_alter_statement(cons)
            try:
                cursor.execute(query)
                self.connection.commit()
            except psycopg2.errors.DuplicateObject:
                LOGGER.info(
                    "constraint already exists: %s",
                    cons.constraint_name,
                )
            except (
                psycopg2.errors.InFailedSqlTransaction,
                psycopg2.errors.InvalidForeignKey,
            ):
                LOGGER.exception(
                    "unable to enable the constraint: %s",
                    cons.constraint_name,
                )
                if retries > 1:
                    raise
                self.connection.rollback()
                failed_constraints.append(cons)
        cursor.close()
        if failed_constraints:
            if retries > max_retries:
                raise psycopg2.errors.InvalidForeignKey
            retries += 1
            self.enable_constraints(failed_constraints, retries)
            LOGGER.error(
                "retrying %s failed constraints",
                len(failed_constraints),
            )
        else:
            LOGGER.info("all constraints enabled")
            LOGGER.debug("remove the constraint backup file")
            self.fk_constraint_backup.get_constraint_backup_file_path().unlink()

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
        LOGGER.debug("input file to load: %s", import_file)
        if not import_file.exists():
            LOGGER.error("sql dump file not found: %s", import_file)
            raise FileNotFoundError

        LOGGER.debug(
            "loading data from csv using sql_dump file, %s",
            import_file,
        )

        my_env = os.environ.copy()
        my_env["PGPASSWORD"] = self.password
        gzip_command_list = ["gunzip", "-c", str(import_file)]
        psql_command_list = [
            "psql",
            "-U",
            self.username,
            "-d",
            self.service_name,
            "-h",
            self.host,
            "-p",
            str(self.port),
        ]
        LOGGER.debug("psql command list: %s", psql_command_list)
        LOGGER.debug("start gunzip pipe...")
        # psql -d spar -h localhost -p 5432 -U postgres  < seed_save.dmp
        gunzip_process = subprocess.Popen(  # noqa: S603
            gzip_command_list,
            stdout=subprocess.PIPE,
        )
        LOGGER.debug("start data load pipe...")
        load_process = subprocess.Popen(  # noqa: S603
            psql_command_list,
            env=my_env,
            stdin=gunzip_process.stdout,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        stdout, stderr = load_process.communicate()
        LOGGER.debug("stdout: %s", stdout)
        LOGGER.debug("stderr: %s", stderr)
        LOGGER.debug("loading data...")
        LOGGER.debug("return code: %s", load_process.returncode)
        if load_process.returncode != 0:
            LOGGER.error("data load failed on input file: %s", import_file)
            raise DatabaseError

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
        LOGGER.debug("exporting table %s to %s", table, export_file)
        file_created = False
        if (not export_file.exists()) or overwrite:
            if "".join(export_file.suffixes) == constants.SQL_DUMP_SUFFIX:
                file_created = self.extract_sql_dump_file(export_file, table)
            elif "".join(export_file.suffixes) == constants.PARQUET_SUFFIX:
                file_created = super().extract_data(
                    table=table,
                    export_file=export_file,
                    overwrite=overwrite,
                )
            else:
                LOGGER.debug("suffix: %s", export_file.suffix)
                LOGGER.error("unsupported file type: %s", export_file)
                raise ValueError
        else:
            LOGGER.info("file exists: %s, not re-exporting", export_file)
        return file_created

    def extract_sql_dump_file(
        self,
        export_file: pathlib.Path,
        table: str,
    ) -> bool:
        """
        Extract the sql dump file from the database.

        The sql dump file is a file that contains the database schema and data.
        """
        export_file.parent.mkdir(parents=True, exist_ok=True)
        LOGGER.debug("extracting sql dump file")
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
        with gzip.open(str(export_file), "wb") as f:
            popen = subprocess.Popen(  # noqa: S603
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
        return True


class ConstraintBackup:
    """
    Handle constraint backup and restore.

    Postgres does not have the ability to disable constraints like oracle does.
    This class is used to backup constraints, so that they can be reloaded
    after the data load has been completed.
    """

    def __init__(self, db_inst: PostgresDatabase) -> ConstraintBackup:
        """
        Create ConstraintBackup instance.

        :param db_inst: Postgres database class to be used to perform constraint
            backup and restore operations
        :type db_inst: PostgresDatabase
        :return: Instance of ConstraintBackup
        :rtype: ConstraintBackup
        """
        connection_params = ConnectionParameters
        connection_params.username = db_inst.username
        connection_params.password = db_inst.password
        connection_params.host = db_inst.host
        connection_params.port = db_inst.port
        connection_params.service_name = db_inst.service_name
        connection_params.schema_to_sync = db_inst.schema_2_sync

        self.connection_params = connection_params
        self.constraint_list: list[db_lib.TableConstraints]

    def get_constraint_backup_file_path(self) -> pathlib.Path:
        """
        Return the path to the constraint backup file.

        :return: the path to the constraint backup file
        :rtype: pathlib.Path
        """
        backup_file_name = (
            f"fk_bkup_{self.connection_params.host}_"
            f"{self.connection_params.port}_"
            f"{self.connection_params.service_name}.sql"
        )
        return pathlib.Path(
            constants.DATA_DIR,
            constants.CONSTRAINT_BACKUP_DIR,
            backup_file_name,
        )

    def backup_constraints(
        self,
        constraint_list: list[db_lib.TableConstraints],
    ) -> None:
        """
        Backup the constraints to a file.
        """
        self.constraint_list = constraint_list
        backup_file = self.get_constraint_backup_file_path()
        LOGGER.debug("backup file: %s", backup_file)

        # make sure the directory exists
        backup_file.parent.mkdir(parents=True, exist_ok=True)

        # need logic for if the constraint file already exists
        with backup_file.open("w") as f:
            for cons in constraint_list:
                # example alter statement:
                # ---------------------------
                # ALTER TABLE
                #   spar.seedlot_registration_a_class_save ADD CONSTRAINT
                # registration_form_a_class_seedlot_fk FOREIGN KEY
                # (seedlot_number) REFERENCES spar.seedlot(seedlot_number);
                LOGGER.debug("constraint: %s", cons.constraint_name)
                alter_statement = self.get_enable_alter_statement(cons)
                f.write(alter_statement)

    def get_enable_alter_statement(self, cons: db_lib.TableConstraints) -> str:
        """
        Return the alter statement for the constraint.

        :param cons: the constraint to generate the alter statement for
        :type cons: TableConstraints
        :return: the alter statement
        :rtype: str
        """
        alter_statement = (
            f"ALTER TABLE "
            f"{self.connection_params.schema_to_sync}.{cons.table_name} "
            f"ADD CONSTRAINT {cons.constraint_name} FOREIGN KEY "
            f"({','.join(cons.column_names)}) "
            f"REFERENCES {self.connection_params.schema_to_sync}."
            f"{cons.referenced_table}({','.join(cons.referenced_columns)}) "
            " ;\n"
        )
        LOGGER.debug("alter statement: %s", alter_statement)
        return alter_statement

    def get_disable_alter_statement(self, cons: db_lib.TableConstraints) -> str:
        """
        Return the alter statement to disable the constraint.

        :param cons: the constraint to generate the alter statement for
        :type cons: TableConstraints
        :return: the alter statement
        :rtype: str
        """
        alter_statement = (
            f"ALTER TABLE {self.connection_params.schema_to_sync}."
            f"{cons.table_name} "
            f"DROP CONSTRAINT {cons.constraint_name};\n"
        )
        LOGGER.debug("alter statement: %s", alter_statement)
        return alter_statement
