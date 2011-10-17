"""
This is an effort to convert the pymssql low-level C module to Cython.
"""
#
# _mssql.pyx
#
#   Copyright (C) 2003 Joon-cheol Park <jooncheol@gmail.com>
#                 2008 Andrzej Kukula <akukula@gmail.com>
#                 2009-2010 Damien Churchill <damoxc@gmail.com>
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
#

DEF PYMSSQL_DEBUG = 0
DEF PYMSSQL_DEBUG_ERRORS = 0
DEF PYMSSQL_CHARSETBUFSIZE = 100
DEF MSSQLDB_MSGSIZE = 1024
DEF PYMSSQL_MSGSIZE = (MSSQLDB_MSGSIZE * 8)
DEF EXCOMM = 9

from cpython cimport PY_MAJOR_VERSION, PY_MINOR_VERSION

if PY_MAJOR_VERSION >= 2 and PY_MINOR_VERSION >= 5:
    import uuid

import os
import socket
import decimal
import datetime
import re

from sqlfront cimport *

from libc.stdio cimport fprintf, sprintf, stderr, FILE
from libc.string cimport strlen, strcpy, strncpy, memcpy

from cpython cimport bool
from cpython.mem cimport PyMem_Malloc, PyMem_Free
from cpython.long cimport PY_LONG_LONG

# Vars to store messages from the server in
cdef int _mssql_last_msg_no = 0
cdef int _mssql_last_msg_severity = 0
cdef int _mssql_last_msg_state = 0
cdef int _mssql_last_msg_line = 0
cdef char *_mssql_last_msg_str = <char *>PyMem_Malloc(PYMSSQL_MSGSIZE)
cdef char *_mssql_last_msg_srv = <char *>PyMem_Malloc(PYMSSQL_MSGSIZE)
cdef char *_mssql_last_msg_proc = <char *>PyMem_Malloc(PYMSSQL_MSGSIZE)
IF PYMSSQL_DEBUG == 1:
    cdef int _row_count = 0

cdef bytes HOSTNAME = socket.gethostname()

# List to store the connection objects in
cdef list connection_object_list = list()

# Store the 32bit max int
cdef int MAX_INT = 2147483647

# Store the module version
__version__ = '1.9.909'

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
SQLBITN = 104
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
    cdef readonly int line
    cdef readonly char *text
    cdef readonly char *srvname
    cdef readonly char *procname

    property message:

        def __get__(self):
            if self.procname:
                return 'SQL Server message %d, severity %d, state %d, ' \
                    'procedure %s, line %d:\n%s' % (self.number,
                    self.severity, self.state, self.procname,
                    self.line, self.text)
            else:
                return 'SQL Server message %d, severity %d, state %d, ' \
                    'line %d:\n%s' % (self.number, self.severity,
                    self.state, self.line, self.text)

# Module attributes for configuring _mssql
login_timeout = 60

min_error_severity = 6

# Buffer size for large numbers
DEF NUMERIC_BUF_SZ = 45

cdef void log(char * message, ...):
    if PYMSSQL_DEBUG != 1:
        return
    fprintf(stderr, "+++ %s\n", message)

###################
## Error Handler ##
###################
cdef int err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr,
        char *dberrstr, char *oserrstr):
    cdef char *mssql_lastmsgstr
    cdef int *mssql_lastmsgno
    cdef int *mssql_lastmsgseverity
    cdef int *mssql_lastmsgstate
    cdef int _min_error_severity = min_error_severity
    cdef char mssql_message[PYMSSQL_MSGSIZE]
    cdef char error_type[16]

    if severity < _min_error_severity:
        return INT_CANCEL

    IF PYMSSQL_DEBUG == 1 or PYMSSQL_DEBUG_ERRORS == 1:
        fprintf(stderr, "\n*** err_handler(dbproc = %p, severity = %d,  " \
            "dberr = %d, oserr = %d, dberrstr = '%s',  oserrstr = '%s'); " \
            "DBDEAD(dbproc) = %d\n", <void *>dbproc, severity, dberr,
            oserr, dberrstr, oserrstr, DBDEAD(dbproc));
        fprintf(stderr, "*** previous max severity = %d\n\n",
            _mssql_last_msg_severity);

    mssql_lastmsgstr = _mssql_last_msg_str
    mssql_lastmsgno = &_mssql_last_msg_no
    mssql_lastmsgseverity = &_mssql_last_msg_severity
    mssql_lastmsgstate = &_mssql_last_msg_state

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

    sprintf(mssql_message, '%sDB-Lib error message %d, severity %d:\n%s\n',
        mssql_lastmsgstr, dberr, severity, dberrstr)

    if oserr != DBNOERR and oserr != 0:
        if severity == EXCOMM:
            strcpy(error_type, 'Net-Lib')
        else:
            strcpy(error_type, 'Operating System')
        sprintf(mssql_message, '%s error during %s', error_type, oserrstr)

    strncpy(mssql_lastmsgstr, mssql_message, PYMSSQL_MSGSIZE)

    return INT_CANCEL

