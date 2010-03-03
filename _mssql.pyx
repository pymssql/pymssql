"""
This is an effort to convert the pymssql low-level C module to Cython.
"""

DEF PYMSSQL_DEBUG = 0

import decimal
import datetime
from sqlfront cimport *
from stdio cimport fprintf, sprintf, FILE
from stdlib cimport strlen

cdef extern int rmv_lcl(char *, char *, size_t)

cdef extern from "stdio.h" nogil:
    cdef FILE *stderr

# Forward declare some types and variables
cdef class MSSQLConnection

# Vars to store messages from the server in
cdef int _mssql_last_msg_no = 0
cdef int _mssql_last_msg_severity = 0
cdef int _mssql_last_msg_state = 0
cdef char *_mssql_last_msg_str = ""

cdef _decimal_context

# List to store the connection objects in
cdef list connection_object_list = list()

#############################
## DB-API type definitions ##
#############################
cdef enum:
    STRING = 1
    BINARY = 2
    NUMBER = 3
    DATETIME = 4
    DECIMAL = 5

##################
## DB-LIB types ##
##################
cdef enum:
    SQLBINARY = SYBBINARY
    SQLBIT = SYBBIT
    SQLCHAR = SYBCHAR
    SQLDATETIME = SYBDATETIME
    SQLDATETIM4 = SYBDATETIME4
    SQLDATETIMN = SYBDATETIMN
    SQLDECIMAL = SYBDECIMAL
    SQLFLT4 = SYBREAL
    SQLFLT8 = SYBFLT8
    SQLFLTN = SYBFLTN
    SQLIMAGE = SYBIMAGE
    SQLINT1 = SYBINT1
    SQLINT2 = SYBINT2
    SQLINT4 = SYBINT4
    SQLINT8 = SYBINT8
    SQLINTN = SYBINTN
    SQLMONEY = SYBMONEY
    SQLMONEY4 = SYBMONEY4
    SQLMONEYN = SYBMONEYN
    SQLNUMERIC = SYBNUMERIC
    SQLREAL = SYBREAL
    SQLTEXT = SYBTEXT
    SQLVARBINARY = SYBVARBINARY
    SQLVARCHAR = SYBVARCHAR

#######################
## Exception classes ##
#######################
cdef extern from "pyerrors.h":
    ctypedef class __builtin__.Exception [object PyBaseExceptionObject]:
        pass

cdef class MSSQLException(Exception):
    """
    Base exception class for the MSSQL driver.
    """

cdef class MSSQLDriverException(MSSQLException):
    """
    Inherits from the base class and raised when an error is caused within
    the driver itself.
    """

cdef class MSSQLDatabaseException(MSSQLException):
    """
    Raised when an error occurs within the database.
    """
    
    cdef readonly int number
    cdef readonly int severity
    cdef readonly int state

# Module attributes for configuring _mssql
login_timeout = 60

min_error_severity = 6

# Buffer size for large numbers
DEF NUMERIC_BUF_SZ = 45

###################
## Error Handler ##
###################
cdef int err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr,
        char *dberrstr, char *oserrstr):

    cdef char *mssql_lastmsgstr = _mssql_last_msg_str
    cdef int mssql_lastmsgno = _mssql_last_msg_no
    cdef int mssql_lastmsgseverity = _mssql_last_msg_severity
    cdef int mssql_lastmsgstate = _mssql_last_msg_state
    cdef int _min_error_severity = min_error_severity

    IF PYMSSQL_DEBUG == 1:
        fprintf(stderr, "\n*** err_handler(dbproc = %p, severity = %d,  " \
            "dberr = %d, oserr = %d, dberrstr = '%s',  oserrstr = '%s'); " \
            "DBDEAD(dbproc) = %d\n", <void *>dbproc, severity, dberr,
            oserr, dberrstr, oserrstr, DBDEAD(dbproc));
        fprintf(stderr, "*** previous max severity = %d\n\n",
            _mssql_last_msg_severity);
    
    if severity < _min_error_severity:
        return INT_CANCEL

    for conn in connection_object_list:
        if dbproc == (<MSSQLConnection>conn).dbproc:
            mssql_lastmsgstr = (<MSSQLConnection>conn).last_msg_str
            mssql_lastmsgno = (<MSSQLConnection>conn).last_msg_no
            mssql_lastmsgseverity = (<MSSQLConnection>conn).last_msg_severity
            mssql_lastmsgstate = (<MSSQLConnection>conn).last_msg_state
            break
    
    if severity > mssql_lastmsgseverity:
        mssql_lastmsgseverity = severity
        mssql_lastmsgno = dberr
        mssql_lastmsgstate = oserr

    message = 'DB-Lib error message %d, severity %d:\n%s\n' % (dberr,
            severity, dberrstr)

    if oserr != DBNOERR and oserr != 0:
        pass

    
    return INT_CANCEL

