# -*- coding: utf-8 -*-

import datetime
import unittest

from pymssql import datetime2
from .helpers import TestCaseWithTable, mssqlconn, get_sql_server_version

import pytest


class TestCaseDATETIME2(unittest.TestCase, TestCaseWithTable):

    @classmethod
    def setup_class(cls):
        cls.conn = mssqlconn()
        if get_sql_server_version(cls.conn) < 2008:
            pytest.skip("DATETIME2 field type isn't supported by SQL Server versions prior to 2008.")
        if cls.conn.tds_version < 7.3:
            pytest.skip("DATETIME2 field type isn't supported by TDS protocol older than 7.3.")
        cls.create_table()


class Test_DATETIME2(TestCaseDATETIME2):

    table_name = "test_datetime2"
    ddl_create = f"CREATE TABLE {table_name} (test DATETIME2)"
    min_date = datetime2(1, 1, 1, 0, 0, 0, 0)
    max_date = datetime2(9999, 12, 31, 23, 59, 59, 999999)

    def test_min_select(self):
        self.conn.execute_query("SELECT CAST ('0001-1-1 0:0:0' as DATETIME2)")
        res = tuple(self.conn)[0][0]
        assert isinstance(res, datetime.datetime)
        assert res == self.min_date

    def test_min_insert(self):
        res = self.insert_and_select('test', self.min_date)
        assert isinstance(res, datetime.datetime)
        assert res == self.min_date

    def test_max_select(self):
        self.conn.execute_query("SELECT CAST ('9999-12-31 23:59:59.9999999' as DATETIME2)")
        res = tuple(self.conn)[0][0]
        assert isinstance(res, datetime.datetime)
        assert res == self.max_date

    def test_max_insert(self):
        res = self.insert_and_select('test', self.max_date)
        assert isinstance(res, datetime.datetime)
        assert res == self.max_date

    def test_datetime2(self):
        testval = datetime2(2013, 1, 2, 3, 4, 5, 6)
        res = self.insert_and_select('test', testval)
        assert isinstance(res, datetime.datetime)
        assert testval == res

    def test_truncate(self):
        self.conn.execute_query("SELECT CAST ('2024-1-1 0:0:0.1234567' as DATETIME2)")
        res = tuple(self.conn)[0][0]
        assert isinstance(res, datetime.datetime)
        assert res == datetime.datetime(2024, 1, 1, 0, 0, 0, 123456)


class Test_695(TestCaseDATETIME2):
    """
    See issue #695
    """
    table_name = "dbo.test695"
    ddl_create = f"""
            CREATE TABLE {table_name} (
                valid_from DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
                valid_to DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
                PERIOD FOR SYSTEM_TIME (valid_from,valid_to),
                id INTEGER NOT NULL IDENTITY(1,1) PRIMARY KEY,
                test VARCHAR(255) NOT NULL,
                )
        """
        #WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.test_history));

    def test_695(self):
        self.conn.execute_non_query(f"INSERT INTO {self.table_name} (test) VALUES (%s)", ("TEST", ))
        self.conn.execute_query(f"SELECT valid_from, valid_to FROM {self.table_name}")
        rows = tuple(self.conn)
        res = rows[0][1]
        assert isinstance(res, datetime.datetime)
        #print(rows)


class Test_DATETIME(TestCaseDATETIME2):

    table_name = "test_datetime"
    ddl_create = f"CREATE TABLE {table_name} (test DATETIME)"
    min_date = datetime.datetime(1753, 1, 1, 0, 0, 0, 0)
    max_date = datetime.datetime(9999, 12, 31, 23, 59, 59, 997000)

    def test_min_select(self):
        self.conn.execute_query("SELECT CAST ('1753-1-1 0:0:0' as DATETIME)")
        res = tuple(self.conn)[0][0]
        assert isinstance(res, datetime.datetime)
        assert not isinstance(res, datetime2)
        assert res == self.min_date

    def test_min_insert(self):
        res = self.insert_and_select('test', self.min_date)
        assert isinstance(res, datetime.datetime)
        assert not isinstance(res, datetime2)
        assert res == self.min_date

    def test_max_select(self):
        self.conn.execute_query("SELECT CAST ('9999-12-31 23:59:59.997' as DATETIME)")
        res = tuple(self.conn)[0][0]
        assert isinstance(res, datetime.datetime)
        assert not isinstance(res, datetime2)
        assert res == self.max_date

    def test_max_insert(self):
        res = self.insert_and_select('test', self.max_date)
        assert isinstance(res, datetime.datetime)
        assert not isinstance(res, datetime2)
        assert res == self.max_date

    def test_datetime(self):
        """
        Test for issue at https://code.google.com/p/pymssql/issues/detail?id=118
        datetime values are rounded to increments of .000, .003, or .007 seconds,
        see https://docs.microsoft.com/en-us/sql/t-sql/data-types/datetime-transact-sql
        """
        for mks in (0, 3000, 7000):
            testval = datetime.datetime(2013, 1, 2, 3, 4, 5, mks)
            self.conn.execute_non_query(f"DELETE FROM {self.table_name}")
            res = self.insert_and_select('test', testval)
            assert isinstance(res, datetime.datetime)
            assert not isinstance(res, datetime2)
            assert res == testval

    def test_datetime_params_as_dict(self):
        testval = datetime.datetime(2013, 1, 2, 3, 4, 5, 3000)
        res = self.insert_and_select('test', testval, params_as_dict=True)
        assert isinstance(res, datetime.datetime)
        assert not isinstance(res, datetime2)
        assert res == testval


