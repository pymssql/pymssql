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

cdef int PYMSSQL_DEBUG = 0
cdef int PYMSSQL_DEBUG_ERRORS = 0
cdef enum: PYMSSQL_CHARSETBUFSIZE = 100
cdef enum: PYMSSQL_MSGSIZE = (1024 * 8)

ROW_FORMAT_TUPLE = 1
ROW_FORMAT_DICT = 2

cdef int _ROW_FORMAT_TUPLE = ROW_FORMAT_TUPLE
cdef int _ROW_FORMAT_DICT = ROW_FORMAT_DICT

from collections.abc import Iterable

import os
import sys
import socket
import decimal
import binascii
import datetime
import re
import uuid
from itertools import zip_longest

class datetime2(datetime.datetime): pass

from .sqlfront cimport *

from libc.stdio cimport fprintf, snprintf, stderr, FILE
from libc.string cimport strlen, strncpy, memcpy, memset

from cpython cimport bool
from cpython.mem cimport PyMem_Malloc, PyMem_Free
from cpython.long cimport PY_LONG_LONG
from cpython.ref cimport Py_INCREF
from cpython.tuple cimport PyTuple_New, PyTuple_SetItem

cdef extern from "version.h":
    const char *PYMSSQL_VERSION
from . import exceptions

# Vars to store messages from the server in
cdef int _mssql_last_msg_no = 0
cdef int _mssql_last_msg_severity = 0
cdef int _mssql_last_msg_state = 0
cdef int _mssql_last_msg_line = 0
cdef char *_mssql_last_msg_str = <char *>PyMem_Malloc(PYMSSQL_MSGSIZE)
_mssql_last_msg_str[0] = <char>0
cdef char *_mssql_last_msg_srv = <char *>PyMem_Malloc(PYMSSQL_MSGSIZE)
_mssql_last_msg_srv[0] = <char>0
cdef char *_mssql_last_msg_proc = <char *>PyMem_Malloc(PYMSSQL_MSGSIZE)
_mssql_last_msg_proc[0] = <char>0

cdef int _row_count = 0

cdef bytes HOSTNAME = socket.gethostname().encode('utf-8')

# List to store the connection objects in
cdef list connection_object_list = list()

# Store the 32bit int limit values
cdef int MAX_INT = 2147483647
cdef int MIN_INT = -2147483648

# Store the module version
__full_version__ = PYMSSQL_VERSION.decode('ascii')
__version__ = '.'.join(__full_version__.split('.')[:3])
VERSION = tuple(int(c) if c.isdigit() else c for c in __full_version__.split('.')[:3])

# Singleton for parameterless queries
NoParams = object()

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
SQLDATETIME = SYBDATETIME  # 61
SQLDATETIM4 = SYBDATETIME4 # 58
SQLDATETIMN = SYBDATETIMN  # 111
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

SQLDATE = 40
SQLTIME = 41
SQLDATETIME2 = 42
SQLDATETIMEOFFSET = SYBMSDATETIMEOFFSET # 43

####################
## TDS_ENCRYPTION_LEVEL ##
####################

cdef dict TDS_ENCRYPTION_LEVEL = {
    'default': 0,  # TDS_ENCRYPTION_DEFAULT,
    'off':     1,  # TDS_ENCRYPTION_OFF,
    'request': 2,  # TDS_ENCRYPTION_REQUEST,
    'require': 3   # TDS_ENCRYPTION_REQUIRE
}

###################
## Type mappings ##
###################

cdef dict DBTYPES = {
    'bool': SQLBITN,
    'str': SQLVARCHAR,
    'unicode': SQLVARCHAR,
    'Decimal': SQLDECIMAL,
    'datetime': SQLDATETIME,
    'date': SQLDATETIME,
    'float': SQLFLT8,
    'bytes': SQLVARBINARY,
    'bytearray': SQLVARBINARY,
    #Dump type for work vith None
    'NoneType': SQLVARCHAR,
}

cpdef int py2db_type(py_type, value) except -1:
    try:
        type_name = py_type.__name__

        if type_name == 'int':
            if value is not None and value >= -2147483648 and value <= 2147483647:  # -2^31 - 2^31-1
                return SQLINTN
            else:
                return SQLINT8

        return DBTYPES[type_name]

    except (AttributeError, KeyError):
        raise MSSQLDriverException('Unable to determine database type from python %s type' % type_name)


#######################
## Exception classes ##
#######################

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

wait_callback = None

def set_wait_callback(a_callable):
    global wait_callback

    wait_callback = a_callable

# Buffer size for large numbers
cdef enum: NUMERIC_BUF_SZ = 45

cdef bytes ensure_bytes(s, encoding='utf-8'):
    try:
        decoded = s.decode(encoding)
        return decoded.encode(encoding)
    except AttributeError:
        return s.encode(encoding)

cdef void log(char * message, ...):
    if PYMSSQL_DEBUG == 1:
        fprintf(stderr, "+++ %s\n", message)


###################
## Error Handler ##
###################
cdef int err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr,
        char *dberrstr, char *oserrstr) noexcept with gil:
    cdef char *mssql_lastmsgstr
    cdef int *mssql_lastmsgno
    cdef int *mssql_lastmsgseverity
    cdef int *mssql_lastmsgstate
    cdef int _min_error_severity = min_error_severity
    cdef char mssql_message[PYMSSQL_MSGSIZE]

    if severity < _min_error_severity:
        return INT_CANCEL

    if dberrstr == NULL:
        dberrstr = ''
    if oserrstr == NULL:
        oserrstr = ''

    if (PYMSSQL_DEBUG == 1 or PYMSSQL_DEBUG_ERRORS == 1):
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
        if DBDEAD(dbproc):
            log("+++ err_handler: dbproc is dead; killing conn...\n")
            conn.mark_disconnected()
        break

    if severity > mssql_lastmsgseverity[0]:
        mssql_lastmsgseverity[0] = severity
        mssql_lastmsgno[0] = dberr
        mssql_lastmsgstate[0] = oserr

    if oserr != DBNOERR and oserr != 0:
        if severity == EXCOMM:
            snprintf(
                mssql_message, sizeof(mssql_message),
                '%sDB-Lib error message %d, severity %d:\n%s\nNet-Lib error during %s (%d)\n',
                mssql_lastmsgstr, dberr, severity, dberrstr, oserrstr, oserr)
        else:
            snprintf(
                mssql_message, sizeof(mssql_message),
                '%sDB-Lib error message %d, severity %d:\n%s\nOperating System error during %s (%d)\n',
                mssql_lastmsgstr, dberr, severity, dberrstr, oserrstr, oserr)
    else:
        snprintf(
            mssql_message, sizeof(mssql_message),
            '%sDB-Lib error message %d, severity %d:\n%s\n',
            mssql_lastmsgstr, dberr, severity, dberrstr)

    strncpy(mssql_lastmsgstr, mssql_message, PYMSSQL_MSGSIZE)
    mssql_lastmsgstr[ PYMSSQL_MSGSIZE - 1 ] = b'\0'

    return INT_CANCEL