#####################
## Message Handler ##
#####################
cdef int msg_handler(DBPROCESS *dbproc, DBINT msgno, int msgstate,
        int severity, char *msgtext, char *srvname, char *procname,
        LINE_T line):

    IF PYMSSQL_DEBUG == 1:
        fprintf(stderr, "\n+++ msg_handler(dbproc = %p, msgno = %d, " \
            "msgstate = %d, severity = %d, msgtext = '%s', " \
            "srvname = '%s', procname = '%s', line = %d)\n",
            <void *>dbproc, msgno, msgstate, severity, msgtext, srvname,
            procname, line);
        fprintf(stderr, "+++ previous max severity = %d\n\n",
            _mssql_last_msg_severity);

    return 0

cdef int db_sqlexec(DBPROCESS *dbproc):
    cdef RETCODE rtc
    with nogil:
        rtc = dbsqlexec(dbproc)
    return rtc

cdef void clr_err(MSSQLConnection conn):
    if conn != None:
        conn.last_msg_no = 0
        conn.last_msg_severity = 0
        conn.last_msg_state = 0
    else:
        _mssql_last_msg_no = 0
        _mssql_last_msg_severity = 0
        _mssql_last_msg_state = 0

cdef RETCODE db_cancel(MSSQLConnection conn):
    cdef RETCODE rtc

    if conn == None:
        return SUCCEED

    if conn.dbproc == NULL:
        return SUCCEED

    rtc = dbcancel(conn.dbproc);

cdef class MSSQLRowIterator:
    
    cdef MSSQLConnection conn
    
    def __init__(self, connection):
        self.conn = connection
    
    def __iter__(self):
        return self
    
    def __next__(self):
        assert_connected(self.conn)
        clr_err(self.conn)
        return self.conn.fetch_next_row_dict(1)

