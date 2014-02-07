from datetime import datetime
import unittest

import _mssql

class ErrHandleTests(unittest.TestCase):

	def test01DBError(self):
		connection = None
		severity = 8
		dberr = 101
		oserr = 0
		dberrstr = "toblerone1"
		oserrstr = None
		
		expect = "DB-Lib error message %d, severity %d:\n%s\n" % ( dberr, severity, dberrstr )
        
		values = _mssql.test_err_handler( connection, severity, dberr, oserr, dberrstr, oserrstr )
		self.assertEqual( values[0] , 2 )
		self.assertEqual( values[1] , expect )

	def test02OSError(self):
		connection = None
		# EXCOMM
		severity = 9
		dberr = 102
		oserr = 1001
		dberrstr = "toblerone2"
		oserrstr = "scorpion"
		
		expect = "DB-Lib error message %d, severity %d:\n%s\nNet-Lib error during %s (%d)\n" % ( 
			dberr, severity, dberrstr, oserrstr, oserr )
        
		values = _mssql.test_err_handler( connection, severity, dberr, oserr, dberrstr, oserrstr )
		self.assertEqual( values[0] , 2 )
		self.assertEqual( values[1] , expect )

	def test03OSError(self):
		connection = None
		severity = 10
		dberr = 103
		oserr = 1003
		dberrstr = "toblerone3"
		oserrstr = "cabezon"
		
		expect = "DB-Lib error message %d, severity %d:\n%s\nOperating System error during %s (%d)\n" % ( 
			dberr, severity, dberrstr, oserrstr, oserr )
        
		values = _mssql.test_err_handler( connection, severity, dberr, oserr, dberrstr, oserrstr )
		self.assertEqual( values[0] , 2 )
		self.assertEqual( values[1] , expect )

	def test04NoError(self):
		connection = None

		# smaller than min error severity, so no output should be generated
		severity = 5
		dberr = 10
		oserr = 4444
		dberrstr = "toblerone4"
		oserrstr = "limpet"
		
		expect = "" 
        
		values = _mssql.test_err_handler( connection, severity, dberr, oserr, dberrstr, oserrstr )
		self.assertEqual( values[0] , 2 )
		self.assertEqual( values[1] , expect )

if __name__ == "__main__":
	unittest.main()