#####################
## Message Handler ##
#####################
cdef int msg_handler(DBPROCESS *dbproc, DBINT msgno, int msgstate,
        int severity, char *msgtext, char *srvname, char *procname,
        LINE_T line) noexcept with gil:

    cdef int *mssql_lastmsgno
    cdef int *mssql_lastmsgseverity
    cdef int *mssql_lastmsgstate
    cdef int *mssql_lastmsgline
    cdef char *mssql_lastmsgstr
    cdef char *mssql_lastmsgsrv
    cdef char *mssql_lastmsgproc
    cdef int _min_error_severity = min_error_severity
    cdef MSSQLConnection conn = None

    if (PYMSSQL_DEBUG == 1):
        fprintf(stderr, "\n+++ msg_handler(dbproc = %p, msgno = %d, " \
            "msgstate = %d, severity = %d, msgtext = '%s', " \
            "srvname = '%s', procname = '%s', line = %d)\n",
            dbproc, msgno, msgstate, severity, msgtext, srvname,
            procname, line);
        fprintf(stderr, "+++ previous max severity = %d\n\n",
            _mssql_last_msg_severity);

    for cnx in connection_object_list:
        if (<MSSQLConnection>cnx).dbproc != dbproc:
            continue

        conn = <MSSQLConnection>cnx
        break

    if conn is not None and conn.msghandler is not None:
        conn.msghandler(msgstate, severity, srvname, procname, line, msgtext)

    if severity < _min_error_severity:
        return INT_CANCEL

    if conn is not None:
        mssql_lastmsgstr = conn.last_msg_str
        mssql_lastmsgsrv = conn.last_msg_srv
        mssql_lastmsgproc = conn.last_msg_proc
        mssql_lastmsgno = &conn.last_msg_no
        mssql_lastmsgseverity = &conn.last_msg_severity
        mssql_lastmsgstate = &conn.last_msg_state
        mssql_lastmsgline = &conn.last_msg_line
    else:
        mssql_lastmsgstr = _mssql_last_msg_str
        mssql_lastmsgsrv = _mssql_last_msg_srv
        mssql_lastmsgproc = _mssql_last_msg_proc
        mssql_lastmsgno = &_mssql_last_msg_no
        mssql_lastmsgseverity = &_mssql_last_msg_severity
        mssql_lastmsgstate = &_mssql_last_msg_state
        mssql_lastmsgline = &_mssql_last_msg_line

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

cdef int db_sqlexec(DBPROCESS *dbproc) except? 0:
    cdef RETCODE rtc

    # The dbsqlsend function sends Transact-SQL statements, stored in the
    # command buffer of the DBPROCESS, to SQL Server.
    #
    # It does not wait for a response. This gives us an opportunity to do other
    # things while waiting for the server response.
    #
    # After dbsqlsend returns SUCCEED, dbsqlok must be called to verify the
    # accuracy of the command batch. Then dbresults can be called to process
    # the results.
    with nogil:
        rtc = dbsqlsend(dbproc)
        if rtc != SUCCEED:
            return rtc

    # If we've reached here, dbsqlsend didn't fail so the query is in progress.

    # Wait for results to come back and return the return code, optionally
    # calling wait_callback first...
    return db_sqlok(dbproc)

cdef int db_sqlok(DBPROCESS *dbproc) except? 0:
    cdef RETCODE rtc

    # If there is a wait callback, call it with the file descriptor we're
    # waiting on.
    # The wait_callback is a good place to do things like yield to another
    # gevent greenlet -- e.g.: gevent.socket.wait_read(read_fileno)
    if wait_callback:
        read_fileno = dbiordesc(dbproc)
        wait_callback(read_fileno)

    # dbsqlok following dbsqlsend is the equivalent of dbsqlexec. This function
    # must be called after dbsqlsend returns SUCCEED. When dbsqlok returns,
    # then dbresults can be called to process the results.
    with nogil:
        rtc = dbsqlok(dbproc)

    return rtc

