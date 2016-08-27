"""DB-SIG compliant module for communicating with MS SQL servers"""
# pymssql.pyx
#
#   Copyright (C) 2003 Joon-cheol Park <jooncheol@gmail.com>
#                 2008 Andrzej Kukula <akukula@gmail.com>
#                 2009 Damien Churchill <damoxc@gmail.com>
#
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

import datetime
import time

import _mssql
cimport _mssql
from cpython cimport bool, PY_MAJOR_VERSION

cdef extern from "version.h":
    const char *PYMSSQL_VERSION

__author__ = 'Damien Churchill <damoxc@gmail.com>'
__full_version__ = PYMSSQL_VERSION.decode('ascii')
__version__ = '.'.join(__full_version__.split('.')[:3])
VERSION = tuple(int(c) for c in __full_version__.split('.')[:3])

# Strives for compliance with DB-API 2.0 (PEP 249)
# http://www.python.org/dev/peps/pep-0249/
apilevel = '2.0'

# module may be shared, but not connections
threadsafety = 1

# this module uses extended python format codes
paramstyle = 'pyformat'

from _mssql import set_wait_callback

# store a tuple of programming error codes
cdef object prog_errors = (
    102,    # syntax error
    207,    # invalid column name
    208,    # invalid object name
    2812,   # unknown procedure
    4104    # multi-part identifier could not be bound
)

# store a tuple of integrity error codes
cdef object integrity_errors = (
    515,    # NULL insert
    547,    # FK related
    2601,   # violate unique index
    2627,   # violate UNIQUE KEY constraint
)

class DBAPIType:

    def __init__(self, value):
        self.value = value

    def __cmp__(self, other):
        if other == self.value:
            return 0
        if other < self.value:
            return 1
        else:
            return -1

    def __eq__(self, other):
        return (other == self.value)

    def __repr__(self):
        return '<DBAPIType %s>' % self.value

STRING = DBAPIType(_mssql.STRING)
BINARY = DBAPIType(_mssql.BINARY)
NUMBER = DBAPIType(_mssql.NUMBER)
DATETIME = DBAPIType(_mssql.DATETIME)
DECIMAL = DBAPIType(_mssql.DECIMAL)

Date = datetime.date
Time = datetime.time
Timestamp = datetime.datetime
DateFromTicks = lambda ticks: Date(*time.localtime(ticks)[:3])
TimeFromTicks = lambda ticks: Time(*time.localtime(ticks)[3:6])
TimestampFromTicks = lambda ticks: Timestamp(*time.localtime(ticks)[:6])
Binary = bytes

cdef dict DBTYPES = {
    'bool': _mssql.SQLBITN,
    'str': _mssql.SQLVARCHAR,
    'unicode': _mssql.SQLVARCHAR,
    'Decimal': _mssql.SQLDECIMAL,
    'datetime': _mssql.SQLDATETIME,
    'date': _mssql.SQLDATETIME,
    'float': _mssql.SQLFLT8,
    #Dump type for work vith None
    'NoneType': _mssql.SQLVARCHAR,
}

cdef int py2db_type(py_type, value):
    if PY_MAJOR_VERSION == 3:
        if py_type == 'int':
            if value is not None and value >= -2147483648 and value <= 2147483647:  # -2^31 - 2^31-1
                return _mssql.SQLINTN
            else:
                return _mssql.SQLINT8
    else:
        if py_type == 'int':
            return _mssql.SQLINTN
        if py_type == 'long':
            return _mssql.SQLINT8

    return DBTYPES[py_type]

try:
    StandardError
except NameError:
    StandardError = Exception

# exception hierarchy
class Warning(StandardError):
    pass

class Error(StandardError):
    pass

class InterfaceError(Error):
    pass

class DatabaseError(Error):
    pass

class DataError(Error):
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

class ColumnsWithoutNamesError(InterfaceError):
    def __init__(self, columns_without_names):
        self.columns_without_names = columns_without_names

    def __str__(self):
        return 'Specified as_dict=True and ' \
            'there are columns with no names: %r' \
            % (self.columns_without_names,)

def row2dict(row):
    """Filter dict so it only has string keys; used when as_dict == True"""
    return dict([(k, v) for k, v in row.items() if hasattr(k, 'startswith')])

# stored procedure output parameter
cdef class output:

    cdef object _type
    cdef object _value

    property type:
        """
        This is the type of the parameter.
        """
        def __get__(self):
            return self._type

    property value:
        """
        This is the value of the parameter.
        """
        def __get__(self):
            return self._value


    def __init__(self, param_type, value=None):
        self._type = param_type
        self._value = value

