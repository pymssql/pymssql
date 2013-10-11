"""DB-SIG compliant module for communicating with MS SQL servers"""
#***************************************************************************
#                          pymssql.py  -  description
#
#    begin                : 2003-03-03
#    copyright            : (C) 2003-03-03 by Joon-cheol Park
#    email                : jooncheol@gmail.com
#    current developer    : Andrzej Kukula <akukula@gmail.com>
#    homepage             : http://pymssql.sourceforge.net
#
#***************************************************************************
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301  USA
#***************************************************************************

__author__ = "Joon-cheol Park <jooncheol@gmail.com>, Andrzej Kukula <akukula@gmail.com>"
__version__ = '1.0.3'
import _mssql, types, string, time, datetime, warnings

### module constants

# compliant with DB SIG 2.0
apilevel = '2.0'

# module may be shared, but not connections
threadsafety = 1

# this module use extended python format codes
paramstyle = 'pyformat'

#export column type names from _mssql

class DBAPITypeObject:
	def __init__(self,*values):
		self.values = values
	def __cmp__(self,other):
		if other in self.values:
			return 0
		if other < self.values:
			return 1
		else:
			return -1

STRING = DBAPITypeObject(_mssql.STRING)
BINARY = DBAPITypeObject(_mssql.BINARY)
NUMBER = DBAPITypeObject(_mssql.NUMBER)
DATETIME = DBAPITypeObject(_mssql.DATETIME)
DECIMAL = DBAPITypeObject(_mssql.DECIMAL)

### exception hierarchy

class Warning(StandardError):
	pass

class Error(StandardError):
	pass

class InterfaceError(Error):
	pass

class DatabaseError(Error):
	pass

class DataError(DatabaseError):
	pass

class OperationalError(DatabaseError):
	pass

class IntegrityError(DatabaseError):
	pass

class InternalError(DatabaseError):
	pass

class ProgrammingError(DatabaseError):
	pass

class NotSupportedError(DatabaseError):
	pass


### cursor object

