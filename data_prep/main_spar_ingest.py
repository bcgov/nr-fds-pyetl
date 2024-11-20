"""

Load / Injest data from cached parquet files in objectstorage.

Setup Steps:

A) Start the docker database
-------------------------
Need to start the local database as that is the database that this script will
load with data.

B) Create / Activate the poetry environment
----------------------------------------
poetry install - to create
source $(poetry env info --path)/bin/activate - to activate

Populate the following environment variables

The script needs to be able to support the following environments,
DEV / TEST / PROD
which corresponds to which database the data that is being loaded originates
from.  If the script is run without arguements it will default to env=TEST
--------------------------------------------
ORACLE_USER_<env> - user to connect to the database with
ORACLE_PASSWORD_<env> - password for that user
ORACLE_HOST_<env> - host for the database
ORACLE_PORT_<env> - port for the database
ORACLE_SERVICE_<env> - database service

Run the script
--------------
python data_prep/main_injest.py

reference: https://www.andrewvillazon.com/quickly-load-data-db-python/

"""

import logging
import pathlib
import sys

import constants
import env_config
import main_common

LOGGER = logging.getLogger(__name__)


if __name__ == "__main__":
    # dealing with args
    # NOTE: if this gets more complex use a CLI framework
    env_str = "TEST"
    if len(sys.argv) > 1:
        env_str = sys.argv[1]
    env_obj = env_config.Env(env_str)

    db_type = constants.DBType.SPAR
    common_util = main_common.Utility(env_str, db_type)
    common_util.configure_logging()
    logger_name = pathlib.Path(__file__).stem
    LOGGER = logging.getLogger(logger_name)
    LOGGER.debug("log message in main")
    common_util.run_injest()
