# -*- coding: utf-8 -*-
"""
Various test helper functions.
"""

import logging
from os import path
import time

import pytest

def eq_(a, b):
    assert a == b

def skip_test(reason='No reason given to skip_test'):
    pytest.skip(reason)

def mark_slow(f):
    return f

mssql_server_required = pytest.mark.mssql_server_required

from pymssql import _mssql
import pymssql


class Config(object):
    def __str__(self):
        return f"server={self.server}, port={self.port}, database={self.database}, " \
               f"user={self.user}, password={self.password}"

config = Config()

cdir = path.dirname(__file__)
tmpdir = path.join(cdir, 'tmp')
cfgpath = path.join(cdir, 'tests.cfg')
global_mssqlconn = None

def mssqlconn(conn_properties=None):
    return _mssql.connect(
        server=config.server,
        user=config.user,
        password=config.password,
        database=config.database,
        port=config.port,
        conn_properties=conn_properties
    )


def pymssqlconn(**kwargs):
    return pymssql.connect(
        server=config.server,
        user=config.user,
        password=config.password,
        database=config.database,
        port=config.port,
        **kwargs
    )


def get_app_lock():
    global global_mssqlconn

    if global_mssqlconn is None:
        try:
            global_mssqlconn = mssqlconn()
        except Exception as exc:
            print(f"Could not connect to {config}:\n{exc}")
            return False

    t1 = time.time()

    while True:
        t2 = time.time()
        print("*** %d: Grabbing app lock for pymssql tests" % (t2,))
        result = global_mssqlconn.execute_scalar("""
        DECLARE @result INTEGER;
        EXEC @result = sp_getapplock
            @Resource = 'pymssql_tests',
            @LockMode = 'Exclusive',
            @LockOwner = 'Session',
            @LockTimeout = 60000;
        SELECT @result AS result;
        """)
        if result != -1:  # -1 => timeout; keep looping
            break

    t2 = time.time()
    print(
        "*** %d: sp_getapplock for 'pymssql_tests' returned %d - "
        "it took %d seconds"
        % (t2, result, t2 - t1))
    return True


def release_app_lock():
    if global_mssqlconn is None:
        return
    t1 = time.time()
    result = global_mssqlconn.execute_scalar("""
    DECLARE @result INTEGER;
    EXEC @result = sp_releaseapplock
        @Resource = 'pymssql_tests',
        @LockOwner = 'Session';
    SELECT @result AS result;
    """)
    print(
        "*** %d: sp_releaseapplock for 'pymssql_tests' returned %d"
        % (t1, result))


def drop_table(conn, tname):
    sql = "if object_id('%s') is not null drop table %s" % (tname, tname)
    conn.execute_non_query(sql)


def clear_table(conn, tname):
    sql = 'delete from %s' % tname
    conn.execute_non_query(sql)


class PyTableBase(object):
    tname = 'pymssql'
    cols = tuple()
    idtype = None

    @classmethod
    def table_sql(cls):
        return 'CREATE TABLE %s (%s)' % (cls.tname, ', '.join(cls.cols))

    @classmethod
    def newconn(cls):
        cls.conn = pymssqlconn()

    @classmethod
    def setup_class(cls):
        cls.newconn()
        # table related commands managed by this class are handled in a
        # different connection
        cls._conn = mssqlconn()
        drop_table(cls._conn, cls.tname)
        cls._conn.execute_non_query(cls.table_sql())

    def setUp(self):
        clear_table(self._conn, self.tname)

    def row_count(self):
        sql = 'select count(*) from %s' % self.tname
        return self.conn._conn.execute_scalar(sql)

    def execute(self, sql, params=None):
        cur = self.conn.cursor()
        cur.execute(sql, params)
        return cur


class TableManager(object):
    def __init__(self, conn, tname, *cols):
        self.conn = conn
        self.tname = tname
        self.cols = cols

        self.create()

    def table_sql(self):
        return 'CREATE TABLE %s (%s)' % (self.tname, ', '.join(self.cols))

    def drop(self):
        #mssql
        sql = "if object_id('%s') is not null drop table %s" % (
            self.tname, self.tname)
        try:
            self.execute(sql)
        except Exception as e:
            self.conn.rollback()
            if 'syntax error' not in str(e):
                raise
            #sqlite
            sql = 'drop table if exists %s' % self.tname
            self.execute(sql)

    def execute(self, sql):
        cur = self.conn.cursor()
        cur.execute(sql)
        self.conn.commit()

    def create(self):
        self.drop()
        self.execute(self.table_sql())

    def clear(self):
        sql = 'delete from %s' % self.tname
        self.execute(sql)

    def count(self):
        sql = 'select count(*) from %s' % self.tname
        cur = self.conn.cursor()
        cur.execute(sql)
        return cur.fetchone()[0]


class DBAPIBase(object):

    def execute(self, sql):
        cur = self.conn.cursor()
        cur.execute(sql)
        return cur

    def executemany(self, sql, params_seq):
        cur = self.conn.cursor()
        cur.executemany(sql, params_seq)
        return cur


