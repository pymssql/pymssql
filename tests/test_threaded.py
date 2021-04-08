# -*- coding: utf-8 -*-
"""
Test usage in threads.
"""

import sys
import threading
import time
import unittest

from pymssql._mssql import MSSQLDatabaseException

from .helpers import mssqlconn, StoredProc, mark_slow, mssql_server_required


error_sproc = StoredProc(
    "pymssqlErrorThreadTest",
    args=(),
    body="SELECT unknown_column FROM unknown_table")


class _TestingThread(threading.Thread):
    def __init__(self):
        super(_TestingThread, self).__init__()
        self.results = []
        self.exc = None

    def run(self):
        try:
            with mssqlconn() as mssql:
                for i in range(0, 1000):
                    num = mssql.execute_scalar('SELECT %d', (i,))
                    assert num == i
                    self.results.append(num)
        except Exception as exc:
            self.exc = exc


@mssql_server_required
class _TestingErrorThread(_TestingThread):
    def run(self):
        try:
            with mssqlconn() as mssql:
                mssql.execute_query('SELECT unknown_column')
        except Exception as exc:
            self.exc = exc


@mssql_server_required
class _SprocTestingErrorThread(_TestingThread):
    def run(self):
        try:
            with mssqlconn() as mssql:
                error_sproc.execute(mssql=mssql)
        except Exception as exc:
            self.exc = exc


@mssql_server_required
class ThreadedTests(unittest.TestCase):
    def run_threads(self, num, thread_class):
        threads = [thread_class() for _ in range(num)]
        for thread in threads:
            thread.start()

        results = []
        exceptions = []

        while len(threads) > 0:
            sys.stdout.write(".")
            sys.stdout.flush()
            for thread in threads:
                if not thread.is_alive():
                    threads.remove(thread)
                if thread.results:
                    results.append(thread.results)
                if thread.exc:
                    exceptions.append(thread.exc)
            time.sleep(5)

        sys.stdout.write(" ")
        sys.stdout.flush()

        return results, exceptions

    @mark_slow
    def testThreadedUse(self):
        results, exceptions = self.run_threads(
            num=50,
            thread_class=_TestingThread)
        self.assertEqual(len(exceptions), 0)
        for result in results:
            self.assertEqual(result, list(range(0, 1000)))

    @mark_slow
    def testErrorThreadedUse(self):
        results, exceptions = self.run_threads(
            num=2,
            thread_class=_TestingErrorThread)
        self.assertEqual(len(exceptions), 2)
        for exc in exceptions:
            self.assertEqual(type(exc), MSSQLDatabaseException)

    @mark_slow
    def testErrorSprocThreadedUse(self):
        with error_sproc.create():
            results, exceptions = self.run_threads(
                num=5,
                thread_class=_SprocTestingErrorThread)
        self.assertEqual(len(exceptions), 5)
        for exc in exceptions:
            self.assertEqual(type(exc), MSSQLDatabaseException)


suite = unittest.TestSuite()
suite.addTest(unittest.makeSuite(ThreadedTests))

if __name__ == '__main__':
    unittest.main()
