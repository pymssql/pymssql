"""
This is an effort to convert the pymssql low-level C module to Cython.
"""

DEF PYMSSQL_DEBUG = 0
DEF PYMSSQL_CHARSETBUFSIZE = 100
DEF MSSQLDB_MSGSIZE = 1024
DEF PYMSSQL_MSGSIZE = (MSSQLDB_MSGSIZE * 8)
DEF EXCOMM = 9

import uuid
import decimal
import datetime
from sqlfront cimport *
from stdio cimport fprintf, sprintf, FILE
from stdlib cimport strlen, strcpy
from python_mem cimport PyMem_Malloc, PyMem_Free

cdef extern int rmv_lcl(char *, char *, size_t)

cdef extern from "stdio.h" nogil:
    cdef FILE *stderr

cdef extern from "string.h":
    
    cdef char *strncpy(char *, char *, size_t)

# Vars to store messages from the server in
cdef int _mssql_last_msg_no = 0
cdef int _mssql_last_msg_severity = 0
cdef int _mssql_last_msg_state = 0
cdef char *_mssql_last_msg_str = <char *>PyMem_Malloc(PYMSSQL_MSGSIZE)
IF PYMSSQL_DEBUG == 1:
    cdef int _row_count = 0

cdef _decimal_context

# List to store the connection objects in
cdef list connection_object_list = list()

#############################
## DB-API type definitions ##
#############################
STRING = 1
BINARY = 2
NUMBER = 3
DATETIME = 4
DECIMAL = 5

##################
## DB-LIB types ##
##################
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
SQLUUID = 36

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

cdef void log(char * message):
    if PYMSSQL_DEBUG == 1:
        fprintf(stderr, "%s\n", message)

###################
## Error Handler ##
###################
cdef int err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr,
        char *dberrstr, char *oserrstr):

    cdef char *mssql_lastmsgstr = _mssql_last_msg_str
    cdef int *mssql_lastmsgno = &_mssql_last_msg_no
    cdef int *mssql_lastmsgseverity = &_mssql_last_msg_severity
    cdef int *mssql_lastmsgstate = &_mssql_last_msg_state
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
        if dbproc != (<MSSQLConnection>conn).dbproc:
            continue
        mssql_lastmsgstr = (<MSSQLConnection>conn).last_msg_str
        mssql_lastmsgno = &(<MSSQLConnection>conn).last_msg_no
        mssql_lastmsgseverity = &(<MSSQLConnection>conn).last_msg_severity
        mssql_lastmsgstate = &(<MSSQLConnection>conn).last_msg_state
        break
    
    if severity > mssql_lastmsgseverity[0]:
        mssql_lastmsgseverity[0] = severity
        mssql_lastmsgno[0] = dberr
        mssql_lastmsgstate[0] = oserr

    message = mssql_lastmsgstr
    message += 'DB-Lib error message %d, severity %d:\n%s\n' % (dberr,
            severity, dberrstr)

    if oserr != DBNOERR and oserr != 0:
        message += '%s error during %s' % ('Net-Lib' if \
            severity == EXCOMM else 'Operating System', oserrstr)

    strncpy(mssql_lastmsgstr, message, PYMSSQL_MSGSIZE)
    
    return INT_CANCEL

