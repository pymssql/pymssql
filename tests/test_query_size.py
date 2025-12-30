"""
Test maximum query size.
"""

import unittest

import pymssql

import pytest
from .helpers import pymssqlconn


@pytest.mark.xfail(strict=False, reason="Could timeout, or fail with different error messages")
@pytest.mark.timeout(60)
@pytest.mark.mssql_server_required
class QueryTests(unittest.TestCase):

    def setUp(self):
        self.connection = pymssqlconn()
        self.connection._conn.execute_non_query("""CREATE TABLE pymssql (data text)""")


    def tearDown(self):
        self.connection._conn.execute_non_query('DROP TABLE pymssql')
        self.connection.close()


    def test_query_size(self):

        cur = self.connection.cursor()
        cur.execute('DELETE FROM pymssql')
        query = "INSERT INTO pymssql (data) VALUES (%s)"
        low = 1024*1024 #*127
        high = 1024*1024*128
        n = 0
        print("")
        while 1:
            n += 1
            next = (low + high) // 2
            cur.execute("DELETE FROM pymssql")
            value = "A"*next
            try:
                cur.execute(query, value)
                cur.execute("SELECT * FROM pymssql")
                res = cur.fetchone()[0]
                if res==value:
                    low = next
                else:
                    print("\t\tres != value")
                    high = next
            except pymssql.OperationalError:
                high = next
                next = low
                self.connection = pymssqlconn()
                self.connection._conn.execute_non_query("""CREATE TABLE pymssql (data text)""")
                cur = self.connection.cursor()

            if high - low == 1:
                break

        print(f"Found max size = {next:#x} {next / (1024*1024)} MiB")
        self.assertTrue(next > self.connection._conn.max_query_size)