######################
## Connection class ##
######################
cdef class Connection:
    """
    This class represents an MS-SQL database connection.
    """

    cdef bool _as_dict
    cdef bool _autocommit
    cdef _mssql.MSSQLConnection conn

    property as_dict:
        """
        Instructs all cursors this connection creates to return results
        as a dictionary rather than a tuple.
        """
        def __get__(self):
            return self._as_dict
        def __set__(self, value):
            self._as_dict = value

    property autocommit_state:
        """
        The current state of autocommit on the connection.
        """
        def __get__(self):
            return self._autocommit

    property _conn:
        """
        INTERNAL PROPERTY. Returns the _mssql.MSSQLConnection object, and
        raise exception if it's set to None. It's easier than adding the
        necessary checks to every other method.
        """
        def __get__(self):
            if self.conn == None:
                raise InterfaceError('Connection is closed.')
            return self.conn

    def __init__(self, conn, as_dict, autocommit):
        self.conn = conn
        self._autocommit = autocommit
        self.as_dict = as_dict

        if not autocommit:
            try:
                self._conn.execute_non_query('BEGIN TRAN')
            except Exception, e:
                raise OperationalError('Cannot start transaction: ' + str(e.args[0]))

    def __dealloc__(self):
        if self.conn:
            self.close()

    def autocommit(self, status):
        """
        Turn autocommit ON or OFF.
        """

        if status == self._autocommit:
            return

        tran_type = 'ROLLBACK' if status else 'BEGIN'
        self._conn.execute_non_query('%s TRAN' % tran_type)

        self._autocommit = status

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()

    def close(self):
        """
        Close the connection to the database. Implicitly rolls back all
        uncommitted transactions.
        """
        if self.conn:
            self.conn.close()
        self.conn = None

    def commit(self):
        """
        Commit transaction which is currently in progress.
        """

        if self._autocommit == True:
            return

        try:
            self._conn.execute_non_query('COMMIT TRAN')
            self._conn.execute_non_query('BEGIN TRAN')
        except Exception, e:
            raise OperationalError('Cannot commit transaction: ' + str(e.args[0]))

    def cursor(self, as_dict=None):
        """
        Return cursor object that can be used to make queries and fetch
        results from the database.
        """
        if as_dict is None:
            as_dict = self.as_dict
        return Cursor(self, as_dict)

    def rollback(self):
        """
        Roll back transaction which is currently in progress.
        """
        if self._autocommit == True:
            return

        try:
            self._conn.execute_non_query('ROLLBACK TRAN')
        except _mssql.MSSQLException, e:
            # PEP 249 indicates that we have contract with the user that we will
            # always have a transaction in place if autocommit is False.
            # Therefore, it seems logical to ignore this exception since it
            # indicates a situation we shouldn't ever encounter anyway.  However,
            # it can happen when an error is severe enough to cause a
            # "batch-abort".  In that case, SQL Server *implicitly* rolls back
            # the transaction for us (how helpful!).  But there doesn't seem
            # to be any way for us to know if an error is severe enough to cause
            # a batch abort:
            #   http://stackoverflow.com/questions/5877162/why-does-microsoft-sql-server-implicitly-rollback-when-a-create-statement-fails
            #
            # the alternative is to do 'select @@trancount' before each rollback
            # but that is slower and doesn't seem to offer any benefit.
            if 'The ROLLBACK TRANSACTION request has no corresponding BEGIN TRANSACTION' not in str(e):
                raise
        try:
            self._conn.execute_non_query('BEGIN TRAN')
        except Exception, e:
            raise OperationalError('Cannot begin transaction: ' + str(e.args[0]))

