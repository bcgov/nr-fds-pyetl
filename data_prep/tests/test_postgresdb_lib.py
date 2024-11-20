import logging

import constants
import postgresdb_lib

LOGGER = logging.getLogger(__name__)


def test_backup_foreign_keys(docker_connection_params):
    """
    Verify foreign keys can be backed up.
    """
    LOGGER.debug("docker_connection_params: %s", docker_connection_params)
    db = postgresdb_lib.PostgresDatabase(docker_connection_params)
    fk_constraints = db.get_fk_constraints()
    LOGGER.debug("fk_constraints: %s", fk_constraints[0:3])
    fk_back = postgresdb_lib.ConstraintBackup(docker_connection_params)
    fk_back.backup_constraints(fk_constraints)
    assert True


def test_get_fk_constraints(docker_connection_params):
    """
    Verify foreign keys can be retrieved.

    Also make sure they describe multiple column constraints.
    """
    LOGGER.debug("docker_connection_params: %s", docker_connection_params)
    db = postgresdb_lib.PostgresDatabase(docker_connection_params)
    fk_constraints = db.get_fk_constraints()
    LOGGER.debug("number of fk_constraints: %s", len(fk_constraints))

    LOGGER.debug("fk_constraints: %s", fk_constraints[0:3])
    assert len(fk_constraints) > 0
