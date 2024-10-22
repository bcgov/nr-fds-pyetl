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
    util = main_common.Utility(env_str, db_type)
    util.run_extract()
    sys.exit()

    # query kubernetes to get parameters necessary to build the tunnel
    # to create the tunnel need to know:
    # 1. the pod name
    # 2. the namespace
    # 3. the port

    # then later to connect to the database need to know:
    # 1. the username
    # 2. the password
    # 3. the database name
    oc_params = env_obj.get_oc_constants()
    kubernetes_client = kubernetes_wrapper.KubeClient(oc_params)
    # this is the string pattern to use to extract the pod name from all the
    # pods in the namespace
    db_filter_string = f"nr-spar-{env_str.lower()}-database"
    pods = kubernetes_client.get_pods(
        filter_str=db_filter_string, exclude_strs=["backup"]
    )
    if len(pods) > 1:
        LOGGER.error(
            "Need to narrow the search pattern as there were more than 1 pod returned"
        )
        sys.exit(1)

    LOGGER.debug("number of returned pods: %s", len(pods))
    db_pod = pods[0]

    # get the database parameters
    # db_pod.metadata.name
    secrets = kubernetes_client.get_secrets(
        namespace=oc_params.namespace, filter_str=db_filter_string
    )
    if len(secrets) > 1:
        LOGGER.error(
            "Need to narrow the search pattern as there were more than 1 secret returned"
        )
        sys.exit(1)

    db_secret = secrets[0]
    db_conn_params = env_config.ConnectionParameters
    db_conn_params.host = "localhost"
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

    # create the tunnel
    pf = kubernetes_client.open_port_forward(
        pod_name=db_pod.metadata.name,
        namespace=oc_params.namespace,
        local_port=db_conn_params.port,
        remote_port=db_conn_params.port,
    )
    # The tunnel can take a few seconds to establish, so adding
    # a sleep to allow the tunnel to be established
    # time.sleep(0.5)
    conn = None
    retry = 0
    sock_success = False
    while not sock_success or retry > 10:
        try:
            # conn = psycopg2.connect(
            #     user=db_conn_params.username,
            #     password=db_conn_params.password,
            #     host=db_conn_params.host,
            #     port=db_conn_params.port,
            #     database=db_conn_params.service_name,
            # )
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(2)
            sock.connect(("localhost", 5432))
            sock_success = True

        except OSError as e:
            # LOGGER.exception("connection failed: %s", e)
            LOGGER.exception("port forward not available...")
            conn = None
            time.sleep(1)
            retry += 1
            sock_success = False
        finally:
            # Close the socket
            sock.close()

    # connect to the database
    conn = psycopg2.connect(
        user=db_conn_params.username,
        password=db_conn_params.password,
        host=db_conn_params.host,
        port=db_conn_params.port,
        database=db_conn_params.service_name,
    )
    cur = conn.cursor()
    table_query = """
        SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'spar'    """
    cur.execute(table_query)
    tables = cur.fetchall()
    for table in tables:
        LOGGER.info("table: %s", table)

    # finally close the tunnel
    # todo: put in a with clause and close the tunnel automatically when with is
    # completed
    kubernetes_client.close_port_forward()
