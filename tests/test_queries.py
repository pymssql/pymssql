from datetime import datetime

import _mssql

from .helpers import mssqlconn, drop_table

class QueryTests(object):

    @classmethod
    def setup_class(self):
        self.mssql = mssqlconn()
        self.createTestTable()

    def tearDown(self):
        clear_table(self.mssql, 'pymssql')
        self.mssql.close()

    def createTestTable(self):
        try:
            self.mssql.execute_non_query("""
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
                numeric_no numeric(38,8),
                stamp_time timestamp
            )""")
            self.tableCreated = True
            self.testTableColCount = 15
        except _mssql.MSSQLDatabaseException, e:
            if e.number != 2714:
                raise

    def dropTestTable(self):
        self.mssql.execute_non_query('DROP TABLE pymssql')
        self.tableCreated = False

    def insertSampleData(self):
        for x in xrange(10):
            y = x + 1
            query = """
            INSERT INTO pymssql (
                real_no,
                float_no,
                money_no,
                stamp_datetime,
                data_bit,
                comment_vch,
                comment_ntext,
                comment_text,
                comment_nvch,
                decimal_no,
                numeric_no
            ) VALUES (
                %d, %d, %d, getdate(), %d,
                'comment %d',
                'detail %d',
                'hmm',
                'bhmme',
                234.99,
                894123.09
            );""" % (y, y, y, (y % 2), y, y)
            self.mssql.execute_non_query(query)

    def test01SimpleSelect(self):
        query = 'SELECT getdate() as cur_date_info'
        self.mssql.execute_query(query)
        rows = tuple(self.mssql)
        self.assertTrue(isinstance(rows[0]['cur_date_info'], datetime))

    def test02EmptySelect(self):
        query = 'SELECT * FROM pymssql'
        self.mssql.execute_query(query)
        rows = tuple(self.mssql)
        self.assertEquals(rows, ())

    def test03InsertSelect(self):
        self.insertSampleData()
        self.mssql.execute_query('SELECT * FROM pymssql')

        # check row count
        rows = tuple(self.mssql)
        self.assertEquals(10, len(rows))

        # check col count
        cols = [k for k in rows[0] if type(k) is int]
        self.assertEquals(self.testTableColCount, len(cols))

    def test19MultipleResults(self):
        self.mssql.execute_query("SELECT 'ret1'; SELECT 'ret2'; SELECT 'ret3'")
        rows = tuple(self.mssql)
        self.assertEquals(rows[0][0], 'ret1')
        self.mssql.nextresult()

        rows = tuple(self.mssql)
        self.assertEquals(rows[0][0], 'ret2')
        self.mssql.nextresult()

        rows = tuple(self.mssql)
        self.assertEquals(rows[0][0], 'ret3')
