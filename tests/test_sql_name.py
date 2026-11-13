# -*- coding: utf-8 -*-
"""Column-catalog selection for bulk_copy table names. No SQL Server required."""

import importlib.util
from pathlib import Path

import pytest

# Load the helper from source so this test does not import the compiled extension.
_PATH = Path(__file__).resolve().parents[1] / "src" / "pymssql" / "_sql_name.py"
_spec = importlib.util.spec_from_file_location("pymssql_sql_name", _PATH)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
bulk_copy_column_source = _mod.bulk_copy_column_source

_TEMPDB = "tempdb.sys.columns"
_CURRENT = "sys.columns"


@pytest.mark.parametrize(
    "table_name, columns_view, lookup_name",
    [
        ("#t", _TEMPDB, "tempdb..#t"),
        ("##t", _TEMPDB, "tempdb..##t"),
        ("[#t]", _TEMPDB, "tempdb..[#t]"),
        ("[##t]", _TEMPDB, "tempdb..[##t]"),
        ("[#my table]", _TEMPDB, "tempdb..[#my table]"),
        ('"#t"', _TEMPDB, 'tempdb.."#t"'),
        ('"##t"', _TEMPDB, 'tempdb.."##t"'),
        ("dbo.#t", _TEMPDB, "tempdb.dbo.#t"),
        ("DBO.##t", _TEMPDB, "tempdb.DBO.##t"),
        ("[dbo].[#t]", _TEMPDB, "tempdb.[dbo].[#t]"),
        ('"dbo"."#t"', _TEMPDB, 'tempdb."dbo"."#t"'),
        ('dbo."##t"', _TEMPDB, 'tempdb.dbo."##t"'),
        ('"sales".[#t]', _TEMPDB, 'tempdb."sales".[#t]'),
        ("[#a]]b]", _TEMPDB, "tempdb..[#a]]b]"),
        ('"#t.x"', _TEMPDB, 'tempdb.."#t.x"'),
        ("tempdb..#t", _TEMPDB, "tempdb..#t"),
        ("tempdb.dbo.#t", _TEMPDB, "tempdb.dbo.#t"),
        ("[tempdb]..[#t]", _TEMPDB, "[tempdb]..[#t]"),
        ('"tempdb".."#t"', _TEMPDB, '"tempdb".."#t"'),
        ("TempDB.dbo.#t", _TEMPDB, "TempDB.dbo.#t"),
        ("other.dbo.#t", _TEMPDB, "tempdb.dbo.#t"),
        ("other..#t", _TEMPDB, "tempdb..#t"),
        ("srv.tempdb.dbo.#t", _TEMPDB, "srv.tempdb.dbo.#t"),
        ("srv.other.dbo.#t", _TEMPDB, "srv.tempdb.dbo.#t"),
        ("orders", _CURRENT, "orders"),
        ("dbo.orders", _CURRENT, "dbo.orders"),
        ('"orders"', _CURRENT, '"orders"'),
        ('"dbo"."orders"', _CURRENT, '"dbo"."orders"'),
        ("[dbo].[orders]", _CURRENT, "[dbo].[orders]"),
        ("tempdb.dbo.orders", _TEMPDB, "tempdb.dbo.orders"),
        ("[tempdb].[dbo].[orders]", _TEMPDB, "[tempdb].[dbo].[orders]"),
        ("tempdb..orders", _TEMPDB, "tempdb..orders"),
    ],
)
def test_bulk_copy_column_source(table_name, columns_view, lookup_name):
    assert bulk_copy_column_source(table_name) == (columns_view, lookup_name)
