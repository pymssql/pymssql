# -*- coding: utf-8 -*-
import decimal
from decimal import Decimal as D
from hashlib import md5
import pickle
from StringIO import StringIO

from nose.plugins.skip import SkipTest
from nose.tools import eq_

from .helpers import drop_table, mssqlconn, clear_table, config

tblsql = """
CREATE TABLE pymssql (
    pk_id int IDENTITY (1, 1) NOT NULL,
    real_no real,
    float_no float,
    money_no money,
    stamp_datetime datetime,
    data_bit bit,
    comment_vch varchar(50),
    comment_nvch nvarchar(50),
    comment_text text,
    comment_ntext ntext,
    data_image image,
    data_binary varbinary(40),
    decimal_no decimal(38,2),
    decimal_no2 decimal(38,10),
    numeric_no numeric(38,8),
    stamp_time timestamp
)
"""

class TestTypes(object):
    tname = 'pymssql'

    @classmethod
    def setup_class(cls):
        cls.conn = mssqlconn()
        drop_table(cls.conn, cls.tname)
        cls.conn.execute_non_query(tblsql)

    def setUp(self):
        clear_table(self.conn, self.tname)

    def hasheq(self, v1, v2):
        hd1 = md5(v1).hexdigest()
        hd2 = md5(v2).hexdigest()
        assert hd1 == hd2, '%s (%s) != %s (%s)' % (v1, hd1, v2, hd2)

    def typeeq(self, v1, v2):
        eq_(type(v1), type(v2))

    def insert_and_select(self, cname, value, vartype):
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
        self.typeeq(u'foobar', colval)
        self.hasheq(u'foobar', colval)

    def test_varchar_unicode(self):
        testval = u'foobär'
        colval = self.insert_and_select('comment_vch', testval, 's')
        self.typeeq(u'foobär', colval)
        eq_(u'foobär', colval)

    def test_nvarchar_unicode(self):
        testval = u'foobär'
        colval = self.insert_and_select('comment_nvch', testval, 's')
        self.typeeq(testval, colval)
        eq_(testval, colval)

    def test_image(self):
        buf = StringIO()
        pickle.dump([1, 2], buf, -1)
        testval = buf.getvalue()
        colval = self.insert_and_select('data_image', testval, 's')
        self.typeeq(testval, colval)
        self.hasheq(testval, colval)
        tlist = pickle.loads(colval)
        eq_(tlist, [1, 2])

    def test_decimal(self):
        # test rounding down
        origval = D('1.2345')
        expect = D('1.23')
        colval = self.insert_and_select('decimal_no', origval, 's')
        self.typeeq(expect, colval)
        eq_(expect, colval)

    def test_dicimal_context_protection(self):
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
        self.typeeq(expect, colval)
        eq_(expect, colval)

    def test_decimal_smaller_precision(self):
        # smaller precision than column
        origval = D('1.2345')
        expect = D('1.2345000000')
        colval = self.insert_and_select('decimal_no2', origval, 's')
        self.typeeq(expect, colval)
        eq_(expect, colval)

    def test_numeric(self):
        # should be handled the same as a decimal column, so only one test
        origval = D('1.2345')
        expect = D('1.23450000')
        colval = self.insert_and_select('numeric_no', origval, 's')
        self.typeeq(expect, colval)
        eq_(expect, colval)