#####################
## Message Handler ##
#####################
cdef int msg_handler(DBPROCESS *dbproc, DBINT msgno, int msgstate,
        int severity, char *msgtext, char *srvname, char *procname,
        LINE_T line):

    cdef char *mssql_lastmsgstr = _mssql_last_msg_str
    cdef int *mssql_lastmsgno = &_mssql_last_msg_no
    cdef int *mssql_lastmsgseverity = &_mssql_last_msg_severity
    cdef int *mssql_lastmsgstate = &_mssql_last_msg_state
    cdef int _min_error_severity = min_error_severity

    IF PYMSSQL_DEBUG == 1:
        fprintf(stderr, "\n+++ msg_handler(dbproc = %p, msgno = %d, " \
            "msgstate = %d, severity = %d, msgtext = '%s', " \
            "srvname = '%s', procname = '%s', line = %d)\n",
            <void *>dbproc, msgno, msgstate, severity, msgtext, srvname,
            procname, line);
        fprintf(stderr, "+++ previous max severity = %d\n\n",
            _mssql_last_msg_severity);

    if severity < _min_error_severity:
        return INT_CANCEL

    for conn in connection_object_list:
        if dbproc != (<MSSQLConnection>conn).dbproc:
            continue
        mssql_lastmsgstr = (<MSSQLConnection>conn).last_msg_str
        mssql_lastmsgno = &(<MSSQLConnection>conn).last_msg_no
        mssql_lastmsgseverity = &(<MSSQLConnection>conn).last_msg_severity
        mssql_lastmsgstate = &(<MSSQLConnection>conn).last_msg_state
        break

    # Calculate the maximum severity of all messages in a row
    # Fill the remaining fields as this is going to raise the exception
    if severity > mssql_lastmsgseverity[0]:
        mssql_lastmsgseverity[0] = severity
        mssql_lastmsgno[0] = msgno
        mssql_lastmsgstate[0] = msgstate

    if procname != NULL and strlen(procname) > 0:
        message = 'SQL Server message %ld, severity %d, state %d, ' \
            'procedure %s, line %d:\n%s\n' % (<long>msgno, severity,
            msgstate, procname, line, msgtext)
    else:
        message = 'SQL Server message %ld, severity %d, state %d, ' \
            'line %d:\n%s\n' % (<long>msgno, severity, msgstate, line,
            msgtext)

    strncpy(mssql_lastmsgstr, message, PYMSSQL_MSGSIZE)

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
    
    with nogil:
        rtc = dbcancel(conn.dbproc);

    conn.clear_metadata()
    return rtc

##############################
## MSSQL Row Iterator Class ##
##############################
cdef class MSSQLRowIterator:
    
    def __init__(self, connection):
        self.conn = connection
    
    def __iter__(self):
        return self
    
    def __next__(self):
        assert_connected(self.conn)
        clr_err(self.conn)
        return self.conn.fetch_next_row_dict(1)

