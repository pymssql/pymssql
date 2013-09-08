from contextlib import contextmanager
try:
    # Python 2
    from StringIO import StringIO
except ImportError:
    # Python 3
    from io import StringIO
import sys
import unittest

from .helpers import mssqlconn


@contextmanager
def redirect_stderr():
    sys.stderr = StringIO()
    yield sys.stderr
    sys.stderr = sys.__stderr__


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
            self.assertEquals(row, expected_row)

        self.assertEqual(stderr.getvalue(), "#%s#\n" % sql)
