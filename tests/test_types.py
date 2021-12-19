# -*- coding: utf-8 -*-
import binascii
from datetime import time
from datetime import date
from datetime import datetime
import decimal
from decimal import Decimal as D
from hashlib import md5
import pickle
import sys
import unittest
import uuid

import pymssql
from .helpers import get_sql_server_version, mssql_server_required

import pytest


def get_bytes_buffer():
    from io import BytesIO
    return BytesIO()

from .helpers import drop_table, mssqlconn, clear_table, config, eq_, pymssqlconn


def typeeq(v1, v2):
    eq_(type(v1), type(v2))

create_test_table_sql = [
    'CREATE TABLE pymssql ('
    '    pk_id int IDENTITY (1, 1) NOT NULL,',
    '    real_no real,',
    '    float_no float,',
    '    money_no money,',
    '    stamp_datetime datetime,',
    '    data_bit bit,',
    '    comment_vch varchar(50),',
    '    comment_nvch nvarchar(50),',
    '    comment_text text,',
    '    comment_ntext ntext,',
    '    data_image image,',
    '    data_binary varbinary(40),',
    '    decimal_no decimal(38,2),',
    '    decimal_no2 decimal(38,10),',
    '    numeric_no numeric(38,8),',
    '    stamp_timestamp timestamp,',
    '    uuid uniqueidentifier',
    ')',
]


def build_create_table_query(conn):
    if get_sql_server_version(conn) < 2008:
        create_sql = '\n'.join(create_test_table_sql)
    else:
        create_sql = '\n'.join(
            create_test_table_sql[:-1] + [
                ','
                'stamp_date date,',
                'stamp_time time,',
                'stamp_datetime2 datetime2'] +
            create_test_table_sql[-1:])
    return create_sql


