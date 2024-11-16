"""
Parsing class for this projects docker compose file.

A class that makes it easy to extract database connection parameters from the
docker compose file.

"""

from __future__ import annotations

import logging
import os
import pathlib

import env_config
import yaml

LOGGER = logging.getLogger(__name__)


class ReadDockerCompose:
    """

    Methods to parse docker compose files.

    Utility methods to extract information from the docker compose file used for
    this project to create an ephemeral oracle database.

    """

    def __init__(self, compose_file_path: str | None = None) -> None:
        """
        Create object to parsedocker compose files.

        A series of methods to extract docker compose connection parameters for
        the oracle databases that have been spun up.

        :param compose_file_path: The path to the docker-compose to read, if no
            path is supplied assumes the docker-compose.yaml is in the directory
            that the script was executed from.
        :type compose_file_path: str, path
        """
        self.compose_file_path = compose_file_path

        if self.compose_file_path is None:
            self.compose_file_path = "./docker-compose.yml"

        with pathlib.Path(self.compose_file_path).open("r") as fh:
            self.docker_comp = yaml.safe_load(fh)

    def get_spar_conn_params(self) -> env_config.ConnectionParameters:
        """
        Return postgres connection parameters.

        Reads the postgres connection parameters from the docker-compose file and
        returns them as a oracledb.ConnectionTuple.

        :return: a oracledb.ConnectionTuple populated with the connection
            parameters
        :rtype: oradb_lib.ConnectionTuple
        """
        import pprint

        pp = pprint.PrettyPrinter()
        pp.pprint(self.docker_comp)
        conn_tuple = env_config.ConnectionParameters
        conn_tuple.username = self.docker_comp["x-postgres-vars"][
            "POSTGRES_USER"
        ]
        conn_tuple.password = self.docker_comp["x-postgres-vars"][
            "POSTGRES_PASSWORD"
        ]
        conn_tuple.port = self.docker_comp["x-postgres-vars"]["POSTGRES_PORT"]

        conn_tuple.service_name = self.docker_comp["x-postgres-vars"][
            "POSTGRES_DB"
        ]
        # using localhost because the connection is going to be made external
        # to the docker container
        conn_tuple.host = os.getenv("POSTGRES_HOST", "localhost")
        conn_tuple.schema_to_sync = "spar"
        return conn_tuple

    def get_ora_conn_params(self) -> env_config.ConnectionParameters:
        """
        Return oracle connection parameters.

        Reads the oracle connection parameters from the docker-compose file and
        returns them as a oracledb.ConnectionTuple.

        :return: a oracledb.ConnectionTuple populated with the connection
            parameters
        :rtype: oradb_lib.ConnectionTuple
        """
        conn_tuple = env_config.ConnectionParameters
        conn_tuple.username = self.docker_comp["x-oracle-vars"]["APP_USER"]
        conn_tuple.password = self.docker_comp["x-oracle-vars"][
            "APP_USER_PASSWORD"
        ]

        # this method will return the host for the docker container which is
        # expected to be running locally and is therefor 'localhost'
        conn_tuple.host = "localhost"

        conn_tuple.port = self.docker_comp["services"]["oracle"]["ports"][
            0
        ].split(":")[0]
        conn_tuple.service_name = self.docker_comp["x-oracle-vars"][
            "ORACLE_DATABASE"
        ]
        return conn_tuple
