import logging
import os
import sys

import pytest

sys.path.append(os.path.join(os.path.dirname(__file__), ".."))
sys.path.append(os.path.join(os.path.dirname(__file__), "."))


LOGGER = logging.getLogger(__name__)

pytest_plugins = [
    "fixtures.demo_fixtures",
]

testSession = None
