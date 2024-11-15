"""
Utility code to configure ingest and extract scripts.
"""

from __future__ import annotations

import base64
import logging
import logging.config
import pathlib
import socket
import time

import constants
import docker_parser
import env_config
import kubernetes_wrapper
import object_store
import oradb_lib
import postgresdb_lib

LOGGER = logging.getLogger(__name__)


class Utility:
    """
    Utility class to run the extract and injest processes.
    """

    def __init__(self, env_str: str, db: constants.DBType) -> None:
        """
        Initialize the Utility class.
        """
        self.env_str = env_str
        self.env_obj = env_config.Env(env_str)
        self.curdir = pathlib.Path(__file__).parents[0]
        self.datadir = pathlib.Path(
            self.curdir,
            constants.DATA_DIR,
            self.env_str,
            db.name.lower(),
        )
        self.db_type = db
        self.kube_client = None

    def make_dirs(self) -> None:
        """
        Make necessary directories.

        Directories that need to be created are dependent on the database
        environment (TEST or PROD)
        """
        LOGGER.debug("datadir: %s", self.datadir)
        if not self.datadir.exists():
            self.datadir.mkdir(parents=True)
        env_path = pathlib.Path(self.datadir, self.env_obj.env)
        if not env_path.exists():
            env_path.mkdir()

    def configure_logging(self) -> None:
        """
        Configure logging.
        """
        log_config_path = pathlib.Path(self.curdir, "logging.config")
        logging.config.fileConfig(
            log_config_path,
            disable_existing_loggers=False,
        )
        global LOGGER  # noqa: PLW0603
        LOGGER = logging.getLogger(__name__)
        LOGGER.debug("test debug message")

    def connect_ostore(self) -> object_store.OStore:
        """
        Connect to object store.
        """
        ostore_params = self.env_obj.get_ostore_constants()
        return object_store.OStore(conn_params=ostore_params)

    def get_db_connection_params(self):
        """
        Get database connection object.

        Determines what the database type is and uses different methods to
        retrieve database connecti
        """
        # TODO: populate this, use this as fork for different db types

    def get_tables(self) -> list[str]:
        tables = []
        if self.db_type == constants.DBType.ORA:
            tables = self.get_tables_from_local_ora_docker()
        elif self.db_type == constants.DBType.SPAR:
            tables = self.get_tables_from_local_spar_docker()
            # tables = self.get_tables_from_spar()
        return tables

    def get_tables_from_spar(self):
        oc_params = self.env_obj.get_oc_constants()

        db_pod = self.get_kubnernetes_db_pod()
        db_params = self.get_dbparams_from_kubernetes()
        self.open_port_forward_sync(
            db_pod.metadata.name,
            oc_params.namespace,
            constants.DB_LOCAL_PORT,
            db_params.port,
        )

        # now get the actual tables
        spar_db_params = self.get_dbparams_from_kubernetes()
        # swap the connection port to the local port configured for the
        # tunnel
        spar_db_params.port = constants.DB_LOCAL_PORT
        db_connection = postgresdb_lib.PostgresDatabase(
            connection_params=spar_db_params,
        )
        tables_to_export = db_connection.get_tables(
            schema=spar_db_params.schema_to_sync,
            omit_tables=["FLYWAY_SCHEMA_HISTORY"],
        )
        return tables_to_export

    def get_tables_from_local_spar_docker(self) -> list[str]:
        """
        Get a list of table from local spar docker database.

        :return: list of tables found in the local spar database schema
        :rtype: list[str]
        """
        dcr = docker_parser.ReadDockerCompose()
        spar_params = dcr.get_spar_conn_params()
        # TODO: ideally get the schema from where it is defined, but its in migrations which makes it tricky... could put into config
        spar_params.schema_to_sync = "spar"
        LOGGER.debug("schema to sync: %s", spar_params.schema_to_sync)
        local_docker_db = postgresdb_lib.PostgresDatabase(spar_params)
        tables_to_export = local_docker_db.get_tables(
            local_docker_db.schema_2_sync,
            omit_tables=["FLYWAY_SCHEMA_HISTORY"],
        )
        LOGGER.debug("tables retrieved: %s", tables_to_export)
        return tables_to_export

    # TODO: need to come back to this and link to the extract process
    def get_tables_from_local_ora_docker(self) -> list[str]:
        """
        Get list of tables from local oracle docker database.
        """
        dcr = docker_parser.ReadDockerCompose()
        local_ora_params = dcr.get_ora_conn_params()
        local_ora_params.schema_to_sync = self.env_obj.get_schema_to_sync()
        LOGGER.debug("schema to sync: %s", local_ora_params.schema_to_sync)
        local_docker_db = oradb_lib.OracleDatabase(local_ora_params)
        tables_to_export = local_docker_db.get_tables(
            local_docker_db.schema_2_sync,
            omit_tables=["FLYWAY_SCHEMA_HISTORY"],
        )
        LOGGER.debug("tables retrieved: %s", tables_to_export)
        return tables_to_export

    def get_kubernetes_client(self):
        """
        This method is called any time a method is called that requires the
        kube_client property
        """
        if self.kube_client == None:
            oc_params = self.env_obj.get_oc_constants()
            self.kube_client = kubernetes_wrapper.KubeClient(oc_params)

    def open_port_forward_sync(
        self,
        pod_name: str,
        namespace: str,
        local_port: str,
        remote_port: str,
    ) -> None:
        """
        Create port forward.

        opens a port-forward then waits until it has successfully been created,
        once the port-forward has completed and can be succesfully connected to
        the method will complete.

        :param pod_name: the name of the pod to establish the port-forward to
        :type pod_name: str
        :param namespace: the namespace that the pod is in
        :type namespace: str
        :param local_port: the local port for the port-forward
        :type local_port: str
        :param remote_port: the remote port for the port-forward
        :type remote_port: str
        """
        self.get_kubernetes_client()
        # oc_params = self.env_obj.get_oc_constants()
        # kubernetes_client = kubernetes_wrapper.KubeClient(oc_params)

        self.kube_client.open_port_forward(
            pod_name=pod_name,
            namespace=namespace,
            local_port=local_port,
            remote_port=remote_port,
        )
        sock_success = False
        retry = 0
        # test the connection
        while not sock_success or retry > 10:
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(2)
                sock.connect(("localhost", local_port))
                sock_success = True
            except OSError as e:  # noqa: PERF203
                LOGGER.exception("port forward not available...")
                time.sleep(1)
                retry += 1
            finally:
                # Close the socket
                sock.close()

    def get_kubnernetes_db_pod(self) -> str:
        self.get_kubernetes_client()

        # oc_params = self.env_obj.get_oc_constants()
        # kube_client = kubernetes_wrapper.KubeClient(oc_params)

        db_filter_string = constants.DB_FILTER_STRING.format(
            env_str=self.env_str.lower()
        )
        pods = self.kube_client.get_pods(
            filter_str=db_filter_string,
            exclude_strs=["backup"],
        )
        if len(pods) > 1:
            pod_names = ", ".join([pod.metadata.name for pod in pods])
            msg = (
                f"searching for pods that match the pattern {db_filter_string}"
                " returned more than one pod, narrow the search pattern so only"
                f" one pod is returned.  pods currently matched: {pod_names}"
            )
            LOGGER.exception(msg)
            raise IndexError(msg)
        elif len(pods) == 0:
            msg = (
                f"searching for pods that match the pattern {db_filter_string}"
                "didn't return any pods"
            )
        return pods[0]

    def get_dbparams_from_kubernetes(self) -> env_config.ConnectionParameters:
        oc_params = self.env_obj.get_oc_constants()

        db_filter_string = constants.DB_FILTER_STRING.format(
            env_str=self.env_str.lower(),
        )
        self.get_kubernetes_client()
        secrets = self.kube_client.get_secrets(
            namespace=oc_params.namespace,
            filter_str=db_filter_string,
        )
        if len(secrets) > 1:
            secret_names = ", ".join(
                [secret.metadata.name for secret in secrets],
            )
            msg = (
                "searching for secrets that match the pattern "
                f"{db_filter_string} returned more than one pod, narrow the "
                "search pattern so only one pod is returned.  pods currently "
                f" matched: {secret_names}"
            )
            LOGGER.exception(msg)
            raise IndexError(msg)
        db_secret = secrets[0]
        db_conn_params = env_config.ConnectionParameters
        db_conn_params.host = "localhost"
        db_conn_params.schema_to_sync = "spar"
        db_conn_params.port = base64.b64decode(
            db_secret.data["database-port"],
        ).decode("utf-8")
        db_conn_params.service_name = base64.b64decode(
            db_secret.data["database-name"],
        ).decode("utf-8")
        db_conn_params.username = base64.b64decode(
            db_secret.data["database-user"],
        ).decode("utf-8")
        db_conn_params.password = base64.b64decode(
            db_secret.data["database-password"],
        ).decode("utf-8")
        return db_conn_params

    def run_extract(self) -> None:
        """
        Run the extract process.
        """
        self.make_dirs()
        # gets the table list from openshift database
        tables_to_export = self.get_tables_from_spar()
        LOGGER.debug("tables to export: %s", tables_to_export)

        # tables_to_export = self.get_tables_from_local_docker()
        ostore = self.connect_ostore()

        if self.db_type == constants.DBType.ORA:
            # if oracle then do these things...
            ora_params = self.env_obj.get_ora_db_env_constants()
            db_connection = oradb_lib.OracleDatabase(
                ora_params,
            )  # use the environment variables for connection parameters
            db_connection.get_connection()
        elif self.db_type == constants.DBType.SPAR:
            spar_db_params = self.get_dbparams_from_kubernetes()
            # using port forward so override the port to the local port that
            # is forwarded to the remote port
            spar_db_params.port = constants.DB_LOCAL_PORT
            db_connection = postgresdb_lib.PostgresDatabase(
                connection_params=spar_db_params,
            )

        # raise NotImplementedError("This method is not implemented yet")

        for table in tables_to_export:
            LOGGER.info("Exporting table %s", table)
            # the export file type is different depending on the database.
            # originally wanted to keep to parquet, but loading the json data
            # used by spar doesn't work well with postgres.  So using pg_dump.
            export_file = constants.get_default_export_file_path(
                table,
                self.env_obj.current_env,
                self.db_type,
            )

            LOGGER.debug("export_file: %s", export_file)
            file_created = db_connection.extract_data(table, export_file)

            if file_created:
                # push the file to object store, if a new file has been created
                ostore.put_data_files(
                    [table], self.env_obj.current_env, self.db_type
                )

    def run_injest(self) -> None:
        """
        Run the injest process.
        """
        self.make_dirs()
        tables_to_import = self.get_tables()
        LOGGER.debug("tables to import: %s", tables_to_import)

        ostore = self.connect_ostore()
        dcr = docker_parser.ReadDockerCompose()

        if self.db_type == constants.DBType.ORA:

            local_db_params = dcr.get_ora_conn_params()

            local_db_params.schema_to_sync = self.env_obj.get_schema_to_sync()
            local_docker_db = oradb_lib.OracleDatabase(local_db_params)

        elif self.db_type == constants.DBType.SPAR:
            local_db_params = dcr.get_spar_conn_params()
            local_docker_db = postgresdb_lib.PostgresDatabase(local_db_params)

        ostore.get_data_files(
            tables_to_import,
            self.env_obj.current_env,
            self.db_type,
        )

        local_docker_db.purge_data(table_list=tables_to_import, cascade=True)

        local_docker_db.load_data_retry(
            data_dir=self.datadir,
            table_list=tables_to_import,
            env_str=self.env_obj.current_env,
            purge=False,
        )
