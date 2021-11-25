# -*- coding: utf-8 -*-
"""
Test bulk copy.
"""

import unittest
import datetime

from pymssql import _mssql
from tests.helpers import drop_table, pymssqlconn, mssql_server_required


tablename = "pymssql"
simple_table = "CREATE TABLE %s (a1 INT, a2 INT, a3 INT)" % tablename
complex_table = """
    CREATE TABLE %s (
        pk_id int IDENTITY (1, 1) NOT NULL,
        uuid uniqueidentifier DEFAULT newsequentialid(),
        col_real real UNIQUE,
        col_float float,
        col_datetime datetime,
        col_bit bit,
        col_varchar varchar(50)
    )
""" % tablename


@mssql_server_required
class TestTypes(unittest.TestCase):
    def setUp(self):
        self.conn = pymssqlconn()
        drop_table(self.conn._conn, tablename)

    def tearDown(self):
        self.conn.close()

    def expect_simple_table_content(self, query, content):
        self.conn._conn.execute_query(query)
        assert [(row[0], row[1], row[2]) for row in self.conn._conn] == content

    def expect_row_count(self, expected_row_count):
        self.conn._conn.execute_query('select count(*) from pymssql')
        assert tuple(self.conn._conn)[0][0] == expected_row_count

    def simple_table_test(self, content, **kwargs):
        self.conn._conn.execute_non_query(simple_table)
        self.conn.bulk_copy(tablename, content, **kwargs)
        self.expect_simple_table_content('select * from pymssql', content)

    def test_simple_table_bulk_copy(self):
        self.simple_table_test([(1, 2, 3), (4, 5, 6)])

    def test_lots_of_rows_single_batch(self):
        self.conn._conn.execute_non_query(simple_table)
        self.conn.bulk_copy(tablename, [(1, 2, 3), (4, 5, 6)] * 100000, batch_size=1000000)
        self.expect_simple_table_content('select top 2 * from pymssql', [(1, 2, 3), (4, 5, 6)])
        self.expect_row_count(200000)

    def test_batches(self):
        self.conn._conn.execute_non_query(simple_table)

        self.conn.bulk_copy(tablename, [(1, 2, 3), (4, 5, 6)] * 100000, batch_size=1000)

        self.expect_simple_table_content('select top 2 * from pymssql', [(1, 2, 3), (4, 5, 6)])
        self.expect_row_count(200000)

    def test_exact_batch_size(self):
        self.conn._conn.execute_non_query(simple_table)

        self.conn.bulk_copy(tablename, [(1, 2, 3), (4, 5, 6)] * 500, batch_size=1000)

        self.expect_simple_table_content('select top 2 * from pymssql', [(1, 2, 3), (4, 5, 6)])
        self.expect_row_count(1000)

    def test_tablock_hint(self):
        self.simple_table_test([(1, 2, 3), (4, 5, 6)], tablock=True)

    def test_check_constraints_hint(self):
        self.simple_table_test([(1, 2, 3), (4, 5, 6)], check_constraints=True)

    def test_fire_triggers_hint(self):
        self.simple_table_test([(1, 2, 3), (4, 5, 6)], fire_triggers=True)

    def test_null_values(self):
        self.simple_table_test([(1, None, 3), (None, None, None), (1, 2, 3)])

    def test_column_ids(self):
        self.conn._conn.execute_non_query(simple_table)
        self.conn.bulk_copy(tablename, [(1, 2, 3), (4, 5, 6)], column_ids=[1, 3, 2])
        self.expect_simple_table_content('select * from pymssql', [(1, 3, 2), (4, 6, 5)])

    def test_too_many_columns(self):
        self.conn._conn.execute_non_query(simple_table)
        with self.assertRaises(_mssql.MSSQLDatabaseException):
            self.conn.bulk_copy(tablename, [(7, 7, 7, 7)])

    def test_bad_value(self):
        self.conn._conn.execute_non_query(simple_table)
        with self.assertRaises(_mssql.MSSQLDatabaseException):
            self.conn.bulk_copy(tablename, [("Hello", 7, 7)])

    def test_too_few_column_ids(self):
        self.conn._conn.execute_non_query(simple_table)
        caught_exception = False

        try:
            self.conn.bulk_copy(tablename, [(1, 2, 3)], column_ids=[1])
        except ValueError:
            caught_exception = True

        assert caught_exception

    def test_invalid_column_ids(self):
        self.conn._conn.execute_non_query(simple_table)
        with self.assertRaises(_mssql.MSSQLDatabaseException):
            self.conn.bulk_copy(tablename, [(1, 2, 3)], column_ids=[1, 2, 9])

    def test_complex_table(self):
        self.conn._conn.execute_non_query(complex_table)
        rows = [
            (1.2000000476837158, 3.4, datetime.datetime(year=2020, month=1, day=2, hour=3, minute=4, second=5), True, "Hello World"),
            (5.599999904632568, 7.8, datetime.datetime(year=2021, month=2, day=3, hour=4, minute=5, second=6), False, "Hello World!"),
        ]
        self.conn.bulk_copy(tablename, rows, [3, 4, 5, 6, 7])
        self.conn._conn.execute_query('select * from pymssql')
        assert [tuple(row[i] for i in range(2, 7)) for row in self.conn._conn] == rows

    def test_uniqueness_failure(self):
        self.conn._conn.execute_non_query(complex_table)

        rows = [
            (1.2000000476837158, 3.4, datetime.datetime(year=2020, month=1, day=2, hour=3, minute=4, second=5), True, "Hello World"),
            (1.2000000476837158, 7.8, datetime.datetime(year=2021, month=2, day=3, hour=4, minute=5, second=6), False, "Hello World!"),
        ]
        with self.assertRaises(_mssql.MSSQLDatabaseException):
            self.conn.bulk_copy(tablename, rows, [3, 4, 5, 6, 7])
