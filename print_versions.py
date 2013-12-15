import _mssql
import pymssql

print('pymssql.__version__ = %r' % pymssql.__version__)
print('_mssql.__version__ = %r' % _mssql.__version__)
print('pymssql.get_dbversion() => %r' % pymssql.get_dbversion())

try:
    print('pymssql.get_freetds_version() => %r' % pymssql.get_freetds_version())
except AttributeError:
    pass
