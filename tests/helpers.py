from os import path

import _mssql

from mssqltests import server, username, password, database, port

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

def drop_table(conn, tname):
    sql = "if object_id('%s') is not null drop table %s" % (tname, tname)
    conn.execute_non_query(sql)

def clear_table(conn, tname):
    sql = 'delete from %s' % tname
    conn.execute_non_query(sql)
