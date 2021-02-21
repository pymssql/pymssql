# -*- coding: utf-8 -*-
#!/usr/bin/python
"""

"""

from pymssql import _mssql

test_str = 'testing' * 1000

for i in xrange(0, 1000):
    cnx = _mssql.connect('ukplcdbtest01', 'sa', 'deter101', charset='cp1252')
    cnx.select_db('tempdb')
    proc = cnx.init_procedure('pymssqlTestVarchar')
    proc.bind(test_str, _mssql.SQLVARCHAR, '@ivarchar')
    proc.bind(None, _mssql.SQLVARCHAR, '@ovarchar', output=True)
    return_value = proc.execute()
    cnx.close()