#####################
## Message Handler ##
#####################
cdef int msg_handler(DBPROCESS *dbproc, DBINT msgno, int msgstate,
        int severity, char *msgtext, char *srvname, char *procname,
        LINE_T line):

    cdef int *mssql_lastmsgno
    cdef int *mssql_lastmsgseverity
    cdef int *mssql_lastmsgstate
    cdef int *mssql_lastmsgline
    cdef char *mssql_lastmsgstr
    cdef char *mssql_lastmsgsrv
    cdef char *mssql_lastmsgproc
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

    mssql_lastmsgstr = _mssql_last_msg_str
    mssql_lastmsgsrv = _mssql_last_msg_srv
    mssql_lastmsgproc = _mssql_last_msg_proc
    mssql_lastmsgno = &_mssql_last_msg_no
    mssql_lastmsgseverity = &_mssql_last_msg_severity
    mssql_lastmsgstate = &_mssql_last_msg_state
    mssql_lastmsgline = &_mssql_last_msg_line

    for conn in connection_object_list:
        if dbproc != (<MSSQLConnection>conn).dbproc:
            continue
        mssql_lastmsgstr = (<MSSQLConnection>conn).last_msg_str
        mssql_lastmsgsrv = (<MSSQLConnection>conn).last_msg_srv
        mssql_lastmsgproc = (<MSSQLConnection>conn).last_msg_proc
        mssql_lastmsgno = &(<MSSQLConnection>conn).last_msg_no
        mssql_lastmsgseverity = &(<MSSQLConnection>conn).last_msg_severity
        mssql_lastmsgstate = &(<MSSQLConnection>conn).last_msg_state
        mssql_lastmsgline = &(<MSSQLConnection>conn).last_msg_line
        break

    # Calculate the maximum severity of all messages in a row
    # Fill the remaining fields as this is going to raise the exception
    if severity > mssql_lastmsgseverity[0]:
        mssql_lastmsgseverity[0] = severity
        mssql_lastmsgno[0] = msgno
        mssql_lastmsgstate[0] = msgstate
        mssql_lastmsgline[0] = line
        strncpy(mssql_lastmsgstr, msgtext, PYMSSQL_MSGSIZE)
        strncpy(mssql_lastmsgsrv, srvname, PYMSSQL_MSGSIZE)
        strncpy(mssql_lastmsgproc, procname, PYMSSQL_MSGSIZE)


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
            if strlen(self._charset):
                return self._charset
            return None

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
            return self.execute_scalar('SELECT SCOPE_IDENTITY()')

    property query_timeout:
        """
        A
        """
        def __get__(self):
            return self._query_timeout

        def __set__(self, value):
            cdef int val = int(value)
            cdef RETCODE rtc
            if val < 0:
                raise ValueError("The 'query_timeout' attribute must be >= 0.")

            # currently this will set it application wide :-(
            rtc = dbsettime(val)
            check_and_raise(rtc, self)

            # if all is fine then set our attribute
            self._query_timeout = val

    property rows_affected:
        """
        Number of rows affected by last query. For SELECT statements this
        value is only meaningful after reading all rows.
        """

        def __get__(self):
            return self._rows_affected

    property tds_version:
        """
        Returns what TDS version the connection is using.
        """
        def __get__(self):
            cdef int version = dbtds(self.dbproc)
            if version == 9:
                return 8.0
            elif version == 8:
                return 7.0
            elif version == 4:
                return 4.2

    def __cinit__(self):
        log("_mssql.MSSQLConnection.__cinit__()")
        self._connected = 0
        self._charset = <char *>PyMem_Malloc(PYMSSQL_CHARSETBUFSIZE)
        self._charset[0] = <char>0
        self.last_msg_str = <char *>PyMem_Malloc(PYMSSQL_MSGSIZE)
        self.last_msg_str[0] = <char>0
        self.last_msg_srv = <char *>PyMem_Malloc(PYMSSQL_MSGSIZE)
        self.last_msg_srv[0] = <char>0
        self.last_msg_proc = <char *>PyMem_Malloc(PYMSSQL_MSGSIZE)
        self.last_msg_proc[0] = <char>0
        self.column_names = None
        self.column_types = None

    def __init__(self, server="localhost", user="sa", password="",
            charset='', database='', appname=None, port='1433', tds_version='7.1'):
        log("_mssql.MSSQLConnection.__init__()")

        cdef LOGINREC *login
        cdef RETCODE rtc
        cdef char *_charset

        # support MS methods of connecting locally
        instance = ""
        if "\\" in server:
            server, instance = server.split("\\")

        if server in (".", "(local)"):
            server = "localhost"

        server = server + "\\" + instance if instance else server

        login = dblogin()
        if login == NULL:
            raise MSSQLDriverException("Out of memory")

        appname = appname or "pymssql"

        DBSETLUSER(login, user)
        DBSETLPWD(login, password)
        DBSETLAPP(login, appname)
        DBSETLVERSION(login, _tds_ver_str_to_constant(tds_version))

        # add the port to the server string if it doesn't have one already and
        # if we are not using an instance
        if ':' not in server and not instance:
            server = '%s:%s' % (server, port)

        # override the HOST to be the portion without the server, otherwise
        # FreeTDS chokes when server still has the port definition.
        # BUT, a patch on the mailing list fixes the need for this.  I am
        # leaving it here just to remind us how to fix the problem if the bug
        # doesn't get fixed for a while.  But if it does get fixed, this code
        # can be deleted.
        # patch: http://lists.ibiblio.org/pipermail/freetds/2011q2/026997.html
        #if ':' in server:
        #    os.environ['TDSHOST'] = server.split(':', 1)[0]
        #else:
        #    os.environ['TDSHOST'] = server

        # Add ourselves to the global connection list
        connection_object_list.append(self)

        # Set the character set name
        if charset:
            _charset = charset
            strncpy(self._charset, _charset, PYMSSQL_CHARSETBUFSIZE)
            DBSETLCHARSET(login, self._charset)

        # Set the login timeout
        dbsetlogintime(login_timeout)

        # Connect to the server
        self.dbproc = dbopen(login, server)

        # Frees the login record, can be called immediately after dbopen.
        dbloginfree(login)

        if self.dbproc == NULL:
            log("_mssql.MSSQLConnection.__init__() -> dbopen() returned NULL")
            connection_object_list.remove(self)
            maybe_raise_MSSQLDatabaseException(None)
            raise MSSQLDriverException("Connection to the database failed for an unknown reason.")

        self._connected = 1

        log("_mssql.MSSQLConnection.__init__() -> dbcmd() setting connection values")
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
            "SET QUOTED_IDENTIFIER ON;"
        )

        rtc = dbsqlexec(self.dbproc)
        if (rtc == FAIL):
            raise MSSQLDriverException("Could not set connection properties")

        db_cancel(self)
        clr_err(self)

        if database:
            self.select_db(database)

    def __dealloc__(self):
        log("_mssql.MSSQLConnection.__dealloc__()")
        self.close()

    def __iter__(self):
        assert_connected(self)
        clr_err(self)
        return MSSQLRowIterator(self)

    cpdef cancel(self):
        """
        cancel() -- cancel all pending results.

        This function cancels all pending results from the last SQL operation.
        It can be called more than once in a row. No exception is raised in
        this case.
        """
        log("_mssql.MSSQLConnection.cancel()")
        cdef RETCODE rtc

        assert_connected(self)
        clr_err(self)

        rtc = db_cancel(self)
        check_and_raise(rtc, self)

    cdef void clear_metadata(self):
        log("_mssql.MSSQLConnection.clear_metadata()")
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
        log("_mssql.MSSQLConnection.close()")
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

    cdef object convert_db_value(self, BYTE *data, int type, int length):
        log("_mssql.MSSQLConnection.convert_db_value()")
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
            return long(<PY_LONG_LONG>(<PY_LONG_LONG *>data)[0])

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

            len = dbconvert(self.dbproc, type, data, -1, SQLCHAR,
                <BYTE *>buf, NUMERIC_BUF_SZ)

            with decimal.localcontext() as ctx:
                ctx.prec = precision
                return decimal.Decimal(_remove_locale(buf, len))

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
            if strlen(self._charset):
                return (<char *>data)[:length].decode(self._charset)
            else:
                return (<char *>data)[:length]

        elif type == SQLUUID and (PY_MAJOR_VERSION >= 2 and PY_MINOR_VERSION >= 5):
            return uuid.UUID(bytes_le=(<char *>data)[:length])

        else:
            return (<char *>data)[:length]

    cdef int convert_python_value(self, object value, BYTE **dbValue,
            int *dbtype, int *length) except 1:
        log("_mssql.MSSQLConnection.convert_python_value()")
        cdef int *intValue
        cdef double *dblValue
        cdef PY_LONG_LONG *longValue
        cdef char *strValue, *tmp
        cdef BYTE *binValue

        if value is None:
            dbValue[0] = <BYTE *>NULL
            return 0

        if dbtype[0] in (SQLBIT, SQLBITN):
            intValue = <int *>PyMem_Malloc(sizeof(int))
            intValue[0] = <int>value
            dbValue[0] = <BYTE *><DBBIT *>intValue
            return 0

        if dbtype[0] == SQLINTN:
            dbtype[0] = SQLINT4

        if dbtype[0] in (SQLINT1, SQLINT2, SQLINT4):
            if value > MAX_INT:
                raise MSSQLDriverException('value cannot be larger than %d' % MAX_INT)
            intValue = <int *>PyMem_Malloc(sizeof(int))
            intValue[0] = <int>value
            if dbtype[0] == SQLINT1:
                dbValue[0] = <BYTE *><DBTINYINT *>intValue
                return 0
            if dbtype[0] == SQLINT2:
                dbValue[0] = <BYTE *><DBSMALLINT *>intValue
                return 0
            if dbtype[0] == SQLINT4:
                dbValue[0] = <BYTE *><DBINT *>intValue
                return 0

        if dbtype[0] == SQLINT8:
            longValue = <PY_LONG_LONG *>PyMem_Malloc(sizeof(PY_LONG_LONG))
            longValue[0] = <PY_LONG_LONG>value
            dbValue[0] = <BYTE *>longValue
            return 0

        if dbtype[0] in (SQLFLT4, SQLFLT8):
            dblValue = <double *>PyMem_Malloc(sizeof(double))
            dblValue[0] = <double>value
            if dbtype[0] == SQLFLT4:
                dbValue[0] = <BYTE *><DBREAL *>dblValue
                return 0
            if dbtype[0] == SQLFLT8:
                dbValue[0] = <BYTE *><DBFLT8 *>dblValue
                return 0

        if dbtype[0] in (SQLDATETIM4, SQLDATETIME):
            if type(value) not in (datetime.date, datetime.datetime):
                raise TypeError('value can only be a date or datetime')

            value = value.strftime('%Y-%m-%d %H:%M:%S.') + \
                str(value.microsecond / 1000)
            dbtype[0] = SQLCHAR

        if dbtype[0] in (SQLMONEY, SQLMONEY4, SQLNUMERIC, SQLDECIMAL):
            if type(value) in (int, long, bytes):
                value = decimal.Decimal(value)

            if type(value) not in (decimal.Decimal, float):
                raise TypeError('value can only be a Decimal')

            value = str(value)
            dbtype[0] = SQLCHAR

        if dbtype[0] in (SQLVARCHAR, SQLCHAR, SQLTEXT):
            if type(value) not in (str, unicode):
                raise TypeError('value can only be str or unicode')

            if strlen(self._charset) > 0 and type(value) is unicode:
                value = value.encode(self._charset)

            strValue = <char *>PyMem_Malloc(len(value) + 1)
            tmp = value
            strcpy(strValue, tmp)
            dbValue[0] = <BYTE *>strValue
            return 0

        if dbtype[0] in (SQLBINARY, SQLVARBINARY, SQLIMAGE):
            if type(value) is not str:
                raise TypeError('value can only be str')

            binValue = <BYTE *>PyMem_Malloc(len(value))
            memcpy(binValue, <char *>value, len(value))
            length[0] = len(value)
            dbValue[0] = <BYTE *>binValue
            return 0

        # No conversion was possible so raise an error
        raise MSSQLDriverException('Unable to convert value')

    cpdef execute_non_query(self, query_string, params=None):
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
        log("_mssql.MSSQLConnection.execute_non_query() BEGIN")
        cdef RETCODE rtc

        self.format_and_run_query(query_string, params)

        with nogil:
            dbresults(self.dbproc)
            self._rows_affected = dbcount(self.dbproc)

        rtc = db_cancel(self)
        check_and_raise(rtc, self)
        log("_mssql.MSSQLConnection.execute_non_query() END")

    cpdef execute_query(self, query_string, params=None):
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
        log("_mssql.MSSQLConnection.execute_query() BEGIN")
        self.format_and_run_query(query_string, params)
        self.get_result()
        log("_mssql.MSSQLConnection.execute_query() END")

    cpdef execute_row(self, query_string, params=None):
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
        log("_mssql.MSSQLConnection.execute_row()")
        self.format_and_run_query(query_string, params)
        return self.fetch_next_row_dict(0)

    cpdef execute_scalar(self, query_string, params=None):
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
        log("_mssql.MSSQLConnection.execute_scalar()")

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

    cdef fetch_next_row(self, int throw):
        cdef RETCODE rtc
        log("_mssql.MSSQLConnection.fetch_next_row() BEGIN")
        try:
            self.get_result()

            if self.last_dbresults == NO_MORE_RESULTS:
                log("_mssql.MSSQLConnection.fetch_next_row(): NO MORE RESULTS")
                self.clear_metadata()
                if throw:
                    raise StopIteration
                return None

            with nogil:
                rtc = dbnextrow(self.dbproc)

            check_cancel_and_raise(rtc, self)

            if rtc == NO_MORE_ROWS:
                log("_mssql.MSSQLConnection.fetch_next_row(): NO MORE ROWS")
                self.clear_metadata()
                # 'rows_affected' is nonzero only after all records are read
                self._rows_affected = dbcount(self.dbproc)
                if throw:
                    raise StopIteration
                return None

            return self.get_row(rtc)
        finally:
            log("_mssql.MSSQLConnection.fetch_next_row() END")

    cdef fetch_next_row_dict(self, int throw):
        cdef int col
        log("_mssql.MSSQLConnection.fetch_next_row_dict()")

        row_dict = {}
        row = self.fetch_next_row(throw)

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
        log("_mssql.MSSQLConnection.format_and_run_query() BEGIN")

        try:
            # Cancel any pending results
            self.cancel()

            if params:
                query_string = self.format_sql_command(query_string, params)

            log(query_string)

            # Prepare the query buffer
            dbcmd(self.dbproc, query_string)

            # Execute the query
            rtc = db_sqlexec(self.dbproc)
            check_cancel_and_raise(rtc, self)
        finally:
            log("_mssql.MSSQLConnection.format_and_run_query() END")

    cdef format_sql_command(self, format, params=None):
        log("_mssql.MSSQLConnection.format_sql_command()")
        return _substitute_params(format, params, self._charset)

    def get_header(self):
        """
        get_header() -- get the Python DB-API compliant header information.

        This method is infrastructure and doesn't need to be called by your
        code. It returns a list of 7-element tuples describing the current
        result header. Only name and DB-API compliant type is filled, rest
        of the data is None, as permitted by the specs.
        """
        cdef int col
        log("_mssql.MSSQLConnection.get_header() BEGIN")
        try:
            self.get_result()

            if self.num_columns == 0:
                log("_mssql.MSSQLConnection.get_header(): num_columns == 0")
                return None

            header_tuple = []
            for col in xrange(1, self.num_columns + 1):
                col_name = self.column_names[col - 1]
                col_type = self.column_types[col - 1]
                header_tuple.append((col_name, col_type, None, None, None, None, None))
            return tuple(header_tuple)
        finally:
            log("_mssql.MSSQLConnection.get_header() END")

    cdef get_result(self):
        cdef int coltype
        cdef char log_message[200]

        log("_mssql.MSSQLConnection.get_result() BEGIN")

        try:
            if self.last_dbresults:
                log("_mssql.MSSQLConnection.get_result(): last_dbresults == True, return None")
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

            self._rows_affected = dbcount(self.dbproc)

            if self.last_dbresults == NO_MORE_RESULTS:
                self.num_columns = 0
                log("_mssql.MSSQLConnection.get_result(): NO_MORE_RESULTS, return None")
                return None

            self.num_columns = dbnumcols(self.dbproc)

            sprintf(log_message, "_mssql.MSSQLConnection.get_result(): num_columns = %d", self.num_columns)
            log(log_message)

            column_names = list()
            column_types = list()

            for col in xrange(1, self.num_columns + 1):
                column_names.append(dbcolname(self.dbproc, col))
                coltype = dbcoltype(self.dbproc, col)
                column_types.append(get_api_coltype(coltype))

            self.column_names = tuple(column_names)
            self.column_types = tuple(column_types)
        finally:
            log("_mssql.MSSQLConnection.get_result() END")

    cdef get_row(self, int row_info):
        cdef DBPROCESS *dbproc = self.dbproc
        cdef int col
        cdef int col_type
        cdef int len
        cdef BYTE *data
        log("_mssql.MSSQLConnection.get_row()")

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
        log("_mssql.MSSQLConnection.init_procedure()")
        return MSSQLStoredProcedure(procname, self)

    def nextresult(self):
        """
        nextresult() -- move to the next result, skipping all pending rows.

        This method fetches and discards any rows remaining from the current
        resultset, then it advances to the next (if any) resultset. Returns
        True if the next resultset is available, otherwise None.
        """

        cdef RETCODE rtc
        log("_mssql.MSSQLConnection.nextresult()")

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
        log("_mssql.MSSQLConnection.select_db()")

        dbuse(self.dbproc, dbname)

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

    def __init__(self, bytes name, MSSQLConnection connection):
        cdef RETCODE rtc
        log("_mssql.MSSQLStoredProcedure.__init__()")

        # We firstly want to check if tdsver is >= 8 as anything less
        # doesn't support remote procedure calls.
        if connection.tds_version < 7:
            raise MSSQLDriverException("Stored Procedures aren't "
                "supported with a TDS version less than 7.")

        self.conn = connection
        self.dbproc = connection.dbproc
        self.procname = name
        self.params = dict()
        self.output_indexes = list()
        self.param_count = 0
        self.had_positional = False

        with nogil:
            rtc = dbrpcinit(self.dbproc, self.procname, 0)

        check_cancel_and_raise(rtc, self.conn)

    def __dealloc__(self):
        cdef _mssql_parameter_node *n, *p
        log("_mssql.MSSQLStoredProcedure.__dealloc__()")

        n = self.params_list
        p = NULL

        while n != NULL:
            PyMem_Free(n.value)
            p = n
            n = n.next
            PyMem_Free(p)

    def bind(self, object value, int dbtype, bytes name=None,
            int output=False, int null=False, int max_length=-1):
        """
        bind(value, data_type, param_name = None, output = False,
            null = False, max_length = -1) -- bind a parameter

        This method binds a parameter to the stored procedure.
        """
        cdef int length = -1
        cdef RETCODE rtc
        cdef BYTE status, *data
        cdef char *param_name
        cdef _mssql_parameter_node *pn
        log("_mssql.MSSQLStoredProcedure.bind()")

        # Set status according to output being True or False
        status = DBRPCRETURN if output else <BYTE>0

        # Convert the PyObject to the db type
        self.conn.convert_python_value(value, &data, &dbtype, &length)

        # We support nullable parameters by just not binding them
        if dbtype in (SQLINTN, SQLBITN) and data == NULL:
            return

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
            SQLVARBINARY, SQLIMAGE):
            if null or data == NULL:
                length = 0
                if not output:
                    max_length = -1
            # only set the length for strings, binary may contain NULLs
            elif dbtype in (SQLVARCHAR, SQLCHAR, SQLTEXT):
                length = strlen(<char *>data)
        else:
            # Fixed length data type
            if null or output:
                length = 0
            max_length = -1

        # Add some monkey fixing for nullable bit types
        if dbtype == SQLBITN:
            if output:
                max_length = 1
                length = 0
            else:
                length = 1

        if status != DBRPCRETURN:
            max_length = -1

        if name:
            param_name = name
            if self.had_positional:
                raise MSSQLDriverException('Cannot bind named parameter after positional')
        else:
            param_name = ''
            self.had_positional = True

        IF PYMSSQL_DEBUG == 1:
            fprintf(stderr, "\n--- rpc_bind(name = '%s', status = %d, " \
                "max_length = %d, data_type = %d, data_length = %d, "
                "data = %x)\n", param_name, status, max_length, dbtype,
                length, data)

        with nogil:
            rtc = dbrpcparam(self.dbproc, param_name, status, dbtype,
                max_length, length, data)
        check_cancel_and_raise(rtc, self.conn)

        # Store the value in the parameters dictionary for returning
        # later, by name if that has been supplied.
        if name:
            self.params[name] = value
        self.params[self.param_count] = value
        if output:
            self.output_indexes.append(self.param_count)
        self.param_count += 1

    def execute(self):
        cdef RETCODE rtc
        cdef int output_count, i, type, length
        cdef char *name
        cdef BYTE *data
        log("_mssql.MSSQLStoredProcedure.execute()")

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

        # Need to call this regardless of wether or not there are output
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
                if strlen(name):
                    self.params[name] = value
                self.params[self.output_indexes[i-1]] = value

        # Get the return value from the procedure ready for return.
        return dbretstatus(self.dbproc)

