from nose.plugins.skip import SkipTest
from nose.tools import eq_

import _mssql

class TestParameterSub(object):

    def test_single_param(self):
        res = _mssql.substitute_params('SELECT * FROM employees WHERE id=%s', 13)
        eq_(res, b'SELECT * FROM employees WHERE id=13')

        res = _mssql.substitute_params('SELECT * FROM empl WHERE name=%s', b'John Doe')
        eq_(res, b"SELECT * FROM empl WHERE name='John Doe'")

        res = _mssql.substitute_params('SELECT * FROM empl WHERE name=%s', u'John Doe')
        eq_(res, b"SELECT * FROM empl WHERE name=N'John Doe'")

    def test_param_quote(self):
        res = _mssql.substitute_params('SELECT * FROM empl WHERE name=%s', b"John's Doe")
        eq_(res, b"SELECT * FROM empl WHERE name='John''s Doe'")

        res = _mssql.substitute_params('SELECT * FROM empl WHERE name=%s', u"John's Doe")
        eq_(res, b"SELECT * FROM empl WHERE name=N'John''s Doe'")

    def test_single_param_with_d(self):
        res = _mssql.substitute_params('SELECT * FROM employees WHERE id=%d', 13)
        eq_(res, b'SELECT * FROM employees WHERE id=13')

    def test_percent_not_touched_with_no_params(self):
        sql = "SELECT COUNT(*) FROM employees WHERE name LIKE 'J%'"
        res = _mssql.substitute_params(sql, None)
        eq_(res, sql)

    def test_tuple_with_in(self):
        res = _mssql.substitute_params('SELECT * FROM empl WHERE id IN %s', ((5, 6),))
        eq_(res, b"SELECT * FROM empl WHERE id IN (5,6)")

        res = _mssql.substitute_params('SELECT * FROM empl WHERE id IN %s', ((b'foo', b'bar'),))
        eq_(res, b"SELECT * FROM empl WHERE id IN ('foo','bar')")

        res = _mssql.substitute_params('SELECT * FROM empl WHERE id IN %s', ((u'foo', u'bar'),))
        eq_(res, b"SELECT * FROM empl WHERE id IN (N'foo',N'bar')")

        # single item
        res = _mssql.substitute_params('SELECT * FROM empl WHERE id IN %s', ((b'foo',),))
        eq_(res, b"SELECT * FROM empl WHERE id IN ('foo')")

        res = _mssql.substitute_params('SELECT * FROM empl WHERE id IN %s', ((u'foo',),))
        eq_(res, b"SELECT * FROM empl WHERE id IN (N'foo')")

    def test_percent_in_param(self):
        res = _mssql.substitute_params('SELECT * FROM empl WHERE name LIKE %s', b'J%')
        eq_(res, b"SELECT * FROM empl WHERE name LIKE 'J%'")

        res = _mssql.substitute_params('SELECT * FROM empl WHERE name LIKE %s', u'J%')
        eq_(res, b"SELECT * FROM empl WHERE name LIKE N'J%'")

    def test_single_dict_params(self):
        res = _mssql.substitute_params(
                'SELECT * FROM cust WHERE salesrep=%(name)s',
                { 'name': b'John Doe'}
            )
        eq_(res, b"SELECT * FROM cust WHERE salesrep='John Doe'")

        res = _mssql.substitute_params(
                'SELECT * FROM cust WHERE salesrep=%(name)s',
                { 'name': u'John Doe'}
            )
        eq_(res, b"SELECT * FROM cust WHERE salesrep=N'John Doe'")

    def test_weird_key_names_dict_params(self):
        res = _mssql.substitute_params(
                'SELECT * FROM cust WHERE salesrep=%(n %s ##ame)s',
                { 'n %s ##ame': b'John Doe'}
            )
        eq_(res, b"SELECT * FROM cust WHERE salesrep='John Doe'")

        res = _mssql.substitute_params(
                'SELECT * FROM cust WHERE salesrep=%(n %s ##ame)s',
                { 'n %s ##ame': u'John Doe'}
            )
        eq_(res, b"SELECT * FROM cust WHERE salesrep=N'John Doe'")

    def test_multi_dict_params(self):
        res = _mssql.substitute_params(
                'SELECT * FROM empl WHERE (name=%(name)s AND city=%(city)s) or supervisor=%(name)s',
                { 'name': b'John Doe', 'city': b'Nowhere' }
            )
        eq_(res, b"SELECT * FROM empl WHERE (name='John Doe' AND city='Nowhere') or supervisor='John Doe'")

        res = _mssql.substitute_params(
                'SELECT * FROM empl WHERE (name=%(name)s AND city=%(city)s) or supervisor=%(name)s',
                { 'name': u'John Doe', 'city': u'Nowhere' }
            )
        eq_(res, b"SELECT * FROM empl WHERE (name=N'John Doe' AND city=N'Nowhere') or supervisor=N'John Doe'")

    def test_single_and_tuple(self):
        res = _mssql.substitute_params(
                'SELECT * FROM cust WHERE salesrep=%s AND id IN %s',
                (b'John Doe', (1, 2, 3))
            )
        eq_(res, b"SELECT * FROM cust WHERE salesrep='John Doe' AND id IN (1,2,3)")

        res = _mssql.substitute_params(
                'SELECT * FROM cust WHERE salesrep=%s AND id IN %s',
                (u'John Doe', (1, 2, 3))
            )
        eq_(res, b"SELECT * FROM cust WHERE salesrep=N'John Doe' AND id IN (1,2,3)")

    def test_bare_percent_position(self):
        res = _mssql.substitute_params('select 5 % %s', 3)
        eq_(res, b"select 5 % 3")

    def test_bare_percent_dict(self):
        res = _mssql.substitute_params('select 5 % %(divisor)s', {'divisor': 3})
        eq_(res, b"select 5 % 3")

    def test_missing_dict_param(self):
        try:
            res = _mssql.substitute_params(
                'SELECT * FROM cust WHERE salesrep=%(name)s',
                { 'foobar': 'John Doe'}
            )
            assert False, 'expected exception b/c dict did not contain replacement value'
        except ValueError as e:
            if 'params dictionary did not contain value for placeholder' not in str(e):
                raise

    def test_too_many_params(self):
        try:
            res = _mssql.substitute_params(
                'SELECT * FROM cust WHERE salesrep=%s and foo=%s',
                ('bar',)
            )
            assert False, 'expected exception b/c too many params in sql'
        except ValueError as e:
            if 'more placeholders in sql than params available' not in str(e):
                raise
