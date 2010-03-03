import unittest
import mssqltests

class QueryTests(mssqltests.MssqlTestCase):
    
    def testQueries(self):
        query = 'CREATE TABLE pymssql (no int, fno float, comment varchar(50));'
        self.mssql.execute_query(query)

        for x in xrange(10):
            query = "INSERT INTO pymssql (no, fno, comment) VALUES (%d,%d,'%dth comment');" % ((x+1,)*3)
            self.mssql.execute_query(query)

        for x in xrange(10):
            query = "UPDATE pymssql SET comment='%dth hahaha.' where no = %d" % (x + 1, x + 1)
            self.mssql.execute_query(query)

        #query = "EXEC sp_tables; SELECT * FROM pymssql;"

        query = "DROP TABLE pymssql;"
        self.mssql.execute_query(query)


if __name__ == '__main__':
    unittest.main()
