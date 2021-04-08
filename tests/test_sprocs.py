# -*- coding: utf-8 -*-
"""
Test stored procedure usage.
"""

import decimal
import datetime
import os
import sys
import unittest

import pymssql
from pymssql import _mssql

import pytest

from .helpers import mssqlconn, pymssqlconn, eq_, skip_test, get_sql_server_version, mssql_server_required

FIXED_TYPES = (
    'BigInt',
    'Bit',
    'DateTime',
    'Decimal',
    'Int',
    'Money',
    'Numeric',
    'SmallInt',
    'TinyInt',
    'UniqueIdentifier',
    'Real',
    'Float'
)

VARIABLE_TYPES = (
    ('Char', 4),
    ('VarChar', 4),
    ('VarBinary', 4),
    ('Text', None)  # Leave this one in the last position in case it fails (see https://code.google.com/p/pymssql/issues/detail?id=113#c2)
)

@mssql_server_required
class TestFixedTypeConversion(unittest.TestCase):

    def setUp(self):
        self.mssql = mssqlconn()
        self.pymssql = pymssqlconn()

        for name in FIXED_TYPES:
            dbtype = name.lower()
            if dbtype == 'decimal':
                identifier = 'decimal(6, 5)'
            elif dbtype == 'numeric':
                identifier = 'numeric(6, 5)'
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

        self.pymssql.close()
        self.mssql.close()


    def testBigInt(self):
        input = 123456789
        proc = self.mssql.init_procedure('pymssqlTestBigInt')
        proc.bind(input, _mssql.SQLINT8, '@ibigint')
        proc.bind(None, _mssql.SQLINT8, '@obigint', output=True)
        proc.execute()
        eq_(input, proc.parameters['@obigint'])

    def testBigIntPymssql(self):
        """Same as testBigInt above but from pymssql. Uses pymssql.output class."""

        if sys.version_info >= (3, ):
            py_type = int
        else:
            py_type = long

        in_val = 123456789
        cursor = self.pymssql.cursor()
        retval = cursor.callproc('pymssqlTestBigInt', [in_val, pymssql.output(py_type)])
        eq_(in_val, retval[1])

        in_val = 2147483647
        retval = cursor.callproc('pymssqlTestBigInt', [in_val, pymssql.output(py_type)])
        eq_(in_val, retval[1])

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
        output = decimal.Decimal('0.00000')
        proc = self.mssql.init_procedure('pymssqlTestDecimal')
        proc.bind(input, _mssql.SQLDECIMAL, '@idecimal')
        proc.bind(output, _mssql.SQLDECIMAL, '@odecimal', output=True, max_length=6)
        proc.execute()
        eq_(input, proc.parameters['@odecimal'])
        eq_(str(input), str(proc.parameters['@odecimal']))

    def testDecimal2(self):
        input = decimal.Decimal('6.23456')
        output = decimal.Decimal('0.00000')
        proc = self.mssql.init_procedure('pymssqlTestDecimal')
        proc.bind(input, _mssql.SQLDECIMAL, '@idecimal')
        proc.bind(output, _mssql.SQLDECIMAL, '@odecimal', output=True, max_length=6)
        proc.execute()
        eq_(input, proc.parameters['@odecimal'])
        eq_(str(input), str(proc.parameters['@odecimal']))

    def testDecimal3(self):
        output = decimal.Decimal('0.00000')
        proc = self.mssql.init_procedure('pymssqlTestDecimal')
        input = decimal.Decimal('6.23400')
        proc.bind(input, _mssql.SQLDECIMAL, '@idecimal')
        proc.bind(output, _mssql.SQLDECIMAL, '@odecimal', output=True, max_length=6)
        proc.execute()
        eq_(input, proc.parameters['@odecimal'])
        eq_(str(input), str(proc.parameters['@odecimal']))

    def testDecimal4(self):
        output = decimal.Decimal('1.0000000')
        proc = self.mssql.init_procedure('pymssqlTestDecimal')
        input = decimal.Decimal('6.2340000')
        proc.bind(input, _mssql.SQLDECIMAL, '@idecimal')
        proc.bind(output, _mssql.SQLDECIMAL, '@odecimal', output=True, max_length=15)
        proc.execute()
        eq_(input, proc.parameters['@odecimal'])
        eq_(str(input), str(proc.parameters['@odecimal']))

    def testDecimal5(self):
        output = decimal.Decimal('1.000000000')
        proc = self.mssql.init_procedure('pymssqlTestDecimal')
        input = decimal.Decimal('6.234000000')
        proc.bind(input, _mssql.SQLDECIMAL, '@idecimal')
        proc.bind(output, _mssql.SQLDECIMAL, '@odecimal', output=True, max_length=15)
        proc.execute()
        eq_(input, proc.parameters['@odecimal'])
        eq_(str(input), str(proc.parameters['@odecimal']))

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
        output = decimal.Decimal('0.00000')
        proc = self.mssql.init_procedure('pymssqlTestNumeric')
        proc.bind(input, _mssql.SQLNUMERIC, '@inumeric')
        proc.bind(output, _mssql.SQLNUMERIC, '@onumeric', output=True)
        proc.execute()
        eq_(input, proc.parameters['@onumeric'])
        eq_(str(input), str(proc.parameters['@onumeric']))

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

    def testUuid(self):
        if os.environ.get('FREETDS_VERSION') != '0.91':
            pytest.xfail("UNIQUEIDENTIFIER as a SP param doesn't work with FreeTDS >= 0.95")
        import uuid
        input = uuid.uuid4()
        proc = self.mssql.init_procedure('pymssqlTestUniqueIdentifier')
        proc.bind(input, _mssql.SQLUUID, '@iuniqueidentifier')
        proc.bind(None, _mssql.SQLUUID, '@ouniqueidentifier', output=True)
        proc.execute()
        eq_(input, proc.parameters['@ouniqueidentifier'])

    def testReal(self):
        input = 3.14
        proc = self.mssql.init_procedure('pymssqlTestReal')
        proc.bind(input, _mssql.SQLREAL, '@ireal')
        proc.bind(None, _mssql.SQLREAL, '@oreal', output=True)
        proc.execute()
        assert abs(input - proc.parameters['@oreal']) < 0.00001

    def testFloat8(self):
        input = 3.40E38 + 1
        proc = self.mssql.init_procedure('pymssqlTestFloat')
        proc.bind(input, _mssql.SQLFLT8, '@ifloat')
        proc.bind(None, _mssql.SQLFLT8, '@ofloat', output=True)
        proc.execute()
        assert abs(input - proc.parameters['@ofloat']) < 0.00001