class CursorBase(DBAPIBase):
    """
    This is a "base" object because I have an uncommitted test module
    that runs these tests against psycopg to see what its behavior is.
    When psycopg comparison isn't needed anymore, this class can be moved to
    test_pymssql and used directly.
    """
    @classmethod
    def setup_class(cls):
        cls.newconn()
        cls.t1 = TableManager(cls.conn, 'test', 'id int', 'name varchar(50)')

    def setup_method(self, method):
        self.conn.rollback()
        self.t1.clear()
        self.execute("insert into test values (1, 'one')")
        self.execute("insert into test values (2, 'two')")
        self.execute("insert into test values (3, 'three')")
        self.execute("insert into test values (4, 'four')")
        self.execute("insert into test values (5, 'five')")
        self.conn.commit()

    def test_description_not_used(self):
        cur = self.conn.cursor()
        assert cur.description is None

    def test_description_after_insert(self):
        cur = self.execute("insert into test values (6, 'six')")
        self.conn.commit()
        assert cur.description is None

    def test_description_after_select(self):
        cur = self.execute('select * from test')
        eq_(len(cur.description), 2)
        eq_(cur.description[0][0], 'id')
        eq_(self.dbmod.NUMBER, cur.description[0][1])
        eq_(cur.description[1][0], 'name')
        eq_(self.dbmod.STRING, cur.description[1][1])

    def test_sticky_description(self):
        cur = self.execute('select * from test')
        eq_(len(cur.description), 2)

        cur2 = self.execute('select id from test')
        eq_(len(cur2.description), 1)

        # description of first cursor should not be affected
        eq_(len(cur.description), 2)

    def test_fetchone(self):
        cur = self.execute('select * from test order by id')
        res = cur.fetchone()
        eq_(res[0], 1)
        res = cur.fetchone()
        eq_(res[0], 2)

        for x in range(0, 5):
            if cur.fetchone() is None:
                # make sure another call is also None and no exception is
                # raised
                assert cur.fetchone() is None
                break
            if x == 5:
                assert False, 'expected cur.fetchone() to be None'

    def test_insert_rowcount(self):
        cur = self.execute("insert into test values (6, 'six')")
        eq_(cur.rowcount, 1)
        self.conn.rollback()

    def test_delete_rowcount(self):
        cur = self.execute("delete from test where id = 5")
        eq_(cur.rowcount, 1)
        cur = self.execute("delete from test where id > 1")
        eq_(cur.rowcount, 3)
        self.conn.rollback()

    def test_update_rowcount(self):
        cur = self.execute("update test set name = 'foo' where id > 1")
        eq_(cur.rowcount, 4)
        self.conn.rollback()

    def test_select_rowcount(self):
        cur = self.execute('select * from test')
        eq_(cur.rowcount, -1)
        cur.fetchall()
        eq_(cur.rowcount, 5)

    def test_fetchone_rowcount(self):
        cur = self.execute('select * from test')
        eq_(cur.rowcount, -1)

        for _ in iter(cur.fetchone, None):
            eq_(cur.rowcount, -1)

        eq_(cur.rowcount, 5)

    def test_fetchmany_rowcount(self):
        cur = self.execute('select * from test')
        eq_(cur.rowcount, -1)

        for _ in iter(cur.fetchmany, []):
            eq_(cur.rowcount, -1)

        eq_(cur.rowcount, 5)

    def test_as_dict(self):
        # test for http://code.google.com/p/pymssql/issues/detail?id=92
        cur = self.conn.cursor(as_dict=True)
        cur.execute("SELECT 'foo' AS first_name, 'bar' AS last_name")
        eq_(cur.fetchall(), [{'first_name': u'foo', 'last_name': u'bar'}])

    def test_as_dict_no_column_name(self):
        cur = self.conn.cursor(as_dict=True)
        try:
            # SQL Server >= 2008:
            #
            #   SELECT MAX(x), MIN(x) AS [MIN(x)]
            #   FROM (VALUES (1), (2), (3))
            #   AS foo(x)
            #
            # SQL Server = 2005 (remove when we drop suport for it):
            #
            #   SELECT MAX(x), MIN(x) AS [MIN(x)]
            #   FROM (SELECT 1
            #         UNION ALL
            #         SELECT 2
            #         UNION ALL
            #         SELECT 3)
            #   AS foo(x)
            cur.execute(
                "SELECT MAX(x), MIN(x) AS [MIN(x)] "
                "FROM (SELECT 1"
                "      UNION ALL"
                "      SELECT 2"
                "      UNION ALL"
                "      SELECT 3) AS foo(x)")
            assert False, "Didn't raise InterfaceError"
        except pymssql.ColumnsWithoutNamesError as exc:
            eq_(exc.columns_without_names, [0])

    def test_as_dict_no_column_name_2(self):
        cur = self.conn.cursor(as_dict=True)
        try:
            # SQL Server >= 2008:
            #
            #   SELECT MAX(x), MAX(y) AS [MAX(y)], MIN(y)
            #   FROM (VALUES (1, 2), (2, 3), (3, 4))
            #   AS foo(x, y)
            #
            # SQL Server = 2005 (remove when we drop suport for it):
            #
            #   SELECT MAX(x), MAX(y) AS [MAX(y)], MIN(y)
            #   FROM (SELECT (1, 2)
            #         UNION ALL
            #         SELECT (2, 3)
            #         UNION ALL
            #         SELECT (3, 4))
            #   AS foo(x, y)
            cur.execute(
                "SELECT MAX(x), MAX(y) AS [MAX(y)], MIN(y) "
                "FROM (SELECT 1, 2"
                "      UNION ALL"
                "      SELECT 2, 3"
                "      UNION ALL"
                "      SELECT 3, 4) AS foo(x, y)")
            assert False, "Didn't raise InterfaceError"
        except pymssql.ColumnsWithoutNamesError as exc:
            eq_(exc.columns_without_names, [0, 2])

    def test_fetchmany(self):
        cur = self.conn.cursor()
        cur.execute('select * from test')
        eq_(len(cur.fetchmany(2)), 2)
        eq_(len(cur.fetchmany(2)), 2)
        eq_(len(cur.fetchmany(2)), 1)

        # now a couple extra for good measure
        eq_(len(cur.fetchmany(2)), 0)
        eq_(len(cur.fetchmany(2)), 0)

    def test_execute_many(self):
        cur = self.executemany(
            "delete from test where id = %(id)s",
            [{'id': 1}, {'id': 2}])
        self.conn.commit()
        eq_(self.t1.count(), 3)
        eq_(cur.rowcount, 2)


