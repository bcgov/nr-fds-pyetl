import base64
import logging
import os
import pathlib
import socket
import sys
import time

import constants
import env_config
import kubernetes_wrapper
import main_common
import psycopg2

LOGGER = logging.getLogger(__name__)

if __name__ == "__main__":
    env_str = "TEST"
    if len(sys.argv) > 1:
        env_str = sys.argv[1]
    env_obj = env_config.Env(env_str)

    # configure logging
    db_type = constants.DBType.SPAR
    common_util = main_common.Utility(env_str, db_type)
    common_util.configure_logging()
    logger_name = pathlib.Path(__file__).stem
    LOGGER = logging.getLogger(logger_name)

    # new stuff
    common_util.run_extract()