cdef int check_and_raise(RETCODE rtc, MSSQLConnection conn) except 1:
    if rtc == FAIL:
        return maybe_raise_MSSQLDatabaseException(conn)
    elif get_last_msg_str(conn):
        return maybe_raise_MSSQLDatabaseException(conn)

cdef int check_cancel_and_raise(RETCODE rtc, MSSQLConnection conn) except 1:
    if rtc == FAIL:
        db_cancel(conn)
        return maybe_raise_MSSQLDatabaseException(conn)
    elif get_last_msg_str(conn):
        return maybe_raise_MSSQLDatabaseException(conn)

cdef char *get_last_msg_str(MSSQLConnection conn):
    return conn.last_msg_str if conn != None else _mssql_last_msg_str

cdef char *get_last_msg_srv(MSSQLConnection conn):
    return conn.last_msg_srv if conn != None else _mssql_last_msg_srv

cdef char *get_last_msg_proc(MSSQLConnection conn):
    return conn.last_msg_proc if conn != None else _mssql_last_msg_proc

cdef int get_last_msg_no(MSSQLConnection conn):
    return conn.last_msg_no if conn != None else _mssql_last_msg_no

cdef int get_last_msg_severity(MSSQLConnection conn):
    return conn.last_msg_severity if conn != None else _mssql_last_msg_severity