@mssql_server_required
class TestCallProcFancy(unittest.TestCase):
    # "Fancy" because we test some exotic cases like passing None or Unicode
    # strings to a called procedure

    def setUp(self):
        self.pymssql = pymssqlconn()
        cursor = self.pymssql.cursor()

        sql = u"""
        CREATE PROCEDURE [dbo].[someProcWithOneParam]
        	@some_arg NVARCHAR(64)
        AS
        BEGIN
        	SELECT @some_arg + N'!',
                   N'%(str1)s ' + @some_arg + N' %(str2)s'
        END
        """ % {
            'str1': u'\u0417\u0434\u0440\u0430\u0432\u0441\u0442\u0432\u0443\u0439',
            'str2': u'\u041c\u0438\u0440',
        }
        sql = sql.encode('utf-8')

        cursor.execute(sql)

    def tearDown(self):
        cursor = self.pymssql.cursor()
        cursor.execute('DROP PROCEDURE [dbo].[someProcWithOneParam]')
        self.pymssql.close()

    def testCallProcWithNone(self):
        cursor = self.pymssql.cursor()
        cursor.callproc(
            'someProcWithOneParam',
            (None,))

        # For some reason, fetchone doesn't work
        # It raises "OperationalError: Statement not executed or executed statement has no resultset"
        # a, b = cursor.fetchone()

        for a, b in cursor:
            eq_(a, None)
            eq_(b, None)

    def testCallProcWithAsciiString(self):
        cursor = self.pymssql.cursor()
        cursor.callproc(
            'someProcWithOneParam',
            ('hello',))

        # For some reason, fetchone doesn't work
        # It raises "OperationalError: Statement not executed or executed statement has no resultset"
        # a, b = cursor.fetchone()

        for a, b in cursor:
            eq_(a, 'hello!')
            eq_(b, u'\u0417\u0434\u0440\u0430\u0432\u0441\u0442\u0432\u0443\u0439 hello \u041c\u0438\u0440')

    def testCallProcWithUnicodeStringWithNoFunnyCharacters(self):
        cursor = self.pymssql.cursor()
        cursor.callproc(
            'someProcWithOneParam',
            (u'hello',))

        # For some reason, fetchone doesn't work
        # It raises "OperationalError: Statement not executed or executed statement has no resultset"
        # a, b = cursor.fetchone()

        for a, b in cursor:
            eq_(a, u'hello!')
            eq_(b, u'\u0417\u0434\u0440\u0430\u0432\u0441\u0442\u0432\u0443\u0439 hello \u041c\u0438\u0440')

    # This is failing for me - the Unicode params somehow gets rendered to a
    # blank string. I am not sure if this is another bug or a user error on my
    # part...?
    #
    def testCallProcWithUnicodeStringWithRussianCharacters(self):
        cursor = self.pymssql.cursor()
        cursor.callproc(
            'someProcWithOneParam',
            (u'\u0417\u0434\u0440\u0430\u0432\u0441\u0442\u0432\u0443\u0439',))  # Russian string

        # For some reason, fetchone doesn't work
        # It raises "OperationalError: Statement not executed or executed statement has no resultset"
        # a, b = cursor.fetchone()

        # This test fails with FreeTDS 0.91 (and probably older versions)
        # because they don't seem to encode the Unicode string properly.
        # See http://code.google.com/p/pymssql/issues/detail?id=109
        skip_test()

        for a, b in cursor:
            eq_(a, u'\u0417\u0434\u0440\u0430\u0432\u0441\u0442\u0432\u0443\u0439!')
            eq_(b, u'\u0417\u0434\u0440\u0430\u0432\u0441\u0442\u0432\u0443\u0439 \u0417\u0434\u0440\u0430\u0432\u0441\u0442\u0432\u0443\u0439 \u041c\u0438\u0440')

    def testExecuteWithNone(self):
        cursor = self.pymssql.cursor()
        cursor.execute(
            u'someProcWithOneParam %s',
            (None,))

        a, b = cursor.fetchone()

        eq_(a, None)
        eq_(b, None)

    def testExecuteWithAsciiString(self):
        cursor = self.pymssql.cursor()
        cursor.execute(
            u'someProcWithOneParam %s',
            ('hello',))

        a, b = cursor.fetchone()

        eq_(a, 'hello!')
        eq_(b, u'\u0417\u0434\u0440\u0430\u0432\u0441\u0442\u0432\u0443\u0439 hello \u041c\u0438\u0440')

    def testExecuteWithUnicodeStringWithNoFunnyCharacters(self):
        cursor = self.pymssql.cursor()
        cursor.execute(
            u'someProcWithOneParam %s',
            (u'hello',))

        a, b = cursor.fetchone()

        eq_(a, u'hello!')
        eq_(b, u'\u0417\u0434\u0440\u0430\u0432\u0441\u0442\u0432\u0443\u0439 hello \u041c\u0438\u0440')

    def testExecuteWithUnicodeWithRussianCharacters(self):
        cursor = self.pymssql.cursor()
        cursor.execute(
            u'someProcWithOneParam %s',
            (u'\u0417\u0434\u0440\u0430\u0432\u0441\u0442\u0432\u0443\u0439',))  # Russian string

        a, b = cursor.fetchone()

        eq_(a, u'\u0417\u0434\u0440\u0430\u0432\u0441\u0442\u0432\u0443\u0439!')
        eq_(b, u'\u0417\u0434\u0440\u0430\u0432\u0441\u0442\u0432\u0443\u0439 \u0417\u0434\u0440\u0430\u0432\u0441\u0442\u0432\u0443\u0439 \u041c\u0438\u0440')