class pymssqlCursor(object):
	"""
	This class represent a database cursor, which is used to issue queries
	and fetch results from a database connection.
	"""

	def __init__(self, src, as_dict):
		"""
		Initialize a Cursor object. 'src' is a pymssqlCnx object instance.
		"""
		self.__source = src
		self.description = None
		self._batchsize = 1
		self._rownumber = 0
		self.as_dict = as_dict

	@property
	def _source(self):
		"""
		INTERNAL PROPERTY. Returns the pymssqlCnx object, and raise
		exception if it's set to None. It's easier than adding necessary
		checks to every other method.
		"""
		if self.__source == None:
			raise InterfaceError, "Cursor is closed."
		return self.__source

	@property
	def rowcount(self):
		"""
		Returns number of rows affected by last operation. In case
		of SELECTs it returns meaningful information only after
		all rows has been fetched.
		"""
		return self._source.rows_affected

	@property
	def connection(self):
		"""
		Returns a reference to the connection object on which the cursor
		was created. This is the extension of the DB-API specification.
		"""
		#warnings.warn("DB-API extension cursor.connection used", SyntaxWarning, 2)
		return self._source

	@property
	def lastrowid(self):
		"""
		Returns identity value of last inserted row. If previous operation
		did not involve inserting a row into a table with identity column,
		None is returned. This is the extension of the DB-API specification.
		"""
		#warnings.warn("DB-API extension cursor.lastrowid used", SyntaxWarning, 2)
		return self._source.identity

	@property
	def rownumber(self):
		"""
		Returns current 0-based index of the cursor in the result set.
		This is the extension of the DB-API specification.
		"""
		#warnings.warn("DB-API extension cursor.rownumber used", SyntaxWarning, 2)
		return self._rownumber

	def close(self):
		"""
		Closes the cursor. The cursor is unusable from this point.
		"""
		self.__source = None
		self.description = None

	def execute(self, operation, *args):
		"""
		Prepare and execute a database operation (query or command).
		Parameters may be provided as sequence or mapping and will be
		bound to variables in the operation. Parameter style for pymssql
		is %-formatting, as in:
		cur.execute('select * from table where id=%d', id)
		cur.execute('select * from table where strname=%s', name)
		Please consult online documentation for more examples and
		guidelines.
		"""
		self.description = None
		self._rownumber = 0  # don't raise warning

		# for this method default value for params cannot be None,
		# because None is a valid value for format string.

		if (args != () and len(args) != 1):
			raise TypeError, "execute takes 1 or 2 arguments (%d given)" % (len(args) + 1,)

		try:
			if args == ():
				self._source.execute_query(operation)
			else:
				self._source.execute_query(operation, args[0])

			self.description = self._source.get_header()
		except _mssql.MssqlDatabaseException, e:
			raise OperationalError, e[0]
		except _mssql.MssqlDriverException, e:
			raise InterfaceError, e[0]

	def executemany(self, operation, param_seq):
		"""
		Execute a database operation repeatedly for each element in the
		parameter sequence. Example:
		cur.executemany("INSERT INTO table VALUES(%s)", [ 'aaa', 'bbb' ])
		"""
		self.description = None

		for params in param_seq:
			self.execute(operation, params)

	def nextset(self):
		"""
		This method makes the cursor skip to the next available result set,
		discarding any remaining rows from the current set. Returns true
		value if next result is available, or None if not.
		"""
		try:
			if self._source.nextresult():
				self._rownumber = 0
				self.description = self._source.get_header()
				return 1
		except _mssql.MssqlDatabaseException, e:
			raise OperationalError, e[0]
		except _mssql.MssqlDriverException, e:
			raise InterfaceError, e[0]

		return None

	def fetchone(self):
		"""
		Fetch the next row of a query result, returning a tuple,
		or None when no more data is available. Raises OperationalError
		if previous call to execute*() did not produce any result set
		or no call was issued yet.
		"""
		if self._source.get_header() == None:
			raise OperationalError, "No data available."

		try:
			if self.as_dict:
				row = iter(self._source).next()
				self._rownumber += 1
				return row
			else:
				row = iter(self._source).next()
				self._rownumber += 1
				return tuple([row[r] for r in sorted(row.keys()) if type(r) == int])

		except StopIteration:
			return None
		except _mssql.MssqlDatabaseException, e:
			raise OperationalError, e[0]
		except _mssql.MssqlDriverException, e:
			raise InterfaceError, e[0]

	def fetchmany(self, size=None):
		"""
		Fetch the next batch of rows of a query result, returning them
		as a list of tuples. An empty list is returned if no more rows
		are available. You can adjust the batch size using the 'size'
		parameter, which is preserved across many calls to this method.
		Raises OperationalError if previous call to execute*() did not
		produce any result set or no call was issued yet.
		"""
		if self._source.get_header() == None:
			raise OperationalError, "No data available."

		if size == None:
			size = self._batchsize

		self._batchsize = size

		try:
			list = []
			for i in xrange(size):
				try:
					row = iter(self._source).next()
					if self.as_dict:
						t = row  # pass through
					else:
						t = tuple([row[r] for r in sorted(row.keys()) if type(r) == int])
					self._rownumber += 1
					list.append(t)
				except StopIteration:
					break
			return list
		except _mssql.MssqlDatabaseException, e:
			raise OperationalError, e[0]
		except _mssql.MssqlDriverException, e:
			raise InterfaceError, e[0]

	def fetchall(self):
		"""
		Fetch all remaining rows of a query result, returning them
		as a list of tuples. An empty list is returned if no more rows
		are available. Raises OperationalError if previous call to
		execute*() did not produce any result set or no call was
		issued yet.
		"""
		if self._source.get_header() == None:
			raise OperationalError, "No data available."

		try:
			if self.as_dict:
				list = [ row for row in self._source ]
			else:
				list = [tuple([row[r] for r in sorted(row.keys()) if type(r) == int]) for row in self._source]
			self._rownumber += len(list)
			return list
		except _mssql.MssqlDatabaseException, e:
			raise OperationalError, e[0]
		except _mssql.MssqlDriverException, e:
			raise InterfaceError, e[0]

	def __iter__(self):
		"""
		Return self to make cursors compatible with
		Python iteration protocol.
		"""
		#warnings.warn("DB-API extension cursor.__iter__() used", SyntaxWarning, 2)
		return self

	def next(self):
		"""
		This method supports Python iterator protocol. It returns next
		row from the currently executing SQL statement. StopIteration
		exception is raised when the result set is exhausted.
		With this method you can iterate over cursors:
		    cur.execute('SELECT * FROM persons')
		    for row in cur:
		        print row[0]
		"""
		#warnings.warn("DB-API extension cursor.next() used", SyntaxWarning, 2)
		try:
			row = iter(self._source).next()
			self._rownumber += 1
			return tuple([row[r] for r in sorted(row.keys()) if type(r) == int])
		except _mssql.MssqlDatabaseException, e:
			raise OperationalError, e[0]
		except _mssql.MssqlDriverException, e:
			raise InterfaceError, e[0]

	def fetchone_asdict(self):
		"""
		Warning: this method is not part of Python DB-API.
		Fetch the next row of a query result, returning a dictionary,
		or None when no more data is available. Data can be accessed
		by 0-based numeric column index, or by column name.
		Raises OperationalError if previous call to execute*() did not
		produce any result set or no call was issued yet.
		"""
		if self._source.get_header() == None:
			raise OperationalError, "No data available."
		
		try:
			row = iter(self._source).next()
			self._rownumber += 1
			return row
		except StopIteration:
			return None
		except _mssql.MssqlDatabaseException, e:
			raise OperationalError, e[0]
		except _mssql.MssqlDriverException, e:
			raise InterfaceError, e[0]

	def fetchmany_asdict(self, size=None):
		"""
		Warning: this method is not part of Python DB-API.
		Fetch the next batch of rows of a query result, returning them
		as a list of dictionaries. An empty list is returned if no more
		rows are available. You can adjust the batch size using the
		'size' parameter, which is preserved across many calls to this
		method. Data can be accessed by 0-based numeric column index,
		or by column name.
		Raises OperationalError if previous call to execute*() did not
		produce any result set or no call was issued yet.
		"""
		if self._source.get_header() == None:
			raise OperationalError, "No data available."

		if size == None:
			size = self._batchsize

		self._batchsize = size

		try:
			list = []
			for i in xrange(size):
				try:
					row = iter(self._source).next()
					self._rownumber += 1
					list.append(row)
				except StopIteration:
					break
			return list
		except _mssql.MssqlDatabaseException, e:
			raise OperationalError, e[0]
		except _mssql.MssqlDriverException, e:
			raise InterfaceError, e[0]

	def fetchall_asdict(self):
		"""
		Warning: this method is not part of Python DB-API.
		Fetch all remaining rows of a query result, returning them
		as a list of dictionaries. An empty list is returned if
		no more rows are available. Data can be accessed by 0-based
		numeric column index, or by column name.
		Raises OperationalError if previous call to execute*() did not
		produce any result set or no call was issued yet.
		"""
		if self._source.get_header() == None:
			raise OperationalError, "No data available."

		try:
			return [ row for row in self._source ]
		except _mssql.MssqlDatabaseException, e:
			raise OperationalError, e[0]
		except _mssql.MssqlDriverException, e:
			raise InterfaceError, e[0]

	def setinputsizes(self, sizes=None):
		"""
		This method does nothing, as permitted by DB-API specification.
		"""
		pass

	def setoutputsize(self, size=None, column=0):
		"""
		This method does nothing, as permitted by DB-API specification.
		"""
		pass

