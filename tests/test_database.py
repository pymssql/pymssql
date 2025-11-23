# -*- coding: utf-8 -*-
"""
Test switching and printing the current database.
"""

import pytest
from pymssql import _mssql

from .helpers import config

@pytest.mark.mssql_server_required
@pytest.mark.parametrize("db", [
    config.database,
    'master',
    'tempdb',
    'msdb',
    'model',
])
def test_connect_cur_db_name(db):
    conn = _mssql.connect(
        server = config.server,
        port = config.port,
        user = config.user,
        password = config.password,
        database = db,
    )
    connDBName = conn.execute_scalar("SELECT DB_NAME() AS myDB")
    assert db == connDBName
    assert conn.cur_db_name() == connDBName
    conn.close()

@pytest.mark.mssql_server_required
def test_select_db():
    conn = _mssql.connect(
        server = config.server,
        port = config.port,
        user = config.user,
        password = config.password,
        database = config.database,
    )
    for db in ['master', 'model', 'msdb', 'tempdb']:
        conn.select_db(db)
        connDBName = conn.execute_scalar("SELECT DB_NAME() AS myDB")
        assert connDBName == db
        assert conn.cur_db_name() == db
    conn.close()