class Test_DATE(TestCaseDATETIME2):

    table_name = "test_date"
    ddl_create = f"CREATE TABLE {table_name} (test DATE)"
    min_date = datetime.date(1, 1, 1)
    max_date = datetime.date(9999, 12, 31)

    def test_min_select(self):
        self.conn.execute_query("SELECT CAST ('0001-1-1' as DATE)")
        res = tuple(self.conn)[0][0]
        assert isinstance(res, datetime.date)
        assert res == self.min_date

    def test_min_insert(self):
        res = self.insert_and_select('test', self.min_date)
        assert isinstance(res, datetime.date)
        assert res == self.min_date

    def test_max_select(self):
        self.conn.execute_query("SELECT CAST ('9999-12-31' as DATE)")
        res = tuple(self.conn)[0][0]
        assert isinstance(res, datetime.date)
        assert res == self.max_date

    def test_max_insert(self):
        res = self.insert_and_select('test', self.max_date)
        assert isinstance(res, datetime.date)
        assert res == self.max_date

    def test_date(self):
        testval = datetime.date(2013, 1, 2)
        res = self.insert_and_select('test', testval)
        assert isinstance(res, datetime.date)
        assert res == testval

    def test_ancient_date(self):
        testval = datetime.date(13, 1, 2)
        res = self.insert_and_select('test', testval)
        assert isinstance(res, datetime.date)
        assert res == testval


class Test_TIME(TestCaseDATETIME2):

    table_name = "test_time"
    ddl_create = f"CREATE TABLE {table_name} (test TIME)"
    min_time = datetime.time(0, 0, 0, 0)
    max_time = datetime.time(23, 59, 59, 999999)

    def test_min_select(self):
        self.conn.execute_query("SELECT CAST ('0:0:0.0' as TIME)")
        res = tuple(self.conn)[0][0]
        assert isinstance(res, datetime.time)
        assert res == self.min_time

    def test_min_insert(self):
        res = self.insert_and_select('test', self.min_time)
        assert isinstance(res, datetime.time)
        assert res == self.min_time

    def test_max_select(self):
        self.conn.execute_query("SELECT CAST ('23:59:59.9999999' as TIME)")
        res = tuple(self.conn)[0][0]
        assert isinstance(res, datetime.time)
        assert res == self.max_time

    def test_max_insert(self):
        res = self.insert_and_select('test', self.max_time)
        assert isinstance(res, datetime.time)
        assert res == self.max_time

    def test_time(self):
        testval = datetime.time(3, 4, 5, 3000)
        res = self.insert_and_select('test', testval)
        assert isinstance(res, datetime.time)
        assert res == testval


class Test_DATETIMEOFFSET(TestCaseDATETIME2):

    table_name = "test_time"
    ddl_create = f"""CREATE TABLE {table_name} (
                        id INT default 1,
                        DateCreated DATETIMEOFFSET default sysdatetimeoffset()
                    )"""

    def test_649(self):
        """
        Test #649
        """
        self.conn.execute_non_query(
            f"INSERT INTO {self.table_name} (id) VALUES (%s)", (2, ))
        self.conn.execute_query(
            f'select DateCreated from {self.table_name} where id = 2')
        res = tuple(self.conn)[0][0]
        assert isinstance(res, datetime.datetime)
        assert res.strftime('%z') != ''

    def test_select_cast_0(self):
        self.conn.execute_query(
            "SELECT CAST ('2019-06-20 09:54:40.09550' as DATETIMEOFFSET)")
        res = tuple(self.conn)[0][0]
        assert isinstance(res, datetime.datetime)
        assert res == datetime.datetime(2019, 6, 20, 9, 54, 40, 95500,
                                        tzinfo=datetime.timezone.utc)

    def test_select_cast(self):
        self.conn.execute_query(
            "SELECT CAST ('2019-06-20 09:54:40.09550 +04:00' as DATETIMEOFFSET)")
        res = tuple(self.conn)[0][0]
        assert isinstance(res, datetime.datetime)
        assert res == datetime.datetime(2019, 6, 20, 9, 54, 40, 95500,
                    tzinfo=datetime.timezone(datetime.timedelta(seconds=4*60*60)))

    def test_insert_select(self):
        testval = datetime.datetime(3, 4, 5, 3,
                    tzinfo=datetime.timezone(datetime.timedelta(seconds=4*60*60)))
        self.conn.execute_non_query(
            f"INSERT INTO {self.table_name} (id, DateCreated) VALUES (%s, %s)",
            (22, testval))
        self.conn.execute_query(
            f'select DateCreated from {self.table_name} where id = 22')
        res = tuple(self.conn)[0][0]
        assert isinstance(res, datetime.datetime)
        assert res.strftime('%z') != ''
        assert res == testval
