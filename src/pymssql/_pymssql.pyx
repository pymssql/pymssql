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
import itertools
import time
import uuid

from pymssql import _mssql
from pymssql cimport _mssql
from cpython cimport bool
from libc.string cimport strlen
from .sqlfront cimport BYTE

cdef extern from "version.h":
    const char *PYMSSQL_VERSION

__author__ = 'Damien Churchill <damoxc@gmail.com>'
__full_version__ = PYMSSQL_VERSION.decode('ascii')
__version__ = '.'.join(__full_version__.split('.')[:3])
VERSION = tuple(int(c) if c.isdigit() else c for c in __full_version__.split('.')[:3])

# Strives for compliance with DB-API 2.0 (PEP 249)
# http://www.python.org/dev/peps/pep-0249/
apilevel = '2.0'

# module may be shared, but not connections
threadsafety = 1

# this module uses extended python format codes
paramstyle = 'pyformat'

# Singleton for parameterless queries
NoParams = _mssql.NoParams


def _quote_ident(name):
    """Quote a SQL identifier with brackets. An embedded ] is escaped as ]]."""
    return '[' + name.replace(']', ']]') + ']'


def _bcp_column_ddl(column):
    """DDL for one column of the staging table. Nullable so FreeTDS can bulk-copy it."""
    name = column['system_type_name'].lower()
    max_length = column['max_length']
    precision = column['precision']
    scale = column['scale']
    if name in ('varchar', 'char', 'varbinary', 'binary'):
        size = 'max' if max_length < 0 else str(max_length)
        type_sql = f'{name}({size})'
    elif name in ('nvarchar', 'nchar'):
        size = 'max' if max_length < 0 else str(max_length // 2)
        type_sql = f'{name}({size})'
    elif name in ('decimal', 'numeric'):
        type_sql = f'{name}({precision},{scale})'
    elif name in ('datetime2', 'datetimeoffset', 'time'):
        type_sql = f'{name}({scale})'
    else:
        type_sql = name
    return f'{_quote_ident(column["name"])} {type_sql} NULL'


_NO_ROW = object()


def _peek(iterable):
    """
    Return the first item and an iterator that still yields it.

    The caller must consume the returned iterator. next() has already
    removed the first item, and the input may be a one-shot generator.
    The first value is _NO_ROW when the iterable is empty.
    """
    iterator = iter(iterable)
    try:
        first = next(iterator)
    except StopIteration:
        return _NO_ROW, iterator
    return first, itertools.chain((first,), iterator)


def _needs_server_default_insert(columns, sent_ids):
    """
    True when every omitted NOT NULL column can take a server default.

    columns: catalog rows from _fetch_bcp_columns. Each row is a dict of
    sys.columns fields (column_id, name, is_nullable, has_default, ...).
    sent_ids: column_id values the bulk-copy row binds. These are
    sys.columns.column_id ordinals, not column names. A column whose
    column_id is absent from this sequence is omitted.

    FreeTDS rejects a bulk-copy row that leaves a NOT NULL column unbound,
    even when that column has a DEFAULT. Nullable omitted columns already
    receive their default from SQL Server, so those stay on the BCP path.
    """
    sent = set(sent_ids)
    found = False
    for column in columns:
        has_data = column['column_id'] in sent
        if has_data or column['is_nullable'] or column['is_identity'] or column['is_computed']:
            continue
        if not column['has_default']:
            return False
        found = True
    return found


def _fetch_bcp_columns(conn, table_name):
    """
    Return catalog rows for a bulk-copy target, ordered by column_id.

    A name starting with '#' is a temp table, so the lookup uses
    tempdb.sys.columns and tempdb.sys.default_constraints. Each row has the
    type metadata for the staging table, plus nullability, identity, computed,
    and default flags used to choose the bulk-copy path.
    """
    if table_name.startswith('#'):
        catalog = 'tempdb'
        object_name = f'tempdb..{table_name}'
    else:
        catalog = ''
        object_name = table_name
    prefix = f'{catalog}.' if catalog else ''
    columns_view = f'{prefix}sys.columns'
    defaults_view = f'{prefix}sys.default_constraints'
    query = (
        "SELECT c.column_id, c.name, TYPE_NAME(c.system_type_id) AS system_type_name, "
        "c.max_length, c.precision, c.scale, c.is_identity, c.is_nullable, c.is_computed, "
        "CASE WHEN dc.parent_column_id IS NULL THEN 0 ELSE 1 END AS has_default "
        f"FROM {columns_view} c "
        f"LEFT JOIN {defaults_view} dc "
        "ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id "
        "WHERE c.object_id = OBJECT_ID(%s) "
        "ORDER BY c.column_id"
    )
    conn.execute_query(query, object_name)
    return list(conn)

from pymssql._mssql import set_wait_callback
from pymssql.exceptions import *

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
Binary = bytearray


# Bulk copy hints
cdef char* TABLOCK = "TABLOCK"
cdef char* CHECK_CONSTRAINTS = "CHECK_CONSTRAINTS"
cdef char* FIRE_TRIGGERS = "FIRE_TRIGGERS"

cdef int TABLOCK_LEN = strlen(TABLOCK)
cdef int CHECK_CONSTRAINTS_LEN = strlen(CHECK_CONSTRAINTS)
cdef int FIRE_TRIGGERS_LEN = strlen(FIRE_TRIGGERS)


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
    cdef int _arraysize

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

    property arraysize:
        """
        This read/write attribute specifies the number of rows to fetch at a time
        with .fetchmany(). It defaults to 1 meaning to fetch a single row at a time.
        """
        def __get__(self):
            return self._arraysize

        def __set__(self, value):
            cdef int val = int(value)
            if val < 0:
                raise ValueError("The 'arraysize' attribute must be >= 0.")
            self._arraysize = val

    def __init__(self, conn, as_dict, autocommit, arraysize=1):
        self.conn = conn
        self._autocommit = autocommit
        self.as_dict = as_dict
        self.arraysize = arraysize

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

    def cursor(self, as_dict=None, arraysize=None):
        """
        Return cursor object that can be used to make queries and fetch
        results from the database.
        """
        if as_dict is None:
            as_dict = self.as_dict
        return Cursor(self, as_dict, arraysize or self.arraysize)

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

    def _bulk_copy_with_server_defaults(self, table_name, elements, column_ids, columns_by_id,
                                         batch_size, tablock):
        """
        Load supplied columns with BCP, then INSERT so SQL Server fills
        omitted NOT NULL columns from their defaults.

        FreeTDS will not send a row that leaves a NOT NULL column unbound.
        """
        ordered = []
        for column_id in column_ids:
            try:
                ordered.append(columns_by_id[column_id])
            except KeyError:
                raise ValueError(f'Unknown bulk copy column id {column_id}')
        stage = f'#pymssql_bcp_{uuid.uuid4().hex}'
        column_ddl = ', '.join(_bcp_column_ddl(column) for column in ordered)
        column_list = ', '.join(_quote_ident(column['name']) for column in ordered)
        hint = ' WITH (TABLOCK)' if tablock else ''
        identity_sent = any(column['is_identity'] for column in ordered)
        cursor = self.cursor()
        cursor.execute(f'CREATE TABLE {stage} ({column_ddl})')
        try:
            self.bulk_copy(stage, elements, column_ids=list(range(1, len(ordered) + 1)), batch_size=batch_size)
            if identity_sent:
                cursor.execute(f'SET IDENTITY_INSERT {table_name} ON')
            q = f'INSERT INTO {table_name}{hint} ({column_list}) SELECT {column_list} FROM {stage}'
            cursor.execute(q)
        finally:
            if identity_sent:
                try:
                    cursor.execute(f'SET IDENTITY_INSERT {table_name} OFF')
                except Exception:
                    pass
            try:
                cursor.execute(f'DROP TABLE {stage}')
            except Exception:
                pass

    cpdef bulk_copy(self,
                    table_name,
                    elements,
                    column_ids=None,
                    batch_size=1000,
                    tablock=False,
                    check_constraints=False,
                    fire_triggers=False):
        cdef int batch_counter = 0
        cdef _mssql.MSSQLConnection conn = self._conn
        cdef object unicode_column_ids = set()
        cdef object identity_column_ids = set()
        cdef object column_id
        cdef bint keep_identity = False

        columns = _fetch_bcp_columns(conn, table_name)
        columns_by_id = {}
        for column in columns:
            columns_by_id[column['column_id']] = column
            if column['system_type_name'] in ('nchar', 'ntext', 'nvarchar', 'xml'):
                unicode_column_ids.add(column['column_id'])
            if column['is_identity']:
                identity_column_ids.add(column['column_id'])

        if column_ids is None:
            # Row width is unknown until a row is seen. Column ids are 1..len(row).
            first, elements = _peek(elements)
            if first is not _NO_ROW:
                inferred_ids = list(range(1, len(first) + 1))
                if _needs_server_default_insert(columns, inferred_ids):
                    self._bulk_copy_with_server_defaults(
                        table_name, elements, inferred_ids, columns_by_id, batch_size, tablock)
                    return
        elif _needs_server_default_insert(columns, column_ids):
            self._bulk_copy_with_server_defaults(
                table_name, elements, column_ids, columns_by_id, batch_size, tablock)
            return

        conn.bcp_init(table_name)

        if column_ids is None:
            keep_identity = bool(identity_column_ids)
        else:
            for column_id in column_ids:
                if column_id in identity_column_ids:
                    keep_identity = True
                    break

        if keep_identity:
            conn.bcp_keep_identity()

        if tablock:
            conn.bcp_hint(<BYTE*> TABLOCK, TABLOCK_LEN)
        if check_constraints:
            conn.bcp_hint(<BYTE*> CHECK_CONSTRAINTS, CHECK_CONSTRAINTS_LEN)
        if fire_triggers:
            conn.bcp_hint(<BYTE*> FIRE_TRIGGERS, FIRE_TRIGGERS_LEN)

        for element in elements:
            if batch_counter == batch_size:
                conn.bcp_batch()
                batch_counter = 0

            conn.bcp_sendrow(element, column_ids, unicode_column_ids)
            batch_counter += 1
        conn.bcp_done()


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
    cdef int _rownumber
    cdef bool as_dict
    cdef object _returnvalue
    cdef int _arraysize

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

    property arraysize:
        """
        This read/write attribute specifies the number of rows to fetch at a time
        with .fetchmany(). It defaults to 1 meaning to fetch a single row at a time.
        """
        def __get__(self):
            return self._arraysize

        def __set__(self, value):
            cdef int val = int(value)
            if val < 0:
                raise ValueError("The 'arraysize' attribute must be >= 0.")
            self._arraysize = val

    def __init__(self, conn, as_dict, arraysize=1):
        self.conn = conn
        self.description = None
        self._rownumber = 0
        self._returnvalue = None
        self.as_dict = as_dict
        self.arraysize = arraysize

    def __iter__(self):
        """
        Return self to make cursors compatible with Python iteration
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

            db_type = _mssql.py2db_type(param_type, param_value)

            proc.bind(param_value, db_type, output=param_output)
        try:
            self._returnvalue = proc.execute()
            self.description = self._source._conn.get_header()
        except _mssql.MSSQLDatabaseException, e:
            raise DatabaseError, e.args[0]
        return tuple([proc.parameters[p] for p in proc.parameters])

    def close(self):
        """
        Closes the cursor. The cursor is unusable from this point.
        """
        self.conn = None
        self.description = None

    def execute(self, operation, params=NoParams):
        self.description = None
        self._rownumber = 0

        try:
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

    def executemany(self, operation, seq_of_parameters, *, batch_size=-1):
        self.description = None
        self._rownumber = -1
        if batch_size == -1:
            batch_size = self.arraysize
        if batch_size == 1:
            rownumber = 0
            for params in seq_of_parameters:
                self.execute(operation, params)
                # support correct rowcount across multiple executes
                rownumber += self._rownumber
            self._rownumber = rownumber
        else:
            self._source._conn.executemany(operation, seq_of_parameters, batch_size)
            self.description = self._source._conn.get_header()

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
            size = self.arraysize
        else:
            self.arraysize = size

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
        host='', appname=None, port='1433', encryption=None, read_only=False,
        conn_properties=None, autocommit=False, tds_version=None,
        use_datetime2=False,
        arraysize=1):
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
    :keyword autocommit: Whether to use default autocommitting mode or not
    :type autocommit: boolean
    :keyword tds_version: TDS protocol version to use.
    :type tds_version: string
    :keyword use_datetime2: Whether to use datetime.datetime conversion compatible with DATETIME2
    :type use_datetime2: bool
    :keyword arraysize:
        This read/write attribute specifies the number of rows to fetch at a time
        with .fetchmany(). It defaults to 1 meaning to fetch a single row at a time.
        Default value: 1.
    :type arraysize: int
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
        conn = _mssql.connect(server=server, encryption=encryption,
                              user=user, password=password,
                              charset=charset, database=database,
                              appname=appname, port=port, tds_version=tds_version,
                              read_only=read_only,
                              use_datetime2=use_datetime2,
                              conn_properties=conn_properties)

    except _mssql.MSSQLDatabaseException, e:
        raise OperationalError(e.args[0])

    except _mssql.MSSQLDriverException, e:
        raise InterfaceError(e.args[0])


    if timeout != 0:
        conn.query_timeout = timeout

    return Connection(conn, as_dict, autocommit, arraysize=arraysize)

def get_max_connections():
    """
    Get the maximum number of simultaneous connections pymssql will open
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

def get_dbversion():
    """
    Return string representing the version of db-lib.
    """
    return _mssql.get_dbversion()

get_freetds_version = get_dbversion

def version_info():
    """
        Returns string with version information about pymssql, FreeTDS, Python and OS.
    """

    import platform
    import sys
    import io

    output = io.StringIO()
    print("System:", file=output)
    print("platform.system()       :", platform.system(), file=output)
    print("platform.architecture() :", platform.architecture(), file=output)
    if platform.system() != 'Windows':
        print("platform.libc_ver()     :", platform.libc_ver(), file=output)

    print("Python:", file=output)
    print("sys.version             :", sys.version, file=output)

    print("pymssql:", file=output)
    print("VERSION            :", VERSION, file=output)
    print("version            :", __version__, file=output)
    print("full_version       :", __full_version__, file=output)
    print("dbversion          :", get_dbversion(), file=output)

    print("_mssql:", file=output)
    print("VERSION            :", _mssql.VERSION, file=output)
    print("version            :", _mssql.__version__, file=output)
    print("full_version       :", _mssql.__full_version__, file=output)
    print("dbversion          :", _mssql.get_dbversion(), file=output)
    print("login_timeout      :", _mssql.login_timeout, file=output)
    print("min_error_severity :", _mssql.min_error_severity, file=output)
    contents = output.getvalue()
    output.close()
    return contents
