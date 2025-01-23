import logging

import db_env_utils.env_config as env_config
import pytest

LOGGER = logging.getLogger(__name__)


@pytest.fixture(scope="module")
def placeholder():
    LOGGER.debug("doing nothingW")
