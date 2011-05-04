import decimal
import datetime

from nose.plugins.skip import SkipTest
from nose.tools import eq_

import _mssql

from .helpers import mssqlconn

FIXED_TYPES = (
    'BigInt',
    'Bit',
    'DateTime',
    'Decimal',
    'Int',
    'Money',
    'Numeric',
    'SmallInt',
    'TinyInt'
)

VARIABLE_TYPES = (
    ('Char', 4),
    ('Text',None),
    ('VarChar', 4)
)

class TestFixedTypeConversion(object):

    def setUp(self):
        self.mssql = mssqlconn()

        for name in FIXED_TYPES:
            dbtype = name.lower()
            if dbtype == 'decimal':
                identifier = 'decimal(6, 5)'
            else:
                identifier = dbtype

            self.mssql.execute_non_query("""
            CREATE PROCEDURE [dbo].[pymssqlTest%(name)s]
                @i%(dbtype)s %(identifier)s,
                @o%(dbtype)s %(identifier)s output
            AS
            BEGIN
                SET @o%(dbtype)s = @i%(dbtype)s;
                RETURN 0;
            END
            """ % {
                'dbtype': dbtype,
                'name': name,
                'identifier': identifier
            })

    def tearDown(self):
        for name in FIXED_TYPES:
            self.mssql.execute_non_query('DROP PROCEDURE [dbo].[pymssqlTest%s]' % name)

        self.mssql.close()


    def testBigInt(self):
        input = 123456789L
        proc = self.mssql.init_procedure('pymssqlTestBigInt')
        proc.bind(input, _mssql.SQLINT8, '@ibigint')
        proc.bind(None, _mssql.SQLINT8, '@obigint', output=True)
        proc.execute()
        eq_(input, proc.parameters['@obigint'])

    def testBit(self):
        input = True
        proc = self.mssql.init_procedure('pymssqlTestBit')
        proc.bind(input, _mssql.SQLBITN, '@ibit')
        proc.bind(False, _mssql.SQLBITN, '@obit', output=True)
        proc.execute()
        eq_(input, proc.parameters['@obit'])

    def testDateTime(self):
        input = datetime.datetime(2009, 8, 27, 15, 28, 38)
        proc = self.mssql.init_procedure('pymssqlTestDateTime')
        proc.bind(input, _mssql.SQLDATETIME, '@idatetime')
        proc.bind(None, _mssql.SQLDATETIME, '@odatetime', output=True)
        proc.execute()
        eq_(input, proc.parameters['@odatetime'])

    def testDecimal(self):
        input = decimal.Decimal('5.12345')
        proc = self.mssql.init_procedure('pymssqlTestDecimal')
        proc.bind(input, _mssql.SQLDECIMAL, '@idecimal')
        proc.bind(None, _mssql.SQLDECIMAL, '@odecimal', output=True, max_length=6)
        proc.execute()
        raise SkipTest # testDecimal - decimal value currently truncated
        eq_(input, proc.parameters['@odecimal'])

    def testInt(self):
        input = 10056
        proc = self.mssql.init_procedure('pymssqlTestInt')
        proc.bind(input, _mssql.SQLINT4, '@iint')
        proc.bind(None, _mssql.SQLINT4, '@oint', output=True)
        proc.execute()
        eq_(input, proc.parameters['@oint'])

    def testMoney(self):
        input = decimal.Decimal('5.12')
        proc = self.mssql.init_procedure('pymssqlTestMoney')
        proc.bind(input, _mssql.SQLMONEY, '@imoney')
        proc.bind(None, _mssql.SQLMONEY, '@omoney', output=True)
        proc.execute()
        eq_(input, proc.parameters['@omoney'])

    def testNumeric(self):
        input = decimal.Decimal('5.12345')
        proc = self.mssql.init_procedure('pymssqlTestNumeric')
        proc.bind(input, _mssql.SQLNUMERIC, '@inumeric')
        proc.bind(None, _mssql.SQLNUMERIC, '@onumeric', output=True)
        proc.execute()
        raise SkipTest # testNumeric - decimal value currently truncated
        eq_(input, proc.parameters['@onumeric'])

    def testSmallInt(self):
        input = 10056
        proc = self.mssql.init_procedure('pymssqlTestSmallInt')
        proc.bind(input, _mssql.SQLINT2, '@ismallint')
        proc.bind(None, _mssql.SQLINT2, '@osmallint', output=True)
        proc.execute()
        eq_(input, proc.parameters['@osmallint'])

    def testTinyInt(self):
        input = 101
        proc = self.mssql.init_procedure('pymssqlTestTinyInt')
        proc.bind(input, _mssql.SQLINT1, '@itinyint')
        proc.bind(None, _mssql.SQLINT1, '@otinyint', output=True)
        proc.execute()
        eq_(input, proc.parameters['@otinyint'])

class TestStringTypeConversion(object):

    def setUp(self):
        self.mssql = mssqlconn()

        for name, size in VARIABLE_TYPES:
            dbtype = name.lower()
            identifier = dbtype if dbtype == 'text' else '%s(%d)' % (dbtype, size)

            try:
                self.mssql.execute_non_query("""
                CREATE PROCEDURE [dbo].[pymssqlTest%(name)s]
                    @i%(dbtype)s %(identifier)s,
                    @o%(dbtype)s %(identifier)s output
                AS
                BEGIN
                    SET @o%(dbtype)s = @i%(dbtype)s;
                    RETURN 0;
                END
                """ % {
                    'dbtype': dbtype,
                    'name': name,
                    'identifier': identifier
                })
            except:
                if name == 'Text':
                    raise

    def tearDown(self):
        for name, size in VARIABLE_TYPES:
            self.mssql.execute_non_query('DROP PROCEDURE [dbo].[pymssqlTest%s]' % name)
        self.mssql.close()

    def testChar(self):
        input = 'test'
        proc = self.mssql.init_procedure('pymssqlTestChar')
        proc.bind(input, _mssql.SQLCHAR, '@ichar')
        proc.bind(None, _mssql.SQLCHAR, '@ochar', output=True, max_length=4)
        proc.execute()
        eq_(input, proc.parameters['@ochar'])

    def testText(self):
        input = 'test'
        proc = self.mssql.init_procedure('pymssqlTestText')
        proc.bind(input, _mssql.SQLTEXT, '@itext')
        proc.bind(None, _mssql.SQLVARCHAR, '@otext', output=True)
        proc.execute()
        eq_(input, proc.parameters['@otext'])

    def testVarChar(self):
        input = 'test'
        proc = self.mssql.init_procedure('pymssqlTestVarChar')
        proc.bind(input, _mssql.SQLVARCHAR, '@ivarchar')
        proc.bind(None, _mssql.SQLVARCHAR, '@ovarchar', output=True)
        proc.execute()
        eq_(input, proc.parameters['@ovarchar'])
