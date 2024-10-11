"""
Declare constants for the data_prep package.

"""

import pathlib

# the name of the directory where data downloads will be cached before they
# get uploaded to object store, and where they are cached when pulled from
# object store
DATA_DIR = "data"

# when running the script these are the different key words for describing
# different environments.
VALID_ENVS = ("DEV", "TEST", "PROD", "LOCAL")

PARQUET_SUFFIX = "parquet"

# name of the directory in object store where the data backup files reside
OBJECT_STORE_DATA_DIRECTORY = "pyetl"


def get_parquet_file_path(table: str, env_str: str) -> pathlib.Path:
    """
    Return path to parquet file that corresponds with a table.

    :param table: name of an oracle table
    :type table: str
    :param env_str: an environment string valid values DEV/TEST/PROD
    :type env_str: str
    :return: the path to the parquet file that corresponds with the table name
    :rtype: pathlib.Path
    """
    parquet_file_name = f"{table}.{PARQUET_SUFFIX}"
    return pathlib.Path(DATA_DIR, env_str, parquet_file_name)


def get_parquet_file_ostore_path(table: str) -> pathlib.Path:
    """
    Get path for data table in object store.

    Calculates the object store path for a table's data file.

    :param table: The name of the table who's corresponding data file is to be
        retrieved.
    :type table: str
    :return: path in object storage for the table's data file
    :rtype: pathlib.Path
    """
    parquet_file_name = f"{table}.{PARQUET_SUFFIX}"
    return pathlib.Path(OBJECT_STORE_DATA_DIRECTORY, parquet_file_name)