@mssql_server_required
class TestTypes(unittest.TestCase):
    tname = 'pymssql'

    @classmethod
    def setup_class(cls):
        cls.conn = mssqlconn()
        drop_table(cls.conn, cls.tname)
        ddl_str = build_create_table_query(cls.conn)
        cls.conn.execute_non_query(ddl_str)

    def setUp(self):
        clear_table(self.conn, self.tname)

    def hasheq(self, v1, v2):
        if sys.version_info >= (3, ):
            if hasattr(v1, 'encode'):
                v1 = v1.encode('utf-8')
            if hasattr(v2, 'encode'):
                v2 = v2.encode('utf-8')

        hd1 = md5(v1).hexdigest()
        hd2 = md5(v2).hexdigest()
        assert hd1 == hd2, '%s (%s) != %s (%s)' % (v1, hd1, v2, hd2)

    def insert_and_select(self, cname, value, vartype, params_as_dict=False):
        if params_as_dict:
            inssql = 'insert into %s (%s) values (%%(value)%s)' % (self.tname, cname, vartype)
            self.conn.execute_non_query(inssql, dict(value=value))
        else:
            inssql = 'insert into %s (%s) values (%%%s)' % (self.tname, cname, vartype)
            self.conn.execute_non_query(inssql, value)
        self.conn.execute_query('select %s from pymssql' % cname)
        rows = tuple(self.conn)
        eq_(len(rows), 1)
        cval = rows[0][cname]
        return cval

    def test_varchar(self):
        testval = 'foobar'
        colval = self.insert_and_select('comment_vch', testval, 's')
        typeeq(u'foobar', colval)
        self.hasheq(u'foobar', colval)

    def test_varchar_hex(self):
        testval = '0xf00'
        colval = self.insert_and_select('comment_vch', testval, 's')
        typeeq(u'0xf00', colval)
        self.hasheq(u'0xf00', colval)

    def test_varchar_unicode(self):
        testval = u'foobär'
        colval = self.insert_and_select('comment_vch', testval, 's')
        typeeq(u'foobär', colval)
        eq_(u'foobär', colval)

    def test_nvarchar_unicode(self):
        testval = u'foobär'
        colval = self.insert_and_select('comment_nvch', testval, 's')
        typeeq(testval, colval)
        eq_(testval, colval)

    def test_binary_bytearray(self):
        bindata = '{z\n\x03\x07\x194;\x034lE4ISo'.encode('ascii')
        colval = self.insert_and_select('data_binary', bytearray(bindata), 's')
        typeeq(bindata, colval)
        eq_(bindata, colval)

    def test_binary_Binary(self):
        """
        See https://github.com/pymssql/pymssql/issues/504
        """
        bindata = '{z\n\x03\x07\x194;\x034lE4ISo'.encode('ascii')
        colval = self.insert_and_select('data_binary', pymssql.Binary(bindata), 's')
        typeeq(bindata, colval)
        eq_(bindata, colval)

    def test_image(self):
        buf = get_bytes_buffer()
        longstr = 'a'*4000
        pickle.dump([1, 2, longstr], buf, -1)
        testval = buf.getvalue()
        colval = self.insert_and_select('data_image', testval, 's')
        typeeq(testval, colval)
        self.hasheq(testval, colval)
        tlist = pickle.loads(colval)
        eq_(tlist, [1, 2, longstr])

    def test_image_gt_4KB(self):
        """
            test_image_gt_4KB

            By default, SQL server sets TEXTSIZE = 4096 bytes.  We up that by
            default and want to make sure it applies.
        """
        buf = get_bytes_buffer()
        longstr = 'a'*5000
        pickle.dump([1, 2, longstr], buf, -1)
        testval = buf.getvalue()
        colval = self.insert_and_select('data_image', testval, 's')
        typeeq(testval, colval)
        self.hasheq(testval, colval)
        tlist = pickle.loads(colval)
        eq_(tlist, [1, 2, longstr])

    def test_datetime(self):
        # Test for issue at https://code.google.com/p/pymssql/issues/detail?id=118
        testval = datetime(2013, 1, 2, 3, 4, 5, 3000)
        colval = self.insert_and_select('stamp_datetime', testval, 's')
        typeeq(testval, colval)
        eq_(testval, colval)

    def test_datetime_params_as_dict(self):
        testval = datetime(2013, 1, 2, 3, 4, 5, 3000)
        colval = self.insert_and_select('stamp_datetime', testval, 's', params_as_dict=True)
        typeeq(testval, colval)
        eq_(testval, colval)

    def test_date(self):
        if get_sql_server_version(self.conn) < 2008:
            pytest.skip("DATE field type isn't supported by SQL Server versions prior to 2008.")
        if self.conn.tds_version < 7.3:
            pytest.skip("DATE field type isn't supported by TDS protocol older than 7.3.")
        testval = date(2013, 1, 2)
        colval = self.insert_and_select('stamp_date', testval, 's')
        typeeq(testval, colval)
        eq_(testval, colval)

    def test_ancient_date(self):
        if get_sql_server_version(self.conn) < 2008:
            pytest.skip("DATE field type isn't supported by SQL Server versions prior to 2008.")
        if self.conn.tds_version < 7.3:
            pytest.skip("DATE field type isn't supported by TDS protocol older than 7.3.")
        testval = date(13, 1, 2)
        colval = self.insert_and_select('stamp_date', testval, 's')
        typeeq(testval, colval)
        eq_(testval, colval)

    def test_time(self):
        if get_sql_server_version(self.conn) < 2008:
            pytest.skip("TIME field type isn't supported by SQL Server versions prior to 2008.")
        if self.conn.tds_version < 7.3:
            pytest.skip("TIME field type isn't supported by TDS protocol older than 7.3.")
        testval = datetime(2013, 1, 2, 3, 4, 5, 3000)
        colval = self.insert_and_select('stamp_time', testval, 's')
        testval_no_date = testval.time()
        typeeq(testval_no_date, colval)
        eq_(testval_no_date, colval)

    def test_datetime2(self):
        if get_sql_server_version(self.conn) < 2008:
            pytest.skip("DATETIME2 field type isn't supported by SQL Server versions prior to 2008.")
        if self.conn.tds_version < 7.3:
            pytest.skip("DATETIME2 field type isn't supported by TDS protocol older than 7.3.")
        testval = datetime(2013, 1, 2, 3, 4, 5, 3000)
        colval = self.insert_and_select('stamp_datetime2', testval, 's')
        typeeq(testval, colval)
        eq_(testval, colval)

    def test_decimal(self):
        # test rounding down
        origval = D('1.2345')
        expect = D('1.23')
        colval = self.insert_and_select('decimal_no', origval, 's')
        typeeq(expect, colval)
        eq_(expect, colval)

    def test_decimal_context_protection(self):
        origval = D('1.2345')
        colval = self.insert_and_select('decimal_no', origval, 's')

        # make sure our manipulation of the decimal values doesn't affect the
        # default decimal context
        eq_(decimal.getcontext().prec, config.orig_decimal_prec)

    def test_decimal_rounding_up(self):
        # test rounding up
        origval = D('1.235')
        expect = D('1.24')
        colval = self.insert_and_select('decimal_no', origval, 's')
        typeeq(expect, colval)
        eq_(expect, colval)

    def test_decimal_smaller_precision(self):
        # smaller precision than column
        origval = D('1.2345')
        expect = D('1.2345000000')
        colval = self.insert_and_select('decimal_no2', origval, 's')
        typeeq(expect, colval)
        eq_(expect, colval)

    def test_numeric(self):
        # should be handled the same as a decimal column, so only one test
        origval = D('1.2345')
        expect = D('1.23450000')
        colval = self.insert_and_select('numeric_no', origval, 's')
        typeeq(expect, colval)
        eq_(expect, colval)

    def test_float_precision(self):
        #origval and expect are not exactly the same, but they test
        # equal and that is what we are getting at.  They should have
        # the same value out to the 16th digit.
        origval = 1.23456789012345670
        expect = 1.23456789012345671
        colval = self.insert_and_select('float_no', origval, 's')
        typeeq(expect, colval)
        eq_(expect, colval)

    def test_uuid_passed_as_string(self):
        """
        Test the case when the application passes a string representation of
        the uuid.UUID data type to _mssql.
        """
        origval = uuid.uuid4()
        stestval = str(origval)
        colval = self.insert_and_select('uuid', stestval, 's')
        typeeq(origval, colval)
        eq_(origval, colval)

    def test_uuid_passed_as_python_datatype(self):
        """
        Test the case when the application passes an instance of the uuid.UUID
        data type to _mssql to confirm it can handle it.
        """
        origval = uuid.uuid4()
        colval = self.insert_and_select('uuid', origval, 's')
        typeeq(origval, colval)
        eq_(origval, colval)


