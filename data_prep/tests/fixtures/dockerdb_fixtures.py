"""
Fixtures used to support testing of docker db.
"""

import logging

import env_config
import pytest

LOGGER = logging.getLogger(__name__)


@pytest.fixture(scope="module")
def docker_connection_params():
    """
    Connection parameters for docker database.
    """
    conn_params = env_config.ConnectionParameters
    conn_params.username = "postgres"
    conn_params.password = "default"
    conn_params.host = "localhost"
    conn_params.port = 5432
    conn_params.service_name = "spar"
    conn_params.schema_to_sync = "spar"
    yield conn_params
