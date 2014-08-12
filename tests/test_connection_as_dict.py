import unittest

import pymssql

from .helpers import config

def pymssqlconn(**kwargs):
    return pymssql.connect(
            server=config.server,
            user=config.user,
            password=config.password,
            database=config.database,
            port=config.port,
            **kwargs
        )


class TestConnectionAsDict(unittest.TestCase):

    def setUp(self):
        self.conn = pymssqlconn(as_dict=True)

    def test_fetchall_with_connection_as_dict(self):
        # This test is for http://code.google.com/p/pymssql/issues/detail?id=18
        cursor = self.conn.cursor()
        cursor.execute("SELECT 'foo' AS first_name, 'bar' AS last_name")
        data = cursor.fetchall()
        self.assertEquals(data, [{'first_name': u'foo', 'last_name': u'bar'}])

    def test_no_results_with_connection_as_dict(self):
        # Make sure that checking for columns without names doesn't break
        # statements that don't return results

        cursor = self.conn.cursor()
        cursor.execute("""
        CREATE TABLE daily_measurement (
            datetime DATETIME,
            value FLOAT,
            notes VARCHAR,
        )
        """)