cdef class MSSQLConnection:

    # Used by properties
    cdef bint _connected
    cdef int _rows_affected
    cdef char *_charset
    
    # Used internally
    cdef DBPROCESS *dbproc
    cdef int last_msg_no
    cdef int last_msg_severity
    cdef int last_msg_state
    cdef int last_dbresults
    cdef int num_columns
    cdef int debug_queries
    cdef char *last_msg_str
    cdef tuple column_names
    cdef tuple column_types
    
    property charset:
        """
        The current encoding in use.
        """
        
        def __get__(self):
            return self._charset

    property connected:
        """
        True if the connection to a database is open.
        """
        
        def __get__(self):
            return self._connected
    
    property identity:
        """
        Returns identity value of the last inserted row. If the previous
        operation did not involve inserting a row into a table with an
        identity column, None is returned.
        
        ** Usage **
        >>> conn.execute_non_query("INSERT INTO table (name) VALUES ('John')")
        >>> print 'Last inserted row has ID = %s' % conn.identity
        Last inserted row has ID = 178
        """
        
        def __get__(self):
            pass
    
    property rows_affected:
        """
        Number of rows affected by last query. For SELECT statements this
        value is only meaningful after reading all rows.
        """
        
        def __get__(self):
            return self._rows_affected
    

    def __init__(self, server="localhost", user="sa", password="", trusted=0,
            charset="", database="master", max_conn=25):
    
        cdef LOGINREC *login
        cdef RETCODE rtc
    
        if max_conn <= 0:
            raise MSSQLDriverException("max_conn value must be greater than 0.")
        
        self._connected = 0
        self._charset = charset
        
        self.column_names = None
        self.column_types = None
        
        login = dblogin()
        if login == NULL:
            raise MSSQLDriverException("Out of memory")
    
        DBSETLUSER(login, user)
        DBSETLPWD(login, password)
        DBSETLAPP(login, "pymssql")
        DBSETLHOST(login, server);
        
        # Set the connection limit
        dbsetmaxprocs(max_conn)
        
        # Set the login timeout
        dbsetlogintime(login_timeout)

        # Add ourselves to the global connection list
        connection_object_list.append(self)
        
        # Connect to the server
        self.dbproc = dbopen(login, server)
        dbloginfree(login) # Frees the login record, can be called immediately after dbopen.
        
        if self.dbproc == NULL:
            raise MSSQLDriverException("Connection to the database failed for an unknown reason.")
            return
        
        self._connected = 1
        
        # Set some connection properties to some reasonable values
        dbcmd(self.dbproc,
            "SET ARITHABORT ON;"                \
            "SET CONCAT_NULL_YIELDS_NULL ON;"   \
            "SET ANSI_NULLS ON;"                \
            "SET ANSI_NULL_DFLT_ON ON;"         \
            "SET ANSI_PADDING ON;"              \
            "SET ANSI_WARNINGS ON;"             \
            "SET ANSI_NULL_DFLT_ON ON;"         \
            "SET CURSOR_CLOSE_ON_COMMIT ON;"    \
            "SET QUOTED_IDENTIFIER ON"
        )
        
        rtc = dbsqlexec(self.dbproc)
        if (rtc == FAIL):
            raise MSSQLDriverException("Could not set connection properties")
        
        db_cancel(self)
        clr_err(self)
        
        if database:
            self.select_db(database)
    
    def __iter__(self):
        assert_connected(self)
        clr_err(self)
        return MSSQLRowIterator(self)

    def cancel(self):
        """
        cancel() -- cancel all pending results.
        
        This function cancels all pending results from the last SQL operation.
        It can be called more than once in a row. No exception is raised in
        this case.
        """
        cdef RETCODE rtc
        
        assert_connected(self)
        clr_err(self)
        
        rtc = db_cancel(self)
        check_and_raise(rtc, self)
    
    cdef void clear_metadata(self):
        self.column_names = None
        self.column_types = None
        self.num_columns = 0
        self.last_dbresults = 0

    def close(self):
        """
        close() -- close connection to an MS SQL Server.
        
        This function tries to close the connection and free all memory used.
        It can be called more than once in a row. No exception is raised in
        this case.
        """
        if self == None:
            return None
        
        if not self._connected:
            return None
        
        with nogil:
            dbclose(self.dbproc)
            self.dbproc = NULL
        
        self._connected = 0
    
    cdef convert_db_value(self, BYTE *data, int type, int length):
        cdef char buf[NUMERIC_BUF_SZ] # buffer in which we store text rep of bug nums
        cdef double ddata
        cdef int len
        cdef long prevPrecision
        cdef BYTE precision
        cdef DBDATEREC di
        cdef DBDATETIME dt
        cdef DBCOL dbcol
        
        if type == SQLBIT:
            return bool(<int>(<DBBIT *>data)[0])

        elif type == SQLINT1:
            return int(<int>(<DBTINYINT *>data)[0])

        elif type == SQLINT2:
            return int(<int>(<DBSMALLINT *>data)[0])

        elif type == SQLINT4:
            return int(<int>(<DBINT *>data)[0])

        elif type == SQLINT8:
            return long(<long>(<long *>data)[0])

        elif type == SQLFLT4:
            return float(<float>(<DBREAL *>data)[0])

        elif type == SQLFLT8:
            return float(<float>(<DBFLT8 *>data)[0])

        elif type in (SQLMONEY, SQLMONEY4, SQLNUMERIC, SQLDECIMAL):
            dbcol.SizeOfStruct = sizeof(dbcol)

            if type in (SQLMONEY, SQLMONEY4):
                precision = 4
            else:
                precision = dbcol.Scale

            prevPrecision = _decimal_context.prec
            _decimal_context.prec = precision

            length = dbconvert(self.dbproc, type, data, -1, SQLCHAR,
                <BYTE *>buf, NUMERIC_BUF_SZ)

            len = rmv_lcl(buf, buf, NUMERIC_BUF_SZ)

            if not len:
                raise MSSQLDriverException('Could not remove locale formatting')
            return decimal.Decimal(str(buf))

        elif type == SQLDATETIM4:
            dbconvert(self.dbproc, type, data, -1, SQLDATETIME,
                <BYTE *>&dt, -1)
            dbdatecrack(self.dbproc, &di, <DBDATETIME *><BYTE *>&dt)
            return datetime.datetime(di.year, di.month, di.day,
                di.hour, di.minute, di.second, di.millisecond * 1000)

        elif type == SQLDATETIME:
            dbdatecrack(self.dbproc, &di, <DBDATETIME *>data)
            return datetime.datetime(di.year, di.month, di.day,
                di.hour, di.minute, di.second, di.millisecond * 1000)

        elif type in (SQLVARCHAR, SQLCHAR, SQLTEXT):
            if self.charset:
                return str(<char *>data)[:length].decode(self.charset)
            else:
                return str(<char *>data)[:length]
        else:
            return str(<char *>data)[:length]

    def execute_non_query(self, query_string, params=None):
        """
        execute_non_query(query_string, params=None)

        This method sends a query to the MS SQL Server to which this object
        instance is connected. After completion, its results (if any) are
        discarded. An exception is raised on failure. If there are any pending
        results or rows prior to executing this command, they are silently
        discarded. This method accepts Python formatting. Please see
        execute_query() for more details.
    
        This method is useful for INSERT, UPDATE, DELETE and for Data
        Definition Language commands, i.e. when you need to alter your database
        schema.
    
        After calling this method, rows_affected property contains number of
        rows affected by the last SQL command.
        """
        cdef RETCODE rtc
        
        self.format_and_run_query(query_string, params)
        
        with nogil:
            dbresults(self.dbproc)
            self._rows_affected = dbcount(self.dbproc)
        
        self.cancel()

    def execute_query(self, query_string, params=None):
        """
        execute_query(query_string, params=None)

        This method sends a query to the MS SQL Server to which this object
        instance is connected. An exception is raised on failure. If there
        are pending results or rows prior to executing this command, they
        are silently discarded. After calling this method you may iterate
        over the connection object to get rows returned by the query.
    
        You can use Python formatting here and all values get properly
        quoted:
            conn.execute_query('SELECT * FROM empl WHERE id=%d', 13)
            conn.execute_query('SELECT * FROM empl WHERE id IN (%s)', ((5,6),))
            conn.execute_query('SELECT * FROM empl WHERE name=%s', 'John Doe')
            conn.execute_query('SELECT * FROM empl WHERE name LIKE %s', 'J%')
            conn.execute_query('SELECT * FROM empl WHERE name=%(name)s AND \
                city=%(city)s', { 'name': 'John Doe', 'city': 'Nowhere' } )
            conn.execute_query('SELECT * FROM cust WHERE salesrep=%s \
                AND id IN (%s)', ('John Doe', (1,2,3)))
            conn.execute_query('SELECT * FROM empl WHERE id IN (%s)',\
                (tuple(xrange(4)),))
            conn.execute_query('SELECT * FROM empl WHERE id IN (%s)',\
                (tuple([3,5,7,11]),))
    
        This method is intented to be used on queries that return results,
        i.e. SELECT. After calling this method AND reading all rows from,
        result rows_affected property contains number of rows returned by
        last command (this is how MS SQL returns it).
        """
        self.format_and_run_query(query_string, params)
        self.get_result()

    def execute_row(self, query_string, params=None):
        """
        execute_row(query_string, params=None)

        This method sends a query to the MS SQL Server to which this object
        instance is connected, then returns first row of data from result.
    
        An exception is raised on failure. If there are pending results or
        rows prior to executing this command, they are silently discarded.
    
        This method accepts Python formatting. Please see execute_query()
        for details.
    
        This method is useful if you want just a single row and don't want
        or don't need to iterate, as in:
    
        conn.execute_row('SELECT * FROM employees WHERE id=%d', 13)
    
        This method works exactly the same as 'iter(conn).next()'. Remaining
        rows, if any, can still be iterated after calling this method.
        """

    def execute_scalar(self, query_string, params=None):
        """
        execute_scalar(query_string, params=None)

        This method sends a query to the MS SQL Server to which this object
        instance is connected, then returns first column of first row from
        result. An exception is raised on failure. If there are pending
    
        results or rows prior to executing this command, they are silently
        discarded.
    
        This method accepts Python formatting. Please see execute_query()
        for details.
    
        This method is useful if you want just a single value, as in:
            conn.execute_scalar('SELECT COUNT(*) FROM employees')
    
        This method works in the same way as 'iter(conn).next()[0]'.
        Remaining rows, if any, can still be iterated after calling this
        method.
        """
    
    cdef fetch_next_row_dict(self, int throw):
        cdef RETCODE rtc
        cdef int col

        if self.last_dbresults == NO_MORE_RESULTS:
            self.clear_metadata()
            if throw:
                raise StopIteration
        
        with nogil:
            rtc = dbnextrow(self.dbproc)
        
        check_cancel_and_raise(rtc, self)

        if rtc == NO_MORE_ROWS:
            self.clear_metadata()
            
            # 'rows_affected' is nonzero only after all records are read
            self._rows_affected = dbcount(self.dbproc)
            self.last_dbresults = 0
            if throw:
                raise StopIteration
        
        row_dict = {}
        row = self.get_row(rtc)
        
        for col in xrange(1, self.num_columns + 1):
            name = self.column_names[col - 1]
            value = row[col - 1]
            
            # Add key by column name, only if the column has a name
            if name:
                row_dict[name] = value
            
            row_dict[col - 1] = value
    
        return row_dict
    
    cdef format_and_run_query(self, query_string, params=None):
        """
        This is a helper function, which does most of the work needed by any
        execute_*() function. It returns NULL on error, None on success.
        """
        cdef RETCODE rtc
        assert_connected(self)
        clr_err(self)
        
        if params:
            query_string = self.format_sql_command(query_string, params)
        
        db_cancel(self)
        
        dbcmd(self.dbproc, query_string)
        
        # Execute the query
        rtc = db_sqlexec(self.dbproc)
        check_cancel_and_raise(rtc, self)
    
    def get_header(self):
        """
        get_header() -- get the Python DB-API compliant header information.
        
        This method is infrastructure and doesn't need to be called by your
        code. It returns a list of 7-element tuples describing the current
        result header. Only name and DB-API compliant type is filled, rest
        of the data is None, as permitted by the specs.
        """
        cdef int col
        self.get_result()
        
        if self.num_columns == 0:
            return None
        
        header_tuple = []
        for col in xrange(1, self.num_columns + 1):
            col_name = self.column_names[col - 1]
            col_type = self.column_types[col - 1]
            header_tuple.append((col_name, col_type, None, None, None, None, None))
        return tuple(header_tuple)
    
    cdef get_result(self):
        cdef int coltype
        
        if self.last_dbresults:
            return None
        
        self.clear_metadata()

        # Since python doesn't have a do/while loop do it this way
        while True:
            with nogil:
                self.last_dbresults = dbresults(self.dbproc)
            self.num_columns = dbnumcols(self.dbproc)
            if self.last_dbresults != SUCCEED or self.num_columns > 0:
                break

        check_cancel_and_raise(self.last_dbresults, self)
        
        if self.last_dbresults == NO_MORE_RESULTS:
            return None
        
        self._rows_affected = dbcount(self.dbproc)
        self.num_columns = dbnumcols(self.dbproc)

        column_names = list()
        column_types = list()
        
        for col in xrange(1, self.num_columns + 1):
            column_names.append(dbcolname(self.dbproc, col))
            coltype = dbcoltype(self.dbproc, col)
            column_types.append(get_api_coltype(coltype))

        self.column_names = tuple(column_names)
        self.column_types = tuple(column_types)
    
    cdef get_row(self, int row_info):
        cdef DBPROCESS *dbproc = self.dbproc
        cdef int col
        cdef int col_type
        cdef int len
        cdef BYTE *data
        
        record = tuple()
        
        for col in xrange(1, self.num_columns + 1):
            with nogil:
                data = get_data(dbproc, row_info, col)
                col_type = get_type(dbproc, row_info, col)
                len = get_length(dbproc, row_info, col)
            
            if data == NULL:
                record += (None,)
                continue
            
            record += (self.convert_db_value(data, col_type, len),)
        return record
    
    def init_procedure(self):
        """
        init_procedure(procname) -- creates and returns a MSSQLStoredProcedure
        object.
        
        This methods initilizes a stored procedure or function on the server
        and creates a MSSQLStoredProcedure object that allows parameters to
        be bound.
        """
    
    def next_result(self):
        """
        nextresult() -- move to the next result, skipping all pending rows.
        
        This method fetches and discards any rows remaining from the current 
        resultset, then it advances to the next (if any) resultset. Returns
        True if the next resultset is available, otherwise None.
        """
        
        cdef RETCODE rtc
        
        assert_connected(self)
        clr_err(self)
        
        rtc = dbnextrow(self.dbproc)        
        check_cancel_and_raise(rtc, self)
        
        while rtc != NO_MORE_ROWS:
            rtc = dbnextrow(self.dbproc)
            check_cancel_and_raise(rtc, self)
        
        self.last_dbresults = 0
        self.get_result()
        
        if self.last_dbresults != NO_MORE_RESULTS:
            return 1
    
    def select_db(self, dbname):
        """
        select_db(dbname) -- Select the current database.
        
        This function selects the given database. An exception is raised on
        failure.
        """
        cdef RETCODE rtc
        
        # Check we are connected first
        assert_connected(self)
        clr_err(self)
        
        if dbname[0] == "[" and dbname[-1] == "]":
            command = "USE %s" % dbname
        else:
            dbname = dbname.replace("]", "]]")
            command = "USE [%s]" % dbname
        
        rtc = db_cancel(self)
        check_and_raise(rtc, self)
        
        rtc = dbcmd(self.dbproc, command)
        check_cancel_and_raise(rtc, self)
        
        # NOTE: don't use Py_BEGIN_ALLOW_THREADS here; doing so causes severe
        # unstability in multihreated scripts (especially when select_db is
        # called whilst constructing MSSQLConnection. Any number of threads > 1
        # causes problems. It has something to do with msg_handler.
        rtc = dbsqlexec(self.dbproc)
        check_and_raise(rtc, self)
        
        rtc = db_cancel(self)
        check_and_raise(rtc, self)

