import datetime
import unittest

from nose.plugins.skip import SkipTest
try:
    import gevent
    import gevent.socket
except ImportError:
    raise SkipTest('gevent is not available')

import pymssql
from .helpers import mssqlconn, pymssqlconn


class GreenletTests(unittest.TestCase):

    def greenlet_run_pymssql_execute(self, num):
        with pymssqlconn() as conn:
            cur = conn.cursor()
            cur.execute("""
            WAITFOR DELAY '00:00:05'  -- sleep for 5 seconds
            SELECT CURRENT_TIMESTAMP
            """)
            row = cur.fetchone()

    def greenlet_run_mssql_execute(self, num):
        conn = mssqlconn()
        conn.execute_query("""
        WAITFOR DELAY '00:00:05'  -- sleep for 5 seconds
        SELECT CURRENT_TIMESTAMP
        """)
        for row in conn:
            pass
        conn.close()

    def _run_all_greenlets(self, greenlet_task):
        greenlets = []

        dt1 = datetime.datetime.now()

        for i in range(5):
            gevent.sleep(1)
            greenlets.append(gevent.spawn(greenlet_task, i))

        gevent.joinall(greenlets)

        dt2 = datetime.datetime.now()

        return dt2 - dt1

    def test_gevent_socket_pymssql_execute_wait_read_concurrency(self):
        def wait_callback(read_fileno):
            gevent.socket.wait_read(read_fileno)

        pymssql.set_wait_callback(wait_callback)

        elapsed_time = self._run_all_greenlets(
            self.greenlet_run_pymssql_execute)

        self.assertTrue(
            elapsed_time < datetime.timedelta(seconds=20),
            'elapsed_time < 20 seconds')

    def test_gevent_socket_mssql_execute_wait_read_concurrency(self):
        def wait_callback(read_fileno):
            gevent.socket.wait_read(read_fileno)

        pymssql.set_wait_callback(wait_callback)

        elapsed_time = self._run_all_greenlets(
            self.greenlet_run_mssql_execute)

        self.assertTrue(
            elapsed_time < datetime.timedelta(seconds=20),
            'elapsed_time < 20 seconds')


suite = unittest.TestSuite()
suite.addTest(unittest.makeSuite(GreenletTests))

if __name__ == '__main__':
    unittest.main()