cdef void clr_err(MSSQLConnection conn):
    if conn != None:
        conn.last_msg_no = 0
        conn.last_msg_severity = 0
        conn.last_msg_state = 0
        conn.last_msg_str[0] = 0
    else:
        _mssql_last_msg_no = 0
        _mssql_last_msg_severity = 0
        _mssql_last_msg_state = 0
        _mssql_last_msg_str[0] = 0

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

    def __init__(self, connection, int row_format):
        self.conn = connection
        self.row_format = row_format

    def __iter__(self):
        return self

    def __next__(self):
        assert_connected(self.conn)
        clr_err(self.conn)
        return self.conn.fetch_next_row(1, self.row_format)

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
                return self._charset.decode('ascii')
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

            # XXX: Currently this will set it application wide :-(
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
            if version == 12:
                return 7.4
            elif version == 11:
                return 7.3
            elif version == 10:
                return 7.2
            elif version == 9:
                return 7.1
            elif version == 8:
                return 7.0
            elif version == 6:
                return 5.0
            elif version == 4:
                return 4.2
            return None

    property tds_version_tuple:
        """
        Reports what TDS version the connection is using in tuple form which is
        more easily handled (parse, compare) programmatically. If no TDS
        version can be detected the value is None.
        """
        def __get__(self):
            cdef int version = dbtds(self.dbproc)
            if version == 12:
                return (7, 4)
            elif version == 11:
                return (7, 3)
            elif version == 10:
                return (7, 2)
            elif version == 9:
                return (7, 1)
            elif version == 8:
                return (7, 0)
            elif version == 6:
                return (5, 0)
            elif version == 4:
                return (4, 2)
            return None

    def __cinit__(self):
        log("_mssql.MSSQLConnection.__cinit__()")
        self._connected = 0
        self._charset = <char *>PyMem_Malloc(PYMSSQL_CHARSETBUFSIZE)
        self._charset[0] = <char>0
        self.use_datetime2 = False
        self.last_msg_str = <char *>PyMem_Malloc(PYMSSQL_MSGSIZE)
        self.last_msg_str[0] = <char>0
        self.last_msg_srv = <char *>PyMem_Malloc(PYMSSQL_MSGSIZE)
        self.last_msg_srv[0] = <char>0
        self.last_msg_proc = <char *>PyMem_Malloc(PYMSSQL_MSGSIZE)
        self.last_msg_proc[0] = <char>0
        self.column_names = None
        self.column_types = None

    def __init__(self, server="localhost", user=None, password=None,
                        charset='UTF-8', database='', appname=None, port='1433',
                        tds_version=None, encryption=None, read_only=False,
                        use_datetime2=False,
                        conn_properties=None):
        log("_mssql.MSSQLConnection.__init__()")

        cdef LOGINREC *login
        cdef RETCODE rtc

        self.use_datetime2 = use_datetime2

        # support MS methods of connecting locally
        instance = ""
        if "\\" in server:
            server, instance = server.split("\\")

        if server in (".", "(local)"):
            server = "localhost"

        server = server + "\\" + instance if instance else server

        # add the port to the server string if it doesn't have one already and
        # if we are not using an instance
        if ':' not in server and not instance:
            server = '%s:%s' % (server, port)

        cdef bytes server_bytes = server.encode('utf-8')
        cdef char *server_cstr = server_bytes

        login = dblogin()
        if login == NULL:
            raise MSSQLDriverException("dblogin() failed")

        appname = appname or "pymssql=%s" % __full_version__
        cdef bytes appname_bytes = appname.encode('utf-8')
        cdef char *appname_cstr = appname_bytes
        DBSETLAPP(login, appname_cstr)

        cdef bytes user_bytes
        cdef char *user_cstr = NULL
        if user is not None:
            user_bytes = user.encode('utf-8')
            user_cstr = user_bytes
            DBSETLUSER(login, user_cstr)

        cdef bytes password_bytes
        cdef char *password_cstr = NULL
        if password is not None:
            password_bytes = password.encode('utf-8')
            password_cstr = password_bytes
            DBSETLPWD(login, password_cstr)

        if tds_version is not None:
            DBSETLVERSION(login, _tds_ver_str_to_constant(tds_version))

        if encryption is not None:
            if encryption in TDS_ENCRYPTION_LEVEL:
                DBSETLENCRYPT(login, TDS_ENCRYPTION_LEVEL[encryption])
            else:
                raise ValueError(f"'encryption' option should be {TDS_ENCRYPTION_LEVEL.keys())} or None.")

        cdef bytes charset_bytes
        cdef char *_charset
        # Set the character set name
        if charset:
            charset_bytes = charset.encode('utf-8')
            _charset = charset_bytes
            strncpy(self._charset, _charset, PYMSSQL_CHARSETBUFSIZE)
            DBSETLCHARSET(login, self._charset)

        # For Python 3, we need to convert unicode to byte strings
        cdef bytes dbname_bytes
        cdef char *dbname_cstr
        # Put the DB name in the login LOGINREC because it helps with connections to Azure
        if database:
            dbname_bytes = database.encode('utf-8')
            dbname_cstr = dbname_bytes
            DBSETLDBNAME(login, dbname_cstr)

        if read_only:
            DBSETLREADONLY(login, 1)

        # Add ourselves to the global connection list
        connection_object_list.append(self)

        # Set the login timeout
        # XXX: Currently this will set it application wide :-(
        dbsetlogintime(login_timeout)

        # Connect to the server
        with nogil:
            self.dbproc = dbopen(login, server_cstr)

        # Frees the login record, can be called immediately after dbopen.
        dbloginfree(login)

        if self.dbproc == NULL:
            log("_mssql.MSSQLConnection.__init__() -> dbopen() returned NULL")
            if self in connection_object_list:
                connection_object_list.remove(self)
            maybe_raise_MSSQLDatabaseException(None)
            raise MSSQLDriverException("Connection to the database failed for an unknown reason.")

        self._connected = 1

        if conn_properties is None:
            conn_properties = \
                "SET ARITHABORT ON;"                \
                "SET CONCAT_NULL_YIELDS_NULL ON;"   \
                "SET ANSI_NULLS ON;"                \
                "SET ANSI_NULL_DFLT_ON ON;"         \
                "SET ANSI_PADDING ON;"              \
                "SET ANSI_WARNINGS ON;"             \
                "SET ANSI_NULL_DFLT_ON ON;"         \
                "SET CURSOR_CLOSE_ON_COMMIT ON;"    \
                "SET QUOTED_IDENTIFIER ON;"         \
                "SET TEXTSIZE 2147483647;"  # http://msdn.microsoft.com/en-us/library/aa259190%28v=sql.80%29.aspx
        elif isinstance(conn_properties, Iterable) and not isinstance(conn_properties, str):
            conn_properties = ' '.join(conn_properties)
        cdef bytes conn_props_bytes
        cdef char *conn_props_cstr
        if conn_properties:
            log("_mssql.MSSQLConnection.__init__() -> dbcmd() setting connection values")
            # Set connection properties, some reasonable values are used by
            # default but they can be customized
            conn_props_bytes = conn_properties.encode('utf-8')
            conn_props_cstr = conn_props_bytes
            dbcmd(self.dbproc, conn_props_bytes)

            rtc = db_sqlexec(self.dbproc)
            if (rtc == FAIL):
                raise MSSQLDriverException("Could not set connection properties")

        db_cancel(self)
        clr_err(self)

        if database:
            self.select_db(database)

    def __dealloc__(self):
        log("_mssql.MSSQLConnection.__dealloc__()")
        self.close()

        PyMem_Free(self._charset)
        PyMem_Free(self.last_msg_str)
        PyMem_Free(self.last_msg_srv)
        PyMem_Free(self.last_msg_proc)

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()

    def __iter__(self):
        assert_connected(self)
        clr_err(self)
        return MSSQLRowIterator(self, ROW_FORMAT_DICT)

    cpdef set_msghandler(self, object handler):
        """
        set_msghandler(handler) -- set the msghandler for the connection

        This function allows setting a msghandler for the connection to
        allow a client to gain access to the messages returned from the
        server.
        """
        self.msghandler = handler

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

        This function tries to close the connection.  It can be called more than once in a row. No exception is raised
        in this case.
        """
        log("_mssql.MSSQLConnection.close()")
        if self == None:
            return None

        if not self._connected:
            return None

        clr_err(self)

        with nogil:
            dbclose(self.dbproc)

        self.mark_disconnected()

    def mark_disconnected(self):
        log("_mssql.MSSQLConnection.mark_disconnected()")
        self.dbproc = NULL
        self._connected = 0
        connection_object_list.remove(self)

    cdef object convert_db_value(self, BYTE *data, int dbtype, int length):
        log("_mssql.MSSQLConnection.convert_db_value()")
        cdef char buf[NUMERIC_BUF_SZ] # buffer in which we store text rep of bug nums
        cdef int converted_length
        cdef long prevPrecision
        cdef BYTE precision
        cdef DBDATEREC2 di
        cdef DBDATETIME dt
        cdef DBCOL dbcol

        if (PYMSSQL_DEBUG == 1):
            sys.stderr.write("convert_db_value: dbtype = %d; length = %d\n" % (dbtype, length))

        if dbtype == SQLBIT:
            return bool(<int>(<DBBIT *>data)[0])

        elif dbtype == SQLINT1:
            return int(<int>(<DBTINYINT *>data)[0])

        elif dbtype == SQLINT2:
            return int(<int>(<DBSMALLINT *>data)[0])

        elif dbtype == SQLINT4:
            return int(<int>(<DBINT *>data)[0])

        elif dbtype == SQLINT8:
            return long(<PY_LONG_LONG>(<PY_LONG_LONG *>data)[0])

        elif dbtype == SQLFLT4:
            return float(<float>(<DBREAL *>data)[0])

        elif dbtype == SQLFLT8:
            return float(<double>(<DBFLT8 *>data)[0])

        elif dbtype in (SQLMONEY, SQLMONEY4, SQLNUMERIC, SQLDECIMAL):
            dbcol.SizeOfStruct = sizeof(dbcol)

            if dbtype in (SQLMONEY, SQLMONEY4):
                precision = 4
            else:
                precision = 0

            converted_length = dbconvert(self.dbproc, dbtype, data, -1, SQLCHAR,
                <BYTE *>buf, NUMERIC_BUF_SZ)

            with decimal.localcontext() as ctx:
                # Python 3 doesn't like decimal.localcontext() with prec == 0
                ctx.prec = precision if precision > 0 else 1
                return decimal.Decimal(_remove_locale(buf, converted_length).decode(self._charset))

        elif dbtype in (SQLDATETIM4, SQLDATETIME, SQLDATETIME2):
            dbanydatecrack(self.dbproc, &di, dbtype, data)
            return datetime.datetime(di.year, di.month, di.day,
                di.hour, di.minute, di.second, di.nanosecond // 1000)

        elif dbtype == SQLDATETIMEOFFSET:
            dbanydatecrack(self.dbproc, &di, dbtype, data)
            tz = datetime.timezone(datetime.timedelta(minutes=di.tzone))
            return datetime.datetime(di.year, di.month, di.day,
                di.hour, di.minute, di.second, di.nanosecond // 1000, tz)

        elif dbtype == SQLDATE:
            dbanydatecrack(self.dbproc, &di, dbtype, data)
            return datetime.date(di.year, di.month, di.day)

        elif dbtype == SQLTIME:
            dbanydatecrack(self.dbproc, &di, dbtype, data)
            return datetime.time(di.hour, di.minute, di.second, di.nanosecond // 1000)

        elif dbtype in (SQLVARCHAR, SQLCHAR, SQLTEXT):
            if strlen(self._charset):
                return (<char *>data)[:length].decode(self._charset)
            else:
                return (<char *>data)[:length]

        elif dbtype == SQLUUID:
            return uuid.UUID(bytes_le=(<char *>data)[:length])

        else:
            return (<char *>data)[:length]

    cdef int convert_python_value(self, object value, BYTE **dbValue,
            int *dbtype, int *length) except -1:
        log("_mssql.MSSQLConnection.convert_python_value()")
        cdef int *intValue
        cdef double *dblValue
        cdef float *fltValue
        cdef PY_LONG_LONG *longValue
        cdef char *strValue
        cdef char *tmp
        cdef BYTE *binValue
        cdef DBTYPEINFO decimal_type_info

        if (PYMSSQL_DEBUG == 1):
            sys.stderr.write("convert_python_value: value = %r; dbtype = %d" % (value, dbtype[0]))

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
            elif value < MIN_INT:
                raise MSSQLDriverException('value cannot be smaller than %d' % MIN_INT)
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

        if dbtype[0] in (SQLFLT4, SQLREAL):
            fltValue = <float *>PyMem_Malloc(sizeof(float))
            fltValue[0] = <float>value
            dbValue[0] = <BYTE *><DBREAL *>fltValue
            return 0

        if dbtype[0] == SQLFLT8:
            dblValue = <double *>PyMem_Malloc(sizeof(double))
            dblValue[0] = <double>value
            dbValue[0] = <BYTE *><DBFLT8 *>dblValue
            return 0

        if dbtype[0] == SQLDATE:
            if not isinstance(value, datetime.date):
                raise TypeError('value can only be a datetime.date, got {type(value)}')
            value = value.strftime(f'{value.year:04}-%m-%d').encode(self.charset)
            dbtype[0] = SQLCHAR

        if dbtype[0] == SQLTIME:
            if not isinstance(value, datetime.time):
                raise TypeError(f'value can only be a datetime.time, got {type(value)}')
            value = value.strftime('%H:%M:%S.%f')
            value = value.encode(self.charset)
            dbtype[0] = SQLCHAR

        if dbtype[0] == SQLDATETIME2:
            if not isinstance(value, datetime.datetime):
                raise TypeError(f'value can only be a datetime.datetime, got {type(value)}')
            value = value.strftime(f'{value.year:04}-%m-%d %H:%M:%S.%f').encode(self.charset)
            dbtype[0] = SQLCHAR

        if dbtype[0] in (SQLDATETIM4, SQLDATETIME):
            if not isinstance(value, datetime.datetime):
                raise TypeError(f'value can only be a datetime.datetime, got {type(value)}')
            microseconds=0
            if type(value) in (datetime.datetime,):
                microseconds=value.microsecond // 1000
            value = value.strftime(f'{value.year:04}-%m-%d %H:%M:%S.') + \
                "%03d" % (microseconds)
            value = value.encode(self.charset)
            dbtype[0] = SQLCHAR

        if dbtype[0] == SQLDATETIMEOFFSET:
            if not isinstance(value, datetime.datetime):
                raise TypeError(f'value can only be a datetime.datetime, got {type(value)}')
            t = value.strftime(f'{value.year:04}-%m-%d %H:%M:%S.%f')
            tz = value.strftime('%Z')
            if tz:
                t = f"{t} {tz[3:]}"
            value = t.encode(self.charset)
            dbtype[0] = SQLCHAR


        if dbtype[0] in (SQLNUMERIC, SQLDECIMAL):
            # There seems to be no harm in setting precision higher than
            # necessary
            decimal_type_info.precision = 33

            # Figure out `scale` - number of digits after decimal point
            decimal_type_info.scale = abs(value.as_tuple().exponent)

            # Need this to prevent Cython error:
            # "Obtaining 'BYTE *' from temporary Python value"
            # bytes_value = bytes(str(value), encoding="ascii")
            bytes_value = unicode(value).encode("ascii")

            decValue = <DBDECIMAL *>PyMem_Malloc(sizeof(DBDECIMAL))
            length[0] = dbconvert_ps(
                self.dbproc,
                SQLCHAR,
                bytes_value,
                -1,
                dbtype[0],
                <BYTE *>decValue,
                sizeof(DBDECIMAL),
                &decimal_type_info,
            )
            dbValue[0] = <BYTE *>decValue

            if (PYMSSQL_DEBUG == 1):
                print("convert_python_value: Converted value to DBDECIMAL with length = %d\n", length[0], file=sys.stderr)
                for i in range(0, 35):
                    print("convert_python_value: dbValue[0][%d] = %d\n", i, dbValue[0][i], file=sys.stderr)

            return 0

        if dbtype[0] in (SQLMONEY, SQLMONEY4, SQLNUMERIC, SQLDECIMAL):
            if type(value) in (int, long, bytes):
                value = decimal.Decimal(value)

            if type(value) not in (decimal.Decimal, float):
                raise TypeError('value can only be a Decimal')

            value = str(value)
            dbtype[0] = SQLCHAR

        if dbtype[0] in (SQLVARCHAR, SQLCHAR, SQLTEXT):
            if not hasattr(value, 'startswith'):
                raise TypeError('value must be a string type')

            if strlen(self._charset) > 0 and type(value) is unicode:
                value = value.encode(self.charset)

            strValue = <char *>PyMem_Malloc(len(value) + 1)
            tmp = value
            strncpy(strValue, tmp, len(value) + 1)
            strValue[ len(value) ] = b'\0';
            dbValue[0] = <BYTE *>strValue
            return 0

        if dbtype[0] in (SQLBINARY, SQLVARBINARY, SQLIMAGE):
            if not isinstance(value, (bytes,bytearray)):
                raise TypeError('value can only be bytes or bytearray')

            binValue = <BYTE *>PyMem_Malloc(len(value))
            memcpy(binValue, <char *>value, len(value))
            length[0] = len(value)
            dbValue[0] = <BYTE *>binValue
            return 0

        if dbtype[0] == SQLUUID:
            binValue = <BYTE *>PyMem_Malloc(16)
            memcpy(binValue, <char *>value.bytes_le, 16)
            length[0] = 16
            dbValue[0] = <BYTE *>binValue
            return 0

        # No conversion was possible so raise an error
        raise MSSQLDriverException(f'Unable to convert value dbtype={dbtype[0]}')

    cpdef execute_non_query(self, query_string, params=NoParams):
        """
        execute_non_query(query_string, params=NoParams)

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

    cpdef execute_query(self, query_string, params=NoParams):
        """
        execute_query(query_string, params=NoParams)

        This method sends a query to the MS SQL Server to which this object
        instance is connected. An exception is raised on failure. If there
        are pending results or rows prior to executing this command, they
        are silently discarded. After calling this method you may iterate
        over the connection object to get rows returned by the query.

        You can use Python formatting here and all values get properly
        quoted:
            conn.execute_query('SELECT * FROM empl WHERE id=%d', 13)
            conn.execute_query('SELECT * FROM empl WHERE id IN %s', ((5,6),))
            conn.execute_query('SELECT * FROM empl WHERE name=%s', 'John Doe')
            conn.execute_query('SELECT * FROM empl WHERE name LIKE %s', 'J%')
            conn.execute_query('SELECT * FROM empl WHERE name=%(name)s AND \
                city=%(city)s', { 'name': 'John Doe', 'city': 'Nowhere' } )
            conn.execute_query('SELECT * FROM cust WHERE salesrep=%s \
                AND id IN (%s)', ('John Doe', (1,2,3)))
            conn.execute_query('SELECT * FROM empl WHERE id IN %s',\
                (tuple(xrange(4)),))
            conn.execute_query('SELECT * FROM empl WHERE id IN %s',\
                (tuple([3,5,7,11]),))

        This method is intended to be used on queries that return results,
        i.e. SELECT. After calling this method AND reading all rows from,
        result rows_affected property contains number of rows returned by
        last command (this is how MS SQL returns it).
        """
        log("_mssql.MSSQLConnection.execute_query() BEGIN")
        self.format_and_run_query(query_string, params)
        self.get_result()
        log("_mssql.MSSQLConnection.execute_query() END")

    cpdef execute_row(self, query_string, params=NoParams):
        """
        execute_row(query_string, params=NoParams)

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
        return self.fetch_next_row(0, ROW_FORMAT_DICT)

    cpdef execute_scalar(self, query_string, params=NoParams):
        """
        execute_scalar(query_string, params=NoParams)

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

        return self.get_row(rtc, ROW_FORMAT_TUPLE)[0]

    cdef fetch_next_row(self, int throw, int row_format):
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

            return self.get_row(rtc, row_format)
        finally:
            log("_mssql.MSSQLConnection.fetch_next_row() END")

    cdef format_and_run_query(self, query_string, params=NoParams):
        """
        This is a helper function, which does most of the work needed by any
        execute_*() function. It returns NULL on error, None on success.
        """
        cdef RETCODE rtc

        # For Python 3, we need to convert unicode to byte strings
        cdef bytes query_string_bytes
        cdef char *query_string_cstr

        log("_mssql.MSSQLConnection.format_and_run_query() BEGIN")

        try:
            # Cancel any pending results
            self.cancel()

            if params is not NoParams:
                query_string = self.format_sql_command(query_string, params)

            # For Python 3, we need to convert unicode to byte strings
            query_string_bytes = ensure_bytes(query_string, self.charset)
            query_string_cstr = query_string_bytes

            log(query_string_cstr)
            if self.debug_queries:
                sys.stderr.write("#%s#\n" % query_string)

            # Prepare the query buffer
            dbcmd(self.dbproc, query_string_cstr)

            # Execute the query
            rtc = db_sqlexec(self.dbproc)

            check_cancel_and_raise(rtc, self)
        finally:
            log("_mssql.MSSQLConnection.format_and_run_query() END")

    cdef format_sql_command(self, format, params=NoParams):
        log("_mssql.MSSQLConnection.format_sql_command()")
        return _substitute_params(format, params, self.use_datetime2, self.charset)

    def executemany(self, query_string, seq_of_parameters, batch_size):
        """
        """
        cdef RETCODE rtc
        cdef bytes query_string_bytes
        cdef char *query_string_cstr

        sentinel = object()
        batches = ( [ entry for entry in _iterable if entry is not sentinel ]
                    for _iterable in
                        zip_longest(*(( iter(seq_of_parameters), ) * batch_size),
                                    fillvalue=sentinel)
                   )
        for params_batch in batches:
            sqls = ( ensure_bytes(self.format_sql_command(query_string, params),
                                  self.charset)
                     for params in params_batch
                    )
            query_string_bytes = b";".join(sqls)
            query_string_cstr = query_string_bytes
            dbcmd(self.dbproc, query_string_cstr)
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

    def get_iterator(self, int row_format):
        """
        get_iterator(row_format) -- allows the format of the iterator to be specified

        While the iter(conn) call will always return a dictionary, this
        method allows the return type of the row to be specified.
        """
        assert_connected(self)
        clr_err(self)
        return MSSQLRowIterator(self, row_format)

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

            snprintf(log_message, sizeof(log_message), "_mssql.MSSQLConnection.get_result(): num_columns = %d", self.num_columns)
            log_message[ sizeof(log_message) - 1 ] = b'\0'
            log(log_message)

            column_names = list()
            column_types = list()

            for col in xrange(1, self.num_columns + 1):
                col_name = dbcolname(self.dbproc, col)
                if not col_name:
                    self.num_columns -= 1
                    return None

                column_name = col_name.decode(self._charset)
                column_names.append(column_name)
                coltype = dbcoltype(self.dbproc, col)
                column_types.append(get_api_coltype(coltype))

            self.column_names = tuple(column_names)
            self.column_types = tuple(column_types)
        finally:
            log("_mssql.MSSQLConnection.get_result() END")

    cdef get_row(self, int row_info, int row_format):
        cdef DBPROCESS *dbproc = self.dbproc
        cdef int col
        cdef int col_type
        cdef int len
        cdef BYTE *data
        cdef tuple trecord
        cdef dict drecord
        log("_mssql.MSSQLConnection.get_row()")

        if (PYMSSQL_DEBUG == 1):
            global _row_count
            _row_count += 1

        if row_format == _ROW_FORMAT_TUPLE:
            trecord = PyTuple_New(self.num_columns)
        elif row_format == _ROW_FORMAT_DICT:
            drecord = dict()

        for col in xrange(1, self.num_columns + 1):
            with nogil:
                data = get_data(dbproc, row_info, col)
                col_type = get_type(dbproc, row_info, col)
                len = get_length(dbproc, row_info, col)

            if data == NULL:
                value = None
            else:
                if (PYMSSQL_DEBUG == 1):
                    global _row_count
                    print('Processing row %d, column %d,' \
                        'Got data=%x, coltype=%d, len=%d\n', _row_count, col,
                        data, col_type, len, file=sys.stderr)
                value = self.convert_db_value(data, col_type, len)

            if row_format == _ROW_FORMAT_TUPLE:
                Py_INCREF(value)
                PyTuple_SetItem(trecord, col - 1, value)
            elif row_format == _ROW_FORMAT_DICT:
                name = self.column_names[col - 1]
                drecord[col - 1] = value
                if name:
                    drecord[name] = value

        if row_format == _ROW_FORMAT_TUPLE:
            return trecord
        elif row_format == _ROW_FORMAT_DICT:
            return drecord

    def init_procedure(self, procname):
        """
        init_procedure(procname) -- creates and returns a MSSQLStoredProcedure
        object.

        This methods initializes a stored procedure or function on the server
        and creates a MSSQLStoredProcedure object that allows parameters to
        be bound.
        """
        log("_mssql.MSSQLConnection.init_procedure()")
        return MSSQLStoredProcedure(procname.encode(self.charset), self)

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

        # For Python 3, we need to convert unicode to byte strings
        cdef bytes dbname_bytes = dbname.encode('utf-8')
        cdef char *dbname_cstr = dbname_bytes

        with nogil:
            dbuse(self.dbproc, dbname_cstr)

    cdef bcp_init(self, object table_name):
        cdef DBPROCESS *dbproc = self.dbproc
        cdef RETCODE rtc
        cdef bytes table_name_bytes
        cdef char *table_name_cstr

        log("_mssql.MSSQLBCPContext.bcp_init()")

        table_name_bytes = ensure_bytes(table_name, self.charset)
        table_name_cstr = table_name_bytes

        with nogil:
            rtc = bcp_init(dbproc, table_name_cstr, NULL, NULL, DB_IN)
        check_cancel_and_raise(rtc, self)

    cdef bcp_hint(self, BYTE * value, int valuelen):
        cdef DBPROCESS *dbproc = self.dbproc
        cdef RETCODE rtc

        log("_mssql.MSSQLBCPContext.bcp_hint()")

        with nogil:
            rtc = bcp_options(dbproc, BCPHINTS, value, valuelen)
        check_cancel_and_raise(rtc, self)

    cdef bcp_bind(self, object value, int is_none, int column_db_type, int position, BYTE **data):
        cdef DBPROCESS *dbproc = self.dbproc
        cdef RETCODE rtc
        cdef int length = -1

        log("_mssql.MSSQLBCPContext.bcp_bind()")

        self.convert_python_value(value, data, &column_db_type, &length)
        if is_none:
            # It doesn't matter which vartype we choose here since we are passing NULL.
            rtc = bcp_bind(
                dbproc,          # dbproc
                NULL,            # varaddr
                0,               # prefixlen
                0,               # varlen
                NULL,            # terminator
                0,               # termlen
                SQLVARCHAR,      # vartype
                position         # table_column
            )
        else:
            rtc = bcp_bind(
                dbproc,          # dbproc
                data[0],         # varaddr
                0,               # prefixlen
                length,          # varlen
                NULL,            # terminator
                0,               # termlen
                column_db_type,  # vartype
                position         # table_column
            )

        check_cancel_and_raise(rtc, self)

    cdef bcp_batch(self):
        cdef DBPROCESS *dbproc = self.dbproc
        cdef int rows_inserted = -1

        log("_mssql.MSSQLBCPContext.bcp_batch()")

        with nogil:
            rows_inserted = bcp_batch(dbproc)
        if rows_inserted == -1:
            raise_MSSQLDatabaseException(self)

    cpdef bcp_sendrow(self, object element, object column_ids):
        cdef DBPROCESS *dbproc = self.dbproc
        cdef RETCODE rtc
        cdef int length = len(element)
        cdef int idx = -1
        cdef BYTE **datas = NULL
        cdef int db_type = -1
        cdef int is_none = -1
        cdef int column_id = -1

        log("_mssql.MSSQLBCPContext.bcp_sendrow()")

        try:
            datas = <BYTE**> PyMem_Malloc(length * sizeof(BYTE *))
            memset(datas, 0, length * sizeof(BYTE *))

            try:
                for idx, col_value in enumerate(element):
                    if column_ids is None:
                        column_id = idx + 1
                    else:
                        try:
                            column_id = column_ids[idx]
                        except IndexError:
                            raise ValueError("Too few column IDs provided")
                    if col_value is None:
                        db_type = 0
                        is_none = 1
                    else:
                        db_type = py2db_type(type(col_value), col_value)
                        is_none = 0
                    self.bcp_bind(col_value, is_none, db_type, column_id, &datas[idx])
                rtc = bcp_sendrow(dbproc)

                check_cancel_and_raise(rtc, self)
            finally:
                for idx in range(0, length):
                    PyMem_Free(datas[idx])
        finally:
            PyMem_Free(datas)

    cdef bcp_done(self):
        cdef DBPROCESS *dbproc = self.dbproc
        cdef int rows_inserted = -1

        log("_mssql.MSSQLBCPContext.bcp_done()")

        with nogil:
            rows_inserted = bcp_done(dbproc)

        if rows_inserted == -1:
            raise_MSSQLDatabaseException(self)


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

        # We firstly want to check if tdsver is >= 7 as anything less
        # doesn't support remote procedure calls.
        cdef int version = dbtds(connection.dbproc)
        if connection.tds_version is None or connection.tds_version < 7:
            raise MSSQLDriverException("Stored Procedures aren't "
                "supported with a TDS version less than 7. Got %r (%r)" % (connection.tds_version, version))

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
        cdef _mssql_parameter_node *n
        cdef _mssql_parameter_node *p
        log("_mssql.MSSQLStoredProcedure.__dealloc__()")

        n = self.params_list
        p = NULL

        while n != NULL:
            PyMem_Free(n.value)
            p = n
            n = n.next
            PyMem_Free(p)

    def bind(self, object value, int dbtype, str param_name=None,
            int output=False, int null=False, int max_length=-1):
        """
        bind(value, data_type, param_name = None, output = False,
            null = False, max_length = -1) -- bind a parameter

        This method binds a parameter to the stored procedure.
        """
        cdef int length = -1
        cdef RETCODE rtc
        cdef BYTE status
        cdef BYTE *data
        cdef bytes param_name_bytes
        cdef char *param_name_cstr
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
            if null or (output and dbtype not in (SQLDECIMAL, SQLNUMERIC)):
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

        if param_name:
            param_name_bytes = param_name.encode('ascii')
            param_name_cstr = param_name_bytes
            if self.had_positional:
                raise MSSQLDriverException('Cannot bind named parameter after positional')
        else:
            param_name_cstr = ''
            self.had_positional = True

        if (PYMSSQL_DEBUG == 1):
            sys.stderr.write(
                "\n--- rpc_bind(name = '%s', status = %d, "
                "max_length = %d, data_type = %d, data_length = %d\n"
                % (param_name, status, max_length, dbtype, length)
            )

        with nogil:
            rtc = dbrpcparam(self.dbproc, param_name_cstr, status, dbtype,
                max_length, length, data)
        check_cancel_and_raise(rtc, self.conn)

        # Store the value in the parameters dictionary for returning
        # later, by name if that has been supplied.
        if param_name:
            self.params[param_name] = value
        self.params[self.param_count] = value
        if output:
            self.output_indexes.append(self.param_count)
        self.param_count += 1

    def execute(self):
        cdef RETCODE rtc
        cdef int output_count, i, type, length
        cdef char *param_name_bytes
        cdef BYTE *data
        log("_mssql.MSSQLStoredProcedure.execute()")

        # Cancel any pending results as this throws a server error
        # otherwise.
        db_cancel(self.conn)

        # Send the RPC request
        with nogil:
            rtc = dbrpcsend(self.dbproc)
        check_cancel_and_raise(rtc, self.conn)

        # Wait for results to come back and return the return code, optionally
        # calling wait_callback first...
        rtc = db_sqlok(self.dbproc)

        check_cancel_and_raise(rtc, self.conn)

        # Need to call this regardless of whether or not there are output
        # parameters in order for the return status to be correct.
        output_count = dbnumrets(self.dbproc)

        # If there are any output parameters then we are going to want to
        # set the values in the parameters dictionary.
        if output_count:
            for i in xrange(1, output_count + 1):
                value = None
                with nogil:
                    type = dbrettype(self.dbproc, i)
                    param_name_bytes = dbretname(self.dbproc, i)
                    length = dbretlen(self.dbproc, i)
                    if length:
                        data = dbretdata(self.dbproc, i)

                if length:
                    value = self.conn.convert_db_value(data, type, length)

                if strlen(param_name_bytes):
                    param_name = param_name_bytes.decode('utf-8')
                    self.params[param_name] = value
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
        return raise_MSSQLDatabaseException(conn)
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

    return raise_MSSQLDatabaseException(conn)