### connection object

class pymssqlCnx:
	"""
	This class represent an MS SQL database connection.
	"""
	def __init__(self, cnx, as_dict):
		self.__cnx = cnx
		self._autocommit = False
		self.as_dict = as_dict
		try:
			self._cnx.execute_non_query("BEGIN TRAN")
		except Exception, e:
			raise OperationalError, "cannot start transaction." + e[0]

	@property
	def _cnx(self):
		"""
		INTERNAL PROPERTY. Returns the _mssql.MssqlConnection object,
		and raise exception if it's set to None. It's easier than adding
		necessary checks to every other method.
		"""

		if self.__cnx == None:
			raise InterfaceError, "Connection is closed."
		return self.__cnx

	def __del__(self):
		if self.__cnx:
			self.__cnx.close()
			self.__cnx = None

	def close(self):
		"""
		Close connection to the database.
		"""
		if self.__cnx:
			self.__cnx.close()
		self.__cnx = None

	def commit(self):
		"""
		Commit transaction which is currently in progress.
		"""

		if self._autocommit == True:
			return
		try:
			self._cnx.execute_non_query("COMMIT TRAN")
			self._cnx.execute_non_query("BEGIN TRAN")
		except Exception, e:
			raise OperationalError, "cannot commit transaction." + e[0]

	def rollback(self):
		"""
		Roll back transaction which is currently in progress.
		"""
		if self._autocommit == True:
			return
		try:
			self._cnx.execute_non_query("ROLLBACK TRAN")
			self._cnx.execute_non_query("BEGIN TRAN")
		except Exception, e:
			raise OperationalError, "cannot roll back transaction: " + e[0]

	def cursor(self):
		"""
		Return cursor object that can be used to make queries and fetch
		results from the database.
		"""
		return pymssqlCursor(self._cnx, self.as_dict)

	def autocommit(self,status):
		"""
		Turn autocommit ON or OFF.
		"""
		if status:
			if self._autocommit == False:
				self._cnx.execute_non_query("ROLLBACK TRAN")
				self._autocommit = True
		else:
			if self._autocommit == True:
				self._cnx.execute_non_query("BEGIN TRAN")
				self._autocommit = False


