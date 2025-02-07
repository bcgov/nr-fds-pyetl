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

import click
import constants
import env_config
import main_common

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
    "--purge",
    is_flag=True,
    help="Purge the database and reload with fresh data",
)
def main(environment, purge):
    """
    Load the data from object store cache to local postgres (spar) database.

    Identify the env to load from... (TEST or PROD).

    Add the --purge flag if you want to purge cached local data and reload from
    remote (object store).
    """
    global LOGGER
    environment = environment.upper()  # Ensure uppercase for consistency
    click.echo(f"Selected environment: {environment}")

    db_type = constants.DBType.SPAR
    common_util = main_common.Utility(environment, db_type)
    common_util.configure_logging()
    logger_name = pathlib.Path(__file__).stem
    LOGGER = logging.getLogger(logger_name)

    if purge:
        click.echo(
            "Purge flag is enabled. Will remove local files, and then pull new ones from ostore..."
        )
    else:
        click.echo(
            "Purge flag is not enabled... Only load data from local files."
        )

    LOGGER.debug("purge: %s %s", purge, type(purge))
    common_util.run_injest(purge=purge)


if __name__ == "__main__":
    if len(sys.argv) == 1:  # No arguments provided
        sys.argv.append("--help")  # Force help text if no args provided
    main()