##################
## Cursor class ##
##################
cdef class Cursor:
    """
    This class represents a database cursor, which is used to issue queries
    and fetch results from a database connection.
    """

    cdef Connection conn
    cdef public tuple description
    cdef int batchsize
    cdef int _batchsize
    cdef int _rownumber
    cdef bool as_dict
    cdef object _returnvalue

    property connection:
        def __get__(self):
            return self.conn

    property lastrowid:
        def __get__(self):
            return self.conn.conn.identity

    property rowcount:
        def __get__(self):
            return self._rownumber

    property returnvalue:
        def __get__(self):
            return self._returnvalue

    property rownumber:
        def __get__(self):
            return self._rownumber

    property _source:
        def __get__(self):
            if self.conn == None:
                raise InterfaceError('Cursor is closed.')
            return self.conn

    def __init__(self, conn, as_dict):
        self.conn = conn
        self.description = None
        self._batchsize = 1
        self._rownumber = 0
        self._returnvalue = None
        self.as_dict = as_dict

    def __iter__(self):
        """
        Return self to make cursors compatibile with Python iteration
        protocol.
        """
        return self

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()

    def callproc(self, str procname, parameters=()):
        """
        Call a stored procedure with the given name.

        :param procname: The name of the procedure to call
        :type procname: str
        :keyword parameters: The optional parameters for the procedure
        :type parameters: sequence
        """
        self._returnvalue = None
        proc = self._source._conn.init_procedure(procname)
        for parameter in parameters:
            if type(parameter) is output:
                param_type = parameter.type
                param_value = parameter.value
                param_output = True
            else:
                param_type = type(parameter)
                param_value = parameter
                param_output = False

            try:
                type_name = param_type.__name__
                db_type = py2db_type(type_name, param_value)
            except (AttributeError, KeyError):
                raise NotSupportedError('Unable to determine database type from python %s type' % type_name)

            proc.bind(param_value, db_type, output=param_output)
        try:
            self._returnvalue = proc.execute()
        except _mssql.MSSQLDatabaseException, e:
            raise DatabaseError, e.args[0]
        return tuple([proc.parameters[p] for p in proc.parameters])

    def close(self):
        """
        Closes the cursor. The cursor is unusable from this point.
        """
        self.conn = None
        self.description = None

    def execute(self, operation, params=()):
        self.description = None
        self._rownumber = 0

        try:
            if not params:
                self._source._conn.execute_query(operation)
            else:
                self._source._conn.execute_query(operation, params)
            self.description = self._source._conn.get_header()
            self._rownumber = self._source._conn.rows_affected

            if self.as_dict and self.description:
                columns_without_names = [
                    idx
                    for idx, column_descriptor in enumerate(self.description)
                    if len(column_descriptor[0]) == 0
                ]
                if columns_without_names:
                    raise ColumnsWithoutNamesError(columns_without_names)

        except _mssql.MSSQLDatabaseException, e:
            if e.number in prog_errors:
                raise ProgrammingError, e.args[0]
            if e.number in integrity_errors:
                raise IntegrityError, e.args[0]
            raise OperationalError, e.args[0]
        except _mssql.MSSQLDriverException, e:
            raise InterfaceError, e.args[0]

    def executemany(self, operation, params_seq):
        self.description = None
        rownumber = 0
        for params in params_seq:
            self.execute(operation, params)
            # support correct rowcount across multiple executes
            rownumber += self._rownumber
        self._rownumber = rownumber

    def nextset(self):
        try:
            if not self._source._conn.nextresult():
                return None
            self._rownumber = 0
            self.description = self._source._conn.get_header()
            return 1

        except _mssql.MSSQLDatabaseException, e:
            raise OperationalError, e.args[0]
        except _mssql.MSSQLDriverException, e:
            raise InterfaceError, e.args[0]

    cdef getrow(self):
        """
        Helper method used by fetchone and fetchmany to fetch and handle
        converting the row if as_dict = True.
        """
        row_format = _mssql.ROW_FORMAT_DICT if self.as_dict else _mssql.ROW_FORMAT_TUPLE
        row = next(self._source._conn.get_iterator(row_format))
        if not self.as_dict:
            return row
        return row2dict(row)

    def fetchone(self):
        if self.description is None:
            raise OperationalError('Statement not executed or executed statement has no resultset')

        try:
            return self.getrow()
        except StopIteration:
            self._rownumber = self._source._conn.rows_affected
            return None
        except _mssql.MSSQLDatabaseException, e:
            raise OperationalError, e.args[0]
        except _mssql.MSSQLDriverException, e:
            raise InterfaceError, e.args[0]

    def fetchmany(self, size=None):
        if self.description is None:
            raise OperationalError('Statement not executed or executed statement has no resultset')

        if size == None:
            size = self._batchsize
        self.batchsize = size

        try:
            rows = []
            for i in xrange(size):
                try:
                    rows.append(self.getrow())
                except StopIteration:
                    self._rownumber = self._source._conn.rows_affected
                    break
            return rows
        except _mssql.MSSQLDatabaseException, e:
            raise OperationalError, e.args[0]
        except _mssql.MSSQLDriverException, e:
            raise InterfaceError, e.args[0]

    def fetchall(self):
        if self.description is None:
            raise OperationalError('Statement not executed or executed statement has no resultset')

        try:
            rows = []
            while True:
                try:
                    rows.append(self.getrow())
                except StopIteration:
                    break
            self._rownumber = self._source._conn.rows_affected
            return rows
        except _mssql.MSSQLDatabaseException, e:
            raise OperationalError, e.args[0]
        except _mssql.MSSQLDriverException, e:
            raise InterfaceError, e.args[0]

    def __next__(self):
        try:
            row = self.getrow()
            self._rownumber += 1
            return row

        except _mssql.MSSQLDatabaseException, e:
            raise OperationalError, e.args[0]
        except _mssql.MSSQLDriverException, e:
            raise InterfaceError, e.args[0]

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