cdef int get_last_msg_state(MSSQLConnection conn):
    return conn.last_msg_state if conn != None else _mssql_last_msg_state

cdef int get_last_msg_line(MSSQLConnection conn):
    return conn.last_msg_line if conn != None else _mssql_last_msg_line

cdef int maybe_raise_MSSQLDatabaseException(MSSQLConnection conn) except 1:

    if get_last_msg_severity(conn) < min_error_severity:
        return 0

    error_msg = get_last_msg_str(conn)
    if len(error_msg) == 0:
        error_msg = "Unknown error"

    ex = MSSQLDatabaseException((get_last_msg_no(conn), error_msg))
    (<MSSQLDatabaseException>ex).text = error_msg
    (<MSSQLDatabaseException>ex).srvname = get_last_msg_srv(conn)
    (<MSSQLDatabaseException>ex).procname = get_last_msg_proc(conn)
    (<MSSQLDatabaseException>ex).number = get_last_msg_no(conn)
    (<MSSQLDatabaseException>ex).severity = get_last_msg_severity(conn)
    (<MSSQLDatabaseException>ex).state = get_last_msg_state(conn)
    (<MSSQLDatabaseException>ex).line = get_last_msg_line(conn)
    db_cancel(conn)
    clr_err(conn)
    raise ex

