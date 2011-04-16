
import _mssql

from mssqltests import server, username, password, database, port

def mssqlconn():
    return _mssql.connect(server=server, user=username, password=password,
                database=database, port=port, charset='UTF-8')

def drop_table(conn, tname):
    sql = "if object_id('%s') is not null drop table %s" % (tname, tname)
    conn.execute_non_query(sql)

def clear_table(conn, tname):
    sql = 'delete from %s' % tname
    conn.execute_non_query(sql)