cdef int raise_MSSQLDatabaseException(MSSQLConnection conn) except 1:
    error_msg = get_last_msg_str(conn)
    if len(error_msg) == 0:
        error_msg = b"Unknown error"

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

cdef void assert_connected(MSSQLConnection conn) except *:
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
    cdef char c
    cdef char *stripped = s
    cdef int i, x = 0, last_sep = -1

    for i, c in enumerate(s[0:buflen]):
        if c in (b',', b'.'):
            last_sep = i

    for i, c in enumerate(s[0:buflen]):
        if (c >= b'0' and c <= b'9') or c in (b'+', b'-'):
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

cdef int _tds_ver_str_to_constant(verstr) except -1:
    """
        http://www.freetds.org/userguide/choosingtdsprotocol.html
    """
    if verstr == '4.2':
        return DBVERSION_42
    if verstr == '7.0':
        return DBVERSION_70
    if verstr in ('7.1', '8.0'):
        return DBVERSION_71
    if verstr == '7.2':
        return DBVERSION_72
    if verstr == '7.3':
        return DBVERSION_73
    if verstr == '7.4':
        return DBVERSION_74
    if verstr == '8.0':
        return DBVERSION_71
    raise MSSQLException('unrecognized tds version: %s' % verstr)

#######################
## Quoting Functions ##
#######################
cdef _quote_simple_value(value, use_datetime2=False, charset='utf8'):

    if value == None:
        return b'NULL'

    if isinstance(value, bool):
        return ('1' if value else '0').encode(charset)

    if isinstance(value, float):
        return repr(value).encode(charset)

    if isinstance(value, (int, long, decimal.Decimal)):
        return str(value).encode(charset)

    if isinstance(value, uuid.UUID):
        return (f"N'{value}'").encode(charset)

    if isinstance(value, str):
        return ("N'" + value.replace("'", "''") + "'").encode(charset)

    if isinstance(value, bytearray):
        return b'0x' + binascii.hexlify(bytes(value))

    if isinstance(value, bytes):
        # see if it can be decoded as ascii if there are no null bytes
        if b'\0' not in value:
            try:
                value.decode('ascii')
                return b"'" + value.replace(b"'", b"''") + b"'"
            except UnicodeDecodeError:
                pass

        # Python 3: handle bytes
        # @todo - Marc - hack hack hack
        if isinstance(value, bytes):
            return b'0x' + binascii.hexlify(value)

        # will still be string type if there was a null byte in it or if the
        # decoding failed.  In this case, just send it as hex.
        if isinstance(value, str):
            return '0x' + value.encode('hex')

    if isinstance(value, datetime.datetime):
        t = value.strftime(f'{value.year:04}-%m-%d %H:%M:%S.')
        tz = value.strftime('%Z')[3:]
        if use_datetime2 or tz or isinstance(value, datetime2):
            t += value.strftime('%f')
        else:
            t += f'{(value.microsecond // 1000):03d}'
        t = f"'{t}{tz}'"
        return t.encode(charset)

    if isinstance(value, datetime.date):
        return value.strftime(f"'{value.year:04}-%m-%d'").encode(charset)

    if isinstance(value, datetime.time):
        return value.strftime("'%H:%M:%S.%f'").encode(charset)

    raise ValueError(f"Unsupported parameter type: {type(value)}")