@mssql_server_required
class TestTypesPymssql(unittest.TestCase):
    tname = 'pymssql'

    @classmethod
    def setup_class(cls):
        cls.conn = pymssqlconn()
        drop_table(cls.conn._conn, cls.tname)
        ddl_str = build_create_table_query(cls.conn._conn)
        with cls.conn.cursor() as c:
            c.execute(ddl_str)

    def setUp(self):
        clear_table(self.conn._conn, self.tname)

    def insert_and_select(self, cname, value, vartype):
        with self.conn.cursor() as c:
            inssql = 'insert into %s (%s) values (%%%s)' % (self.tname, cname, vartype)
            c.execute(inssql, value)
            c.execute('select %s from %s' % (cname, self.tname))
            rows = c.fetchall()
            eq_(len(rows), 1)
            cval = rows[0][0]
        return cval

    def test_uuid_passed_as_string(self):
        """
        The uuid.UUID type isn't supported by the pyformat paramstyle (that
        only supports '%s' and is the style supported by pymsql).
        Test the case when the application passes a string representation of
        such data type to _mssql.
        """
        origval = uuid.uuid4()
        stestval = str(origval)
        colval = self.insert_and_select('uuid', stestval, 's')
        typeeq(origval, colval)
        eq_(origval, colval)

    def test_uuid_passed_as_python_datatype(self):
        """
        The uuid.UUID type isn't supported by the pyformat paramstyle (that
        only supports '%s' and is the style supported by pymsql).
        Test the case when the application passes an instance of such data type
        to _mssql to confirm it can handle it.
        """
        origval = uuid.uuid4()
        colval = self.insert_and_select('uuid', origval, 's')
        typeeq(origval, colval)
        eq_(origval, colval)
