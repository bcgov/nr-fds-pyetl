import base64
import logging
import os
import pathlib
import socket
import sys
import time

import click
import constants
import env_config
import kubernetes_wrapper
import main_common
import psycopg2

LOGGER = logging.getLogger(__name__)


@click.command()
@click.argument(
    "environment",
    type=click.Choice(
        ["TEST", "PROD"],
        case_sensitive=False,
    ),
)
@click.option(
    "--refresh", is_flag=True, help="Refresh the environment configuration."
)
def main(environment, refresh):
    """
    Extract data from spar postgres database.

    Identify the env to extract from... (TEST or PROD)

    Add the --refresh flag if you want to purge and recreate local and remote
    (object store) cached data.
    """
    global LOGGER
    environment = environment.upper()  # Ensure uppercase for consistency
    click.echo(f"Selected environment: {environment}")

    env_obj = env_config.Env(environment)
    db_type = constants.DBType.SPAR
    common_util = main_common.Utility(environment, db_type)
    common_util.configure_logging()
    logger_name = pathlib.Path(__file__).stem
    LOGGER = logging.getLogger(logger_name)

    if refresh:
        click.echo("Refresh flag is enabled. Refreshing configuration...")
    else:
        click.echo("Refresh flag is not enabled.")

    LOGGER.debug("refresh: %s %s", refresh, type(refresh))
    common_util.run_extract(refresh=refresh)


if __name__ == "__main__":
    if len(sys.argv) == 1:  # No arguments provided
        sys.argv.append("--help")  # Force help text if no args provided
    main()

    # # get the environment
    # env_str = "TEST"
    # if len(sys.argv) > 1:
    #     env_str = sys.argv[1]
    # env_obj = env_config.Env(env_str)

    # # configure logging
    # db_type = constants.DBType.SPAR
    # common_util = main_common.Utility(env_str, db_type)
    # common_util.configure_logging()
    # logger_name = pathlib.Path(__file__).stem
    # LOGGER = logging.getLogger(logger_name)

    # # new stuff
    # common_util.run_extract()