# connects to a database
def connect(dsn = None, user = "sa", password = "", host = ".", database = "", 
		    timeout = 0, login_timeout = 60, trusted = False, charset = None,
		    as_dict = False, max_conn = 25):
	"""
	Constructor for creating a connection to the database. Returns
	a connection object. Paremeters are as follows:

	dsn       colon-delimited string in form host:dbase:user:pass:opt:tty
	          primarily for compatibility with previous versions of pymssql.
	user      database user to connect as
	password  user's password
	trusted   whether to use Windows Integrated Authentication to connect 
	          instead of SQL autentication with user and password [Win]
	host      database host and instance, valid examples are:
	          r'.\SQLEXPRESS'       - named instance on local machine [Win]
	          r'(local)\SQLEXPRESS' - same as above [Win]
	          r'SQLHOST'            - default instance and port [Win]
	          r'SQLHOST'            - instance set up in freetds.conf [Lnx]
	          r'SQLHOST,1433'       - specified TCP port at a host [ALL]
	          r'SQLHOST:1433'       - same as above [ALL]
	          r'SQLHOST,5000'       - if you have set up an instance
	                                  to listen on port 5000 [ALL]
	          r'SQLHOST:5000'       - same as above [ALL]
	          '.' is assumed is host is not provided
	database  the database you want initially to connect to
	timeout   query timeout in seconds, default 0 (no timeout)
	login_timeout
	          timeout for connection and login in seconds, default 60
	charset
	          character set with which to connect to the database
	as_dict   whether rows should be returned as dictionaries instead of tuples
	max_conn  how many simultaneous connections to allow; default is 25
	
	Examples:
	con = pymssql.connect(host=r'DBHOST,1433', user='username',
                              password='P@ssw0rd', database='MYDB')
	con = pymssql.connect(host=r'DBHOST\INSTANCE',trusted=True)
	"""
	# first try to get params from DSN
	dbhost = ""
	dbbase = ""
	dbuser = ""
	dbpasswd = ""
	dbopt = ""
	dbtty = ""
	try:
		params = string.split(dsn, ":")
		dbhost = params[0]
		dbbase = params[1]
		dbuser = params[2]
		dbpasswd = params[3]
		dbopt = params[4]
		dbtty = params[5]
	except:
		pass

	# override if necessary
	if user != "":
		dbuser = user
	if password != "":
		dbpasswd = password
	if database != "":
		dbbase = database
	if host != "":
		dbhost = host

	# empty host is localhost
	if dbhost == "":
		dbhost = "."
	if dbuser == "":
		dbuser = "sa"

	# add default port
	# it will be deleted, it doesn't work well for different names
	# of local machine; it forces TCP/IP communication for them [on windows]
	#	if ":" not in dbhost and "," not in dbhost and "\\" not in dbhost:
	#		dbhost += ",1433"

	_mssql.login_timeout = login_timeout

	# open the connection
	try:
		if dbbase != "":
			con = _mssql.connect(dbhost, dbuser, dbpasswd, trusted, charset, database, max_conn=max_conn)
		else:
			con = _mssql.connect(dbhost, dbuser, dbpasswd, trusted, charset, max_conn=max_conn)
	except _mssql.MssqlDatabaseException, e:
		raise OperationalError, e[0]
	except _mssql.MssqlDriverException, e:
		raise InterfaceError, e[0]
	
	# default query timeout
	try:
		timeout = int(timeout)
	except ValueError, e:
		timeout = 0

	if timeout != 0:
		con.query_timeout = timeout

	return pymssqlCnx(con, as_dict)
