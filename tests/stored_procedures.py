import _mssql
import decimal
import datetime
import unittest
import mssqltests

class FixedTypeConversion(mssqltests.MssqlTestCase):

    def testBigInt(self):
        input = 123456789L
        proc = self.mssql.init_procedure('pymssqlTestBigInt')
        proc.bind(input, _mssql.SQLINT8, '@ibigint')
        proc.bind(None, _mssql.SQLINT8, '@obigint', output=True)
        proc.execute()
        self.assertEqual(input, proc.parameters['@obigint'])

    def testBit(self):
        input = 1
        proc = self.mssql.init_procedure('pymssqlTestBit')
        proc.bind(input, _mssql.SQLBIT, '@ibit')
        proc.bind(None, _mssql.SQLBIT, '@obit', output=True)
        proc.execute()
        self.assertEqual(input, proc.parameters['@obit'])

    def testDateTime(self):
        input = datetime.datetime(2009, 8, 27, 15, 28, 38)
        proc = self.mssql.init_procedure('pymssqlTestDateTime')
        proc.bind(input, _mssql.SQLDATETIME, '@idatetime')
        proc.bind(None, _mssql.SQLDATETIME, '@odatetime', output=True)
        proc.execute()
        self.assertEqual(input, proc.parameters['@odatetime'])

    def testDecimal(self):
        input = decimal.Decimal('5.12345')
        proc = self.mssql.init_procedure('pymssqlTestDecimal')
        proc.bind(input, _mssql.SQLDECIMAL, '@idecimal')
        proc.bind(None, _mssql.SQLDECIMAL, '@odecimal', output=True, max_length=6)
        proc.execute()
        self.assertEqual(input, proc.parameters['@odecimal'])

    def testInt(self):
        input = 10056
        proc = self.mssql.init_procedure('pymssqlTestInt')
        proc.bind(input, _mssql.SQLINT4, '@iint')
        proc.bind(None, _mssql.SQLINT4, '@oint', output=True)
        proc.execute()
        self.assertEqual(input, proc.parameters['@oint'])

    def testMoney(self):
        input = decimal.Decimal('5.12')
        proc = self.mssql.init_procedure('pymssqlTestMoney')
        proc.bind(input, _mssql.SQLMONEY, '@imoney')
        proc.bind(None, _mssql.SQLMONEY, '@omoney', output=True)
        proc.execute()
        self.assertEqual(input, proc.parameters['@omoney'])

    def testNumeric(self):
        input = decimal.Decimal('5.12345')
        proc = self.mssql.init_procedure('pymssqlTestNumeric')
        proc.bind(input, _mssql.SQLNUMERIC, '@inumeric')
        proc.bind(None, _mssql.SQLNUMERIC, '@onumeric', output=True)
        proc.execute()
        self.assertEqual(input, proc.parameters['@onumeric'])

    def testSmallInt(self):
        input = 10056
        proc = self.mssql.init_procedure('pymssqlTestSmallInt')
        proc.bind(input, _mssql.SQLINT2, '@ismallint')
        proc.bind(None, _mssql.SQLINT2, '@osmallint', output=True)
        proc.execute()
        self.assertEqual(input, proc.parameters['@osmallint'])

    def testTinyInt(self):
        input = 101
        proc = self.mssql.init_procedure('pymssqlTestTinyInt')
        proc.bind(input, _mssql.SQLINT1, '@itinyint')
        proc.bind(None, _mssql.SQLINT1, '@otinyint', output=True)
        proc.execute()
        self.assertEqual(input, proc.parameters['@otinyint'])

class StringTypeConversion(mssqltests.MssqlTestCase):
    
    def testChar(self):
        input = 'test'
        proc = self.mssql.init_procedure('pymssqlTestChar')
        proc.bind(input, _mssql.SQLCHAR, '@ichar')
        proc.bind(None, _mssql.SQLCHAR, '@ochar', output=True, max_length=4)
        proc.execute()
        self.assertEqual(input, proc.parameters['@ochar'])
    
    def testText(self):
        input = 'test'
        proc = self.mssql.init_procedure('pymssqlTestText')
        proc.bind(input, _mssql.SQLTEXT, '@itext')
        proc.bind(None, _mssql.SQLVARCHAR, '@otext', output=True)
        proc.execute()
        self.assertEqual(input, proc.parameters['@otext'])
    
    def testVarChar(self):
        input = 'test'
        proc = self.mssql.init_procedure('pymssqlTestVarChar')
        proc.bind(input, _mssql.SQLVARCHAR, '@ivarchar')
        proc.bind(None, _mssql.SQLVARCHAR, '@ovarchar', output=True)
        proc.execute()
        self.assertEqual(input, proc.parameters['@ovarchar'])

if __name__ == '__main__':
    import sys

    if len(sys.argv) == 2:
        action = sys.argv[1]

        if action == 'create':
            queries = open('stored_procedures.sql').read().split('--SPLIT')
        elif action == 'drop':
            queries = [open('drop_stored_procedures.sql').read()]
        else:
            print 'Unknown action'
            exit(1)

        mssql = _mssql.connect(mssqltests.server, mssqltests.username, mssqltests.password)
        mssql.select_db(mssqltests.database)
        for query in queries:
            mssql.execute_non_query(query)
    else:
        unittest.main()
