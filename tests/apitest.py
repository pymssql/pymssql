import _mssql
import unittest
import mssqltests

class QueryTests(mssqltests.MSSQLTestCase):

    def setUp(self):
        super(QueryTests, self).setUp()
        self.tableCreated = False
        self.createTestTable()

    def tearDown(self):
        if self.tableCreated:
            self.dropTestTable()
        super(QueryTests, self).tearDown()

    def createTestTable(self):
        if self.tableCreated:
            return
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
        except _mssql.MSSQLDatabaseException, e:
            if e.number == 2714:
                self.tableCreated = True
            else:
                raise

    def dropTestTable(self):
        self.mssql.execute_non_query('DROP TABLE pymssql')
        self.tableCreated = False

    
    def test01SimpleSelect(self):
        query = 'SELECT getdate() as cur_date_info'
        self.mssql.execute_query(query)

    def test02EmptySelect(self):
        query = 'SELECT * FROM pymssql'
        self.mssql.execute_query(query)

suite = unittest.TestSuite()
suite.addTest(unittest.makeSuite(QueryTests))

if __name__ == '__main__':
    unittest.main()
