"""Copy orchestration.

Reads the ordered table manifest, runs one Oracle ``SELECT`` per target
Postgres table (all transformations live in the Oracle SQL), and performs a
straight ``INSERT`` into Postgres. The whole operation runs inside a single
Postgres transaction: any failure rolls the entire copy back.
"""

from __future__ import annotations

import json
import logging
import os

LOGGER = logging.getLogger("copy.copier")

_CONFIG_DIR = os.path.join(os.path.dirname(__file__), "config")
_QUERIES_DIR = os.path.join(_CONFIG_DIR, "queries")
_MANIFEST = os.path.join(_CONFIG_DIR, "manifest.json")


class SeedlotExistsError(RuntimeError):
    """Raised when the seedlot already exists in Postgres and overwrite is off."""


def load_manifest() -> list[dict]:
    """Return the ordered list of tables to copy (parent first)."""
    with open(_MANIFEST, encoding="utf-8") as handle:
        return json.load(handle)["tables"]


def _read_query(file_name: str) -> str:
    with open(os.path.join(_QUERIES_DIR, file_name), encoding="utf-8") as handle:
        return handle.read()


def _find_existing(pg_cursor, tables: list[dict], seedlot_number: str) -> list[str]:
    """Return the target tables that already hold rows for this seedlot."""
    existing = []
    for table in tables:
        pg_cursor.execute(
            f"SELECT 1 FROM {table['target_table']} "
            "WHERE seedlot_number = %s LIMIT 1",
            (seedlot_number,),
        )
        if pg_cursor.fetchone() is not None:
            existing.append(table["target_table"])
    return existing


def _delete_existing(pg_cursor, tables: list[dict], seedlot_number: str) -> None:
    """Delete the seedlot from every target table in reverse (child-first) order."""
    for table in reversed(tables):
        LOGGER.info("Deleting existing rows from %s", table["target_table"])
        pg_cursor.execute(
            f"DELETE FROM {table['target_table']} WHERE seedlot_number = %s",
            (seedlot_number,),
        )


def _copy_table(ora_cursor, pg_cursor, table: dict, seedlot_number: str) -> int:
    """Run the Oracle query for one table and insert the results into Postgres."""
    query = _read_query(table["query"])
    ora_cursor.execute(query, {"seedlot_number": seedlot_number})
    rows = ora_cursor.fetchall()

    if not rows:
        LOGGER.info("  %s: no source rows", table["target_table"])
        return 0

    # The Oracle SELECT aliases every output column to its Postgres name, so we
    # can build the INSERT column list straight from the cursor description.
    columns = [desc[0].lower() for desc in ora_cursor.description]
    column_list = ", ".join(columns)
    placeholders = ", ".join(["%s"] * len(columns))
    insert_sql = (
        f"INSERT INTO {table['target_table']} ({column_list}) "
        f"VALUES ({placeholders})"
    )
    pg_cursor.executemany(insert_sql, rows)
    LOGGER.info("  %s: inserted %d row(s)", table["target_table"], len(rows))
    return len(rows)


def copy_seedlot(
    ora_conn,
    pg_conn,
    seedlot_number: str,
    overwrite: bool = False,
) -> dict[str, int]:
    """Copy one seedlot and all child tables from Oracle to Postgres.

    Args:
        ora_conn: Open Oracle connection (source).
        pg_conn: Open Postgres connection (target).
        seedlot_number: The seedlot to copy.
        overwrite: If True, delete existing target rows first. If False and the
            seedlot already exists in Postgres, ``SeedlotExistsError`` is raised.

    Returns:
        Mapping of target table name to number of rows inserted.
    """
    tables = load_manifest()
    ora_cursor = ora_conn.cursor()
    pg_cursor = pg_conn.cursor()
    counts: dict[str, int] = {}

    try:
        existing = _find_existing(pg_cursor, tables, seedlot_number)
        if existing and not overwrite:
            raise SeedlotExistsError(
                f"Seedlot {seedlot_number} already exists in Postgres "
                f"(found rows in: {', '.join(existing)}). "
                "Re-run with --overwrite to delete and replace it."
            )

        if overwrite and existing:
            _delete_existing(pg_cursor, tables, seedlot_number)

        for table in tables:
            counts[table["target_table"]] = _copy_table(
                ora_cursor, pg_cursor, table, seedlot_number
            )

        pg_conn.commit()
        LOGGER.info("Committed copy of seedlot %s", seedlot_number)
    except Exception:
        pg_conn.rollback()
        LOGGER.error("Copy failed - rolled back Postgres transaction")
        raise
    finally:
        ora_cursor.close()
        pg_cursor.close()

    return counts
