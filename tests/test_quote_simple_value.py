"""
Test parameters substitution.
"""

import datetime
import decimal

import pytest

from pymssql._mssql import quote_simple_value, datetime2


def test_none():
    res = quote_simple_value(None)
    assert res == b'NULL'


@pytest.mark.parametrize('val', (0, 13))
def test_int(val):
    res = quote_simple_value(val)
    assert res == f"{val}".encode('utf-8')


@pytest.mark.parametrize('val', (0.0, 3.14))
def test_float(val):
    res = quote_simple_value(val)
    assert res == f"{val}".encode('utf-8')


@pytest.mark.parametrize('val', (True, False))
def test_bool(val):
    res = quote_simple_value(val)
    assert res == f"{int(val)}".encode('utf-8')


@pytest.mark.parametrize('val', (0.123, 13.789))
def test_decimal(val):
    res = quote_simple_value(decimal.Decimal(val))
    assert res == f"{decimal.Decimal(val)}".encode('utf-8')


def test_uuid():
    u = '3cde0c92-2674-481f-8fd4-feacf98d8504'
    res = quote_simple_value(u)
    assert res == f"N'{u}'".encode('utf-8')


@pytest.mark.parametrize('val', ('Фрязино', 'Здравствуй Мир'))
def test_str(val):
    res = quote_simple_value(val)
    assert res == f"N'{val}'".encode('utf-8')


@pytest.mark.parametrize('val', (b"Hello", b"Hello 'World!'"))
def test_bytes(val):
    res = quote_simple_value(val)
    assert res == b"'%s'"%(val.replace(b"'", b"''"))


@pytest.mark.parametrize('val', (
                         datetime.date(1, 2, 3),
                         datetime.date(2024, 3, 24)))
def test_date(val):
    res = quote_simple_value(val)
    assert res == val.strftime("'%04Y-%m-%d'").encode()


@pytest.mark.parametrize('val', (
                         datetime.time(0, 0, 0),
                         datetime.time(0, 0, 1),
                         datetime.time(1, 2, 59),
                         datetime.time(23, 3, 24)))
def test_time(val):
    res = quote_simple_value(val)
    assert res == val.strftime("'%H:%M:%S.%f'").encode()


@pytest.mark.parametrize('val', (
                         datetime.datetime(1, 2, 3, 23, 3, 59),
                         datetime.datetime(2024, 3, 24, 0, 0, 1)))
def test_datetime(val):
    res = quote_simple_value(val)
    assert res == val.strftime("'%04Y-%m-%d %H:%M:%S.%%03d'").encode(
                                ) % (val.microsecond // 1000)


@pytest.mark.parametrize('val', (
                         datetime.datetime(1, 2, 3, 23, 3, 59),
                         datetime.datetime(2024, 3, 24, 0, 0, 1)))
def test_datetime_use_datetime2(val):
    res = quote_simple_value(val, use_datetime2=True)
    assert res == val.strftime("'%04Y-%m-%d %H:%M:%S.%f'").encode()


@pytest.mark.parametrize('val', (
                         datetime2(1, 2, 3, 23, 3, 59),
                         datetime2(2024, 3, 24, 0, 0, 1)))
def test_datetime2(val):
    res = quote_simple_value(val)
    assert res == val.strftime("'%04Y-%m-%d %H:%M:%S.%f'").encode()


@pytest.mark.parametrize('val', (
                         datetime.datetime(1, 2, 3, 23, 3, 59,
                                           tzinfo=datetime.timezone.utc),
                         datetime.datetime(2024, 3, 24, 0, 0, 1,
                                           tzinfo=datetime.timezone.utc)))
def test_datetime_utc(val):
    res = quote_simple_value(val)
    assert res == val.strftime("'%04Y-%m-%d %H:%M:%S.%%03d'").encode(
                                ) % (val.microsecond // 1000)


@pytest.mark.parametrize('val', (
                         datetime.datetime(1, 2, 3, 23, 3, 59,
                                           tzinfo=datetime.timezone(
                                               datetime.timedelta(hours=3))),
                         datetime.datetime(2024, 3, 24, 0, 0, 1,
                                           tzinfo=datetime.timezone(
                                               datetime.timedelta(hours=3)))))
def test_datetime_tz(val):
    res = quote_simple_value(val)
    assert res == val.strftime("'%04Y-%m-%d %H:%M:%S.%f%%b'").encode(
                                ) % (val.strftime('%Z')[3:].encode())