def connect(server='.', user=None, password=None, database='', timeout=0,
        login_timeout=60, charset='UTF-8', as_dict=False,
        host='', appname=None, port='1433', conn_properties=None, autocommit=False, tds_version=None):
    """
    Constructor for creating a connection to the database. Returns a
    Connection object.

    :param server: database host
    :type server: string
    :param user: database user to connect as. Default value: None.
    :type user: string
    :param password: user's password. Default value: None.
    :type password: string
    :param database: the database to initially connect to
    :type database: string
    :param timeout: query timeout in seconds, default 0 (no timeout)
    :type timeout: int
    :param login_timeout: timeout for connection and login in seconds, default 60
    :type login_timeout: int
    :param charset: character set with which to connect to the database
    :type charset: string
    :keyword as_dict: whether rows should be returned as dictionaries instead of tuples.
    :type as_dict: boolean
    :keyword appname: Set the application name to use for the connection
    :type appname: string
    :keyword port: the TCP port to use to connect to the server
    :type port: string
    :keyword conn_properties: SQL queries to send to the server upon connection
                              establishment. Can be a string or another kind
                              of iterable of strings
    :keyword autocommit: Whether to use default autocommiting mode or not
    :type autocommit: boolean
    :keyword tds_version: TDS protocol version to use.
    :type tds_version: string
    """

    # set the login timeout
    try:
        login_timeout = int(login_timeout)
    except ValueError:
        login_timeout = 0

    _mssql.login_timeout = login_timeout

    # default query timeout
    try:
        timeout = int(timeout)
    except ValueError:
        timeout = 0

    if host:
        server = host

    try:
        conn = _mssql.connect(server=server, user=user, password=password,
                              charset=charset, database=database,
                              appname=appname, port=port, tds_version=tds_version,
                              conn_properties=conn_properties)

    except _mssql.MSSQLDatabaseException, e:
        raise OperationalError(e.args[0])

    except _mssql.MSSQLDriverException, e:
        raise InterfaceError(e.args[0])


    if timeout != 0:
        conn.query_timeout = timeout

    return Connection(conn, as_dict, autocommit)

def get_max_connections():
    """
    Get the maximum number of simulatenous connections pymssql will open
    to the server.
    """
    return _mssql.get_max_connections()

def set_max_connections(int limit):
    """
    Set maximum simultaneous connections db-lib will open to the server.

    :param limit: the connection limit
    :type limit: int
    """
    _mssql.set_max_connections(limit)

cdef extern from "sybdb.h":
    char *dbversion()

# Only recent versions of FreeTDS have the ct_config function
# so this can break builds
# Maybe later we can enable this or make it conditional
DEF HAS_CT_CONFIG = False
IF HAS_CT_CONFIG:
    cdef extern from "ctpublic.h":
        ctypedef int      CS_INT
        ctypedef void     CS_VOID
        struct            _CS_CONTEXT
        ctypedef _CS_CONTEXT CS_CONTEXT
        ctypedef CS_INT   CS_RETCODE

        int CS_GET, CS_VERSION

        CS_RETCODE ct_config(CS_CONTEXT * ctx, CS_INT action, CS_INT property,
                             CS_VOID * buffer, CS_INT buflen, CS_INT * outlen)

    def get_freetds_version():
        cdef CS_CONTEXT *ctx = NULL
        cdef char buf[256]
        cdef int outlen

        ret = ct_config(ctx, CS_GET, CS_VERSION, buf, 256, &outlen)
        return buf

def get_dbversion():
    return dbversion()