cdef class MSSQLStoredProcedure:

    cdef bind(self, value, data_type, param_name, output, null, max_length):
        pass

cdef void check_and_raise(RETCODE rtc, MSSQLConnection conn):
    if rtc == FAIL:
        maybe_raise_MSSQLDatabaseException(conn)
    elif get_last_msg_str(conn):
        maybe_raise_MSSQLDatabaseException(conn)

cdef void check_cancel_and_raise(RETCODE rtc, MSSQLConnection conn):
    if rtc == FAIL:
        db_cancel(conn)
        maybe_raise_MSSQLDatabaseException(conn)
    elif get_last_msg_str(conn):
        maybe_raise_MSSQLDatabaseException(conn)

cdef char *get_last_msg_str(MSSQLConnection conn):
    return conn.last_msg_str if conn != None else _mssql_last_msg_str
    
cdef int get_last_msg_no(MSSQLConnection conn):
    return conn.last_msg_no if conn != None else _mssql_last_msg_no

cdef int get_last_msg_severity(MSSQLConnection conn):
    return conn.last_msg_severity if conn != None else _mssql_last_msg_severity

cdef int get_last_msg_state(MSSQLConnection conn):
    return conn.last_msg_state if conn != None else _mssql_last_msg_state

cdef int maybe_raise_MSSQLDatabaseException(MSSQLConnection conn):
    
    if get_last_msg_severity(conn) < min_error_severity:
        return 0
    
    error_msg = get_last_msg_str(conn)
    if len(error_msg) == 0:
        error_msg = "Unknown error"

    ex = MSSQLDatabaseException(error_msg)
    ex._number = get_last_msg_no(conn)
    ex._severity = get_last_msg_severity(conn)
    ex._state = get_last_msg_state(conn)
    db_cancel(conn)
    clr_err(conn)
    raise ex