@mssql_server_required
class TestStringTypeConversion(unittest.TestCase):

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

    def testVarBinary(self):
        def check_conversion(input, output_type):
            proc = self.mssql.init_procedure('pymssqlTestVarBinary')
            proc.bind(input, _mssql.SQLVARBINARY, '@ivarbinary')
            proc.bind(None, _mssql.SQLVARBINARY, '@ovarbinary', output=True)
            proc.execute()
            eq_(input, proc.parameters['@ovarbinary'])
            eq_(output_type, type(proc.parameters['@ovarbinary']))

        if sys.version_info[0] == 3:
            check_conversion(bytes(b'\xDE\xAD\xBE\xEF'), bytes)
            check_conversion(bytearray(b'\xDE\xAD\xBE\xEF'), bytes)
            with pytest.raises(TypeError) as exc_info:
                check_conversion('FOO', bytes)
                assert 'value can only be bytes or bytearray' == str(exc_info.value)
        else:
            check_conversion(b'\xDE\xAD\xBE\xEF', str)
            check_conversion(bytes(b'\xDE\xAD\xBE\xEF'), str)
            check_conversion(bytearray(b'\xDE\xAD\xBE\xEF'), str)
            with pytest.raises(TypeError) as exc_info:
                check_conversion(unicode('Foo'), str)
                assert 'value can only be str or bytearray' == str(exc_info.value)


