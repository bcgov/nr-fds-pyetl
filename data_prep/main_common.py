"""
Utility code to configure ingest and extract scripts.
"""

from __future__ import annotations

import logging
import logging.config
import pathlib

import constants
import docker_parser
import env_config
import object_store
import oradb_lib

LOGGER = logging.getLogger(__name__)


class Utility:
    """
    Utility class to run the extract and injest processes.
    """

    def __init__(self, env_str: str) -> None:
        """
        Initialize the Utility class.
        """
        self.env_str = env_str
        self.env_obj = env_config.Env(env_str)
        self.curdir = pathlib.Path(__file__).parents[0]
        self.datadir = pathlib.Path(
            self.curdir,
            "..",
            constants.DATA_DIR,
        ).resolve()

    def make_dirs(self) -> None:
        """
        Make necessary directories.
        """
        LOGGER.debug("datadir: %s", self.datadir)
        if not self.datadir.exists():
            self.datadir.mkdir(parents=True)
        env_path = pathlib.Path(self.datadir, self.env_obj.env)
        if not env_path.exists():
            env_path.mkdir()

    def configure_logging(self) -> None:
        """
        Configure logging.
        """
        log_config_path = pathlib.Path(self.curdir, "logging.config")
        logging.config.fileConfig(
            log_config_path,
            disable_existing_loggers=False,
        )
        global LOGGER  # noqa: PLW0603
        LOGGER = logging.getLogger(__name__)
        LOGGER.debug("test debug message")

    def get_tables_from_local_docker(self) -> list[str]:
        """
        Get tables from local docker.
        """
        dcr = docker_parser.ReadDockerCompose()
        local_ora_params = dcr.get_ora_conn_params()
        local_ora_params.schema_to_sync = self.env_obj.get_schema_to_sync()
        LOGGER.debug("schema to sync: %s", local_ora_params.schema_to_sync)
        local_docker_db = oradb_lib.OracleDatabase(local_ora_params)
        tables_to_export = local_docker_db.get_tables(
            local_docker_db.schema_2_sync,
            omit_tables=["FLYWAY_SCHEMA_HISTORY"],
        )
        LOGGER.debug("tables retrieved: %s", tables_to_export)
        return tables_to_export

    def connect_ostore(self) -> object_store.OStore:
        """
        Connect to object store.
        """
        ostore_params = self.env_obj.get_ostore_constants()
        return object_store.OStore(conn_params=ostore_params)

    def run_extract(self) -> None:
        """
        Run the extract process.
        """
        self.make_dirs()
        tables_to_export = self.get_tables_from_local_docker()
        ostore = self.connect_ostore()

        ora_params = self.env_obj.get_db_env_constants()
        remote_ora_db = oradb_lib.OracleDatabase(
            ora_params,
        )  # use the environment variables for connection parameters
        remote_ora_db.get_connection()
        for table in tables_to_export:
            LOGGER.info("Exporting table %s", table)
            export_file = constants.get_parquet_file_path(
                table,
                self.env_obj.current_env,
            )
            LOGGER.debug("export_file: %s", export_file)
            file_created = remote_ora_db.extract_data(table, export_file)

            if file_created:
                # push the file to object store
                ostore.put_data_files([export_file], self.env_obj.current_env)

    def run_injest(self) -> None:
        """
        Run the injest process.
        """
        self.make_dirs()
        tables_to_import = self.get_tables_from_local_docker()
        ostore = self.connect_ostore()

        dcr = docker_parser.ReadDockerCompose()
        local_ora_params = dcr.get_ora_conn_params()
        local_ora_params.schema_to_sync = self.env_obj.get_schema_to_sync()
        local_docker_db = oradb_lib.OracleDatabase(local_ora_params)

        ostore.get_data_files(tables_to_import, self.env_obj.current_env)

        local_docker_db.purge_data(table_list=tables_to_import)

        local_docker_db.load_data_retry(
            data_dir=self.datadir,
            table_list=tables_to_import,
            env_str=self.env_obj.current_env,
            purge=False,
        )
