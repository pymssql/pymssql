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


class ThreadedTests(unittest.TestCase):
    
    def testThreadedUse(self):
        threads = []
        for i in xrange(0, 5):
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

suite = unittest.TestSuite()
suite.addTest(unittest.makeSuite(ThreadedTests))

if __name__ == '__main__':
    unittest.main()
