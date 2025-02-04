import json
import logging.config
import os
import pathlib
import sys

import module.data_synchronization as data_sync
import yaml

LOGGER = logging.getLogger(__name__)


def env_var_is_filled(variable):
    if os.environ.get(variable) is None:
        print("Error: " + variable + " environment variable is None")
        return False
    return True


def generate_db_config(type_, schema_, settings):
    """
    Generate database connection configuration.

    :param type_: the type of database to connect to
    :type type_: oracle | postgres
    :param schema_: the schema or user to connect to
    :type schema_: str
    :param settings: a settings configuration
    :type settings: _type_
    :return: _description_
    :rtype: _type_
    """
    dbconfig = {}
    ssl_required = settings["ssl_required"]
    version_column = settings["version_column"]
    max_rows_upsert = settings["max_rows_upsert"]
    if type_ == "ORACLE":
        dbconfig = {
            "type": "ORACLE",
            "username": os.environ.get("ORACLE_SYNC_USER"),
            "password": os.environ.get("ORACLE_SYNC_PASSWORD"),
            "host": os.environ.get("ORACLE_HOST"),
            "port": os.environ.get("ORACLE_PORT"),
            "service_name": os.environ.get("ORACLE_SERVICE"),
            "schema": schema_,
            "test_query": "SELECT 'SUCCESS' a FROM DUAL",
            "ssl_required": ssl_required,  # do we really need this?  can't we infer if the port is 1521 or 2484?
            "version_column": version_column,
            "max_rows_upsert": max_rows_upsert,
        }
    if type_ == "POSTGRES":
        dbconfig = {
            "type": "POSTGRES",
            "username": os.environ.get("POSTGRES_USER"),
            "password": os.environ.get("POSTGRES_PASSWORD"),
            "host": os.environ.get("POSTGRES_HOST"),
            "database": os.environ.get("POSTGRES_DB"),
            "port": os.environ.get("POSTGRES_PORT"),
            "schema": schema_,
            "test_query": "SELECT 'SUCCESS' a",
            "ssl_required": ssl_required,
            "version_column": version_column,
            "max_rows_upsert": max_rows_upsert,
        }
    return dbconfig


def get_build_number():
    return os.environ.get("BUILD_NUMBER")


def required_variables_exists():
    ret = True

    print("-------------------------------------")
    print("----- ETL Tool: Unit test Execution  ")
    print("----- 1. Checking if required variables are defined")
    print("-------------------------------------")

    if (
        not env_var_is_filled("TEST_MODE")
        or not env_var_is_filled("EXECUTION_ID")
        or not env_var_is_filled("POSTGRES_HOST")
        or not env_var_is_filled("POSTGRES_PORT")
        or not env_var_is_filled("POSTGRES_USER")
        or not env_var_is_filled("POSTGRES_PASSWORD")
        or not env_var_is_filled("POSTGRES_DB")
        or not env_var_is_filled("ORACLE_PORT")
        or not env_var_is_filled("ORACLE_HOST")
        or not env_var_is_filled("ORACLE_SERVICE")
        or not env_var_is_filled("ORACLE_SYNC_USER")
        or not env_var_is_filled("ORACLE_SYNC_PASSWORD")
    ):
        ret = False

    if ret:
        print("Required variable tests passed!")
    else:
        raise Exception(
            "Not all required variables to execute a instance of Data Sync Engine exists."
        )


def testOracleConnection(settings):
    print("-------------------------------------")
    print("-- 3. Checking if Oracle connection is available and reachable")
    print("-------------------------------------")
    from module.test_db_connection import test_db_connection

    dbConfig = generate_db_config("ORACLE", "THE", settings)
    d = test_db_connection.do_test(dbConfig)
    print(d)


def testPostgresConnection(settings):
    print("-------------------------------------")
    print("-- 2. Checking if Postgres connection is available and reachable")
    print("-------------------------------------")
    from module.test_db_connection import test_db_connection

    dbConfig = generate_db_config("POSTGRES", "spar", settings)
    d = test_db_connection.do_test(dbConfig)
    print(d)


def read_settings():
    file = os.path.join(
        os.path.abspath(os.path.dirname(__file__)), "settings.yml"
    )
    try:
        with open(file, "r") as stream:
            data_loaded = yaml.safe_load(stream)
            if (
                data_loaded["postgres"]["max_rows_upsert"]
                or data_loaded["postgres"]["version_column"]
                or data_loaded["oracle"]["max_rows_upsert"]
                or data_loaded["oracle"]["version_column"]
                or data_loaded["postgres"]["ssl_version"]
                or data_loaded["oracle"]["ssl_version"]
            ):
                return data_loaded
    except FileNotFoundError:
        print("Error: settings.yml not found")
    except KeyError:
        print(
            "Error: settings.yml is not well formated or does not have required settings"
        )
    except Exception as err:
        print(
            f"A fatal error has occurred when trying to load settings.yml ({type(err)}): {err}"
        )


def main() -> int:
    """
    Run main method that triggers the ETL process.

    If no errors encountered, it will return 0, otherwise 1

    :return: status of the run, 0 if successful, 1 if failed
    :rtype: int
    """
    try:
        definition_of_yes = ["Y", "YES", "1", "T", "TRUE", "t", "true"]
        job_return_code = 0

        build_number = get_build_number()
        print("<------------------ b.u.i.l.d  n.u.m.b.e.r ----------------->")
        print(f"Running Sync BUILD NUMBER: {build_number}")
        print("<------------------ b.u.i.l.d  n.u.m.b.e.r ----------------->")

        # print(os.environ.get("TEST_MODE"))
        if os.environ.get("TEST_MODE") is None:
            print("Error: test mode variable is None")
        elif os.environ.get("EXECUTION_ID") is None:
            print(
                "Error: EXECUTION_ID is None, no execution defined to be executed in this run."
            )
        else:
            this_is_a_test = os.environ.get("TEST_MODE")
            settings = read_settings()
            print("<------------------ settings ----------------->")
            print(settings)
            print("<------------------ settings ----------------->")
            if this_is_a_test in definition_of_yes:
                print("Executing in Test mode")
                required_variables_exists()
                testPostgresConnection(settings["postgres"])
                testOracleConnection(settings["oracle"])
                # Vault disabled
                # testVault()
            else:
                print("-------------------------------------")
                print("Starting ETL main process ")
                print("-------------------------------------")
                # think should test db here also
                dbOracle = generate_db_config(
                    "ORACLE", "THE", settings["oracle"]
                )
                dbPostgres = generate_db_config(
                    "POSTGRES", "spar", settings["postgres"]
                )

                job_return_code = execute_etl(dbPostgres, dbOracle)

                print("-------------------------------------")
                print("ETL Main process finished ")
                print("-------------------------------------")
        return job_return_code

    except Exception as err:
        print(f"A fatal error has occurred ({type(err)}): {err}")
        return 1  # failure


def config_logging():
    log_file = pathlib.Path(__file__).parent / "logging.config"
    logging.config.fileConfig(log_file, disable_existing_loggers=False)


# MAIN Execution
def execute_etl(dbPostgres, dbOracle):
    config_logging()
    return data_sync.execute_instance(
        oracle_config=dbOracle,
        postgres_config=dbPostgres,
        track_config=dbPostgres,
    )


if __name__ == "__main__":
    sys.exit(main())
