"""
Populate constants based on env str.

The objective for this lib is to translate the env name into a bunch of
constants that can be used by the code to determine things like:
* which database to connect to and the parameters required for that connection.
* which object store bucket to use.
"""

from __future__ import annotations

import logging
import os
from dataclasses import dataclass

import constants

LOGGER = logging.getLogger(__name__)


@dataclass
class ConnectionParameters:
    """
    Data class for database connection parameters.

    * username: the username to connect to the database with
    * password: the password for the username
    * host: the host for the database
    * port: the port for the database
    * service_name: the service name for the database

    """

    username: str | None
    password: str | None
    host: str | None
    port: str | None
    service_name: str | None
    schema_to_sync: str | None


@dataclass
class ObjectStoreParameters:
    """
    Parameters used to connect to object store buckets.

    """

    user_id: str
    bucket: str
    host: str
    secret: str


@dataclass
class AppConstants:
    """
    app constants.

    constants used to connect to backing services (database / object store /
    etc)

    """

    db_conn_params: ConnectionParameters
    object_store_params: ObjectStoreParameters
    schema_to_sync: str


SCHEMA_TO_SYNC: str


class Env:
    """
    Helper for retrieving environment variables.
    """

    def __init__(self, env_str: str) -> None:
        """
        Populate environment constants from environment variables.

        Different environment variables are used for different environments.
        A list of the environments considered by this calls include:

        OBJECT_STORE_BUCKET_<env>
        OBJECT_STORE_HOST_<env>
        OBJECT_STORE_SECRET_<env>
        OBJECT_STORE_USER_<env>

        ORACLE_HOST_<env>
        ORACLE_PORT_<env>
        ORACLE_SERVICE_<env>
        ORACLE_USER_<env>
        ORACLE_USER_<env>

        where env is the environment string.  This is a simple class to make it
        easy to retrive those environment variables and populate them into
        ObjectStoreParameters or ConnectionParameters


        :param env_str: the env string that is to be used to retrieve a set of
            environment variables, that are then used to populate object store
            and database connection parameters.
        :type env_str: str
        """
        self.validate(env_str)
        self.env = env_str

    def validate(self, proposed_env_str: str) -> None:
        """
        Validate proposed environment name.

        Will raise an error if the proposed environment does not align with
        allowed values.

        :param proposed_env_str: the proposed environment string
        :type proposed_env_str: str
        """
        if proposed_env_str not in constants.VALID_ENVS:
            msg = (
                f"The environment provided: '{proposed_env_str}' is invalid.  "
                f"Valid values include: {constants.VALID_ENVS}"
            )
            raise ValueError(msg)

    def get_schema_to_sync(self) -> str:
        """
        Get the schema to injest or export.

        This is handled differently from the other oracle connection parameters
        as the source of oracle connection parameters could come from a
        different location than the environment.  In that situation will still
        need to pull in this value from the environment.
        """
        LOGGER.debug("env for schema retrieval: %s", self.env)
        return os.getenv(f"ORACLE_SCHEMA_TO_SYNC_{self.env}")

    def get_ostore_constants(self) -> ObjectStoreParameters:
        """
        Get object store parameters.

        Returns the object store parameters necessary to communicate with object
        store.

        :return: _description_
        :rtype: AppConstants
        """
        obj_store_const = ObjectStoreParameters

        obj_store_const.bucket = os.getenv(f"OBJECT_STORE_BUCKET_{self.env}")
        obj_store_const.host = os.getenv(f"OBJECT_STORE_HOST_{self.env}")
        obj_store_const.secret = os.getenv(f"OBJECT_STORE_SECRET_{self.env}")
        obj_store_const.user_id = os.getenv(f"OBJECT_STORE_USER_{self.env}")
        return obj_store_const

    def get_db_env_constants(self) -> ConnectionParameters:
        """
        Populate constants from the environment.

        Required variables:
          * OBJECT_STORE_USER_<env>
          * OBJECT_STORE_SECRET_<env>
          * OBJECT_STORE_BUCKET_<env>
          * ORACLE_HOST_<env>
          * ORACLE_PORT_<env>
          * ORACLE_SERVICE_<env>
          * ORACLE_SYNC_USER_<env>
          * ORACLE_SYNC_PASSWORD_<env>
          * ORACLE_SCHEMA_TO_SYNC_<env>
        """
        database_const = ConnectionParameters

        database_const.host = os.getenv(f"ORACLE_HOST_{self.env}")
        database_const.port = os.getenv(f"ORACLE_PORT_{self.env}")
        database_const.service_name = os.getenv(f"ORACLE_SERVICE_{self.env}")
        database_const.username = os.getenv(f"ORACLE_USER_{self.env}")
        database_const.password = os.getenv(f"ORACLE_PASSWORD_{self.env}")

        database_const.schema_to_sync = self.get_schema_to_sync()
        LOGGER.debug("schema to sync: %s", database_const.schema_to_sync)
        return database_const


if __name__ == "__main__":
    env_str = "TEST"
    myenv = Env(env_str)