cdef _quote_data(data, use_datetime2=False, charset='utf8'):
    """
        This function is supposed to take a simple value, tuple or dictionary,
        passed in via the params argument in the execute_* methods.
        It then quotes and flattens the arguments and returns them.
    """
    if isinstance(data, dict):
        result = {}
        for k, v in data.items():
            if isinstance(v, (list, tuple)):
                result[k] = b'(' + b','.join([ _quote_simple_value(_v, use_datetime2, charset) for _v in v ]) + b')'
            else:
                result[k] = _quote_simple_value(v, use_datetime2, charset)
        return result

    if isinstance(data, (list, tuple)):
        result = []
        for v in data:
            if isinstance(v, (list, tuple)):
                _v = b'(' + b','.join([ _quote_simple_value(_v, use_datetime2, charset) for _v in v ]) + b')'
            else:
                _v = _quote_simple_value(v, use_datetime2, charset)
            result.append(_v)
        return tuple(result)

    return ( _quote_simple_value(data, use_datetime2, charset), )

_re_pos_param = re.compile(br'(%([sd]))')
_re_name_param = re.compile(br'(%\(([^\)]+)\)(?:[sd]))')

cdef _substitute_params(toformat, params=NoParams, use_datetime2=False, charset='utf-8'):

    if isinstance(toformat, str):
        toformat = toformat.encode(charset)
    elif not isinstance(toformat, bytes):
        raise exceptions.ProgrammingError(f"Query should be string or bytes, got {type(toformat)}")

    if params is NoParams:
        return toformat

    quoted = _quote_data(params, use_datetime2, charset)

    if isinstance(params, dict):
        """ assume name based substitutions """
        offset = 0
        for match in _re_name_param.finditer(toformat):
            param_key = match.group(2).decode(charset)

            if not param_key in params:
                raise ValueError('params dictionary did not contain value for placeholder: %s' % param_key)

            # calculate string positions so we can keep track of the offset to
            # be used in future substitutions on this string. This is
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
            toformat = toformat[:match_start] + ensure_bytes(param_val, charset) + toformat[match_end:]

            # adjust the offset for the next usage
            offset += offset_adjust
    else:
        """ assume position based substitutions """
        offset = 0
        for count, match in enumerate(_re_pos_param.finditer(toformat)):
            # calculate string positions so we can keep track of the offset to
            # be used in future substitutions on this string. This is
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
            toformat = toformat[:match_start] + ensure_bytes(param_val, charset) + toformat[match_end:]
            #print(param_val, param_val_len, offset_adjust, match_start, match_end)
            # adjust the offset for the next usage
            offset += offset_adjust

    return toformat

