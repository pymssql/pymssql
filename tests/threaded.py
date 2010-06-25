import _mssql
import unittest
import threading
from mssqltests import server, username, password, database

class TestingThread(threading.Thread):

    def run(self):
        self.running = True
        self.exc = None
        try:
            mssql = _mssql.connect(server, username, password)
            mssql.select_db(database)
            for i in xrange(0, 1000):
                mssql.execute_query('SELECT %d', (i,))
                for row in mssql:
                    assert row[0] == i
            mssql.close()
        except Exception, e:
            self.exc = e
        finally:
            self.running = False

class TestingErrorThread(threading.Thread):

    def run(self):
        self.running = True
        self.exc = None
        try:
            mssql = _mssql.connect(server, username, password)
            mssql.select_db(database)
            for i in xrange(0, 1000):
                try:
                    mssql.execute_query('SELECT unknown_column')
                except:
                    pass
            mssql.close()
        except Exception, e:
            self.exc = e
        finally:
            self.running = False

class SprocTestingErrorThread(threading.Thread):

    def run(self):
        self.running = True
        self.exc = None
        try:
            mssql = _mssql.connect(server, username, password)
            mssql.select_db(database)
            for i in xrange(0, 1000):
                try:
                    proc = mssql.init_procedure('pymssqlErrorThreadTest')
                    proc.execute()
                except:
                    pass
            mssql.close()
        except Exception, e:
            self.exc = e
        finally:
            self.running = False

class ThreadedTests(unittest.TestCase):
    
    def testThreadedUse(self):
        threads = []
        for i in xrange(0, 50):
            thread = TestingThread()
            thread.start()
            threads.append(thread)

        running = True
        while running:
            running = False
            for thread in threads:
                if thread.exc:
                    raise thread.exc
                if thread.running:
                    running = True
                    break

    def testErrorThreadedUse(self):
        threads = []
        for i in xrange(0, 2):
            thread = TestingErrorThread()
            thread.start()
            threads.append(thread)

        running = True
        while running:
            running = False
            for thread in threads:
                if thread.exc:
                    raise thread.exc
                if thread.running:
                    running = True
                    break

    def testErrorSprocThreadedUse(self):

        mssql = _mssql.connect(server, username, password)
        mssql.select_db(database)
        mssql.execute_non_query("""
        CREATE PROCEDURE [dbo].[pymssqlErrorThreadTest]
        AS
        BEGIN
            SELECT unknown_column FROM unknown_table;
        END
        """)

        threads = []
        for i in xrange(0, 5):
            thread = SprocTestingErrorThread()
            thread.start()
            threads.append(thread)

        try:
            running = True
            while running:
                running = False
                for thread in threads:
                    if thread.exc:
                        raise thread.exc
                    if thread.running:
                        running = True
                        break
        finally:
            mssql.execute_non_query("DROP PROCEDURE [dbo].[pymssqlThreadTest]")
            mssql.close()

suite = unittest.TestSuite()
suite.addTest(unittest.makeSuite(ThreadedTests))

if __name__ == '__main__':
    unittest.main()
