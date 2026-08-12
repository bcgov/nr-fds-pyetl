"""Regression tests for the SEEDLOT_OWNER_QUANTITY ownership lock.

`the.seedlot_owner_quantity` must not be written for a seedlot whose
`THE.SEEDLOT.ORIGINAL_SEED_QTY` is greater than zero: once a balance exists,
ownership is owned by legacy SPAR and the ETL has to leave it alone.

The interesting case is a batch that *mixes* locked and unlocked seedlots. A
batch of only-locked or only-unlocked seedlots cannot tell whether the lock is
enforced per seedlot or merely happens to hold for the whole run.
"""

from contextlib import contextmanager

import module.data_synchronization as data_sync
import pandas as pd
import pytest

OWNERSHIP_TABLE = "the.seedlot_owner_quantity"

SCHEDULE_TIMES = {
    "current_start_time": "2026-01-01 00:00:00",
    "current_end_time": "2026-01-01 02:00:00",
}
TRACK_CONFIG = {"schema": "spar_etl"}


class FakeResult:
    """Stands in for the driver result of the ORIGINAL_SEED_QTY lookup."""

    def __init__(self, row):
        self._row = row

    def fetchone(self):
        return self._row


class FakeTargetConnection:
    """Oracle side: answers the ORIGINAL_SEED_QTY lookup from a lookup table."""

    def __init__(self, original_seed_qty_by_seedlot):
        self._quantities = original_seed_qty_by_seedlot

    def execute(self, query, params=None):
        return FakeResult((self._quantities[params["seedlot_number"]],))

    def commit(self):
        pass


class FakeSourceConnection:
    """Postgres side: only its `engine` attribute is ever read."""

    engine = None


class RecordedRun:
    """What the ETL did, per seedlot, during one `process_seedlots` call."""

    def __init__(self):
        self.deleted_tables = {}
        self.executed_tables = {}

    def tables_written_for(self, seedlot_number):
        return self.executed_tables.get(seedlot_number, [])

    def tables_deleted_for(self, seedlot_number):
        return self.deleted_tables.get(seedlot_number, [])


@pytest.fixture
def run_etl(monkeypatch):
    """Run `process_seedlots` over a batch, recording the writes it performs.

    Everything that touches a database is replaced; the batch driver query, the
    child-table deletes and the per-process execution are recorded instead.
    """

    def _run(original_seed_qty_by_seedlot):
        seedlot_numbers = list(original_seed_qty_by_seedlot)
        recorded = RecordedRun()

        source_conn = FakeSourceConnection()
        target_conn = FakeTargetConnection(original_seed_qty_by_seedlot)

        @contextmanager
        def fake_database_connection(config):
            yield source_conn if config["type"] == "POSTGRES" else target_conn

        def fake_read_sql_query(sql, con, params):
            return pd.DataFrame({"seedlot_number": seedlot_numbers})

        def fake_delete_seedlot_child_tables(
            seedlot_number,
            track_db_conn,
            track_db_schema,
            target_db_conn,
            processes,
        ):
            recorded.deleted_tables[seedlot_number] = [
                process[0]["target_table"] for process in processes
            ]
            return {}

        def fake_execute_process(**kwargs):
            recorded.executed_tables.setdefault(
                kwargs["seedlot_number"], []
            ).append(kwargs["process"]["target_table"])
            return {}

        monkeypatch.setattr(
            data_sync.db_conn, "database_connection", fake_database_connection
        )
        monkeypatch.setattr(data_sync.pd, "read_sql_query", fake_read_sql_query)
        monkeypatch.setattr(
            data_sync,
            "delete_seedlot_child_tables",
            fake_delete_seedlot_child_tables,
        )
        monkeypatch.setattr(data_sync, "execute_process", fake_execute_process)
        monkeypatch.setattr(
            data_sync.data_sync_ctl,
            "save_execution_log",
            lambda *args, **kwargs: None,
        )

        data_sync.process_seedlots(
            oracle_config={"type": "ORACLE"},
            postgres_config={"type": "POSTGRES"},
            track_config=TRACK_CONFIG,
            track_db_conn=None,
            schedule_times=SCHEDULE_TIMES,
        )
        return recorded

    return _run


def test_locked_seedlot_is_not_written_after_an_unlocked_one(run_etl):
    """The ordering that leaks: an unlocked seedlot processed first.

    64208 was overwritten in production exactly this way -- it followed three
    seedlots that legitimately needed the ownership sync.
    """
    recorded = run_etl({"64205": 0, "64208": 4183})

    assert OWNERSHIP_TABLE in recorded.tables_written_for("64205")
    assert OWNERSHIP_TABLE not in recorded.tables_written_for("64208")
    assert OWNERSHIP_TABLE not in recorded.tables_deleted_for("64208")


def test_lock_holds_for_every_locked_seedlot_in_a_mixed_batch(run_etl):
    """Position in the batch must not decide whether the lock is honoured."""
    recorded = run_etl(
        {"64120": None, "64158": 0, "64205": 0, "64208": 4183, "64209": 8211}
    )

    for seedlot_number in ("64208", "64209"):
        assert OWNERSHIP_TABLE not in recorded.tables_written_for(
            seedlot_number
        )
        assert OWNERSHIP_TABLE not in recorded.tables_deleted_for(
            seedlot_number
        )


def test_unlocked_seedlot_is_written_exactly_once(run_etl):
    """No amplification: the Nth unlocked seedlot is synced once, not N times."""
    recorded = run_etl({"64257": 0, "64258": 0, "64259": None})

    for seedlot_number in ("64257", "64258", "64259"):
        written = recorded.tables_written_for(seedlot_number)
        assert written.count(OWNERSHIP_TABLE) == 1
