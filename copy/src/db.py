"""Thin database connection helpers for the seedlot copy utility.

Two standalone connections are created from environment variables:

* Oracle  (source, ``THE`` schema)  -> python-oracledb
* Postgres (target, ``spar`` schema) -> psycopg2

No SQLAlchemy / pandas layer is used - the copy is a straight
Oracle ``SELECT`` followed by a Postgres ``INSERT``.
"""

from __future__ import annotations

import logging
import os
import ssl

import oracledb
import psycopg2

LOGGER = logging.getLogger("copy.db")

# Values that are interpreted as "true" for boolean-ish env vars.
TRUTHY = {"Y", "YES", "1", "T", "TRUE"}

# Return CLOB/large text columns as plain ``str`` instead of LOB objects, and
# keep numbers as float/int so they insert cleanly into Postgres.
oracledb.defaults.fetch_lobs = False


class MissingConfigError(RuntimeError):
    """Raised when a required environment variable is not set."""


def _require(name: str) -> str:
    value = os.environ.get(name)
    if value is None or value == "":
        raise MissingConfigError(
            f"Required environment variable {name} is not set"
        )
    return value


def connect_oracle() -> oracledb.Connection:
    """Open a connection to the source Oracle database (THE schema)."""
    user = _require("ORACLE_SYNC_USER")
    password = _require("ORACLE_SYNC_PASSWORD")
    host = _require("ORACLE_HOST")
    port = _require("ORACLE_PORT")
    service = _require("ORACLE_SERVICE")

    non_encrypt = (
        os.environ.get("ORA_NON_ENCRYPT_LISTENER", "false").strip().upper()
        in TRUTHY
    )
    protocol = "TCP" if non_encrypt else "TCPS"
    dsn = (
        f"(DESCRIPTION=(ADDRESS=(PROTOCOL={protocol})"
        f"(HOST={host})(PORT={port}))"
        f"(CONNECT_DATA=(SERVICE_NAME={service})))"
    )

    connect_args: dict = {"user": user, "password": password, "dsn": dsn}
    if not non_encrypt:
        # Match the relaxed cipher/security level used by the sync tool so the
        # same on-prem TLS listener is reachable.
        ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
        ssl_context.set_ciphers("DEFAULT@SECLEVEL=1")
        connect_args["ssl_context"] = ssl_context

    LOGGER.info("Connecting to Oracle %s:%s/%s", host, port, service)
    return oracledb.connect(**connect_args)


def connect_postgres() -> "psycopg2.extensions.connection":
    """Open a connection to the target Postgres database (spar schema)."""
    host = _require("POSTGRES_HOST")
    port = _require("POSTGRES_PORT")
    dbname = _require("POSTGRES_DB")
    user = _require("POSTGRES_USER")
    password = _require("POSTGRES_PASSWORD")
    sslmode = os.environ.get("POSTGRES_SSLMODE", "prefer")

    LOGGER.info("Connecting to Postgres %s:%s/%s", host, port, dbname)
    return psycopg2.connect(
        host=host,
        port=port,
        dbname=dbname,
        user=user,
        password=password,
        sslmode=sslmode,
    )
