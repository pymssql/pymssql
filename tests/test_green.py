import datetime
import unittest

import gevent
import gevent.socket

import pymssql
from .helpers import pymssqlconn


class GreenletTests(unittest.TestCase):

    def greenlet_run(self, num):
        with pymssqlconn() as conn:
            cur = conn.cursor()
            cur.execute("""
            WAITFOR DELAY '00:00:05'  -- sleep for 5 seconds
            SELECT CURRENT_TIMESTAMP
            """)
            row = cur.fetchone()

    def _run_all_greenlets(self):
        greenlets = []

        dt1 = datetime.datetime.now()

        for i in range(5):
            gevent.sleep(1)
            greenlets.append(gevent.spawn(self.greenlet_run, i))

        gevent.joinall(greenlets)

        dt2 = datetime.datetime.now()

        return dt2 - dt1

    def test_fast(self):
        def wait_callback(read_fileno):
            gevent.socket.wait_read(read_fileno)

        pymssql.set_wait_callback(wait_callback)

        elapsed_time = self._run_all_greenlets()

        self.assertTrue(
            elapsed_time < datetime.timedelta(seconds=20),
            'elapsed_time < 20 seconds')


suite = unittest.TestSuite()
suite.addTest(unittest.makeSuite(GreenletTests))

if __name__ == '__main__':
    unittest.main()
