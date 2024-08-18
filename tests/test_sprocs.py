# -*- coding: utf-8 -*-
"""
Test stored procedure usage.
"""

from contextlib import contextmanager
import decimal
import datetime
import os
import unittest

import pymssql
from pymssql import _mssql

import pytest

from .helpers import mssqlconn, pymssqlconn


@contextmanager
def stored_proc(mssqlcon, dbtype):

    dbtype = dbtype.lower()
    identifier = dbtype
    if dbtype == 'decimal':
        identifier = 'decimal(6, 5)'
    elif dbtype == 'numeric':
        identifier = 'numeric(6, 5)'
    elif dbtype == 'time':
        identifier = 'time(7)'
    elif dbtype == 'datetimeoffset':
        identifier = 'datetimeoffset(7)'

    name = f"pymssqlTest_{dbtype}"

    cmd = f"""
        CREATE PROCEDURE [dbo].[{name}]
            @inp {identifier},
            @out {identifier} output
        AS
        BEGIN
            SET @out = @inp;
            RETURN 0;
        END
    """
    mssqlcon.execute_non_query(cmd)

    try:
        yield name
    finally:
        # Code to release resource, e.g.:
        mssqlcon.execute_non_query(f'DROP PROCEDURE [dbo].[{name}]')


FIXED_TYPES = (
    'BigInt',
    'Bit',
    'Date',
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

@pytest.mark.mssql_server_required
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

    def testBigIntNullIn(self):
        input = None
        proc = self.mssql.init_procedure('pymssqlTestBigInt')
        proc.bind(input, _mssql.SQLINT8, '@ibigint', null=True)
        proc.bind(None, _mssql.SQLINT8, '@obigint', output=True)
        proc.execute()
        self.assertEqual(input, proc.parameters['@obigint'])

    def testBigInt(self):
        input = 123456789
        proc = self.mssql.init_procedure('pymssqlTestBigInt')
        proc.bind(input, _mssql.SQLINT8, '@ibigint')
        proc.bind(None, _mssql.SQLINT8, '@obigint', output=True)
        proc.execute()
        self.assertEqual(input, proc.parameters['@obigint'])

    def testBigIntPymssql(self):
        """Same as testBigInt above but from pymssql. Uses pymssql.output class."""
        in_val = 123456789
        cursor = self.pymssql.cursor()
        retval = cursor.callproc('pymssqlTestBigInt', [in_val, pymssql.output(int)])
        self.assertEqual(in_val, retval[1])

        in_val = 2147483647
        retval = cursor.callproc('pymssqlTestBigInt', [in_val, pymssql.output(int)])
        self.assertEqual(in_val, retval[1])

    def testBit(self):
        input = True
        proc = self.mssql.init_procedure('pymssqlTestBit')
        proc.bind(input, _mssql.SQLBITN, '@ibit')
        proc.bind(False, _mssql.SQLBITN, '@obit', output=True)
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
        output = decimal.Decimal('0.00000')
        proc = self.mssql.init_procedure('pymssqlTestDecimal')
        proc.bind(input, _mssql.SQLDECIMAL, '@idecimal')
        proc.bind(output, _mssql.SQLDECIMAL, '@odecimal', output=True, max_length=6)
        proc.execute()
        self.assertEqual(input, proc.parameters['@odecimal'])
        self.assertEqual(str(input), str(proc.parameters['@odecimal']))

    def testDecimal2(self):
        input = decimal.Decimal('6.23456')
        output = decimal.Decimal('0.00000')
        proc = self.mssql.init_procedure('pymssqlTestDecimal')
        proc.bind(input, _mssql.SQLDECIMAL, '@idecimal')
        proc.bind(output, _mssql.SQLDECIMAL, '@odecimal', output=True, max_length=6)
        proc.execute()
        self.assertEqual(input, proc.parameters['@odecimal'])
        self.assertEqual(str(input), str(proc.parameters['@odecimal']))

    def testDecimal3(self):
        output = decimal.Decimal('0.00000')
        proc = self.mssql.init_procedure('pymssqlTestDecimal')
        input = decimal.Decimal('6.23400')
        proc.bind(input, _mssql.SQLDECIMAL, '@idecimal')
        proc.bind(output, _mssql.SQLDECIMAL, '@odecimal', output=True, max_length=6)
        proc.execute()
        self.assertEqual(input, proc.parameters['@odecimal'])
        self.assertEqual(str(input), str(proc.parameters['@odecimal']))

    def testDecimal4(self):
        output = decimal.Decimal('1.0000000')
        proc = self.mssql.init_procedure('pymssqlTestDecimal')
        input = decimal.Decimal('6.2340000')
        proc.bind(input, _mssql.SQLDECIMAL, '@idecimal')
        proc.bind(output, _mssql.SQLDECIMAL, '@odecimal', output=True, max_length=15)
        proc.execute()
        self.assertEqual(input, proc.parameters['@odecimal'])
        self.assertEqual(str(input), str(proc.parameters['@odecimal']))

    def testDecimal5(self):
        output = decimal.Decimal('1.000000000')
        proc = self.mssql.init_procedure('pymssqlTestDecimal')
        input = decimal.Decimal('6.234000000')
        proc.bind(input, _mssql.SQLDECIMAL, '@idecimal')
        proc.bind(output, _mssql.SQLDECIMAL, '@odecimal', output=True, max_length=15)
        proc.execute()
        self.assertEqual(input, proc.parameters['@odecimal'])
        self.assertEqual(str(input), str(proc.parameters['@odecimal']))

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
        output = decimal.Decimal('0.00000')
        proc = self.mssql.init_procedure('pymssqlTestNumeric')
        proc.bind(input, _mssql.SQLNUMERIC, '@inumeric')
        proc.bind(output, _mssql.SQLNUMERIC, '@onumeric', output=True)
        proc.execute()
        self.assertEqual(input, proc.parameters['@onumeric'])
        self.assertEqual(str(input), str(proc.parameters['@onumeric']))

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

    def testUuid(self):
        if os.environ.get('FREETDS_VERSION') != '0.91':
            pytest.skip("UNIQUEIDENTIFIER as a SP param doesn't work with FreeTDS >= 0.95")
        import uuid
        input = uuid.uuid4()
        proc = self.mssql.init_procedure('pymssqlTestUniqueIdentifier')
        proc.bind(input, _mssql.SQLUUID, '@iuniqueidentifier')
        proc.bind(None, _mssql.SQLUUID, '@ouniqueidentifier', output=True)
        proc.execute()
        self.assertEqual(input, proc.parameters['@ouniqueidentifier'])

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


@pytest.mark.mssql_server_required
class TestDateTimeConversion:

    def test_date(self, mssql_conn, subtests):
        with stored_proc(mssql_conn, 'date') as proc_name:
            for input in (
                datetime.date(1, 1, 1), # min supported
                datetime.date(90, 8, 27), # GH #454
                datetime.date(906, 8, 27), # GH #454
                datetime.date(2009, 8, 27),
                datetime.date(9999, 12, 31), # max supported
                ):
                with subtests.test(date=input):
                    proc = mssql_conn.init_procedure(proc_name)
                    proc.bind(input, _mssql.SQLDATE, '@inp')
                    proc.bind(None, _mssql.SQLDATE, '@out', output=True)
                    res = proc.execute()
                    assert res == 0
                    assert input == proc.parameters['@out']

    def test_time(self, mssql_conn, subtests):
        with stored_proc(mssql_conn, 'time') as proc_name:
            for input in (
                datetime.time(0, 0, 0), # min supported
                datetime.time(23, 59, 59, 0),
                datetime.time(23, 59, 59, 999999), # max supported
                ):
                with subtests.test(time=input):
                    proc = mssql_conn.init_procedure(proc_name)
                    proc.bind(input, _mssql.SQLTIME, '@inp')
                    proc.bind(None, _mssql.SQLTIME, '@out', output=True)
                    res = proc.execute()
                    assert res == 0
                    assert input == proc.parameters['@out']

    def test_datetime(self, mssql_conn, subtests):
        with stored_proc(mssql_conn, 'datetime') as proc_name:
            for input in (
                datetime.datetime(1753, 1, 1), # min supported
                datetime.datetime(2009, 8, 27),
                datetime.datetime(2009, 8, 27, 23, 59, 59, 997000),
                datetime.datetime(9999, 12, 31, 23, 59, 59, 997000), # max supported
                ):
                with subtests.test(datetime=input):
                    proc = mssql_conn.init_procedure(proc_name)
                    proc.bind(input, _mssql.SQLDATETIME, '@inp')
                    proc.bind(None, _mssql.SQLDATETIME, '@out', output=True)
                    res = proc.execute()
                    assert res == 0
                    assert input == proc.parameters['@out']

    def test_datetime2(self, mssql_conn, subtests):
        with stored_proc(mssql_conn, 'datetime2') as proc_name:
            for input in (
                datetime.datetime(1, 1, 1), # min supported
                datetime.datetime(90, 8, 27),
                datetime.datetime(906, 8, 27),
                datetime.datetime(2009, 8, 27),
                datetime.datetime(2009, 8, 27, 23, 59, 59, 999999),
                datetime.datetime(9999, 12, 31, 23, 59, 59, 999999), # max supported
                ):
                with subtests.test(datetime=input):
                    proc = mssql_conn.init_procedure(proc_name)
                    proc.bind(input, _mssql.SQLDATETIME2, '@inp')
                    proc.bind(None, _mssql.SQLDATETIME2, '@out', output=True)
                    res = proc.execute()
                    assert res == 0
                    assert input == proc.parameters['@out']

    def test_datetimeoffset(self, mssql_conn, subtests):
        with stored_proc(mssql_conn, 'datetimeoffset') as proc_name:
            for h in range(-12,13,1):
                for m in range(0, 61, 15):
                    tz = datetime.timezone(datetime.timedelta(hours=h, minutes=m))
                    for input in (
                        datetime.datetime(10, 1, 2, tzinfo=tz), # min supported
                        datetime.datetime(2999, 12, 31, 23, 59, 59, 999999, tzinfo=tz), # max supported
                        ):
                        with subtests.test(datetime=input):
                            proc = mssql_conn.init_procedure(proc_name)
                            proc.bind(input, _mssql.SQLDATETIMEOFFSET, '@inp')
                            proc.bind(None, _mssql.SQLDATETIMEOFFSET, '@out', output=True)
                            res = proc.execute()
                            assert res == 0
                            assert input == proc.parameters['@out']


@pytest.mark.mssql_server_required
class TestCallProcFancy(unittest.TestCase):
    """
    "Fancy" because we test some exotic cases like passing None or Unicode
    # strings to a called procedure
    """

    def setUp(self):
        self.pymssql = pymssqlconn()
        cursor = self.pymssql.cursor()

        sql = """
        CREATE PROCEDURE [dbo].[someProcWithOneParam]
            @some_arg NVARCHAR(64)
        AS
        BEGIN
            SELECT @some_arg + N'!',
                   N'%(str1)s ' + @some_arg + N' %(str2)s'
        END
        """ % {
            'str1': 'Здравствуй',
            'str2': 'Мир',
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

        a, b = cursor.fetchone()
        self.assertEqual(a, None)
        self.assertEqual(b, None)

    def testCallProcWithAsciiString(self):
        cursor = self.pymssql.cursor()
        cursor.callproc(
            'someProcWithOneParam',
            ('hello',))

        a, b = cursor.fetchone()
        self.assertEqual(a, 'hello!')
        self.assertEqual(b, 'Здравствуй hello Мир')

    def testCallProcWithUnicodeStringWithNoFunnyCharacters(self):
        cursor = self.pymssql.cursor()
        cursor.callproc(
            'someProcWithOneParam',
            ('hello',))

        a, b = cursor.fetchone()
        self.assertEqual(a, 'hello!')
        self.assertEqual(b, 'Здравствуй hello Мир')

    # This is failing for me - the Unicode params somehow gets rendered to a
    # blank string. I am not sure if this is another bug or a user error on my
    # part...?
    #
    def testCallProcWithUnicodeStringWithRussianCharacters(self):
        cursor = self.pymssql.cursor()
        cursor.callproc(
            'someProcWithOneParam',
            ('Здравствуй',))  # Russian string

        a, b = cursor.fetchone()
        self.assertEqual(a, 'Здравствуй!')
        self.assertEqual(b, 'Здравствуй Здравствуй Мир')

    def testExecuteWithNone(self):
        cursor = self.pymssql.cursor()
        cursor.execute(
            'someProcWithOneParam %s',
            (None,))

        a, b = cursor.fetchone()
        self.assertEqual(a, None)
        self.assertEqual(b, None)

    def testExecuteWithAsciiString(self):
        cursor = self.pymssql.cursor()
        cursor.execute(
            'someProcWithOneParam %s',
            ('hello',))

        a, b = cursor.fetchone()
        self.assertEqual(a, 'hello!')
        self.assertEqual(b, 'Здравствуй hello Мир')

    def testExecuteWithUnicodeStringWithNoFunnyCharacters(self):
        cursor = self.pymssql.cursor()
        cursor.execute(
            'someProcWithOneParam %s',
            ('hello',))

        a, b = cursor.fetchone()
        self.assertEqual(a, 'hello!')
        self.assertEqual(b, 'Здравствуй hello Мир')

    def testExecuteWithUnicodeWithRussianCharacters(self):
        cursor = self.pymssql.cursor()
        cursor.execute(
            'someProcWithOneParam %s',
            ('Здравствуй',))  # Russian string

        a, b = cursor.fetchone()
        self.assertEqual(a, 'Здравствуй!')
        self.assertEqual(b, 'Здравствуй Здравствуй Мир')



@pytest.mark.mssql_server_required
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

    def testVarBinary(self):
        def check_conversion(input, output_type):
            proc = self.mssql.init_procedure('pymssqlTestVarBinary')
            proc.bind(input, _mssql.SQLVARBINARY, '@ivarbinary')
            proc.bind(None, _mssql.SQLVARBINARY, '@ovarbinary', output=True)
            proc.execute()
            self.assertEqual(input, proc.parameters['@ovarbinary'])
            self.assertEqual(output_type, type(proc.parameters['@ovarbinary']))

        check_conversion(bytes(b'\xDE\xAD\xBE\xEF'), bytes)
        check_conversion(bytearray(b'\xDE\xAD\xBE\xEF'), bytes)
        with pytest.raises(TypeError) as exc_info:
            check_conversion('FOO', bytes)
            assert 'value can only be bytes or bytearray' == str(exc_info.value)


@pytest.mark.mssql_server_required
class TestFloatTypeConversion(unittest.TestCase):

    def setUp(self):
        self.mssql = mssqlconn()
        self.pymssql = pymssqlconn()
        self.cursor = self.pymssql.cursor()

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
        self.mssql.execute_non_query('DROP PROCEDURE [dbo].[pymssqlRealTest]')
        self.mssql.execute_non_query('DROP PROCEDURE [dbo].[pymssqlFloatTest]')
        self.mssql.close()
        self.cursor.close()
        self.pymssql.close()

    def test_real(self):
        self.cursor.callproc('pymssqlRealTest', (0.5,))
        a = next(self.cursor)
        assert len(a) == 1
        assert abs(a[0] - 0.5) < 0.000001

    def test_float8(self):
        self.cursor.callproc('pymssqlFloatTest', (5.44451787074e+39,))
        a = next(self.cursor)
        assert len(a) == 1
        assert abs(a[0] - 5.44451787074e+39) < 0.000001


@pytest.mark.mssql_server_required
class TestFetch(unittest.TestCase):

    def setUp(self):
        self.pymssql = pymssqlconn()
        self.cursor = self.pymssql.cursor()

        self.cursor.execute("""
            CREATE PROCEDURE [dbo].[pymssqlTest]
                @inparam real
            AS
            BEGIN
                SELECT @inparam AS outparam
            END
            """
        )

    def tearDown(self):
        self.cursor.execute('DROP PROCEDURE [dbo].[pymssqlTest]')
        self.cursor.close()
        self.pymssql.close()

    def test_fetchall(self):
        self.cursor.callproc('pymssqlTest', (0.5,))
        a = self.cursor.fetchall()
        assert len(a) == 1
        assert len(a[0]) == 1
        assert abs(a[0][0] - 0.5) < 0.000001

    def test_fetchone(self):
        self.cursor.callproc('pymssqlTest', (0.5,))
        a = self.cursor.fetchone()
        assert len(a) == 1
        assert abs(a[0] - 0.5) < 0.000001

    def test_fetchmany(self):
        self.cursor.callproc('pymssqlTest', (0.5,))
        a = self.cursor.fetchmany()
        assert len(a) == 1
        assert len(a[0]) == 1
        assert abs(a[0][0] - 0.5) < 0.000001

    def test_real_next(self):
        self.cursor.callproc('pymssqlTest', (0.5,))
        a = next(self.cursor)
        assert len(a) == 1
        assert abs(a[0] - 0.5) < 0.000001


@pytest.mark.mssql_server_required
class TestErrorInSP(unittest.TestCase):

    def setUp(self):
        self.pymssql = pymssqlconn()
        self.cursor = self.pymssql.cursor()

        sql = """
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
        self.cursor.execute(sql)

    def tearDown(self):
        self.cursor.execute('DROP PROCEDURE [dbo].[SPThatRaisesAnError]')
        self.cursor.close()
        self.pymssql.close()

    def test_tsql_to_python_exception_translation(self):
        """
        An error raised by a SP is translated to a PEP-249-dictated,
        pymssql layer exception.
        See https://github.com/pymssql/pymssql/issues/61
        """
        # Must raise an exception
        self.assertRaises(Exception, self.cursor.callproc, 'SPThatRaisesAnError')
        # Must be a PEP-249 exception, not a _mssql-layer one
        try:
            self.cursor.callproc('SPThatRaisesAnError')
        except Exception as e:
            self.assertTrue(isinstance(e,  pymssql.Error))
        # Must be a DatabaseError exception
        try:
            self.cursor.callproc('SPThatRaisesAnError')
        except Exception as e:
            self.assertTrue(isinstance(e,  pymssql.DatabaseError))


@pytest.mark.mssql_server_required
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

    def test_pymssql(self):
        cursor = self.pymssql.cursor()
        cursor.callproc(
            self.SP_NAME,
            ('hello',))

        a, b = cursor.fetchone()
        self.assertEqual(a, 'hello!')
        self.assertEqual(b, 'hello!!')

    def test_mssql(self):
        proc = self.mssql.init_procedure(self.SP_NAME)
        proc.bind('hello', _mssql.SQLVARCHAR)
        proc.execute()

        for row_dict in self.mssql:
            self.assertEqual(row_dict, {0: 'hello!', 1: 'hello!!'})


@pytest.mark.mssql_server_required
class TestMultipleDataSetsInResult(unittest.TestCase):
    """
    Test for https://github.com/pymssql/pymssql/pull/134
    See also https://gist.github.com/msabramo/6747703
    """
    table_name = 'callproc_demo_tbl'
    proc_name = 'callproc_get_2_resultsets'

    def setUp(self):
        self.pymssql = pymssqlconn()
        self.cursor = self.pymssql.cursor()
        self.cursor.execute(f"IF OBJECT_ID('{self.table_name}', 'U') IS NOT NULL DROP TABLE {self.table_name}")
        self.cursor.execute(f"CREATE TABLE {self.table_name} (name VARCHAR(30))")
        self.cursor.execute(f"INSERT INTO {self.table_name} VALUES ('Tom'), ('Dick'), ('Harry')")
        self.cursor.execute(f"""
        CREATE PROCEDURE [dbo].[{self.proc_name}] AS
        BEGIN
            SET NOCOUNT ON
            SELECT * FROM {self.table_name} WHERE name = 'not here';
            SELECT * FROM {self.table_name};
        END
        """)

    def tearDown(self):
        self.cursor.execute(f'DROP PROCEDURE [dbo].[{self.proc_name}]')
        self.cursor.close()
        self.pymssql.close()

    def test_exec(self):
        self.cursor.execute(f'EXEC {self.proc_name}')
        res = self.cursor.fetchall()
        self.assertEqual(res, [])
        res = self.cursor.fetchall()
        self.assertEqual(res, [('Tom',), ('Dick',), ('Harry',)])

    @pytest.mark.xfail(strict=True)
    def test_callproc(self):
        self.cursor.callproc(self.proc_name)
        res = self.cursor.fetchall()
        self.assertEqual(res, [])
        res = self.cursor.fetchall()
        self.assertEqual(res, [('Tom',), ('Dick',), ('Harry',)])


@pytest.mark.mssql_server_required
class TestSPWithNULLResult(unittest.TestCase):
    """
    GH: #441
    """

    SP_NAME = 'SPWithANullResult'

    def setUp(self):
        self.mssql = mssqlconn()
        self.pymssql = pymssqlconn()

        self.mssql.execute_non_query("""
        CREATE PROCEDURE [dbo].[%(spname)s]
                @int_arg int output,
                @varchar_arg varchar output
        AS
        BEGIN
                SET @int_arg = null
                SET @varchar_arg = null
        END
        """ % {'spname': self.SP_NAME})

    def tearDown(self):
        self.mssql.execute_non_query('DROP PROCEDURE [dbo].[%(spname)s]' % {'spname': self.SP_NAME})
        self.pymssql.close()
        self.mssql.close()

    def testNull(self):
        proc = self.mssql.init_procedure(self.SP_NAME)
        proc.bind(None, _mssql.SQLINT8, '@int_arg', output=True)
        proc.bind(None, _mssql.SQLVARCHAR, '@varchar_arg', output=True)
        proc.execute()
        self.assertIsNone(proc.parameters['@int_arg'])
        self.assertIsNone(proc.parameters['@varchar_arg'])

