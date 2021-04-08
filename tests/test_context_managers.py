# -*- coding: utf-8 -*-
"""
Test context managers -- i.e.: the `with` statement
"""

import unittest

from pymssql import InterfaceError
from .helpers import pymssqlconn, mssqlconn, mssql_server_required


@mssql_server_required
class TestContextManagers(unittest.TestCase):
    def test_pymssql_Connection_with(self):
        with pymssqlconn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT @@version AS version")
            self.assertIsNotNone(conn._conn)

        with self.assertRaises(InterfaceError) as context:
            self.assertIsNotNone(conn._conn)

        self.assertEqual(str(context.exception), "Connection is closed.")

    def test_pymssql_Cursor_with(self):
        conn = pymssqlconn()
        with conn.cursor() as cursor:
            cursor.execute("SELECT @@version AS version")
            self.assertIsNotNone(conn._conn)

        self.assertIsNotNone(cursor)

        with self.assertRaises(InterfaceError) as context:
            cursor.execute("SELECT @@version AS version")

        self.assertEqual(str(context.exception), "Cursor is closed.")

    def test_mssql_Connection_with(self):
        with mssqlconn() as conn:
            conn.execute_query("SELECT @@version AS version")
            self.assertTrue(conn.connected)

        self.assertFalse(conn.connected)
