"""
Utility code to configure ingest and extract scripts.
"""

from __future__ import annotations

import base64
import logging
import logging.config
import pathlib
import socket
import time

import constants

# import docker_parser
import env_config

# import kubernetes_wrapper
# import object_store
import oradb_lib
import postgresdb_lib

LOGGER = logging.getLogger(__name__)


class Utility:
    """
    Utility class to run the extract and injest processes.
    """

    def __init__(self, env_str: str, db: constants.DBType) -> None:
        """
        Initialize the Utility class.
        """
        self.env_str = env_str
        self.env_obj = env_config.Env(env_str)
        self.curdir = pathlib.Path(__file__).parents[0]
        self.datadir = pathlib.Path(
            constants.DATA_DIR,
            self.env_str.upper(),
            db.name.upper(),
        )
        self.db_type = db
        self.kube_client = None

        self.connection_retries = 10

    def make_dirs(self) -> None:
        """
        Make necessary directories.

        Directories that need to be created are dependent on the database
        environment (TEST or PROD)

        """
        LOGGER.debug("datadir: %s", self.datadir)
        if not self.datadir.exists():
            self.datadir.mkdir(parents=True)
        # env_path = pathlib.Path(self.datadir, self.env_str)
        # if not env_path.exists():
        #     env_path.mkdir()

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
