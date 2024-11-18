"""

Extract data from the oracle database and cache in parquet files in object storage.

Start the docker database
-------------------------
docker compose up oracle-migrations

Start the VPN
-----------------------
start the VPN to allow access to the database

Resolve WSL / VPN network issues
--------------------------------
different by computer / I run the following powershell commands:
    Get-NetAdapter | Where-Object {$_.InterfaceDescription -Match "Cisco AnyConnect"} | Set-NetIPInterface -InterfaceMetric 6000
    Get-NetIPInterface -InterfaceAlias "vEthernet (WSL)" | Set-NetIPInterface -InterfaceMetric 1

Create / Activate the poetry environment
----------------------------------------
poetry install - to create
source $(poetry env info --path)/bin/activate - to activate

Populate the following environment variables
--------------------------------------------
ORACLE_USER - user to connect to the database with
ORACLE_PASSWORD - password for that user
ORACLE_HOST - host for the database
ORACLE_PORT - port for the database
ORACLE_SERVICE - database service

Run the script
--------------
python data_prep/pull_ora_objstr.py

:return: _description_
:rtype: _type_


reference: https://www.andrewvillazon.com/quickly-load-data-db-python/

"""  # noqa: E501

import logging
import logging.config
import pathlib
import sys
from concurrent import futures  # noqa: F401

import constants
import main_common

LOGGER = logging.getLogger(__name__)


if __name__ == "__main__":
    # dealing with args
    # NOTE: if this gets more complex use a CLI framework
    env_str = "TEST"
    if len(sys.argv) > 1:
        env_str = sys.argv[1]

    common_util = main_common.Utility(env_str, constants.DBType.ORA)
    common_util.configure_logging()
    logger_name = pathlib.Path(__file__).stem
    LOGGER = logging.getLogger(logger_name)
    LOGGER.debug("log message in main")
    common_util.run_extract()