def clear_db():
    conn = mssqlconn()
    mapping = {
        'P': 'drop procedure [%(name)s]',
        'C': 'alter table [%(parent_name)s] drop constraint [%(name)s]',
        ('FN', 'IF', 'TF'): 'drop function [%(name)s]',
        'V': 'drop view [%(name)s]',
        'F': 'alter table [%(parent_name)s] drop constraint [%(name)s]',
        'U': 'drop table [%(name)s]',
    }
    delete_sql = []
    for type, drop_sql in mapping.items():
        sql = 'select name, object_name( parent_object_id ) as parent_name '\
            'from sys.objects where type in (\'%s\')' % '", "'.join(type)
        conn.execute_query(sql)
        for row in conn:
            delete_sql.append(drop_sql % dict(row))
    for sql in delete_sql:
        conn.execute_non_query(sql)


class StoredProc(object):
    def __init__(self, name, args, body, mssql=None):
        self.name = name
        self.args = args
        self.body = body
        self.mssql = mssql
        logger_name = '.'.join([__name__, self.__class__.__name__, self.name])
        self.logger = logging.getLogger(logger_name)

    def create(self, mssql=None):
        mssql = mssql or self.mssql
        if not mssql:
            mssql = self.mssql = mssqlconn()

        try:
            self.drop(mssql)
        except:
            pass

        mssql.execute_non_query("""
        CREATE PROCEDURE [dbo].[%(name)s]
            %(args)s
        AS
        BEGIN
            %(body)s
        END
        """ % {
            'name': self.name,
            'args': '\n'.join(self.args),
            'body': self.body,
        })
        self.logger.debug("Created stored proc: %r" % self.name)
        return self

    def execute(self, mssql=None, args=()):
        mssql = mssql or self.mssql
        if not mssql:
            mssql = self.mssql = mssqlconn()
        proc = mssql.init_procedure(self.name)
        for arg in args:
            proc.bind(*arg)
        self.logger.debug("Calling stored proc: %r" % self.name)
        proc.execute()
        self.logger.debug("Called stored proc: %r" % self.name)

    def drop(self, mssql=None):
        mssql = mssql or self.mssql
        if not mssql:
            mssql = self.mssql = mssqlconn()
        mssql.execute_non_query("DROP PROCEDURE [dbo].[%s]" % self.name)
        self.logger.debug("Dropped stored proc: %r" % self.name)
        if self.mssql:
            self.mssql.close()
            self.logger.debug("Closed mssql connection: %r" % self.mssql)
            self.mssql = None

    def __enter__(self):
        return self

    def __exit__(self, type, value, tb):
        self.drop()


def get_sql_server_version(mssql_connection):
    """
    Returns the version of the SQL Server in use:
    """
    result = mssql_connection.execute_scalar(
        "SELECT CAST(SERVERPROPERTY('ProductVersion') as varchar)"
    )
    ver_code = int(result.split('.')[0])
    if ver_code >= 12:
        major_version = 2014
    elif ver_code == 11:
        major_version = 2012
    elif ver_code == 10:
        major_version = 2008
    elif ver_code == 9:
        major_version = 2005
    else:
        major_version = 2000
    return major_version
