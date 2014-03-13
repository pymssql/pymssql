import _mssql
import pymssql

print('pymssql.__full_version__ = %r' % pymssql.__full_version__)
print('_mssql.__full_version__ = %r' % _mssql.__full_version__)
print('pymssql.get_dbversion() => %r' % pymssql.get_dbversion())

try:
    print('pymssql.get_freetds_version() => %r' % pymssql.get_freetds_version())
except AttributeError:
    pass