@mssql_server_required
class TestFloatTypeConversion(unittest.TestCase):
    def setUp(self):
        self.mssql = mssqlconn()
        self.pymssql = pymssqlconn()
        cursor = self.pymssql.cursor()

        self.mssql.execute_non_query("""
            CREATE PROCEDURE [dbo].[pymssqlRealTest]
                @inparam real
            AS
            BEGIN
                SELECT @inparam AS outparam
            END
            """
        )

        self.mssql.execute_non_query("""
            CREATE PROCEDURE [dbo].[pymssqlFloatTest]
                @inparam float
            AS
            BEGIN
                SELECT @inparam AS outparam
            END
            """
        )

    def tearDown(self):
        cursor = self.pymssql.cursor()
        self.mssql.execute_non_query('DROP PROCEDURE [dbo].[pymssqlRealTest]')
        self.mssql.execute_non_query('DROP PROCEDURE [dbo].[pymssqlFloatTest]')
        self.pymssql.close()

    def testReal(self):
        cursor = self.pymssql.cursor()
        cursor.callproc(
            'pymssqlRealTest',
            (0.5,))

        # TODO: Use the solution we implement once #134 gets fixed
        a = next(cursor)
        assert abs(a[0] - 0.5) < 0.000001

    def testFloat8(self):
        cursor = self.pymssql.cursor()
        cursor.callproc(
            'pymssqlFloatTest',
            (5.44451787074e+39,))

        # TODO: Use the solution we implement once #134 gets fixed
        a = next(cursor)
        assert abs(a[0] - 5.44451787074e+39) < 0.000001

@mssql_server_required
class TestErrorInSP(unittest.TestCase):

    def setUp(self):
        self.pymssql = pymssqlconn()
        cursor = self.pymssql.cursor()

        sql = u"""
        CREATE PROCEDURE [dbo].[SPThatRaisesAnError]
        AS
        BEGIN
            -- RAISERROR -- Generates an error message and initiates error processing for the session.
            -- http://msdn.microsoft.com/en-us/library/ms178592.aspx
            -- Severity levels from 0 through 18 can be specified by any user.
            RAISERROR('Error message', 18, 1)
            RETURN
        END
        """
        cursor.execute(sql)

    def tearDown(self):
        cursor = self.pymssql.cursor()
        cursor.execute('DROP PROCEDURE [dbo].[SPThatRaisesAnError]')
        self.pymssql.close()

    def test_tsql_to_python_exception_translation(self):
        """An error raised by a SP is translated to a PEP-249-dictated, pymssql layer exception."""
        # See https://github.com/pymssql/pymssql/issues/61
        cursor = self.pymssql.cursor()
        # Must raise an exception
        self.assertRaises(Exception, cursor.callproc, 'SPThatRaisesAnError')
        # Must be a PEP-249 exception, not a _mssql-layer one
        try:
            cursor.callproc('SPThatRaisesAnError')
        except Exception as e:
            self.assertTrue(isinstance(e,  pymssql.Error))
        # Must be a DatabaseError exception
        try:
            cursor.callproc('SPThatRaisesAnError')
        except Exception as e:
            self.assertTrue(isinstance(e,  pymssql.DatabaseError))


@mssql_server_required
class TestSPWithQueryResult(unittest.TestCase):

    SP_NAME = 'SPWithAQuery'

    def setUp(self):
        self.mssql = mssqlconn()
        self.pymssql = pymssqlconn()

        self.mssql.execute_non_query("""
        CREATE PROCEDURE [dbo].[%(spname)s]
                @some_arg NVARCHAR(64)
        AS
        BEGIN
                SELECT @some_arg + N'!', @some_arg + N'!!'
        END
        """ % {'spname': self.SP_NAME})

    def tearDown(self):
        self.mssql.execute_non_query('DROP PROCEDURE [dbo].[%(spname)s]' % {'spname': self.SP_NAME})
        self.pymssql.close()
        self.mssql.close()

    def testPymssql(self):
        cursor = self.pymssql.cursor()
        cursor.callproc(
            self.SP_NAME,
            ('hello',))

        # For some reason, fetchone doesn't work
        # It raises "OperationalError: Statement not executed or executed statement has no resultset"
        #a, b = cursor.fetchone()

        for a, b in cursor:
            eq_(a, 'hello!')
            eq_(b, 'hello!!')

    def test_mssql(self):
        proc = self.mssql.init_procedure(self.SP_NAME)
        proc.bind('hello', _mssql.SQLVARCHAR)
        proc.execute()

        for row_dict in self.mssql:
            eq_(row_dict, {0: 'hello!', 1: 'hello!!'})
