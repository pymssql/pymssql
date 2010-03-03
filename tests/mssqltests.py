import unittest
import _mssql

server = 'localhost'
username = 'sa'
password = 'passsword'
database = 'tempdb'

class MssqlTestCase(unittest.TestCase):
    def setUp(self):
        self.mssql = _mssql.connect(server, username, password)
        self.mssql.select_db(database)
    
    def tearDown(self):
        self.mssql.close()