cdef void assert_connected(MSSQLConnection conn):
    if not conn.connected:
        raise MSSQLDriverException("Not connected to any MS SQL server")

cdef BYTE *get_data(DBPROCESS *dbproc, int row_info, int col) nogil:
    return dbdata(dbproc, col) if row_info == REG_ROW else dbadata(dbproc, row_info, col)

cdef int get_type(DBPROCESS *dbproc, int row_info, int col) nogil:
    return dbcoltype(dbproc, col) if row_info == REG_ROW else dbalttype(dbproc, row_info, col)

cdef int get_length(DBPROCESS *dbproc, int row_info, int col) nogil:
    return dbdatlen(dbproc, col) if row_info == REG_ROW else dbadlen(dbproc, row_info, col)


######################
## Helper Functions ##
######################
cdef int get_api_coltype(int coltype):
    if coltype in (SQLBIT, SQLINT1, SQLINT2, SQLINT4, SQLINT8, SQLINTN,
            SQLFLT4, SQLFLT8, SQLFLTN):
        return NUMBER
    elif coltype in (SQLMONEY, SQLMONEY4, SQLMONEYN, SQLNUMERIC,
            SQLDECIMAL):
        return DECIMAL
    elif coltype in (SQLDATETIME, SQLDATETIM4, SQLDATETIMN):
        return DATETIME
    elif coltype in (SQLVARCHAR, SQLCHAR, SQLTEXT):
        return STRING
    else:
        return BINARY

