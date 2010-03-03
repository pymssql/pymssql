import _mssql
import unittest
import threading
from mssqltests import server, username, password, database

class TestingThread(threading.Thread):

    def run(self):
        self.running = True
        mssql = _mssql.connect(server, username, password)
        mssql.select_db(database)
        for i in xrange(0, 100):
            mssql.execute_query('SELECT %d', (i,))
            for row in mssql:
                assert row[0] == i
        mssql.close()
        self.running = True


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
                if thread.is_alive():
                    running = True
                    break

if __name__ == '__main__':
    unittest.main()
