from nose.plugins.skip import SkipTest
from nose.tools import eq_

import pymssql as pym

from .helpers import pymssqlconn, PyTableBase, drop_table, CursorBase

class TestDBAPI2(object):
    def test_version(self):
        assert pym.__version__

class TestTransaction(PyTableBase):
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
        except pym.ProgrammingError, e:
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
        except pym.OperationalError, e:
            if 'badschema' not in str(e):
                raise
            # encountered an error, so we want to rollback
            self.conn.rollback()
        # rollback should have resulted in user's insert getting rolled back
        # too
        eq_(self.row_count(), 0)

class TestCursor(CursorBase):
    dbmod = pym

    def newconn(self):
        self.conn = pymssqlconn()
