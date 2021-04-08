# -*- coding: utf-8 -*-
"""
Test queries with debug on.
"""

from contextlib import contextmanager
from io import StringIO
import sys
import unittest

from .helpers import mssqlconn, mssql_server_required


@contextmanager
def redirect_stderr():
    sys.stderr = StringIO()
    yield sys.stderr
    sys.stderr = sys.__stderr__


@mssql_server_required
class TestMSSQLConnectionWithDebugQueries(unittest.TestCase):

    def setUp(self):
        self.conn = mssqlconn()
        self.conn.debug_queries = True

    def test_MSSQLConnection_with_debug_queries(self):
        # This test is for http://code.google.com/p/pymssql/issues/detail?id=98

        sql = "SELECT 'foo' AS first_name, 'bar' AS last_name"
        expected_row = {
            0: 'foo',
            1: 'bar',
            'first_name': 'foo',
            'last_name': 'bar',
        }

        with redirect_stderr() as stderr:
            row = self.conn.execute_row(sql)
            self.assertEqual(row, expected_row)

        self.assertEqual(stderr.getvalue(), "#%s#\n" % sql)
