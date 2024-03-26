# -*- coding: utf-8 -*-
"""
Test queries.
"""

import pytest

from .helpers import pymssqlconn, drop_table
from pymssql._mssql import substitute_params


@pytest.mark.mssql_server_required
class Test_609:

    table_name = 'testtab'
    table_ddl = f'''
        CREATE TABLE {table_name} (
            int_col int,
            int_col_none int,
            text_col nvarchar(100)
            )
    '''
    N = 10
    table_data = tuple( (x, f"Column {x}") for x in range(N) )

    @classmethod
    def setup_class(cls):
        cls.conn = pymssqlconn(encryption='require')
        drop_table(cls.conn._conn, cls.table_name)
        cls.create_test_table()
        cls.fill_test_table()

    @classmethod
    def teardown_class(cls):
        drop_table(cls.conn._conn, cls.table_name)
        cls.conn.close()

    @classmethod
    def create_test_table(cls):
        with cls.conn.cursor() as c:
            c.execute(cls.table_ddl)

    @classmethod
    def fill_test_table(cls):
        query = f"INSERT INTO {cls.table_name} (int_col, text_col) VALUES (%d, %s);"
        with cls.conn.cursor() as c:
            for vals in cls.table_data:
                c.execute(query, vals)


    def test_text0(self):
        with self.conn.cursor() as c:
            c.execute(f'SELECT * FROM {self.table_name} WHERE text_col=%s', "a")
            rows = c.fetchall()
            assert len(rows) == 0


    @pytest.mark.parametrize('i', range(N))
    def test_int(self, i):
        int_col, text_col = self.table_data[i]
        with self.conn.cursor() as c:
            c.execute(f'SELECT * FROM {self.table_name} WHERE int_col=%s', (int_col, ))
            rows = c.fetchall()
            assert len(rows) == 1
            assert rows[0] == (int_col, None, text_col)


    @pytest.mark.parametrize('i', range(N))
    def test_int_pymssql(self, i):
        int_col, text_col = self.table_data[i]
        with self.conn.cursor() as c:
            c.execute(f'SELECT * FROM {self.table_name} WHERE int_col=%s', int_col)
            rows = c.fetchall()
            assert len(rows) == 1
            assert rows[0] == (int_col, None, text_col)


    @pytest.mark.parametrize('i', range(N))
    def test_text(self, i):
        int_col, text_col = self.table_data[i]
        with self.conn.cursor() as c:
            c.execute(f'SELECT * FROM {self.table_name} WHERE text_col=%s', (text_col, ))
            rows = c.fetchall()
            assert len(rows) == 1
            assert rows[0] == (int_col, None, text_col)


    @pytest.mark.parametrize('i', range(N))
    def test_text_pymssql(self, i):
        int_col, text_col = self.table_data[i]
        with self.conn.cursor() as c:
            c.execute(f'SELECT * FROM {self.table_name} WHERE text_col=%s', text_col)
            rows = c.fetchall()
            assert len(rows) == 1
            assert rows[0] == (int_col, None, text_col)


    @pytest.mark.xfail(reason="known parser issue")
    def test_424(self):
        query = "SELECT COUNT(*) FROM document WHERE title LIKE '%summary%' AND id < %s"
        parms = (1500,)
        with self.conn.cursor() as c:
            c.execute(query, parms)


    @pytest.mark.xfail(reason="known parser issue")
    def test_276(self):
        res = substitute_params('select %s;'.encode('utf-8'), tuple(["Фрязино".encode('utf-16-le')]))
        assert res == b'select 0x240440044f04370438043d043e042000;'
        #assert res == b"select '$\x04@\x04O\x047\x048\x04=\x04>\x04';"

        res = substitute_params('select %s;'.encode('utf-8'), tuple(["Фрязино ".encode('utf-16-le')]))
        assert res == b'select 0x240440044f04370438043d043e042000;'
        "Фрязино".encode('utf-16-le')
        '$\x04@\x04O\x047\x048\x04=\x04>\x04'
        "Фрязино ".encode('utf-16-le')
        '$\x04@\x04O\x047\x048\x04=\x04>\x04 \x00'