cdef void assert_connected(MSSQLConnection conn):
    log("_mssql.assert_connected()")
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

cdef char *_remove_locale(char *s, size_t buflen):
    cdef char c, *stripped = s
    cdef int i, x = 0, last_sep = -1

    for i, c in enumerate(s[0:buflen]):
        if c in (',', '.'):
            last_sep = i

    for i, c in enumerate(s[0:buflen]):
        if (c >= '0' and c <= '9') or c in ('+', '-'):
            stripped[x] = c
            x += 1
        elif i == last_sep:
            stripped[x] = c
            x += 1
    stripped[x] = 0
    return stripped

def remove_locale(bytes value):
    cdef char *s = <char*>value
    cdef size_t l = strlen(s)
    return _remove_locale(s, l)

cdef int _tds_ver_str_to_constant(bytes verstr) except -1:
    """
        http://www.freetds.org/userguide/choosingtdsprotocol.htm
    """
    if verstr == u'4.2':
        return DBVERSION_42
    if verstr == u'7.0':
        return DBVERSION_70
    if verstr == u'7.1':
        return DBVERSION_71
    if verstr == u'7.2':
        return DBVERSION_72
    if verstr == u'8.0':
        return DBVERSION_80
    raise MSSQLException('unrecognized tds version: %s' % verstr)

