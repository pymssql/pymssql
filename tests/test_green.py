# -*- coding: utf-8 -*-
"""
Some async tests with gevent.
"""

import datetime
import unittest

import pytest

import pymssql
from .helpers import mssqlconn, pymssqlconn

gevent = pytest.importorskip("gevent")
try:
    import gevent.socket
except ImportError:
    pytest.skip('gevent is not available', allow_module_level=True)


@pytest.mark.mssql_server_required
class GreenletTests(unittest.TestCase):

    def greenlet_run_pymssql_execute(self, num):
        with pymssqlconn() as conn:
            cur = conn.cursor()
            cur.execute("""
            WAITFOR DELAY '00:00:05'  -- sleep for 5 seconds
            SELECT CURRENT_TIMESTAMP
            """)
            row = cur.fetchone()
            print("greenlet_run_pymssql_execute: num = %r; row = %r" % (num, row))

    def greenlet_run_pymssql_callproc(self, num):
        with pymssqlconn() as conn:
            cur = conn.cursor()
            proc_name = 'my_proc'
            # print("~~ Checking for stored proc (num=%r)..." % num)
            # cur.execute("IF OBJECT_ID('%s', 'P') IS NOT NULL DROP PROCEDURE %s" % (proc_name, proc_name))
            # print("~~ Creating stored proc (num=%r)..." % num)
            # cur.execute("""
            # CREATE PROCEDURE %s AS
            # BEGIN
            #     SET NOCOUNT ON
            #     WAITFOR DELAY '00:00:05'  -- sleep for 5 seconds
            #     SELECT CURRENT_TIMESTAMP
            # END
            # """ % (proc_name,))
            # print("~~ Calling stored proc (num=%r)..." % num)
            cur.callproc(proc_name, ())
            # print("~~ callproc returned (num=%r)..." % num)
            cur.nextset()
            row = cur.fetchone()
            print("greenlet_run_pymssql_callproc: num = %r; row = %r" % (num, row))
            cur.close()

    def greenlet_run_mssql_execute(self, num):
        conn = mssqlconn()
        conn.execute_query("""
        WAITFOR DELAY '00:00:05'  -- sleep for 5 seconds
        SELECT CURRENT_TIMESTAMP
        """)
        for row in conn:
            print("greenlet_run_mssql_execute: num = %r; row = %r" % (num, row))
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

    @pytest.mark.slow
    def test_gevent_socket_pymssql_execute_wait_read_concurrency(self):
        def wait_callback(read_fileno):
            gevent.socket.wait_read(read_fileno)

        pymssql.set_wait_callback(wait_callback)

        elapsed_time = self._run_all_greenlets(
            self.greenlet_run_pymssql_execute)

        self.assertTrue(
            elapsed_time < datetime.timedelta(seconds=20),
            'elapsed_time < 20 seconds')

    @pytest.mark.slow
    def test_gevent_socket_pymssql_callproc_wait_read_concurrency(self):
        def wait_callback(read_fileno):
            gevent.socket.wait_read(read_fileno)

        pymssql.set_wait_callback(wait_callback)

        with pymssqlconn() as conn:
            cur = conn.cursor()
            proc_name = 'my_proc'
            cur.execute("IF OBJECT_ID('%s', 'P') IS NOT NULL DROP PROCEDURE %s" % (proc_name, proc_name))
            cur.execute("""
            CREATE PROCEDURE %s AS
            BEGIN
                SET NOCOUNT ON
                WAITFOR DELAY '00:00:05'  -- sleep for 5 seconds
                SELECT CURRENT_TIMESTAMP
            END
            """ % (proc_name,))
            conn.commit()

        elapsed_time = self._run_all_greenlets(
            self.greenlet_run_pymssql_callproc)

        self.assertTrue(
            elapsed_time < datetime.timedelta(seconds=20),
            'elapsed_time < 20 seconds')

    @pytest.mark.slow
    def test_gevent_socket_mssql_execute_wait_read_concurrency(self):
        def wait_callback(read_fileno):
            gevent.socket.wait_read(read_fileno)

        pymssql.set_wait_callback(wait_callback)

        elapsed_time = self._run_all_greenlets(
            self.greenlet_run_mssql_execute)

        self.assertTrue(
            elapsed_time < datetime.timedelta(seconds=20),
            'elapsed_time < 20 seconds')

    def test_timeout(self):

        def wait_callback(read_fileno):
            gevent.socket.wait_read(read_fileno, timeout=3)

        pymssql.set_wait_callback(wait_callback)

        with self.assertRaises(Exception) as cm:
            self.greenlet_run_mssql_execute(1)

        exc = cm.exception
        self.assertTrue(isinstance(exc, gevent.socket.timeout))