#######################
## Quoting Functions ##
#######################
cdef _quote_simple_value(value):

    if value == None:
        return 'NULL'

    if type(value) is bool:
        return 1 if value else 0

    if type(value) in (int, long, float):
        return value

    if type(value) is unicode:
        return "N'" + value.encode('utf8').replace("'", "''") + "'"

    if type(value) is str:
        return "'" + value.replace("'", "''") + "'"

    if type(value) is datetime.datetime:
        return "{ts '%04d-%02d-%02d %02d:%02d:%02d.%d'}" % (
            value.year, value.month, value.day,
            value.hour, value.minute, value.second, value.microsecond / 1000)

    if type(value) is datetime.date:
        return "{d '%04d-%02d-%02d'} " % (value.year, value.month, value.day)

    return None

cdef _quote_or_flatten(data):
    result = _quote_simple_value(data)

    if result is not None:
        return result

    if type(data) not in (list, tuple):
        raise ValueError('expected a simple type, a tuple or a list')

    string = ''
    for value in data:
        value = _quote_simple_value(value)

        if value is None:
            raise ValueError('found an unsupported type')

        string += '%s,' % value
    return string[:-1]

# This function is supposed to take a simple value, tuple or dictionary,
# normally passed in via the params argument in the execute_* methods. It
# then quotes and flattens the arguments and returns then.
cdef _quote_data(data):
    result = _quote_simple_value(data)

    if result is not None:
        return result

    if type(data) is dict:
        result = {}
        for k, v in data.iteritems():
            result[k] = _quote_or_flatten(v)
        return result

    if type(data) is tuple:
        result = []
        for v in data:
            result.append(_quote_or_flatten(v))
        return tuple(result)

    raise ValueError('expected a simple type, a tuple or a dictionary.')

# We'll add these methods to the module to allow for unit testing of the
# underlying C methods.
def quote_simple_value(value):
    return _quote_simple_value(value)

def quote_or_flatten(data):
    return _quote_or_flatten(data)

def quote_data(data):
    return _quote_data(data)

cdef void init_mssql():
    global _decimal_context
    cdef RETCODE rtc
    rtc = dbinit()
    if rtc == FAIL:
        raise MSSQLDriverException("Could not initialize communication layer")
    
    dberrhandle(err_handler)
    dbmsghandle(msg_handler)

    _decimal_context = decimal.getcontext()

init_mssql()