#######################
## Quoting Functions ##
#######################
cdef _quote_simple_value(value, charset='utf8'):

    if value == None:
        return 'NULL'

    if isinstance(value, bool):
        return '1' if value else '0'

    if isinstance(value, (int, long, float, decimal.Decimal)):
        return str(value)

    if isinstance(value, str):
        # see if it can be decoded as ascii if there are no null bytes
        if '\0' not in value:
            try:
                value.decode('ascii')
                return "'" + value.replace("'", "''") + "'"
            except UnicodeDecodeError:
                pass

        # will still be string type if there was a null byte in it or if the
        # decoding failed.  In this case, just send it as hex.
        if isinstance(value, str):
            return '0x' + value.encode('hex')

    if isinstance(value, unicode):
        return "N'" + value.encode(charset).replace("'", "''") + "'"

    if isinstance(value, datetime.datetime):
        return "{ts '%04d-%02d-%02d %02d:%02d:%02d.%d'}" % (
            value.year, value.month, value.day,
            value.hour, value.minute, value.second,
            value.microsecond / 1000)

    if isinstance(value, datetime.date):
        return "{d '%04d-%02d-%02d'} " % (
        value.year, value.month, value.day)

    return None

cdef _quote_or_flatten(data, charset='utf8'):
    result = _quote_simple_value(data, charset)

    if result is not None:
        return result

    if not issubclass(type(data), (list, tuple)):
        raise ValueError('expected a simple type, a tuple or a list')

    string = ''
    for value in data:
        value = _quote_simple_value(value, charset)

        if value is None:
            raise ValueError('found an unsupported type')

        string += '%s,' % value
    return string[:-1]

