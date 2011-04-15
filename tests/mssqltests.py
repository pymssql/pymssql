import sys
import _mssql
import unittest
import ConfigParser

_parser = ConfigParser.ConfigParser({
    'server': 'localhost',
    'username': 'sa',
    'password': '',
    'database': 'tempdb',
    'port': '1433',
    'ipaddress': '127.0.0.1',
    'instance': '',
})
_parser.read('tests.cfg')

if sys.argv[1:] and _parser.has_section(sys.argv[1]):
    section = sys.argv[1]
else:
    section = 'DEFAULT'

server = _parser.get(section, 'server')
username = _parser.get(section, 'username')
password = _parser.get(section, 'password')
database = _parser.get(section, 'database')
port = _parser.get(section, 'port')
ipaddress = _parser.get(section, 'ipaddress')
instance = _parser.get(section, 'instance')

class MSSQLTestCase(unittest.TestCase):
    def setUp(self):
        self.mssql = _mssql.connect(server, username, password, port=port)
        self.mssql.select_db(database)

    def tearDown(self):
        self.mssql.close()
