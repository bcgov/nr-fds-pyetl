"""Connection retry behaviour for `database_connection`.

A refused connection (e.g. an Oracle listener restart) used to fail the
whole ETL run in under a second, because the job runs with backoffLimit 0.
"""

import pytest
from sqlalchemy.exc import OperationalError

import module.database_connection as db_conn

POSTGRES_CONFIG = {
    "type": "POSTGRES",
    "username": "user",
    "password": "pass",
    "host": "localhost",
    "port": "5432",
    "database": "db",
    "ssl_required": "N",
}


class FakeEngine:
    """Fails `connect()` the first `failures` times, then succeeds."""

    def __init__(self, failures):
        self.failures = failures
        self.calls = 0

    def connect(self):
        self.calls += 1
        if self.calls <= self.failures:
            raise OperationalError("SELECT 1", {}, Exception("refused"))
        return self

    def execution_options(self, **_kwargs):
        return "connected"


@pytest.fixture(autouse=True)
def no_sleep(monkeypatch):
    monkeypatch.setattr(db_conn.time, "sleep", lambda _seconds: None)


def make_connection(failures):
    connection = db_conn.database_connection(POSTGRES_CONFIG)
    connection.engine = FakeEngine(failures)
    return connection


def test_retries_until_the_connection_succeeds():
    connection = make_connection(failures=db_conn.CONNECT_ATTEMPTS - 1)

    assert connection.connect_with_retry() == "connected"
    assert connection.engine.calls == db_conn.CONNECT_ATTEMPTS


def test_succeeds_on_the_first_attempt_without_retrying():
    connection = make_connection(failures=0)

    assert connection.connect_with_retry() == "connected"
    assert connection.engine.calls == 1


def test_raises_once_the_attempts_are_exhausted():
    connection = make_connection(failures=db_conn.CONNECT_ATTEMPTS)

    with pytest.raises(OperationalError):
        connection.connect_with_retry()
    assert connection.engine.calls == db_conn.CONNECT_ATTEMPTS