# This function is supposed to take a simple value, tuple or dictionary,
# normally passed in via the params argument in the execute_* methods. It
# then quotes and flattens the arguments and returns then.
cdef _quote_data(data, charset='utf8'):
    result = _quote_simple_value(data)

    if result is not None:
        return result

    if issubclass(type(data), dict):
        result = {}
        for k, v in data.iteritems():
            result[k] = _quote_or_flatten(v, charset)
        return result

    if issubclass(type(data), tuple):
        result = []
        for v in data:
            result.append(_quote_or_flatten(v, charset))
        return tuple(result)

    raise ValueError('expected a simple type, a tuple or a dictionary.')

_re_pos_param = re.compile(r'(%(s|d))')
_re_name_param = re.compile(r'(%\(([^\)]+)\)s)')
cdef _substitute_params(toformat, params, charset):
    if params is None:
        return toformat

    if not issubclass(type(params),
            (bool, int, long, float, unicode, str,
            datetime.datetime, datetime.date, dict, tuple, decimal.Decimal)):
        raise ValueError("'params' arg can be only a tuple or a dictionary.")

    if charset:
        quoted = _quote_data(params, charset)
    else:
        quoted = _quote_data(params)

    # positional string substitution now requires a tuple
    if isinstance(quoted, basestring):
        quoted = (quoted,)

    if isinstance(params, dict):
        """ assume name based substitutions """
        offset = 0
        for match in _re_name_param.finditer(toformat):
            param_key = match.group(2)

            if not params.has_key(param_key):
                raise ValueError('params dictionary did not contain value for placeholder: %s' % param_key)

            # calculate string positions so we can keep track of the offset to
            # be used in future substituations on this string.  This is
            # necessary b/c the match start() and end() are based on the
            # original string, but we modify the original string each time we
            # loop, so we need to make an adjustment for the difference between
            # the length of the placeholder and the length of the value being
            # substituted
            param_val = quoted[param_key]
            param_val_len = len(param_val)
            placeholder_len = len(match.group(1))
            offset_adjust = param_val_len - placeholder_len

            # do the string substitution
            match_start = match.start(1) + offset
            match_end = match.end(1) + offset
            toformat = toformat[:match_start] + param_val + toformat[match_end:]

            # adjust the offset for the next usage
            offset += offset_adjust
    else:
        """ assume position based substitutions """
        offset = 0
        for count, match in enumerate(_re_pos_param.finditer(toformat)):
            # calculate string positions so we can keep track of the offset to
            # be used in future substituations on this string.  This is
            # necessary b/c the match start() and end() are based on the
            # original string, but we modify the original string each time we
            # loop, so we need to make an adjustment for the difference between
            # the length of the placeholder and the length of the value being
            # substituted
            try:
                param_val = quoted[count]
            except IndexError:
                raise ValueError('more placeholders in sql than params available')
            param_val_len = len(param_val)
            placeholder_len = 2
            offset_adjust = param_val_len - placeholder_len

            # do the string substitution
            match_start = match.start(1) + offset
            match_end = match.end(1) + offset
            toformat = toformat[:match_start] + param_val + toformat[match_end:]
            #print(param_val, param_val_len, offset_adjust, match_start, match_end)
            # adjust the offset for the next usage
            offset += offset_adjust
    return toformat

