#!/usr/bin/env python

#EDIT HERE########################################
HOST="localhost"
USER="sa"
PASSWORD=""
DATABASE="tempdb"

#DO NOT EDIT BELOW THIS LINE######################

import _mssql
import unittest,types,datetime

try:
    from decimal import Decimal

except ImportError:
    print "Sorry you need at least python 2.4"
    import sys
    sys.exit(1)

class MSSQLTestCase(unittest.TestCase):

    def setUp(self):
        self.mssql=_mssql.connect(HOST,USER,PASSWORD)
        self.mssql.select_db(DATABASE)
        self.tableCreated = False

    def tearDown(self):
        if self.tableCreated:
            self.dropTestTable()
        self.mssql.close()

    def createTestTable(self):
        query="""
        create table pymssql (
        pk_id int IDENTITY (1, 1) NOT NULL, real_no real,float_no float,money_no money
        ,stamp_datetime datetime,data_bit bit, comment_vch varchar(50)
        ,comment_nvch nvarchar(50)
        ,comment_text text,comment_ntext ntext,data_image image
        ,data_binary varbinary(40),decimal_no decimal(38,2)
        ,numeric_no numeric(38,8),stamp_time timestamp)"""

        ret = self.mssql.query(query)
        self.assert_(ret,"creating test table failed")
        self.mssql.fetch_array()
        self.tableCreated = True
        self.t_table_col_count = 15 #number of columns in test table

    def dropTestTable(self):
        query="drop table pymssql"
        ret = self.mssql.query(query)
        self.assert_(ret,"droping test table failed")
        self.mssql.fetch_array()
        self.tableCreated = False

    def insertSampleData(self):
        for x in range(10):
            y = x + 1

            query = """
            insert into pymssql (real_no,float_no,money_no,stamp_datetime,data_bit
            ,comment_vch,comment_ntext,comment_text,comment_nvch,decimal_no,numeric_no ) 
            values (%d,%d,%d,getdate(),%d,'comment %d','detail %d','hmm','bhmme',234.99,894123.009);
            """ % (y,y,y,(y % 2),y,y)

            ret = self.mssql.query(query)
            self.assertEquals(1,ret,"insert failed")
            self.mssql.fetch_array()

    def test01SimpleSelect(self):
        query="select getdate() as cur_date_info"
        ret = self.mssql.query(query)
        self.assert_(ret,"simple select failed")
        result = self.mssql.fetch_array()
        self.assertEquals("cur_date_info",result[0][0][0][0],"invalid name for column")
        self.assertEquals(_mssql.DATETIME,result[0][0][0][1],"invalid type, DATETIME was expected")
        self.assertEquals(1,result[0][1],"invalid number of rows")
        self.assertEquals(1,len(result[0][2]),"invalid number of rows")
        self.assertEquals(1,len(result[0][2][0]),"invalid number of columns")

    def test02EmptySelect(self):
        self.createTestTable()
        query = "select * from pymssql;"
        ret = self.mssql.query(query)
        self.assert_(ret,"simple select failed")
        result = self.mssql.fetch_array()
        self.assertEquals(0,result[0][1],"invalid number of rows, expected 0 on empty select")
        self.assertEquals(types.ListType,type(result[0][2]),"expected list but got %s" % type(result[0][2]))
        self.dropTestTable()

    def test03InsertSelect(self):
        self.createTestTable()
        self.insertSampleData()
        query = "select * from pymssql;"
        ret = self.mssql.query(query)
        self.assert_(ret,"simple select failed")
        result = self.mssql.fetch_array()
        self.assertEquals(10,result[0][1],"invalid count of rows in table")
        self.assertEquals(self.t_table_col_count,len(result[0][2][4]),"invalid column count")
        self.assertEquals(5,result[0][2][4][0],"invalid value, expected 5")
        self.assertEquals(5.0,result[0][2][4][1],"invalid value, expected 5.0")
        self.assertEquals(10,result[0][2][9][0],"invalid value, expected 9")
        self.assertEquals(_mssql.NUMBER,result[0][0][0][1],"invalid type, expected _mssql.NUMBER")
        self.assertEquals(_mssql.STRING,result[0][0][7][1],"invalid type, expected _mssql.NUMBER")
        self.dropTestTable()

    def test04UpdateDelete(self):
        self.createTestTable()
        self.insertSampleData()
        query = "update pymssql set decimal_no = 145.11 WHERE pk_id = 3"
        ret = self.mssql.query(query)
        self.assert_(ret,"update statement failed")
        self.mssql.fetch_array()
        query = "update pymssql set comment_vch = 'hello world'"
        ret = self.mssql.query(query)
        self.assert_(ret,"update statement failed")
        self.mssql.fetch_array()
        query = "delete from pymssql where real_no = 7.0 or pk_id = 8"
        ret = self.mssql.query(query)
        self.assert_(ret,"delete statement failed")
        self.mssql.fetch_array()
        query = "select * from pymssql;"
        ret = self.mssql.query(query)
        self.assert_(ret,"select statement failed")
        result = self.mssql.fetch_array()
        self.assertEquals(8,result[0][1],"invalid count of rows in table")
        self.assertEquals(Decimal("145.11"),result[0][2][2][12],"value is supposed to be decimal 145.11")
        self.assertEquals("hello world",result[0][2][0][6],"value is supposed to be 'hello world'")
        self.dropTestTable()

    def test05MultipleSelect(self):
        self.createTestTable()
        self.insertSampleData()
        query="EXEC sp_tables; select * from pymssql;"

        for x in range(10):
            ret = self.mssql.query(query)
            self.assert_(ret,"select statement failed")
            header=self.mssql.fetch_array()
            self.assertEquals(10,header[1][1],"invalid count of rows in table")

        self.dropTestTable()

    def test06ErrorMessage(self):
        self.createTestTable()
        self.insertSampleData()
        query="select fake_column from pymssql"

        try:
            ret = self.mssql.query(query)
            self.assertEquals(1,0,"no exception was thrown on wrong statement")

        except:
            #errmsg return None - not sure why
            errmsg = self.mssql.errmsg()
            #stdmsg has the error however
            stdmsg = self.mssql.stdmsg()
            self.assert_("fake_column" in stdmsg,"fake_column not mentioned in error")

        self.dropTestTable()

    def test07TypesTest(self):
        self.createTestTable()
        self.insertSampleData()
        query = "select * from pymssql;"
        ret = self.mssql.query(query)
        self.assert_(ret,"select statement failed")
        result = self.mssql.fetch_array()
        #test int it's also pk
        self.assertEquals(types.IntType,type(result[0][2][0][0]),"type is supposed to be int")
        self.assertEquals(_mssql.NUMBER,result[0][0][0][1],"invalid type, _mssql.NUMBER was expected")
        #test real
        self.assertEquals(types.FloatType,type(result[0][2][0][1]),"type is supposed to be float")
        #test float
        self.assertEquals(types.FloatType,type(result[0][2][0][2]),"type is supposed to be float")
        #test money
        self.assertEquals(Decimal,type(result[0][2][0][3]),"type is supposed to be decimal.Decimal")
        self.assertEquals(_mssql.DECIMAL,result[0][0][3][1],"invalid type, _mssql.DECIMAL was expected")
        #test datetime
        self.assertEquals(datetime.datetime,type(result[0][2][0][4]),"type is supposed to be datetime.datetime")
        self.assertEquals(_mssql.DATETIME,result[0][0][4][1],"invalid type, _mssql.DATETIME was expected")
        #test bit
        self.assertEquals(bool,type(result[0][2][0][5]),"type is supposed to be bool")
        self.assertEquals(_mssql.NUMBER,result[0][0][5][1],"invalid type, _mssql.NUMBER was expected")
        #test varchar
        self.assert_(type(result[0][2][0][6]) in types.StringTypes,"type is supposed to be one of types.StringTypes")
        self.assertEquals(_mssql.STRING,result[0][0][6][1],"invalid type, _mssql.STRING was expected")
        #test nvarchar
        self.assert_(type(result[0][2][0][7]) in types.StringTypes,"type is supposed to be one of types.StringTypes")
        self.assertEquals(_mssql.STRING,result[0][0][7][1],"invalid type, _mssql.STRING was expected")
        #test text
        self.assert_(type(result[0][2][0][8]) in types.StringTypes,"type is supposed to be one of types.StringTypes")
        self.assertEquals(_mssql.STRING,result[0][0][8][1],"invalid type, _mssql.STRING was expected")
        #test ntext
        self.assert_(type(result[0][2][0][9]) in types.StringTypes,"type is supposed to be one of types.StringTypes")
        self.assertEquals(_mssql.STRING,result[0][0][9][1],"invalid type, _mssql.STRING was expected")
        #test image
        self.assertEquals(type(result[0][2][0][10]),types.NoneType,"type is supposed to be NoneType")
        self.assertEquals(_mssql.BINARY,result[0][0][10][1],"invalid type, _mssql.BINARY was expected")
        #test binary
        self.assertEquals(type(result[0][2][0][11]),types.NoneType,"type is supposed to be NoneType")
        self.assertEquals(_mssql.BINARY,result[0][0][11][1],"invalid type, _mssql.BINARY was expected")
        #test decimal
        self.assertEquals(Decimal,type(result[0][2][0][12]),"type is supposed to be decimal.Decimal")
        self.assertEquals(_mssql.DECIMAL,result[0][0][12][1],"invalid type, _mssql.DECIMAL was expected")
        #test numeric
        self.assertEquals(Decimal,type(result[0][2][0][13]),"type is supposed to be decimal.Decimal")
        self.assertEquals(_mssql.DECIMAL,result[0][0][13][1],"invalid type, _mssql.DECIMAL was expected")
        #test timestamp (which really is a binary(8) in ms sql 2000)
        self.assertEquals(_mssql.BINARY,result[0][0][14][1],"invalid type, _mssql.BINARY was expected")
        self.dropTestTable()

    def test08RealType(self):
        self.createTestTable()
        self.insertSampleData()
        query = "select * from pymssql;"
        ret = self.mssql.query(query)
        self.assert_(ret,"select statement failed")
        result = self.mssql.fetch_array()
        #test real
        self.assertEquals(types.FloatType,type(result[0][2][0][1]),"type is supposed to be float")
        self.assertEquals(_mssql.NUMBER,result[0][0][1][1],"invalid type, _mssql.NUMBER was expected")
        self.dropTestTable()

    def test09FloatType(self):
        self.createTestTable()
        self.insertSampleData()
        query = "select * from pymssql;"
        ret = self.mssql.query(query)
        self.assert_(ret,"select statement failed")
        result = self.mssql.fetch_array()
        #test float
        self.assertEquals(types.FloatType,type(result[0][2][0][2]),"type is supposed to be float")
        self.assertEquals(_mssql.NUMBER,result[0][0][2][1],"invalid type, _mssql.NUMBER was expected")
        self.dropTestTable()

if __name__ == '__main__':
    suite = unittest.TestSuite()
    suite.addTest(unittest.makeSuite(MSSQLTestCase))
    unittest.TextTestRunner(verbosity=2).run(suite)
