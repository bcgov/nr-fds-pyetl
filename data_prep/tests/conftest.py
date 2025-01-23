import logging
import os
import sys

import pytest

LOGGER = logging.getLogger(__name__)

root_path = os.path.dirname(__file__)
LOGGER.debug("root_path: %s", root_path)
print("root_path: %s", root_path)
sys.path.append(os.path.join(os.path.dirname(__file__), ".."))
sys.path.append(os.path.join(os.path.dirname(__file__), "."))

LOGGER = logging.getLogger(__name__)

pytest_plugins = [
    "fixtures.demo_fixtures",
    "fixtures.dockerdb_fixtures",
    "fixtures.oradb_fixtures",
]

testSession = None