# We'll add these methods to the module to allow for unit testing of the
# underlying C methods.
def quote_simple_value(value):
    return _quote_simple_value(value)

def quote_or_flatten(data):
    return _quote_or_flatten(data)

def quote_data(data):
    return _quote_data(data)

def substitute_params(toformat, params, charset='utf8'):
    return _substitute_params(toformat, params, charset)

###########################
## Compatibility Aliases ##
###########################
def connect(*args, **kwargs):
    return MSSQLConnection(*args, **kwargs)

MssqlDatabaseException = MSSQLDatabaseException
MssqlDriverException = MSSQLDriverException
MssqlConnection = MSSQLConnection

#####################
## Max Connections ##
#####################
def get_max_connections():
    """
    Get maximum simultaneous connections db-lib will open to the server.
    """
    return dbgetmaxprocs()

def set_max_connections(int limit):
    """
    Set maximum simultaneous connections db-lib will open to the server.

    :param limit: the connection limit
    :type limit: int
    """
    dbsetmaxprocs(limit)

cdef void init_mssql():
    cdef RETCODE rtc
    rtc = dbinit()
    if rtc == FAIL:
        raise MSSQLDriverException("Could not initialize communication layer")

    dberrhandle(err_handler)
    dbmsghandle(msg_handler)

init_mssql()
