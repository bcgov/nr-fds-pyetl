import logging

import db_env_utils.constants as constants
import db_env_utils.oradb_lib as oradb_lib

LOGGER = logging.getLogger(__name__)


def test_get_triggers(docker_connection_params_oracle):
    LOGGER.info("Testing backup_foreign_keys")
    LOGGER.debug(
        "docker_connection_params: %s", docker_connection_params_oracle
    )
    LOGGER.debug(
        "docker_connection_params types: %s",
        type(docker_connection_params_oracle),
    )
    db = oradb_lib.OracleDatabase(docker_connection_params_oracle)
    trigs = db.get_triggers()
    LOGGER.debug("trigs: %s", trigs)


def test_disable_triggers(docker_connection_params_oracle):
    db = oradb_lib.OracleDatabase(docker_connection_params_oracle)
    trigs = db.get_triggers()

    db.disable_trigs(trigs)

    db.enable_trigs(trigs)