############################
## MSSQL Connection Class ##
############################
cdef class MSSQLConnection:

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

    def __cinit__(self):
        log("MSSQLConnection.__cinit__()")
        self._connected = 0
        self._charset = <char *>PyMem_Malloc(PYMSSQL_CHARSETBUFSIZE)
        self.last_msg_str = <char *>PyMem_Malloc(PYMSSQL_MSGSIZE)
        self.column_names = None
        self.column_types = None

    def __init__(self, server="localhost", user="sa", password="", trusted=0,
            charset="", database='', max_conn=25):
        log("MSSQLConnection.__init__()")
    
        cdef LOGINREC *login
        cdef RETCODE rtc
    
        if max_conn <= 0:
            raise MSSQLDriverException("max_conn value must be greater than 0.")
        
        login = dblogin()
        if login == NULL:
            raise MSSQLDriverException("Out of memory")
    
        DBSETLUSER(login, user)
        DBSETLPWD(login, password)
        DBSETLAPP(login, "pymssql")
        DBSETLHOST(login, server);
        
        # Set the connection limit
        dbsetmaxprocs(max_conn)

        # Add ourselves to the global connection list
        connection_object_list.append(self)

        # Set the character set name
        if charset:
            strncpy(self._charset, charset, PYMSSQL_CHARSETBUFSIZE)
        
        # Set the login timeout
        dbsetlogintime(login_timeout)
        
        # Connect to the server
        self.dbproc = dbopen(login, server)

        # Frees the login record, can be called immediately after dbopen.
        dbloginfree(login)
        
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

    def __dealloc__(self):
        log("MSSQLConnection.__dealloc__()")
        self.close()

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
        log("MSSQLConnection.cancel()")
        cdef RETCODE rtc
        
        assert_connected(self)
        clr_err(self)
        
        rtc = db_cancel(self)
        check_and_raise(rtc, self)
    
    cdef void clear_metadata(self):
        log("MSSQLConnection.clear_metadata()")
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
        log("MSSQLConnection.close()")
        if self == None:
            return None
        
        if not self._connected:
            return None

        clr_err(self)
        
        with nogil:
            dbclose(self.dbproc)
            self.dbproc = NULL

        self._connected = 0
        PyMem_Free(self.last_msg_str)
        PyMem_Free(self._charset)
        connection_object_list.remove(self)
    
    cdef convert_db_value(self, BYTE *data, int type, int length):
        cdef char buf[NUMERIC_BUF_SZ] # buffer in which we store text rep of bug nums
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

            len = dbconvert(self.dbproc, type, data, -1, SQLCHAR,
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
                return (<char *>data)[:length].decode(self.charset)
            else:
                return (<char *>data)[:length]

        elif type == SQLUUID:
            return uuid.UUID(bytes_le=(<char *>data)[:length])

        else:
            return (<char *>data)[:length]

    cdef BYTE *convert_python_value(self, value, int *dbtype, int *length) except NULL:
        cdef int *intValue
        cdef double *dblValue
        cdef long *longValue
        cdef char *strValue

        if value is None:
            return NULL

        if dbtype[0] == SQLBIT:
            intValue = <int *>PyMem_Malloc(sizeof(int))
            intValue[0] = <int>value
            return <BYTE *><DBBIT *>intValue

        if dbtype[0] in (SQLINT1, SQLINT2, SQLINT4):
            intValue = <int *>PyMem_Malloc(sizeof(int))
            intValue[0] = <int>value
            if dbtype[0] == SQLINT1:
                return <BYTE *><DBTINYINT *>intValue
            if dbtype[0] == SQLINT2:
                return <BYTE *><DBSMALLINT *>intValue
            if dbtype[0] == SQLINT4:
                return <BYTE *><DBINT *>intValue

        if dbtype[0] == SQLINT8:
            longValue = <long *>PyMem_Malloc(sizeof(long))
            longValue[0] = <long>value
            return <BYTE *>longValue

        if dbtype[0] in (SQLFLT4, SQLFLT8):
            dblValue = <double *>PyMem_Malloc(sizeof(double))
            dblValue[0] = <double>value
            if dbtype[0] == SQLFLT4:
                return <BYTE *><DBREAL *>dblValue
            if dbtype[0] == SQLFLT8:
                return <BYTE *><DBFLT8 *>dblValue

        if dbtype[0] in (SQLDATETIM4, SQLDATETIME):
            if type(value) not in (datetime.date, datetime.datetime):
                raise TypeError

            value = value.strftime('%Y-%m-%d %H:%M:%S.') + \
                str(value.microsecond / 1000)
            dbtype[0] = SQLCHAR

        if dbtype[0] in (SQLMONEY, SQLMONEY4, SQLNUMERIC, SQLDECIMAL):
            if type(value) != decimal.Decimal:
                raise TypeError

            value = str(value)
            dbtype[0] = SQLCHAR

        if dbtype[0] in (SQLVARCHAR, SQLCHAR, SQLTEXT):
            if type(value) not in (str, unicode):
                raise TypeError

            if self._charset and type(value) is unicode:
                value = value.encode(self._charset)

            strValue = <char *>PyMem_Malloc(len(value) + 1)
            strcpy(strValue, value)
            return <BYTE *>strValue

        if dbtype[0] in (SQLBINARY, SQLIMAGE):
            if type(value) is not str:
                raise TypeError()
            return <BYTE *><char *>value

        # No conversion was possible so just return NULL
        return NULL

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

        rtc = db_cancel(self)
        check_and_raise(rtc, self)

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
        self.format_and_run_query(query_string, params)
        return self.fetch_next_row_dict(0)

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
        cdef RETCODE rtc

        self.format_and_run_query(query_string, params)
        self.get_result()

        with nogil:
            rtc = dbnextrow(self.dbproc)

        self._rows_affected = dbcount(self.dbproc)

        if rtc == NO_MORE_ROWS:
            self.clear_metadata()
            self.last_dbresults = 0
            return None

        return self.get_row(rtc)[0]
    
    cdef fetch_next_row_dict(self, int throw):
        cdef RETCODE rtc
        cdef int col

        self.get_result()

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
        
        # Cancel any pending results
        db_cancel(self)
        
        # Prepare the query buffer
        dbcmd(self.dbproc, query_string)
        
        # Execute the query
        rtc = db_sqlexec(self.dbproc)
        check_cancel_and_raise(rtc, self)

    cdef format_sql_command(self, format, params=None):
        
        if params is None:
            return format

        if type(params) not in (bool, int, long, float, unicode, str,
            datetime.datetime, datetime.date, tuple, dict):
            raise ValueError("'params' arg can be only a tuple or a dictionary.")

        quoted = quote_data(params)
        return format % quoted
    
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

        if PYMSSQL_DEBUG == 1:
            global _row_count
            _row_count += 1
        
        record = tuple()
        
        for col in xrange(1, self.num_columns + 1):
            with nogil:
                data = get_data(dbproc, row_info, col)
                col_type = get_type(dbproc, row_info, col)
                len = get_length(dbproc, row_info, col)
            
            if data == NULL:
                record += (None,)
                continue

            IF PYMSSQL_DEBUG == 1:
                global _row_count
                fprintf(stderr, 'Processing row %d, column %d,' \
                    'Got data=%x, coltype=%d, len=%d\n', _row_count, col,
                    data, col_type, len)
            
            record += (self.convert_db_value(data, col_type, len),)
        return record
    
    def init_procedure(self, procname):
        """
        init_procedure(procname) -- creates and returns a MSSQLStoredProcedure
        object.
        
        This methods initilizes a stored procedure or function on the server
        and creates a MSSQLStoredProcedure object that allows parameters to
        be bound.
        """
        return MSSQLStoredProcedure(procname, self)

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

##################################
## MSSQL Stored Procedure Class ##
##################################
cdef class MSSQLStoredProcedure:

    property connection:
        """The underlying MSSQLConnection object."""
        def __get__(self):
            return self.conn

    property name:
        """The name of the procedure that this object represents."""
        def __get__(self):
            return self.procname

    property parameters:
        """The parameters that have been bound to this procedure."""
        def __get__(self):
            return self.params

    
    def __init__(self, str name, MSSQLConnection connection):
        cdef RETCODE rtc

        # We firstly want to check if tdsver is >= 8 as anything less
        # doesn't support remote procedure calls.
        if dbtds(connection.dbproc) < 8:
            raise MSSQLDriverException("Stored Procedures aren't " \
                "supported with a TDS version less than 8.")
        
        self.conn = connection
        self.dbproc = connection.dbproc
        self.procname = name
        self.params = dict()
        self.params_list = NULL

        with nogil:
            rtc = dbrpcinit(self.dbproc, self.procname, 0)

        check_cancel_and_raise(rtc, self.conn)

    def __dealloc__(self):
        cdef _mssql_parameter_node *n, *p

        n = self.params_list
        p = NULL

        while n != NULL:
            PyMem_Free(n.value)
            p = n
            n = n.next
            PyMem_Free(p)
            
    def bind(self, value, dbtype, str param_name=None, output=False,
            null=False, int max_length=-1):
        """
        bind(value, data_type, param_name = None, output = False,
            null = False, max_length = -1) -- bind a parameter

        This method binds a parameter to the stored procedure.
        """
        self._bind(value, dbtype, param_name, output, null, max_length)

    cdef int _bind(self, value, int dbtype, char *name, int output,
            int null, int max_length) except 1:
        cdef int length = -1
        cdef BYTE status, *data
        cdef RETCODE rtc
        cdef _mssql_parameter_node *pn

        # Set status according to output being True or False
        status = DBRPCRETURN if output else <BYTE>0

        # Convert the PyObject to the db type
        data = self.conn.convert_python_value(value, &dbtype, &length)

        # Store the value in the parameters dictionary for returning
        # later.
        self.params[name] = value

        # Store the converted parameter in our parameter list so we can
        # free() it later.
        if data != NULL:
            pn = <_mssql_parameter_node *>PyMem_Malloc(sizeof(_mssql_parameter_node))
            if pn == NULL:
                raise MSSQLDriverException('Out of memory')
            pn.next = self.params_list
            pn.value = data
            self.params_list = pn

        # We may need to set the data length depending on the type being
        # passed to the server here.
        if dbtype in (SQLVARCHAR, SQLCHAR, SQLTEXT, SQLBINARY,
                SQLIMAGE):
            if null or data == NULL:
                length = 0
                if not output:
                    max_length = -1
            else:
                length = strlen(<char *>data)
        else:
            # Fixed length data type
            if null or output:
                length = 0
            max_length = -1

        if status != DBRPCRETURN:
            max_length = -1

        IF PYMSSQL_DEBUG == 1:
            fprintf(stderr, "\n--- rpc_bind(name = '%s', status = %d, " \
                "max_length = %d, data_type = %d, data_length = %d, "
                "data = %x)\n", name, status, max_length, dbtype,
                length, data)

        with nogil:
            rtc = dbrpcparam(self.dbproc, name, status, dbtype,
                max_length, length, data)
        return check_cancel_and_raise(rtc, self.conn)

    def execute(self):
        cdef RETCODE rtc
        cdef int output_count, i, type, length
        cdef char *name
        cdef BYTE *data

        # Cancel any pending results as this throws a server error
        # otherwise.
        db_cancel(self.conn)

        # Send the RPC request
        with nogil:
            rtc = dbrpcsend(self.dbproc)
        check_cancel_and_raise(rtc, self.conn)

        # Wait for the server to return
        with nogil:
            rtc = dbsqlok(self.dbproc)
        check_cancel_and_raise(rtc, self.conn)

        # Need to call thsi regardless of wether or not there are output
        # parameters in roder for the return status to be correct.
        output_count = dbnumrets(self.dbproc)

        # If there are any output parameters then we are going to want to
        # set the values in the parameters dictionary.
        if output_count:
            for i in xrange(1, output_count + 1):
                with nogil:
                    type = dbrettype(self.dbproc, i)
                    name = dbretname(self.dbproc, i)
                    length = dbretlen(self.dbproc, i)
                    data = dbretdata(self.dbproc, i)

                value = self.conn.convert_db_value(data, type, length)
                self.params[name] = value

        # Get the return value from the procedure ready for return.
        return dbretstatus(self.dbproc)

cdef int check_and_raise(RETCODE rtc, MSSQLConnection conn) except 1:
    if rtc == FAIL:
        return maybe_raise_MSSQLDatabaseException(conn)
    elif get_last_msg_str(conn):
        return maybe_raise_MSSQLDatabaseException(conn)

cdef inline int check_cancel_and_raise(RETCODE rtc, MSSQLConnection conn) except 1:
    if rtc == FAIL:
        db_cancel(conn)
        return maybe_raise_MSSQLDatabaseException(conn)
    elif get_last_msg_str(conn):
        return maybe_raise_MSSQLDatabaseException(conn)

cdef char *get_last_msg_str(MSSQLConnection conn):
    return conn.last_msg_str if conn != None else _mssql_last_msg_str
    
cdef int get_last_msg_no(MSSQLConnection conn):
    return conn.last_msg_no if conn != None else _mssql_last_msg_no

cdef int get_last_msg_severity(MSSQLConnection conn):
    return conn.last_msg_severity if conn != None else _mssql_last_msg_severity

cdef int get_last_msg_state(MSSQLConnection conn):
    return conn.last_msg_state if conn != None else _mssql_last_msg_state

cdef int maybe_raise_MSSQLDatabaseException(MSSQLConnection conn) except 1:

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

cdef inline BYTE *get_data(DBPROCESS *dbproc, int row_info, int col) nogil:
    return dbdata(dbproc, col) if row_info == REG_ROW else \
        dbadata(dbproc, row_info, col)

cdef inline int get_type(DBPROCESS *dbproc, int row_info, int col) nogil:
    return dbcoltype(dbproc, col) if row_info == REG_ROW else \
        dbalttype(dbproc, row_info, col)

cdef inline int get_length(DBPROCESS *dbproc, int row_info, int col) nogil:
    return dbdatlen(dbproc, col) if row_info == REG_ROW else \
        dbadlen(dbproc, row_info, col)

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
            value.hour, value.minute, value.second,
            value.microsecond / 1000)

    if type(value) is datetime.date:
        return "{d '%04d-%02d-%02d'} " % (
        value.year, value.month, value.day)

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

###########################
## Compatibility Aliases ##
###########################
def connect(*args, **kwargs):
    return MSSQLConnection(*args, **kwargs)

MssqlDatabaseException = MSSQLDatabaseException
MssqlDriverException = MSSQLDriverException
MssqlConnection = MSSQLConnection

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
