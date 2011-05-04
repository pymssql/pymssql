from os import path

import _mssql
import pymssql

class Config(object):
    pass
config = Config()

cdir = path.dirname(__file__)
tmpdir = path.join(cdir, 'tmp')
cfgpath = path.join(cdir, 'tests.cfg')

def mssqlconn():
    return _mssql.connect(
            server=config.server,
            user=config.user,
            password=config.password,
            database=config.database,
            port=config.port,
            charset='UTF-8'
        )

def pymssqlconn():
    return pymssql.connect(
            server=config.server,
            user=config.user,
            password=config.password,
            database=config.database,
            port=config.port,
            charset='UTF-8'
        )

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
