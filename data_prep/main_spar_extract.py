import base64
import logging
import os
import pathlib
import sys
import time

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
    common_util = main_common.Utility(env_str)
    common_util.configure_logging()
    logger_name = pathlib.Path(__file__).stem
    LOGGER = logging.getLogger(logger_name)

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
        db_secret.data["database-port"]
    ).decode("utf-8")
    db_conn_params.service_name = base64.b64decode(
        db_secret.data["database-name"]
    ).decode("utf-8")
    db_conn_params.username = base64.b64decode(
        db_secret.data["database-user"]
    ).decode("utf-8")
    db_conn_params.password = base64.b64decode(
        db_secret.data["database-password"]
    ).decode("utf-8")

    # create the tunnel
    pf = kubernetes_client.open_port_forward(
        pod_name=db_pod.metadata.name,
        namespace=oc_params.namespace,
        local_port=db_conn_params.port,
        remote_port=db_conn_params.port,
    )
    conn = None
    retry = 0
    while conn is None and retry < 4:
        try:
            conn = psycopg2.connect(
                user=db_conn_params.username,
                password=db_conn_params.password,
                host=db_conn_params.host,
                port=db_conn_params.port,
                database=db_conn_params.service_name,
            )
        except psycopg2.OperationalError as e:
            LOGGER.error("connection failed: %s", e)
            conn = None
            time.sleep(1)
            retry += 1

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