# We'll add these methods to the module to allow for unit testing of the
# underlying C methods.
def quote_simple_value(value, use_datetime2=False, charset='utf-8'):
    return _quote_simple_value(value, use_datetime2, charset)

def quote_data(data, use_datetime2=False, charset='utf-8'):
    return _quote_data(data, use_datetime2, charset)

def substitute_params(toformat, params=NoParams, use_datetime2=False, charset='utf-8'):
    return _substitute_params(toformat, params, use_datetime2, charset)

###########################
## Compatibility Aliases ##
###########################
def connect(*args, **kwargs):
    return MSSQLConnection(*args, **kwargs)

MssqlDatabaseException = MSSQLDatabaseException
MssqlDriverException = MSSQLDriverException
MssqlConnection = MSSQLConnection

###########################
## Test Helper Functions ##
###########################

def test_err_handler(connection, int severity, int dberr, int oserr, dberrstr, oserrstr):
    """
    Expose err_handler function and its side effects to facilitate testing.
    """
    cdef DBPROCESS *dbproc = NULL
    cdef char *dberrstrc = NULL
    cdef char *oserrstrc = NULL
    if dberrstr:
        dberrstr_byte_string = dberrstr.encode('UTF-8')
        dberrstrc = dberrstr_byte_string
    if oserrstr:
        oserrstr_byte_string = oserrstr.encode('UTF-8')
        oserrstrc = oserrstr_byte_string
    if connection:
        dbproc = (<MSSQLConnection>connection).dbproc
    results = (
        err_handler(dbproc, severity, dberr, oserr, dberrstrc, oserrstrc),
        get_last_msg_str(connection),
        get_last_msg_no(connection),
        get_last_msg_severity(connection),
        get_last_msg_state(connection)
    )
    clr_err(connection)
    return results


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

def get_dbversion():
    """
    Return string representing the version of db-lib.
    """
    return dbversion().decode('ascii')

cdef void init_mssql():
    if dbinit() == FAIL:
        raise MSSQLDriverException("dbinit() failed")

    dberrhandle(err_handler)
    dbmsghandle(msg_handler)

init_mssql()
