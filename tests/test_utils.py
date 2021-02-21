# -*- coding: utf-8 -*-
"""
Test parameters substitution.
"""

from .helpers import eq_

from pymssql._mssql import substitute_params


def test_single_param():
    res = substitute_params(
        'SELECT * FROM employees WHERE id = %s',
        13)
    eq_(res, b'SELECT * FROM employees WHERE id = 13')

    res = substitute_params(
        'SELECT * FROM empl WHERE name = %s',
        b'John Doe')
    eq_(res, b"SELECT * FROM empl WHERE name = 'John Doe'")

    res = substitute_params(
        'SELECT * FROM empl WHERE name = %s',
        u'John Doe')
    eq_(res, b"SELECT * FROM empl WHERE name = N'John Doe'")


def test_param_quote():
    res = substitute_params(
        'SELECT * FROM empl WHERE name = %s',
        b"John's Doe")
    eq_(res, b"SELECT * FROM empl WHERE name = 'John''s Doe'")

    res = substitute_params(
        'SELECT * FROM empl WHERE name = %s',
        u"John's Doe")
    eq_(res, b"SELECT * FROM empl WHERE name = N'John''s Doe'")


def test_unicode_params():
    res = substitute_params(
        u'SELECT * FROM \u0394 WHERE name = %s',
        u'\u03A8'
    )
    eq_(res, b"SELECT * FROM \xce\x94 WHERE name = N'\xce\xa8'")

    res = substitute_params(u"testing ascii (\u0105\u010D\u0119) 1=%d 'one'=%s", (1, u'str'))
    eq_(res, b"testing ascii (\xc4\x85\xc4\x8d\xc4\x99) 1=1 'one'=N'str'")


def test_single_param_with_d():
    res = substitute_params(
        'SELECT * FROM employees WHERE id = %d',
        13)
    eq_(res, b'SELECT * FROM employees WHERE id = 13')


def test_keyed_param_with_d():
    res = substitute_params(
        'SELECT * FROM employees WHERE id = %(emp_id)d',
        {'emp_id': 13})
    eq_(res, b'SELECT * FROM employees WHERE id = 13')


def test_percent_not_touched_with_no_params():
    sql = "SELECT COUNT(*) FROM employees WHERE name LIKE 'J%'"
    res = substitute_params(sql, None)
    eq_(res, sql)


def test_tuple_with_in():
    res = substitute_params(
        'SELECT * FROM empl WHERE id IN %s',
        ((5, 6),))
    eq_(res, b"SELECT * FROM empl WHERE id IN (5,6)")

    res = substitute_params(
        'SELECT * FROM empl WHERE id IN %s',
        ((b'foo', b'bar'),))
    eq_(res, b"SELECT * FROM empl WHERE id IN ('foo','bar')")

    res = substitute_params(
        'SELECT * FROM empl WHERE id IN %s',
        ((u'foo', u'bar'),))
    eq_(res, b"SELECT * FROM empl WHERE id IN (N'foo',N'bar')")

    # single item
    res = substitute_params(
        'SELECT * FROM empl WHERE id IN %s',
        ((b'foo',),))
    eq_(res, b"SELECT * FROM empl WHERE id IN ('foo')")

    res = substitute_params(
        'SELECT * FROM empl WHERE id IN %s',
        ((u'foo',),))
    eq_(res, b"SELECT * FROM empl WHERE id IN (N'foo')")


def test_percent_in_param():
    res = substitute_params(
        'SELECT * FROM empl WHERE name LIKE %s',
        b'J%')
    eq_(res, b"SELECT * FROM empl WHERE name LIKE 'J%'")

    res = substitute_params(
        'SELECT * FROM empl WHERE name LIKE %s',
        u'J%')
    eq_(res, b"SELECT * FROM empl WHERE name LIKE N'J%'")


def test_single_dict_params():
    res = substitute_params(
        'SELECT * FROM cust WHERE salesrep = %(name)s',
        {'name': b'John Doe'})
    eq_(res, b"SELECT * FROM cust WHERE salesrep = 'John Doe'")

    res = substitute_params(
        'SELECT * FROM cust WHERE salesrep = %(name)s',
        {'name': u'John Doe'})
    eq_(res, b"SELECT * FROM cust WHERE salesrep = N'John Doe'")


def test_weird_key_names_dict_params():
    res = substitute_params(
        'SELECT * FROM cust WHERE salesrep = %(n %s ##ame)s',
        {'n %s ##ame': b'John Doe'})
    eq_(res, b"SELECT * FROM cust WHERE salesrep = 'John Doe'")

    res = substitute_params(
        'SELECT * FROM cust WHERE salesrep = %(n %s ##ame)s',
        {'n %s ##ame': u'John Doe'})
    eq_(res, b"SELECT * FROM cust WHERE salesrep = N'John Doe'")


def test_multi_dict_params():
    res = substitute_params(
        'SELECT * FROM empl '
        'WHERE (name = %(name)s AND city = %(city)s) '
        'OR supervisor = %(name)s',
        {'name': b'John Doe', 'city': b'Nowhere'})
    eq_(res, b"SELECT * FROM empl "
             b"WHERE (name = 'John Doe' AND city = 'Nowhere') "
             b"OR supervisor = 'John Doe'")

    res = substitute_params(
        'SELECT * FROM empl '
        'WHERE (name = %(name)s AND city = %(city)s) '
        'OR supervisor = %(name)s',
        {'name': u'John Doe', 'city': u'Nowhere'})
    eq_(res, b"SELECT * FROM empl "
             b"WHERE (name = N'John Doe' AND city = N'Nowhere') "
             b"OR supervisor = N'John Doe'")


def test_single_and_tuple():
    res = substitute_params(
        'SELECT * FROM cust '
        'WHERE salesrep = %s AND id IN %s',
        (b'John Doe', (1, 2, 3)))
    eq_(res, b"SELECT * FROM cust "
             b"WHERE salesrep = 'John Doe' AND id IN (1,2,3)")

    res = substitute_params(
        'SELECT * FROM cust '
        'WHERE salesrep = %s AND id IN %s',
        (u'John Doe', (1, 2, 3)))
    eq_(res, b"SELECT * FROM cust "
             b"WHERE salesrep = N'John Doe' AND id IN (1,2,3)")


def test_bare_percent_position():
    res = substitute_params('select 5 % %s', 3)
    eq_(res, b"select 5 % 3")


def test_bare_percent_dict():
    res = substitute_params('select 5 % %(divisor)s', {'divisor': 3})
    eq_(res, b"select 5 % 3")


def test_missing_dict_param():
    expected_err = 'params dictionary did not contain value for placeholder'

    try:
        substitute_params(
            'SELECT * FROM cust WHERE salesrep = %(name)s',
            {'foobar': 'John Doe'})
        assert False, \
            'expected exception b/c dict did not contain replacement value'
    except ValueError as exc:
        if expected_err not in str(exc):
            raise


def test_too_many_params():
    try:
        substitute_params(
            'SELECT * FROM cust WHERE salesrep = %s and foo = %s',
            ('bar',))
        assert False, 'expected exception b/c too many params in sql'
    except ValueError as exc:
        if 'more placeholders in sql than params available' not in str(exc):
            raise
