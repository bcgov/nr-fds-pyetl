"""Extraction dates must reach THE.SEEDLOT on update, without overwriting SPR09 (#132).

The ETL inserts the Oracle seedlot row when the seedlot is first synced, before
anyone has entered extraction dates. Every later sync is the DUP_VAL_ON_INDEX
update branch, so the dates have to be written there -- but only while the
Oracle columns are still blank, because TSC keys dates into SPR09 directly.
"""

import re

import pandas as pd
from module.database_connection import database_connection

IGNORE_ON_UPDATE = (
    "extraction_st_date,extraction_end_date,seed_store_client_number,seed_store_client_locn,"
    "temporary_storage_start_date,temporary_storage_end_date,seedlot_status_code,"
    "stored_cli_number,stored_cli_locn_cd,original_seed_qty,utm_easting,utm_northing,utm_zone,"
    "registered_seed_ind"
)


class RecordingConnection:
    def __init__(self):
        self.statements = []

    def execute(self, statement, params):
        self.statements.append((str(statement), params))

        class Result:
            rowcount = 1

        return Result()

    def commit(self):
        pass


def upsert_seedlot(row):
    db = database_connection.__new__(database_connection)
    db.conn = RecordingConnection()
    columns = {col: None for col in IGNORE_ON_UPDATE.split(",")}
    columns.update({"seedlot_number": "64267", "vegetation_code": "FDI"})
    columns.update(row)
    db.bulk_upsert_oracle(
        dataframe=pd.DataFrame([columns]),
        table_name="the.seedlot",
        table_pk="seedlot_number",
        run_mode="UPSERT",
        ignore_columns_on_update=IGNORE_ON_UPDATE,
    )
    return db.conn.statements[0]


def update_branch(sql):
    return sql.split("WHEN DUP_VAL_ON_INDEX THEN", 1)[1]


def test_update_fills_extraction_dates_only_when_blank():
    sql, params = upsert_seedlot(
        {"extraction_st_date": "2026-08-19", "extraction_end_date": "2026-09-15"}
    )
    update = update_branch(sql)

    assert re.search(
        r"extraction_st_date\s*=\s*NVL\(extraction_st_date,\s*:s_extraction_st_date\)", update
    )
    assert re.search(
        r"extraction_end_date\s*=\s*NVL\(extraction_end_date,\s*:s_extraction_end_date\)",
        update,
    )
    assert params["s_extraction_st_date"] == "2026-08-19"
    assert params["s_extraction_end_date"] == "2026-09-15"


def test_extraction_dates_are_not_overwritten_unconditionally():
    sql, _ = upsert_seedlot({"extraction_st_date": "2026-08-19"})
    update = update_branch(sql)

    # Only the NVL form may assign them; a plain "= :s_..." would clobber SPR09.
    assert not re.search(r"extraction_st_date\s*=\s*:s_extraction_st_date", update)
    assert not re.search(r"extraction_end_date\s*=\s*:s_extraction_end_date", update)


def test_insert_still_carries_extraction_dates():
    sql, params = upsert_seedlot({"extraction_st_date": "2026-08-19"})
    insert = sql.split("WHEN DUP_VAL_ON_INDEX THEN", 1)[0]

    assert "extraction_st_date" in insert
    assert params["extraction_st_date"] == "2026-08-19"
