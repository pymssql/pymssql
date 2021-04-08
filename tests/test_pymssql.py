# -*- coding: utf-8 -*-
"""
Test pymssql module.
"""

import unittest

import pytest

import pymssql as pym

from .helpers import (pymssqlconn, PyTableBase, CursorBase, eq_, config,
                      skip_test, mssql_server_required)

class TestDBAPI2(object):
    def test_version(self):
        assert pym.__version__

@mssql_server_required
class TestTransaction(unittest.TestCase, PyTableBase):
    tname = 'users'
    cols = (
        'name varchar(50)',
    )

    def setUp(self):
        PyTableBase.setUp(self)
        # make sure we start with a fresh connection for transaction tests
        # so that previous transaction activities don't taint a test
        self.newconn()

    def test_immediate_rollback(self):
        # just making sure this doesn't throw an exception
        self.conn.rollback()

    def test_multiple_rollbacks(self):
        # just making sure this doesn't throw an exception
        self.conn.rollback()
        self.conn.rollback()
        self.conn.rollback()

    def test_rollback(self):
        cur = self.conn.cursor()
        cur.execute('insert into users values (%s)', 'foobar')
        eq_(self.row_count(), 1)
        self.conn.rollback()
        eq_(self.row_count(), 0)

    def test_commit(self):
        cur = self.conn.cursor()
        cur.execute('insert into users values (%s)', 'foobar')
        eq_(self.row_count(), 1)
        self.conn.commit()
        self.conn.rollback()
        eq_(self.row_count(), 1)

    def test_rollback_after_error(self):
        cur = self.conn.cursor()
        cur.execute('insert into users values (%s)', 'foobar')
        eq_(self.row_count(), 1)
        try:
            cur.execute('insert into notable values (%s)', '123')
        except pym.ProgrammingError as e:
            if 'notable' not in str(e):
                raise
            # encountered an error, so we want to rollback
            self.conn.rollback()
        # rollback should have resulted in user's insert getting rolled back
        # too
        eq_(self.row_count(), 0)

    def test_rollback_after_create_error(self):
        """
            test_rollback_after_create_error

            For some reason, SQL server will issue a batch-abort
            if the statement is a CREATE statement and it fails.  This means
            the transaction is implicitly rolled back and a subsequent call to
            rollback() without special handling would result in an error.
        """
        cur = self.conn.cursor()
        cur.execute('insert into users values (%s)', 'foobar')
        eq_(self.row_count(), 1)
        try:
            cur.execute("CREATE TABLE badschema.t1 ( test1 CHAR(5) NOT NULL)")
        except pym.OperationalError as e:
            if 'badschema' not in str(e):
                raise
            # encountered an error, so we want to rollback
            self.conn.rollback()
        # rollback should have resulted in user's insert getting rolled back
        # too
        eq_(self.row_count(), 0)


@mssql_server_required
class TestCursor(CursorBase):
    dbmod = pym

    @classmethod
    def newconn(cls):
        cls.conn = pymssqlconn()


@mssql_server_required
class TestBasicConnection(unittest.TestCase):

    def connect(self, conn_props=None):
        return pym.connect(
            server=config.server,
            user=config.user,
            password=config.password,
            database=config.database,
            port=config.port,
            conn_properties=conn_props
        )

    def test_conn_props_override(self):
        conn = self.connect(conn_props='SET TEXTSIZE 2147483647')
        conn.close()

        conn = self.connect(conn_props='SET TEXTSIZE 2147483647;')
        conn.close()

        conn = self.connect(conn_props='SET TEXTSIZE 2147483647;SET ANSI_NULLS ON;')
        conn.close()

        conn = self.connect(conn_props='SET TEXTSIZE 2147483647;SET ANSI_NULLS ON')
        conn.close()

        conn = self.connect(conn_props='SET TEXTSIZE 2147483647;'
                        'SET ANSI_NULLS ON;')
        conn.close()

        conn = self.connect(conn_props=['SET TEXTSIZE 2147483647;', 'SET ANSI_NULLS ON'])
        conn.close()
        self.assertRaises(Exception, self.connect, conn_props='BOGUS SQL')

        conn = pym.connect(
            conn_properties='SET TEXTSIZE 2147483647',
            server=config.server,
            user=config.user,
            password=config.password
        )
        conn.close()


@mssql_server_required
class TestAutocommit(unittest.TestCase, PyTableBase):
    tname = 'test'
    cols = (
        'name varchar(50)',
    )

    insert_query = 'INSERT INTO {tname} VALUES (%s)'.format(tname=tname)
    select_query = 'SELECT * FROM {tname} WHERE name = (%s)'.format(tname=tname)

    test_db_name = 'autocommit_test_database'

    def setUp(self):
        PyTableBase.setUp(self)

    def tearDown(self):
        self.conn._conn.execute_non_query("IF EXISTS(select * from sys.databases where name='{0}') DROP DATABASE {0}".format(self.test_db_name))

    def test_db_creation_with_autocommit(self):
        """
        Try creating and dropping database with autocommit
        """
        cur = pymssqlconn(autocommit=True).cursor()
        try:
            cur.execute("CREATE DATABASE {0}".format(self.test_db_name))
        except pym.OperationalError as e:
            expected_msg = "CREATE DATABASE permission denied in database 'master'"
            if expected_msg in str(e.args[1]):
                skip_test('We have no CREATE DATABASE permission on test database')
            else:
                pytest.fail()
        else:
            cur.execute("DROP DATABASE {0}".format(self.test_db_name))

    def test_db_creation_without_autocommit(self):
        """
        Try creating and dropping database without autocommit, expecting it to fail
        """
        cur = pymssqlconn(autocommit=False).cursor()
        with pytest.raises(pym.OperationalError) as excinfo:
            cur.execute("CREATE DATABASE autocommit_test_database")
        expected_msg = "CREATE DATABASE statement not allowed within multi-statement transaction"
        assert expected_msg in excinfo.exconly()

    def test_autocommit_flipping_tf(self):
        insert_value = 'true-false'
        conn = pymssqlconn(autocommit=True)
        conn.autocommit(False)
        cur = conn.cursor()
        cur.execute(self.insert_query, insert_value)
        conn.commit()
        cur.execute(self.select_query, insert_value)
        row = cur.fetchone()
        cur.close()
        conn.close()
        assert len(row) > 0

    def test_autocommit_flipping_ft(self):
        insert_value = 'false-true'
        conn = pymssqlconn(autocommit=False)
        conn.autocommit(True)
        cur = conn.cursor()
        cur.execute(self.insert_query, insert_value)
        cur.execute(self.select_query, insert_value)
        row = cur.fetchone()
        assert len(row) > 0

    def test_autocommit_false_does_not_commit(self):
        insert_value = 'false'
        conn = pymssqlconn(autocommit=False)
        cur = conn.cursor()
        cur.execute(self.insert_query, insert_value)
        conn.rollback()
        cur.execute(self.select_query, insert_value)
        row = cur.fetchone()
        cur.close()
        conn.close()
        assert row is None
