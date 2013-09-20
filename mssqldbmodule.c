/*
 * _mssql module - low level Python module for communicating with MS SQL servers
 *
 * Initial Developer:
 *      Joon-cheol Park <jooncheol@gmail.com>, http://www.exman.pe.kr
 *
 * Active Developer:
 *      Andrzej Kukula <akukula@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA  02110-1301  USA
 ****************************************************************************
 * CREDITS:
 * List ref count patch 2004.04.09 by Hans Roh <hans@lufex.com>
 * Significant contributions by Mark Pettit (thanks)
 * Multithreading patch by John-Peter Lee (thanks)
 ***************************************************************************/

#include <Python.h>
#include <structmember.h>
#include <datetime.h>

// Py_ssize_t is defined starting from Python 2.5
#if PY_VERSION_HEX < 0x02050000 && !defined(PY_SSIZE_T_MIN)
typedef int Py_ssize_t;
#endif

// lame assumption, but for now I have no better idea
#ifndef MS_WINDOWS
#define HAVE_FREETDS
#endif

#ifdef MS_WINDOWS
#define DBNTWIN32      // must identify operating system environment
#define NOCRYPT        // must be defined under Visual C++
#include <windows.h>
#include <lmerr.h>
#include <sqlfront.h>
#include <sqldb.h>     // DB-LIB header file (should always be included)

#ifndef SQLINT8
#define SQLINT8 127    // from freetds/include/sybdb.h
#endif

#else
#define MSDBLIB        // we need FreeTDS to provide MSSQL API,
                       // not Sybase API. See README.freetds for details
#include <sqlfront.h>
#include <sqldb.h>

#define SQLNUMERIC     SYBNUMERIC
#define SQLDECIMAL     SYBDECIMAL
#define SQLBIT         SYBBIT
#define SQLINT1        SYBINT1
#define SQLINT2        SYBINT2
#define SQLINT4        SYBINT4
#define SQLINT8        SYBINT8
#define SQLINTN        SYBINTN
#define SQLFLT4        SYBREAL
#define SQLFLT8        SYBFLT8
#define SQLFLTN        SYBFLTN
#define SQLDATETIME    SYBDATETIME
#define SQLDATETIM4    SYBDATETIME4
#define SQLDATETIMN    SYBDATETIMN
#define SQLMONEY       SYBMONEY
#define SQLMONEY4      SYBMONEY4
#define SQLMONEYN      SYBMONEYN
#define SQLBINARY      SYBBINARY
#define SQLVARBINARY   SYBVARBINARY
#define SQLIMAGE       SYBIMAGE
#define SQLVARCHAR     SYBVARCHAR
#define SQLCHAR        SYBCHAR
#define SQLTEXT        SYBTEXT

#define BYTE           unsigned char
typedef unsigned char *LPBYTE;
#endif

#define TYPE_STRING      1
#define TYPE_BINARY      2
#define TYPE_NUMBER      3
#define TYPE_DATETIME    4
#define TYPE_DECIMAL     5

//#define PYMSSQLDEBUG   1

#include <stdio.h>
#include <string.h>        // include for string functions

#define MSSQL_LASTMSGNO(self)       \
	((self != NULL) ? self->last_msg_no : _mssql_last_msg_no)
#define MSSQL_LASTMSGSEVERITY(self) \
	((self != NULL) ? self->last_msg_severity : _mssql_last_msg_severity)
#define MSSQL_LASTMSGSTATE(self)    \
	((self != NULL) ? self->last_msg_state : _mssql_last_msg_state)
#define MSSQL_LASTMSGSTR(self)      \
	((self != NULL) ? self->last_msg_str : _mssql_last_msg_str)

#ifdef MS_WINDOWS
#define DBFREELOGIN(login) dbfreelogin(login)
#else
#define DBFREELOGIN(login) dbloginfree(login)
#define DBFLT4 DBREAL
#endif

#define check_and_raise(rtc,obj)                                \
	{                                                           \
		if (rtc == FAIL) {                                      \
			if (maybe_raise_MssqlDatabaseException(obj))        \
				return NULL;                                    \
		} else if (*MSSQL_LASTMSGSTR(obj)) {                    \
			if (maybe_raise_MssqlDatabaseException(obj))        \
				return NULL;                                    \
		}                                                       \
	}

#define check_cancel_and_raise(rtc,obj)                         \
	{                                                           \
		if (rtc == FAIL) {                                      \
			db_cancel(obj);                                     \
			if (maybe_raise_MssqlDatabaseException(obj))        \
				return NULL;                                    \
		} else if (*MSSQL_LASTMSGSTR(obj)) {                    \
			if (maybe_raise_MssqlDatabaseException(obj))        \
				return NULL;                                    \
		}                                                       \
	}

#define raise_MssqlDriverException(message)                     \
	{                                                           \
		PyErr_SetString(_mssql_MssqlDriverException, message);  \
		return NULL;                                            \
    }

#define assert_connected(obj)                                   \
	{                                                           \
		if (!obj->connected)                                    \
			raise_MssqlDriverException("Not connected to any MS SQL server"); \
	}

#define clr_metadata(conn)                                      \
	{                                                           \
		Py_XDECREF(conn->column_names);                         \
		Py_XDECREF(conn->column_types);                         \
		conn->column_names = conn->column_types = NULL;         \
		conn->num_columns = 0;                                  \
		conn->last_dbresults = 0;                               \
	}

static PyObject *_mssql_module;
static PyObject *_mssql_MssqlException;
static PyObject *_mssql_MssqlDatabaseException;
static PyObject *_mssql_MssqlDriverException;
static PyObject *_decimal_module;              // "decimal" module handle
static PyObject *_decimal_class;
static PyObject *_decimal_context;

// Connection object
typedef struct {
	PyObject_HEAD
	DBPROCESS *dbproc;             // PDBPROCESS dbproc;
	int        connected;          // readonly property
	int        query_timeout;      // dbgettime() is absent in old FreeTDS...
	int        rows_affected;      // readonly property
	char      *charset;            // read/write property
	char      *last_msg_str;       // the error message buffer
	int        last_msg_no;        // most recent message code value
	int        last_msg_severity;  // most recent message severity value
	int        last_msg_state;     // most recent message state value
	int        last_dbresults;     // value of most recent call to dbresult()
	int        num_columns;        // number of columns in current result
	PyObject  *column_names;       // column names in a tuple
	PyObject  *column_types;       // column DB-API data types in a tuple
	int        debug_queries;      // whether to debug queries
} _mssql_connection;

// row iterator object
typedef struct {
	PyObject_HEAD
	_mssql_connection *conn;       // we just need to know what conn we iterate over
} _mssql_row_iterator;

// prototypes
PyObject *_mssql_format_sql_command(PyObject * /*unused*/ self, PyObject *args);
PyObject *_mssql_get_header(_mssql_connection *self);
int rmv_lcl(char *, char *, size_t);
PyObject *format_and_run_query(_mssql_connection *self, PyObject *args);
PyObject *get_result(_mssql_connection *conn);
PyObject *get_row(_mssql_connection *conn, int rowinfo);
PyObject *fetch_next_row_dict(_mssql_connection *conn, int raise);
void clr_err(_mssql_connection *self);
int maybe_raise_MssqlDatabaseException(_mssql_connection *);
RETCODE db_cancel(_mssql_connection *conn);

static PyTypeObject _mssql_connection_type;
static PyTypeObject _mssql_row_iterator_type;

#define PYMSSQL_CHARSETBUFSIZE 100
#define MSSQLDB_MSGSIZE 1024
#define PYMSSQL_MSGSIZE (MSSQLDB_MSGSIZE*8)
static char _mssql_last_msg_str[PYMSSQL_MSGSIZE] = { 0, };

static int _mssql_last_msg_no = 0;
/* we'll be calculating max message severity returned by multiple calls
   to the handlers in a row, and if that severity is higher than
   minimum required, we'll raise exception. */
static int _mssql_last_msg_severity = 0;
static int _mssql_last_msg_state = 0;

/* there's only one error handler per dbinit() call, that is one for whole
   _mssql module; to be able to route error messages to appropriate connection
   instance, we must maintain a list of allocated connection objects */
struct _mssql_connection_list_node {
	struct _mssql_connection_list_node *next;
	_mssql_connection *obj;
};

static struct _mssql_connection_list_node *connection_object_list = NULL;

/* _mssql.Connection class methods *******************************************/

static char _mssql_select_db_doc[] =
"select_db(dbname) -- Select the current database.\n\n\
This function selects given database as the current one.\n\
An exception is raised on failure.";

// select_db
static PyObject *_mssql_select_db(_mssql_connection *self, PyObject *args) {
	RETCODE rtc;
	char *dbname;
	char command[255];
	PyObject *value, *search, *replace, *replaced = NULL;

	if (PyErr_Occurred())  return NULL;
	assert_connected(self);
	clr_err(self);

	if ((dbname = PyString_AsString(args)) == NULL)  return NULL;

	/* this workaround is for db name truncation by ntwdblib.dll's
	   version of dbuse(), thanks Luke Benstead <luke@riverhall.co.uk> */

	/* if name starts in '[' and ends in ']' then we pass it as is;
	   otherwise we replace all occurrences of ']' with ']]' then add
	   '[' at the beginning and ']' at the end. */

	if ((dbname[0] == '[') && dbname[strlen(dbname)-1] == ']')
		snprintf(command, 255, "USE %s", dbname);
	else {
		value = PyString_FromString(dbname);
		search = PyString_FromString("]");
		replace = PyString_FromString("]]");
		replaced = PyObject_CallMethod(value, "replace", "OO", search, replace);
		dbname = PyString_AsString(replaced);
		Py_DECREF(value); Py_DECREF(search); Py_DECREF(replace);
		snprintf(command, 255, "USE [%s]", dbname);
		Py_DECREF(replaced);
	}

	Py_BEGIN_ALLOW_THREADS
	rtc = dbcmd(self->dbproc, command);
	check_cancel_and_raise(rtc, self);
	Py_END_ALLOW_THREADS

	rtc = dbsqlexec(self->dbproc);
	check_and_raise(rtc, self);
	rtc = db_cancel(self);
	check_and_raise(rtc, self);

	Py_RETURN_NONE;
}

static char _mssql_execute_query_doc[] =
"execute_query(query_string, params=None)\n\n\
This method sends a query to the MS SQL Server to which this object\n\
instance is connected. An exception is raised on failure. If there\n\
are pending results or rows prior to executing this command, they\n\
are silently discarded. After calling this method you may iterate\n\
over the connection object to get rows returned by the query.\n\n\
You can use Python formatting here and all values get properly\n\
quoted:\n\
  conn.execute_query('SELECT * FROM empl WHERE id=%d', 13)\n\
  conn.execute_query('SELECT * FROM empl WHERE id IN (%s)', ((5,6),))\n\
  conn.execute_query('SELECT * FROM empl WHERE name=%s', 'John Doe')\n\
  conn.execute_query('SELECT * FROM empl WHERE name LIKE %s', 'J%')\n\
  conn.execute_query('SELECT * FROM empl WHERE name=%(name)s AND \\\n\
    city=%(city)s', { 'name': 'John Doe', 'city': 'Nowhere' } )\n\
  conn.execute_query('SELECT * FROM cust WHERE salesrep=%s \\\n\
    AND id IN (%s)', ('John Doe', (1,2,3)))\n\
  conn.execute_query('SELECT * FROM empl WHERE id IN (%s)',\\\n\
    (tuple(xrange(4)),))\n\
  conn.execute_query('SELECT * FROM empl WHERE id IN (%s)',\\\n\
    (tuple([3,5,7,11]),))\n\n\
This method is intented to be used on queries that return results,\n\
i.e. SELECT. After calling this method AND reading all rows from,\n\
result rows_affected property contains number of rows returned by\n\
last command (this is how MS SQL returns it).";

static PyObject *_mssql_execute_query(_mssql_connection *self, PyObject *args) {
	if (format_and_run_query(self, args) == NULL)  return NULL;

	// we must call dbresults() for nextresult() to work correctly
	if (get_result(self) == NULL)  return NULL;
	Py_RETURN_NONE;
}

static char _mssql_execute_non_query_doc[] =
"execute_non_query(query_string, params=None)\n\n\
This method sends a query to the MS SQL Server to which this object\n\
instance is connected. After completion, its results (if any) are\n\
discarded. An exception is raised on failure. If there are pending\n\
results or rows prior to executing this command, they are silently\n\n\
discarded. This method accepts Python formatting. Please see\n\
execute_query() for more details.\n\n\
This method is useful for INSERT, UPDATE, DELETE, and for Data\n\
Definition Language commands, i.e. when you need to alter your\n\
database schema.\n\n\
After calling this method, rows_affected property contains number\n\
of rows affected by last SQL command.";

static PyObject *_mssql_execute_non_query(_mssql_connection *self, PyObject *args) {
	RETCODE rtc;
	if (format_and_run_query(self, args) == NULL)  return NULL;

	Py_BEGIN_ALLOW_THREADS
	dbresults(self->dbproc);  // only to get number of affected rows
	self->rows_affected = dbcount(self->dbproc);
	Py_END_ALLOW_THREADS

	rtc = db_cancel(self);
	check_and_raise(rtc, self);

	Py_RETURN_NONE;
}

static char _mssql_execute_scalar_doc[] =
"execute_scalar(query_string, params=None)\n\n\
This method sends a query to the MS SQL Server to which this object\n\
instance is connected, then returns first column of first row from\n\
result. An exception is raised on failure. If there are pending\n\n\
results or rows prior to executing this command, they are silently\n\
discarded.\n\n\
This method accepts Python formatting. Please see execute_query()\n\
for details.\n\n\
This method is useful if you want just a single value, as in:\n\
  conn.execute_scalar('SELECT COUNT(*) FROM employees')\n\n\
This method works in the same way as 'iter(conn).next()[0]'.\n\
Remaining rows, if any, can still be iterated after calling this\n\
method.";

static PyObject *_mssql_execute_scalar(_mssql_connection *self, PyObject *args) {
	RETCODE rtc;
	PyObject *row, *val;

	if (format_and_run_query(self, args) == NULL)  return NULL;

	if (get_result(self) == NULL)  return NULL;

	Py_BEGIN_ALLOW_THREADS
	rtc = dbnextrow(self->dbproc);
	Py_END_ALLOW_THREADS

	check_cancel_and_raise(rtc, self);

	self->rows_affected = dbcount(self->dbproc); // get rows affected, if possible

	// check if any rows (in case user passed e.g. DDL command here)
	if (rtc == NO_MORE_ROWS) {
		clr_metadata(self);
		self->last_dbresults = 0;  // force next results, if any
		Py_RETURN_NONE;
	}

	row = get_row(self, rtc); // get first row of data
	if (row == NULL)  return NULL;

	val = PyTuple_GetItem(row, 0);
	if (val == NULL)  return NULL;
	Py_INCREF(val);

	// we don't call db_cancel, user can iterate
	// over remaining rows

	Py_DECREF(row);  // row data no longer needed
	return val;
}

static char _mssql_execute_row_doc[] =
"execute_row(query_string, params=None)\n\n\
This method sends a query to the MS SQL Server to which this object\n\
instance is connected, then returns first row of data from result.\n\n\
An exception is raised on failure. If there are pending results or\n\
rows prior to executing this command, they are silently discarded.\n\n\
This method accepts Python formatting. Please see execute_query()\n\
for details.\n\n\
This method is useful if you want just a single row and don't want\n\
or don't need to iterate, as in:\n\n\
  conn.execute_row('SELECT * FROM employees WHERE id=%d', 13)\n\n\
This method works exactly the same as 'iter(conn).next()'. Remaining\n\
rows, if any, can still be iterated after calling this method.";

static PyObject *_mssql_execute_row(_mssql_connection *self, PyObject *args) {
	if (format_and_run_query(self, args) == NULL)  return NULL;
    return fetch_next_row_dict(self, 0);
}

/* datetime quoting (thanks Jan Finell <jfinell@regionline.fi>)
   described under "Writing International Transact-SQL Statements" in BOL
   beware the order: isinstance(x,datetime.date)=True even if x is
   datetime.datetime ! Also round x.microsecond to milliseconds,
   otherwise we get Msg 241, Level 16, State 1: Syntax error */

/* this is internal method, called for each element of a sequence.
   if it cannot be quoted, None is returned */

PyObject *_quote_simple_value(PyObject *value) {
	if (value == Py_None)
		return PyString_FromString("NULL");

	if (PyBool_Check(value)) {
		// if bool then safe to return as is
		Py_INCREF(value);
		return value;
	}

	if (PyInt_Check(value) || PyLong_Check(value) || PyFloat_Check(value)) {
		// return as is
		Py_INCREF(value);
		return value;
	}

	if (PyUnicode_Check(value)) {
		// equivalent of
		// x = "N'" + value.encode('utf8').replace("'", "''") + "'"
		PyObject *search, *replace, *encoded, *replaced, *quoted;

		search = PyString_FromString("'");
		replace = PyString_FromString("''");
		encoded = PyUnicode_AsUTF8String(value);
		replaced = PyObject_CallMethod(encoded, "replace", "OO", search, replace);
		Py_DECREF(search); Py_DECREF(replace); Py_DECREF(encoded);
		quoted = PyString_FromString("N'");
		PyString_ConcatAndDel(&quoted, replaced); // replaced is DECREFed
		if (quoted == NULL)  return NULL;
		PyString_ConcatAndDel(&quoted, PyString_FromString("'"));
		if (quoted == NULL)  return NULL;

		return quoted;
	}

	if (PyString_Check(value)) {
		// x = "'" + x.replace("'", "''") + "'"
		PyObject *search, *replace, *replaced, *quoted;

		search = PyString_FromString("'");
		replace = PyString_FromString("''");
		replaced = PyObject_CallMethod(value, "replace", "OO", search, replace);
		Py_DECREF(search); Py_DECREF(replace);
		quoted = PyString_FromString("'");
		PyString_ConcatAndDel(&quoted, replaced); // replaced is DECREFed
		if (quoted == NULL)  return NULL;
		PyString_ConcatAndDel(&quoted, PyString_FromString("'"));
		if (quoted == NULL)  return NULL;

		return quoted;
	}

	if (PyDateTime_CheckExact(value)) {
		PyObject *quoted, *val, *format, *tuple;

		// prepare arguments for format
		tuple = PyTuple_New(7);
		if (tuple == NULL)  return NULL;

		PyTuple_SET_ITEM(tuple, 0, PyObject_GetAttrString(value, "year"));
		PyTuple_SET_ITEM(tuple, 1, PyObject_GetAttrString(value, "month"));
		PyTuple_SET_ITEM(tuple, 2, PyObject_GetAttrString(value, "day"));
		PyTuple_SET_ITEM(tuple, 3, PyObject_GetAttrString(value, "hour"));
		PyTuple_SET_ITEM(tuple, 4, PyObject_GetAttrString(value, "minute"));
		PyTuple_SET_ITEM(tuple, 5, PyObject_GetAttrString(value, "second"));

		val = PyObject_GetAttrString(value, "microsecond");
		PyTuple_SET_ITEM(tuple, 6, PyLong_FromLong(PyLong_AsLong(val) / 1000));
		Py_DECREF(val);

		format = PyString_FromString("{ts '%04d-%02d-%02d %02d:%02d:%02d.%d'}");
		quoted = PyString_Format(format, tuple);
		Py_DECREF(format); Py_DECREF(tuple);

		return quoted;
	}

	if (PyDate_CheckExact(value)) {
		PyObject *quoted, *format, *tuple;

		// prepare arguments for format
		tuple = PyTuple_New(3);
		if (tuple == NULL)  return NULL;

		PyTuple_SET_ITEM(tuple, 0, PyObject_GetAttrString(value, "year"));
		PyTuple_SET_ITEM(tuple, 1, PyObject_GetAttrString(value, "month"));
		PyTuple_SET_ITEM(tuple, 2, PyObject_GetAttrString(value, "day"));

		format = PyString_FromString("{d '%04d-%02d-%02d'}");
		quoted = PyString_Format(format, tuple);
		Py_DECREF(format); Py_DECREF(tuple);

		return quoted;
	}

	// return None so caller knows we're succeeded, but not quoted anything,
	// so it can try sequence types
	Py_RETURN_NONE;
}

/* this function quotes its argument if it's a simple data type,
   or flattens it if it's a list or a tuple. returns new reference
   to quoted string */

PyObject *_quote_or_flatten(PyObject *data) {
	PyObject *res = _quote_simple_value(data);
	if (res == NULL)  return NULL;
	if (res != Py_None) {
		// we got something, return it
		return res;
	}

	// we got Py_None from _quote_simple_value, so it wasn't simple type
	// we only accept a list or a tuple below this point
	Py_DECREF(res);

	if (PyList_Check(data)) {
		PyObject *str;
		int i;
		Py_ssize_t len = PyList_GET_SIZE(data);

		str = PyString_FromString("");  // an empty string
		if (str == NULL)  return NULL;

		for (i = 0; i < len; i++) {
			PyObject *o, *quoted, *quotedstr;
			o = PyList_GET_ITEM(data, i);          // borrowed
			quoted = _quote_simple_value(o);       // new ref
			if (quoted == NULL) {
				Py_DECREF(str);
				return NULL;
			}

			if (quoted == Py_None) {
				Py_DECREF(Py_None);
				Py_DECREF(str);
				PyErr_SetString(PyExc_ValueError, "argument error, expected simple value, found nested sequence.");
				return NULL;
			}

			quotedstr = PyObject_Str(quoted);
			Py_DECREF(quoted);

			if (quotedstr == NULL) {
				Py_DECREF(str);
				return NULL;
			}

			PyString_ConcatAndDel(&str, quotedstr);
			if (str == NULL)  return NULL;

			if (i < len-1) {
				PyString_ConcatAndDel(&str, PyString_FromString(","));
				if (str == NULL)  return NULL;
			}
		}

		return str;
	}

	if (PyTuple_Check(data)) {
		PyObject *str;
		int i;
		Py_ssize_t len = PyTuple_GET_SIZE(data);

		str = PyString_FromString("");  // an empty string
		if (str == NULL)  return NULL;

		for (i = 0; i < len; i++) {
			PyObject *o, *quoted, *quotedstr;
			o = PyTuple_GET_ITEM(data, i);         // borrowed
			quoted = _quote_simple_value(o);       // new ref
			if (quoted == NULL) {
				Py_DECREF(str);
				return NULL;
			}

			if (quoted == Py_None) {
				Py_DECREF(Py_None);
				Py_DECREF(str);
				PyErr_SetString(PyExc_ValueError, "argument error, expected simple value, found nested sequence.");
				return NULL;
			}

			quotedstr = PyObject_Str(quoted);
			Py_DECREF(quoted);

			if (quotedstr == NULL) {
				Py_DECREF(str);
				return NULL;
			}

			PyString_ConcatAndDel(&str, quotedstr);
			if (str == NULL)  return NULL;

			if (i < len-1) {
				PyString_ConcatAndDel(&str, PyString_FromString(","));
				if (str == NULL)  return NULL;
			}
		}

		return str;
	}

	PyErr_SetString(PyExc_ValueError, "expected simple type, a tuple or a list.");
	return NULL;
}

static char _mssql_quote_data_doc[] =
"_quote_data(data) -- quote value so it is safe for query string.\n\n\
This method transforms given data into form suitable for putting in\n\
a query string and returns transformed data. This feature may\n\
not be very useful by itself, so examples below will be from other\n\
method, _format_sql_command.\n\n\
Argument may be one of the simple types: string, unicode, bool,\n\
int, long, float, None, or it can be a tuple, or a dictionary.\n\
If it's a tuple or a dict, it's elements can only be of the same\n\
simple types, or tuple, or list. If such an element is encountered\n\
it is 'flattened' by producing a comma separated string of its items.\n\
This is useful for IN operators. Examples:\n\
    _mssql._format_sql_command('SELECT * FROM cust WHERE id=%d', 13)\n\
\n\
    _mssql._format_sql_command('SELECT * FROM cust WHERE id IN (%s)',\n\
        ((1,2,3,4,5),))\n\
you can see here a tuple with another tuple as the only element.\n\
If you need to pass a list, an xrange, a generator or an iterator,\n\
just use tuple() constructor:\n\
    _mssql._format_sql_command('SELECT * FROM cust WHERE id IN (%s)',\n\
        (tuple(xrange(4)),)\n";

PyObject *_mssql_quote_data(PyObject * /*unused*/ self, PyObject *data) {
	PyObject *res;

	res = _quote_simple_value(data);
	if (res == NULL)  return NULL;
	if (res != Py_None) {
		// we got something, return it
		return res;
	}

	// we got Py_None from _quote_simple_value, it may be a sequence type
	Py_DECREF(res);

	// first check if dict, and if so, quote values
	if (PyDict_Check(data)) {
		PyObject *dict, *k, *v;
		Py_ssize_t pos = 0;
		dict = PyDict_New();                       // new dictionary for results
		if (dict == NULL)  return NULL;

		while (PyDict_Next(data, &pos, &k, &v)) {
			PyObject *quoted = _quote_or_flatten(v); // new ref

			if (quoted == NULL) {
				Py_DECREF(dict);
				return NULL;
			}

			PyDict_SetItem(dict, k, quoted);       // dict[k] = _quote_single_value(v)
			Py_DECREF(quoted);
		}

		return dict;
	}

	if (PyTuple_Check(data)) {                     // input is a tuple
		PyObject *res;
		int i;
		Py_ssize_t len = PyTuple_GET_SIZE(data);

		res = PyTuple_New(len);
		if (res == NULL)  return NULL;

		for (i = 0; i < len; i++) {
			PyObject *o, *quoted;
			o = PyTuple_GET_ITEM(data, i);         // borrowed
			quoted = _quote_or_flatten(o);         // new ref

			if (quoted == NULL) {
				Py_DECREF(res);
				return NULL;
			}

			PyTuple_SET_ITEM(res, i, quoted);      // ref stolen
		}

		return res;
	}

	PyErr_SetString(PyExc_ValueError, "expected simple type, a tuple or a dictionary.");
	return NULL;
}

static char _mssql_format_sql_command_doc[] =
"_format_sql_command(format_str, params) -- build an SQL command.\n\n\
This method outputs a string with all '%' placeholders replaced\n\
with given value(s). Mechanism is similar to built-in Python\n\
string interpolation, but the values get quoted before interpolation.\n\
Quoting means transforming data into form suitable for puttin\n\
in a query string.\n\nExamples:\n\
    _mssql._format_sql_command(\n\
        'UPDATE customers SET salesrep=%s WHERE id IN (%s)',\n\
        ('John Doe', (1,2,3)))\n\
Please see docs for _quote_data() for details.";

PyObject *_mssql_format_sql_command(PyObject * /*unused*/ self, PyObject *args) {
	PyObject *format = NULL, *params = NULL, *quoted, *ret;

	if (!PyArg_ParseTuple(args, "O|O:_format_sql_command", &format, &params))
		return NULL;

	if (params == NULL) {   // no params given, all we can do is return the string
		Py_INCREF(format);
		return format;
	}

	// check if quotable type; WARNING: update below
	// whenever quote_simple_value() function changes

	if (!((params == Py_None)
	    || PyBool_Check(params)
	    || PyInt_Check(params) || PyLong_Check(params) || PyFloat_Check(params)
	    || PyUnicode_Check(params)
	    || PyString_Check(params)
	    || PyDateTime_CheckExact(params)
	    || PyDate_CheckExact(params)
	    || PyTuple_Check(params) || PyDict_Check(params))) {
			PyErr_SetString(PyExc_ValueError, "'params' arg can be only a tuple or a dictionary.");
			return NULL;
		}

	// we got acceptable params, quote them
	quoted = _mssql_quote_data(self, params);
	if (quoted == NULL)  return NULL;
	ret = PyString_Format(format, quoted);
	Py_DECREF(quoted);
	return ret;
}

static char _mssql_get_header_doc[] =
"get_header() -- get the Python DB-API compliant header information.\n\n\
This method is infrastructure and don't need to be called by your\n\
code. It returns a list of 7-element tuples describing current\n\
result header. Only name and DB-API compliant type is filled, rest\n\
of the data is None, as permitted by the specs.";

PyObject *_mssql_get_header(_mssql_connection *self) {
	int col;
	PyObject *colname, *coltype, *headertuple;

	if (get_result(self) == NULL)  return NULL;

	if (self->num_columns == 0)  // either not returned any rows or no more results
		Py_RETURN_NONE;

	headertuple = PyTuple_New(self->num_columns);
	if (headertuple == NULL)
		raise_MssqlDriverException("Could not create tuple for column header.");

	for (col = 1; col <= self->num_columns; col++) {     // loop on all columns
		PyObject *colinfotuple = NULL;
		colinfotuple = PyTuple_New(7);
		if (colinfotuple == NULL)
			raise_MssqlDriverException("Could not create tuple for column header details.");

		colname = PyTuple_GetItem(self->column_names, col-1);
		coltype = PyTuple_GetItem(self->column_types, col-1);
		Py_INCREF(colname);
		Py_INCREF(coltype);

		PyTuple_SET_ITEM(colinfotuple, 0, colname);
		PyTuple_SET_ITEM(colinfotuple, 1, coltype);
		Py_INCREF(Py_None); PyTuple_SET_ITEM(colinfotuple, 2, Py_None);
		Py_INCREF(Py_None); PyTuple_SET_ITEM(colinfotuple, 3, Py_None);
		Py_INCREF(Py_None); PyTuple_SET_ITEM(colinfotuple, 4, Py_None);
		Py_INCREF(Py_None); PyTuple_SET_ITEM(colinfotuple, 5, Py_None);
		Py_INCREF(Py_None); PyTuple_SET_ITEM(colinfotuple, 6, Py_None);

		PyTuple_SET_ITEM(headertuple, col-1, colinfotuple);
	}

	return headertuple;
}

static char _mssql_cancel_doc[] =
"cancel() -- cancel all pending results.\n\n\
This function cancels all pending results from last SQL operation.\n\
It can be called more than one time in a row. No exception is\n\
raised in this case.";

static PyObject *_mssql_cancel(_mssql_connection *self, PyObject *args) {
	RETCODE rtc;

	if (PyErr_Occurred())  return NULL;
	assert_connected(self);
	clr_err(self);

	rtc = db_cancel(self);
	check_and_raise(rtc, self);

	Py_RETURN_NONE;
}

static char _mssql_nextresult_doc[] =
"nextresult() -- move to the next result, skipping all pending rows.\n\n\
This method fetches and discards any rows remaining from current\n\
result, then it advances to next (if any). Returns True value if\n\
next result is available, None otherwise.";

static PyObject *_mssql_nextresult(_mssql_connection *self, PyObject *args) {
	RETCODE rtc;

	if (PyErr_Occurred())  return NULL;
	assert_connected(self);
	clr_err(self);

	Py_BEGIN_ALLOW_THREADS
	rtc = dbnextrow(self->dbproc);
	Py_END_ALLOW_THREADS

	check_cancel_and_raise(rtc, self);

	while (rtc != NO_MORE_ROWS) {
		Py_BEGIN_ALLOW_THREADS
		rtc = dbnextrow(self->dbproc);
		Py_END_ALLOW_THREADS

		check_cancel_and_raise(rtc, self);
	}

	self->last_dbresults = 0;  // force call to dbresults() inside get_result()

	if (get_result(self) == NULL)  return NULL;

	if (self->last_dbresults != NO_MORE_RESULTS)
		return PyInt_FromLong(1);

	Py_RETURN_NONE;
}

static char _mssql_close_doc[] =
"close() -- close connection to an MS SQL Server.\n\n\
This function tries to close the connection and free all memory\n\
used. It can be called more than one time in a row. No exception\n\
is raised in this case.";

static PyObject *_mssql_close(_mssql_connection *self, PyObject *args) {
#ifdef MS_WINDOWS
	RETCODE rtc;
#endif
	struct _mssql_connection_list_node *p, *n;

	if (self == NULL)  // this can be true if called from tp_dealloc
		Py_RETURN_NONE;

	if (!self->connected)
		Py_RETURN_NONE;

	clr_err(self);

#ifdef MS_WINDOWS
	Py_BEGIN_ALLOW_THREADS
	rtc = dbclose(self->dbproc);
	self->dbproc = NULL;
	Py_END_ALLOW_THREADS

	check_and_raise(rtc, self);

#else
	Py_BEGIN_ALLOW_THREADS
	dbclose(self->dbproc);
	Py_END_ALLOW_THREADS
#endif

	self->connected = 0;

	/* find and remove the connection from internal list used for
	   error message routing */
	n = connection_object_list;
	p = NULL;

	while (n != NULL) {
		if (n->obj == self) {   // found
			PyMem_Free(n->obj->last_msg_str);
			PyMem_Free(n->obj->charset);
			n->obj->last_msg_str = NULL;
			n->obj->charset = NULL;

			if (p != NULL) {
				p->next = n->next;
				PyMem_Free(n);
			} else
				connection_object_list = n->next;

			break;
		}

		p = n;
		n = n->next;
	}

	Py_RETURN_NONE;
}

/* this method returns pointer to a new RowIterator instance (yet we don't
   know if there are any results, it will turn out later) */

static PyObject *_mssql___iter__(_mssql_connection *self) {
	_mssql_row_iterator *iter;

	assert_connected(self);
	clr_err(self);

	iter = PyObject_NEW(_mssql_row_iterator, &_mssql_row_iterator_type);
	if (iter == NULL)  return NULL;

	Py_INCREF(self);
	iter->conn = self;
	return (PyObject *) iter;
}

/* _mssql.Connection class properties ****************************************/

/* conn.query_timeout property getter */

PyObject *_mssql_query_timeout_get(_mssql_connection *self, void *closure) {
	return PyInt_FromLong(self->query_timeout);
}

/* conn.query_timeout property setter */

int _mssql_query_timeout_set(_mssql_connection *self, PyObject *val, void *closure) {
	long intval;
	RETCODE rtc;

	if (PyErr_Occurred())  return -1;  // properties return -1 on error!
	clr_err(self);

	if (val == NULL) {
		PyErr_SetString(PyExc_TypeError,
				"Cannot delete 'query_timeout' attribute.");
		return -1;
	}

	if (!PyInt_Check(val)) {
		PyErr_SetString(PyExc_TypeError,
				"The 'query_timeout' attribute value must be an integral number.");
		return -1;
	}

	intval = PyInt_AS_LONG(val);

	if (intval < 0) {
		PyErr_SetString(PyExc_ValueError,
				"The 'query_timeout' attribute value must be >= 0.");
		return -1;
	}

	// WARNING - by inspecting FreeTDS sources it turns out that it affects
	// all connections made from this application
	rtc = dbsettime(intval);

	if (rtc == FAIL) {  // can't use check_and_raise
		if (maybe_raise_MssqlDatabaseException(self))
			return -1;
	} else if (*MSSQL_LASTMSGSTR(self))
		if (maybe_raise_MssqlDatabaseException(self))
			return -1;

	self->query_timeout = intval;
	return 0;
}

/* conn.identity property getter */

PyObject *_mssql_identity_get(_mssql_connection *self, void *closure) {
	RETCODE rtc;
	PyObject *row, *id;

	if (PyErr_Occurred())  return NULL;
	assert_connected(self);
	clr_err(self);

	db_cancel(self);  // cancel any pending results

	Py_BEGIN_ALLOW_THREADS
	dbcmd(self->dbproc, "SELECT @@IDENTITY");
	rtc = dbsqlexec(self->dbproc);
	Py_END_ALLOW_THREADS

	check_cancel_and_raise(rtc, self);

	if (get_result(self) == NULL)  return NULL;

	Py_BEGIN_ALLOW_THREADS
	rtc = dbnextrow(self->dbproc);
	Py_END_ALLOW_THREADS

	check_cancel_and_raise(rtc, self);

	if (rtc == NO_MORE_ROWS) {     // check it, just to be pendatically sure
		clr_metadata(self);
		self->last_dbresults = 0;  // force next results, if any
		Py_RETURN_NONE;
	}

	row = get_row(self, rtc);      // get first row of data
	if (row == NULL)  return NULL;

	id = PyTuple_GetItem(row, 0);
	if (id == NULL)  return NULL;
	Py_INCREF(id);

	db_cancel(self);

	Py_DECREF(row);  // row data no longer needed
	return id;
}

/* _mssql module methods *****************************************************/

/* err_handler() and msg_handler() are callbacks called by DB-Library
   or FreeTDS whenever database or library error occurs. There are one
   err_handler and one msg_handler per dbinit() call, that is, presently,
   for the whole _mssql module. But we maintain multiple connections
   and messages may relate to any of them, so we need a way to know
   which connection object route message to. For this purpose we maintain
   a list of DBPROCESS pointers and compare dbproc parameter until they
   match. Then, there's also a filter. We don't consider messages that have
   severity value less than _mssql.min_error_severity. This is because they
   are informational only, and don't represent any real value (for example
   if you call select_db, "Database changed" informational message is
   returned).
   The handlers used to be separated in previous versions of pymssql, but
   it turned out that it has no added value, so I decided to combine them,
   and I checked that min_error_severity of 6 is ok for most users.
   But they can change it if they need. */

int err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr,
		char *dberrstr, char *oserrstr) {
	struct _mssql_connection_list_node *p, *n;
	PyObject *o;
	long lo;
	char *mssql_lastmsgstr = _mssql_last_msg_str;
	int *mssql_lastmsgno = &_mssql_last_msg_no;
	int *mssql_lastmsgseverity = &_mssql_last_msg_severity;
	int *mssql_lastmsgstate = &_mssql_last_msg_state;

#ifdef PYMSSQLDEBUG
	fprintf(stderr, "\n*** err_handler(dbproc = %p, severity = %d, dberr = %d, \
			oserr = %d, dberrstr = '%s', oserrstr = '%s'); DBDEAD(dbproc) = %d\n", (void *)dbproc,
			severity, dberr, oserr, dberrstr, oserrstr, DBDEAD(dbproc));
	fprintf(stderr, "*** previous max severity = %d\n\n", _mssql_last_msg_severity);
#endif

	// mute if below the acceptable threshold
	o = PyObject_GetAttr(_mssql_module, PyString_FromString("min_error_severity"));
	lo = PyInt_AS_LONG(o);
	Py_DECREF(o);

	if (severity < lo)
		return INT_CANCEL;  // ntwdblib.dll 2000.80.2273.0 hangs Python here

	// try to find out which connection this handler belongs to.
	// do it by scanning the list
	n = connection_object_list;
	p = NULL;

	while (n != NULL) {
		if (n->obj->dbproc == dbproc) {   // found
			mssql_lastmsgstr = n->obj->last_msg_str;
			mssql_lastmsgno = &n->obj->last_msg_no;
			mssql_lastmsgseverity = &n->obj->last_msg_severity;
			mssql_lastmsgstate = &n->obj->last_msg_state;
			break;
		}

		p = n;
		n = n->next;
	}

	// if not found, pointers will point to global vars, which is good

	// calculate the maximum severity of all messages in a row
	if (severity > *mssql_lastmsgseverity) {
		*mssql_lastmsgseverity = severity;
		*mssql_lastmsgno = dberr;
		*mssql_lastmsgstate = oserr;
	}

	// but get all of them regardless of severity
	snprintf(mssql_lastmsgstr + strlen(mssql_lastmsgstr),
			PYMSSQL_MSGSIZE - strlen(mssql_lastmsgstr),
			"DB-Lib error message %d, severity %d:\n%s\n",
			dberr, severity, dberrstr);

	if ((oserr != DBNOERR) && (oserr != 0)) {
		/* get a textual representation of the error code */

#ifdef MS_WINDOWS
		HMODULE hModule = NULL; // default to system source
		LPSTR msg;
		DWORD buflen;
		DWORD fmtflags = FORMAT_MESSAGE_ALLOCATE_BUFFER |
							FORMAT_MESSAGE_IGNORE_INSERTS |
							FORMAT_MESSAGE_FROM_SYSTEM;

		if (oserr > NERR_BASE && oserr <= MAX_NERR) {
			// this can take a long time...
			Py_BEGIN_ALLOW_THREADS
			hModule = LoadLibraryEx(TEXT("netmsg.dll"), NULL,
					LOAD_LIBRARY_AS_DATAFILE);
			Py_END_ALLOW_THREADS

			if (hModule != NULL)  fmtflags |= FORMAT_MESSAGE_FROM_HMODULE;
		}

		buflen = FormatMessageA(fmtflags,
						hModule,               // module to get message from (NULL == system)
						oserr, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // default language
						(LPSTR) &msg, 0, NULL);
		if (buflen) {
#else
#define EXCOMM 9
			char *msg = strerror(oserr);
#endif

			snprintf(mssql_lastmsgstr + strlen(mssql_lastmsgstr),
					PYMSSQL_MSGSIZE - strlen(mssql_lastmsgstr),
					"%s error during %s ",
					(severity == EXCOMM) ? "Net-Lib" : "Operating system",
							oserrstr);
			snprintf(mssql_lastmsgstr + strlen(mssql_lastmsgstr),
					PYMSSQL_MSGSIZE - strlen(mssql_lastmsgstr),
					"Error %d - %s", oserr, msg);

#ifdef MS_WINDOWS
			LocalFree(msg);

			// unload netmsg.dll
			if (hModule != NULL) FreeLibrary(hModule);
		}
#endif
	}

	return INT_CANCEL;  /* sigh FreeTDS sets DBDEAD on incorrect login! */
}

/* gosh! different prototypes! (again...) */
#ifdef MS_WINDOWS
#define LINE_T DBUSMALLINT
#else
#define LINE_T int
#endif
int msg_handler(DBPROCESS *dbproc, DBINT msgno, int msgstate, int severity,
		char *msgtext, char *srvname, char *procname, LINE_T line) {
	struct _mssql_connection_list_node *p, *n;
	PyObject *o;
	long lo;
	char *mssql_lastmsgstr = _mssql_last_msg_str;
	int *mssql_lastmsgno = &_mssql_last_msg_no;
	int *mssql_lastmsgseverity = &_mssql_last_msg_severity;
	int *mssql_lastmsgstate = &_mssql_last_msg_state;

#ifdef PYMSSQLDEBUG
	fprintf(stderr, "\n+++ msg_handler(dbproc = %p, msgno = %d, msgstate = %d, \
			severity = %d, msgtext = '%s', srvname = '%s', procname = '%s', line = %d\n", (void *)dbproc,
			msgno, msgstate, severity, msgtext, srvname, procname, line);
	fprintf(stderr, "+++ previous max severity = %d\n\n", _mssql_last_msg_severity);
#endif

	// mute if below the acceptable threshold
	o = PyObject_GetAttr(_mssql_module, PyString_FromString("min_error_severity"));
	lo = PyInt_AS_LONG(o);
	Py_DECREF(o);

	if (severity < lo)
		return 0;

	// try to find out which connection this handler belongs to.
	// do it by scanning the list
	n = connection_object_list;
	p = NULL;

	while (n != NULL) {
		if (n->obj->dbproc == dbproc) { // found
			mssql_lastmsgstr = n->obj->last_msg_str;
			mssql_lastmsgno = &n->obj->last_msg_no;
			mssql_lastmsgseverity = &n->obj->last_msg_severity;
			mssql_lastmsgstate = &n->obj->last_msg_state;
			break;
		}

		p = n;
		n = n->next;
	}

	// calculate the maximum severity of all messages in a row
	// fill the remaining fields if this is going to raise the exception
	if (*mssql_lastmsgseverity < severity) {
		*mssql_lastmsgseverity = severity;
		*mssql_lastmsgno = msgno;
		*mssql_lastmsgstate = msgstate;
	}

	// but get all of them regardless of severity
	if ((procname != NULL) && *procname)
		snprintf(mssql_lastmsgstr + strlen(mssql_lastmsgstr),
				PYMSSQL_MSGSIZE - strlen(mssql_lastmsgstr),
				"SQL Server message %ld, severity %d, state %d, procedure %s, line %d:\n%s\n",
				(long)msgno, severity, msgstate, procname, line, msgtext);
	else
		snprintf(mssql_lastmsgstr + strlen(mssql_lastmsgstr),
				PYMSSQL_MSGSIZE - strlen(mssql_lastmsgstr),
				"SQL Server message %ld, severity %d, state %d, line %d:\n%s\n",
				(long)msgno, severity, msgstate, line, msgtext);

	return 0;
}

static char _mssql_connect_doc[] =
"connect(server, user, password, trusted, charset, database)\n\
           -- connect to an MS SQL Server.\n\
This method returns an instance of class _mssql.MssqlConnection.\n\n\
server   - an instance of MS SQL server to connect to; it can be host\n\
           name, 'host,port' or 'host:port' syntax, or server\n\
           identifier from freetds.conf config file. On Windows you\n\
           can also use r'hostname\\instancename' to connect to a named\n\
           instance.\n\
user     - user name to login as.\n\
password - password to authenticate with.\n\
trusted  - use trusted connection (Windows Integrated Authentication)\n\
           instead of SQL user and password, user and password\n\
           are ignored. Only available on Windows.\n\
charset  - character set name to set for the connection.\n\
database - database name to select initially as the current database.\n\
max_conn - maximum number of simultaneous connections allowed; default\n\
           is 25\n\
";

static PyObject *_mssql_connect(_mssql_connection *self, PyObject *args,
		PyObject *kwargs) {
	_mssql_connection *dbconn;
	LOGINREC *login;         // DB-LIB login structure
	char *server = NULL, *user = NULL, *password = NULL;
	char *database = NULL, *charset = NULL;
	char *p;
	int trusted = 0, max_conn = 25;
	RETCODE rtc;
	struct _mssql_connection_list_node *n;
	PyObject *ologintimeout, *o;

	static char *kwlist[] = { "server", "user", "password", "trusted",
			"charset", "database", "max_conn", NULL };

	if(!PyArg_ParseTupleAndKeywords(args, kwargs, "s|zzizzi:connect", kwlist,
			&server, &user, &password, &trusted, &charset, &database, &max_conn))
		return NULL;

	clr_err(NULL);

#ifdef PYMSSQLDEBUG
	fprintf(stderr, "_mssql.connect(server=\"%s\", user=\"%s\", password=\"%s\", trusted=\"%d\", charset=\"%s\", database=\"%s\", max_conn=\"%d\")\n",
			server, user, password, trusted, charset, database, max_conn);
#endif

	// lame hack to improve portability, will break with IPv6
	// FreeTDS doesn't accept ',' as port number separator
#ifdef MS_WINDOWS
	// Windows accepts syntax 'host.name.or.ip,port' with comma
	p = strchr(server, ':');
	if (p != NULL)
		*p = ',';
#else
	// FreeTDS accepts syntax 'host.name.or.ip:port' with colon
	p = strchr(server, ',');
	if (p != NULL)
		*p = ':';
#endif

	login = dblogin();        // get login record from DB-LIB
	if (login == NULL)
		raise_MssqlDriverException("Out of memory");

	if (max_conn < 0)
		raise_MssqlDriverException("max_conn value must be greater than 0.");

	// these don't need to release GIL
	DBSETLUSER(login, user);
	DBSETLPWD(login, password);
	DBSETLAPP(login, "pymssql");
	dbsetmaxprocs(max_conn);
#ifdef MS_WINDOWS
	DBSETLVERSION(login, DBVER60);
#else
	DBSETLHOST(login, server);
#endif

#ifdef MS_WINDOWS
	if (trusted)
		DBSETLSECURE(login);
#endif

	dbconn = PyObject_NEW(_mssql_connection, &_mssql_connection_type);
	if (dbconn == NULL) {
		DBFREELOGIN(login);
		raise_MssqlDriverException("Could not create _mssql.MssqlConnection object");
	}

	dbconn->connected = 0;
	dbconn->column_names = dbconn->column_types = NULL;
	dbconn->num_columns = 0;
	dbconn->debug_queries = 0;
	dbconn->last_msg_str = PyMem_Malloc(PYMSSQL_MSGSIZE);
	dbconn->charset = PyMem_Malloc(PYMSSQL_CHARSETBUFSIZE);

	if ((dbconn->last_msg_str == NULL) || (dbconn->charset == NULL)) {
		Py_DECREF(dbconn);
		DBFREELOGIN(login);
		raise_MssqlDriverException("Out of memory");
	}

	*dbconn->last_msg_str = 0;
	*dbconn->charset = 0;

	// create list node and allocate message buffer
	n = PyMem_Malloc(sizeof(struct _mssql_connection_list_node));

	if (n == NULL) {
		Py_DECREF(dbconn);  // also frees last_msg_str and charset buf
		DBFREELOGIN(login);
		raise_MssqlDriverException("Out of memory");
	}

	// prepend this connection to the list, will be needed soon, because
	// dbopen can raise errors
	n->next = connection_object_list;
	n->obj = dbconn;
	connection_object_list = n;

	// set the character set name
	if (charset) {
		strncpy(dbconn->charset, charset, PYMSSQL_CHARSETBUFSIZE);
#ifndef MS_WINDOWS
		if (DBSETLCHARSET(login, dbconn->charset) == FAIL) {
			Py_DECREF(dbconn);
			DBFREELOGIN(login);
			raise_MssqlDriverException("Could not set character set");
		}
#endif
	}

	// set login timeout

	ologintimeout = PyObject_GetAttrString(_mssql_module, "login_timeout");
	if (ologintimeout == NULL) {
		connection_object_list = connection_object_list->next;
		PyMem_Free(n);
		Py_DECREF(dbconn);  // also frees last_msg_str and charset buf
		DBFREELOGIN(login);
		return NULL;
	}

	dbsetlogintime((int) PyInt_AS_LONG(ologintimeout));
	Py_DECREF(ologintimeout);

	// connect to the database

	Py_BEGIN_ALLOW_THREADS
	dbconn->dbproc = dbopen(login, server);
	Py_END_ALLOW_THREADS

	if (dbconn->dbproc == NULL) {
		connection_object_list = connection_object_list->next;
		PyMem_Free(n);
		Py_DECREF(dbconn);
		DBFREELOGIN(login);
		maybe_raise_MssqlDatabaseException(NULL); // we hope it will raise something
		if (!PyErr_Occurred())  // but if not, give a meaningful response
			PyErr_SetString(_mssql_MssqlDriverException,
					"Connection to the database failed for an unknown reason.");
		return NULL;
	}

	// these don't need to release GIL
	DBFREELOGIN(login);       // Frees a login record.
	dbconn->connected = 1;

	// set initial connection properties to some reasonable values
	Py_BEGIN_ALLOW_THREADS
	dbcmd(dbconn->dbproc,
			"SET ARITHABORT ON;"
			"SET CONCAT_NULL_YIELDS_NULL ON;"
			"SET ANSI_NULLS ON;"
			"SET ANSI_NULL_DFLT_ON ON;"
			"SET ANSI_PADDING ON;"
			"SET ANSI_WARNINGS ON;"
			"SET ANSI_NULL_DFLT_ON ON;"
			"SET CURSOR_CLOSE_ON_COMMIT ON;"
			"SET QUOTED_IDENTIFIER ON"
	);

	rtc = dbsqlexec(dbconn->dbproc);
	Py_END_ALLOW_THREADS

	if (rtc == FAIL) {
		raise_MssqlDriverException("Could not set connection properties");
		// connection is still valid and open
	}

	db_cancel(dbconn);
	clr_err(dbconn);

	if (database) {
		o = _mssql_select_db(dbconn, PyString_FromString(database));
		if (o == NULL)  return NULL;
	}

	return (PyObject *)dbconn;
}

/* _mssql.Connection class definition ****************************************/

static void _mssql_connection_dealloc(_mssql_connection *self) {
	if (self->connected) {
		PyObject *o = _mssql_close(self, NULL);
		Py_XDECREF(o);
	}

	if (self->last_msg_str)
		PyMem_Free(self->last_msg_str);

	if (self->charset)
		PyMem_Free(self->charset);

	Py_XDECREF(self->column_names);
	Py_XDECREF(self->column_types);
	PyObject_Free((void *) self);
}

static PyObject *_mssql_connection_repr(_mssql_connection *self) {
	return PyString_FromFormat("<%s mssql connection at %p>",
		self->connected ? "Open" : "Closed", self);
}

/* instance methods */
static PyMethodDef _mssql_connection_methods[] = {
	{ "select_db",         (PyCFunction) _mssql_select_db,         METH_O,      _mssql_select_db_doc },
	{ "execute_query",     (PyCFunction) _mssql_execute_query,     METH_VARARGS,_mssql_execute_query_doc },
	{ "execute_non_query", (PyCFunction) _mssql_execute_non_query, METH_VARARGS,_mssql_execute_non_query_doc },
	{ "execute_scalar",    (PyCFunction) _mssql_execute_scalar,    METH_VARARGS,_mssql_execute_scalar_doc },
	{ "execute_row",       (PyCFunction) _mssql_execute_row,       METH_VARARGS,_mssql_execute_row_doc },
	{ "get_header",        (PyCFunction) _mssql_get_header,        METH_NOARGS, _mssql_get_header_doc },
	{ "cancel",            (PyCFunction) _mssql_cancel,            METH_NOARGS, _mssql_cancel_doc },
	{ "nextresult",        (PyCFunction) _mssql_nextresult,        METH_NOARGS, _mssql_nextresult_doc },
	{ "close",             (PyCFunction) _mssql_close,             METH_NOARGS, _mssql_close_doc },
	{ NULL, NULL, 0, NULL }
};

/* properties */
static PyGetSetDef _mssql_connection_getset[] = {
	{ "query_timeout", (getter) _mssql_query_timeout_get, (setter) _mssql_query_timeout_set,
		"Query timeout in seconds. This value affects all connections\n"
	    "opened in current script.", NULL },
	{ "identity", (getter) _mssql_identity_get, (setter) NULL,
		"Returns identity value of last inserted row. If previous operation\n"
		"did not involve inserting a row into a table with identity column,\n"
		"None is returned. Example usage:\n\n"
		"conn.execute_non_query(\"INSERT INTO table (name) VALUES ('John')\")\n"
		"print 'Last inserted row has ID = ' + conn.identity", NULL },
	{ NULL, NULL, NULL, NULL, NULL }
};

#define _MSSQL_OFF(m) offsetof(_mssql_connection, m)

/* instance properties */
static PyMemberDef _mssql_connection_members[] = {
	{ "connected", T_INT, _MSSQL_OFF(connected), READONLY,
	  "True if the connection to a database is open." },
	{ "rows_affected", T_INT, _MSSQL_OFF(rows_affected), READONLY,
	  "Number of rows affected by last query. For SELECT statements\n"
	  "this value is only meaningful after reading all rows." },
	{ "charset", T_STRING, _MSSQL_OFF(charset), READONLY,
	  "Character set name that was passed to _mssql.connect()." },
	{ "debug_queries", T_INT, _MSSQL_OFF(debug_queries), RESTRICTED,
	  "If set to True, all queries are printed to stderr after\n"
	  "formatting and quoting, just before execution." },
	{ NULL, 0, 0, 0, NULL },
};

static char _mssql_connection_type_doc[] =
"This object represents an MS SQL database connection. You can\n\
make queries and obtain results through a database connection.";

static PyTypeObject _mssql_connection_type = {
	PyObject_HEAD_INIT(NULL)
	0,                                     /* ob_size           */
	"_mssql.MssqlConnection",              /* tp_name           */
	sizeof(_mssql_connection),             /* tp_basicsize      */
	0,                                     /* tp_itemsize       */
	(destructor)_mssql_connection_dealloc, /* tp_dealloc        */
	0,                                     /* tp_print          */
	0,                                     /* tp_getattr        */
	0,                                     /* tp_setattr        */
	0,                                     /* tp_compare        */
	(reprfunc)_mssql_connection_repr,      /* tp_repr           */
	0,                                     /* tp_as_number      */
	0,                                     /* tp_as_sequence    */
	0,                                     /* tp_as_mapping     */
	0,                                     /* tp_hash           */
	0,                                     /* tp_call           */
	0,                                     /* tp_str            */
	0,                                     /* tp_getattro       */
	0,                                     /* tp_setattro       */
	0,                                     /* tp_as_buffer      */
	Py_TPFLAGS_DEFAULT,                    /* tp_flags          */
	_mssql_connection_type_doc,            /* tp_doc            */
	0,                                     /* tp_traverse       */
	0,                                     /* tp_clear          */
	0,                                     /* tp_richcompare    */
	0,                                     /* tp_weaklistoffset */
	(getiterfunc)_mssql___iter__,          /* tp_iter           */
	0,                                     /* tp_iternext       */
	_mssql_connection_methods,             /* tp_methods        */
	_mssql_connection_members,             /* tp_members        */
	_mssql_connection_getset,              /* tp_getset         */
	0,                                     /* tp_base           */
	0,                                     /* tp_dict           */
	0,                                     /* tp_descr_get      */
	0,                                     /* tp_descr_set      */
	0,                                     /* tp_dictoffset     */
	0,                                     /* tp_init           */
	NULL,                                  /* tp_alloc          */
	NULL,                                  /* tp_new            */
	NULL,                                  /* tp_free Low-level free-memory routine */
	0,                                     /* tp_bases          */
	0,                                     /* tp_mro method resolution order */
	0,                                     /* tp_defined        */
};

/* module methods */
static PyMethodDef _mssql_methods[] = {
	{ "connect",     (PyCFunction) _mssql_connect, METH_KEYWORDS, _mssql_connect_doc },
	{ "_quote_data", (PyCFunction) _mssql_quote_data, METH_O, _mssql_quote_data_doc },
	{ "_format_sql_command", (PyCFunction) _mssql_format_sql_command, METH_VARARGS, _mssql_format_sql_command_doc },
	{ NULL, NULL }
};

static char _mssql_MssqlDatabaseException_doc[] =
"Exception raised when a database (query or server) error occurs.\n\n\
You can use it as in the following example:\n\n\
try:\n\
    conn = _mssql.connect('server','user','password')\n\
    conn.execute_non_query('CREATE TABLE t1(id INT, name VARCHAR(50))')\n\
except _mssql.MssqlDatabaseException,e:\n\
    if e.number == 2714 and e.severity == 16:\n\
        # table already existed, so mute the error\n\
    else:\n\
        raise  # re-raise real error\n\
finally:\n\
    conn.close()\n\n\
Message numbers can be obtained by executing the query without\n\
the 'try' block, or from SQL Server Books Online.\n\n\
--------------------------------------------------------";

PyMODINIT_FUNC
init_mssql(void) {
#ifdef MS_WINDOWS
	LPCSTR rtc;
#else
	RETCODE rtc;
#endif

	PyObject *dict;

	/* if we initialize this at declar	ation, MSVC 7 issues the following warn:
	   warning C4232: nonstandard extension used : 'tp_getattro': address of
	   dllimport 'PyObject_GenericGetAttr' is not static, identity not guaranteed */
	_mssql_connection_type.tp_getattro = PyObject_GenericGetAttr;
	_mssql_row_iterator_type.tp_getattro = PyObject_GenericGetAttr;

	PyDateTime_IMPORT;  // import datetime

	_decimal_module = PyImport_ImportModule("decimal");
	if (_decimal_module == NULL)  return;
	_decimal_class = PyObject_GetAttrString(_decimal_module, "Decimal");
    _decimal_context = PyObject_CallMethod(_decimal_module, "getcontext", NULL);

	if (PyType_Ready(&_mssql_connection_type) == -1)
		return;

	if (PyType_Ready(&_mssql_row_iterator_type) == -1)
		return;

	_mssql_module = Py_InitModule3("_mssql", _mssql_methods,
		"Low level Python module for communicating with MS SQL servers.");

	if (_mssql_module == NULL)  return;

	// add the connection object to module dictionary
	Py_INCREF(&_mssql_connection_type);
	if (PyModule_AddObject(_mssql_module, "MssqlConnection",
			(PyObject *)&_mssql_connection_type) == -1) return;

	// MssqlException
	dict = PyDict_New();
	if (dict == NULL)  return;

	if (PyDict_SetItemString(dict, "__doc__",
			PyString_FromString("Base class for all _mssql related exceptions.")) == -1)
		return;

	_mssql_MssqlException = PyErr_NewException("_mssql.MssqlException", NULL, dict);
	if (_mssql_MssqlException == NULL)  return;

	if (PyModule_AddObject(_mssql_module, "MssqlException", _mssql_MssqlException) == -1) return;

	// MssqlDatabaseException
	dict = PyDict_New();
	if (dict == NULL)  return;

	if (PyDict_SetItemString(dict, "__doc__",
			PyString_FromString(_mssql_MssqlDatabaseException_doc)) == -1)
		return;

	if (PyDict_SetItemString(dict, "number",
			PyInt_FromLong(0)) == -1)
		return;

	if (PyDict_SetItemString(dict, "severity",
			PyInt_FromLong(0)) == -1)
		return;

	if (PyDict_SetItemString(dict, "state",
			PyInt_FromLong(0)) == -1)
		return;

	// explicit definition of message will allow us to use it
	// without DeprecationWarning in Python 2.6
	Py_INCREF(Py_None);
	if (PyDict_SetItemString(dict, "message", Py_None) == -1)
		return;

	_mssql_MssqlDatabaseException = PyErr_NewException("_mssql.MssqlDatabaseException",
			_mssql_MssqlException, dict);
	if (_mssql_MssqlDatabaseException == NULL)  return;

	if (PyModule_AddObject(_mssql_module, "MssqlDatabaseException",
			_mssql_MssqlDatabaseException) == -1)
		return;

	// MssqlDriverException
	dict = PyDict_New();
	if (dict == NULL)  return;

	if (PyDict_SetItemString(dict, "__doc__",
			PyString_FromString("Exception raised when an _mssql module error occurs.")) == -1)
		return;

	_mssql_MssqlDriverException = PyErr_NewException("_mssql.MssqlDriverException",
			_mssql_MssqlException, dict);
	if (_mssql_MssqlDriverException == NULL)  return;

	if (PyModule_AddObject(_mssql_module, "MssqlDriverException",
			_mssql_MssqlDriverException) == -1) return;

	if (PyModule_AddIntConstant(_mssql_module, "STRING", TYPE_STRING) == -1)
		return;
	if (PyModule_AddIntConstant(_mssql_module, "BINARY", TYPE_BINARY) == -1)
		return;
	if (PyModule_AddIntConstant(_mssql_module, "NUMBER", TYPE_NUMBER) == -1)
		return;
	if (PyModule_AddIntConstant(_mssql_module, "DATETIME", TYPE_DATETIME) == -1)
		return;
	if (PyModule_AddIntConstant(_mssql_module, "DECIMAL", TYPE_DECIMAL) == -1)
		return;
	// don't set it too high - for example query timeouts has severity = 6,
	// for now the best seems 6, because 5 generates too many db-lib warnings
	if (PyModule_AddObject(_mssql_module, "min_error_severity",
			PyInt_FromLong((long) 6)) == -1) return;
	if (PyModule_AddObject(_mssql_module, "login_timeout",
			PyInt_FromLong((long) 60)) == -1) return;

	rtc = dbinit();

#ifdef MS_WINDOWS
	if (rtc == (char *)NULL) {
#else
	if (rtc == FAIL) {
#endif
		PyErr_SetString(_mssql_MssqlDriverException,
				"Could not initialize communication layer");
		return;
	}

	// these don't need to release GIL
#ifdef MS_WINDOWS
	dberrhandle((DBERRHANDLE_PROC)err_handler);
	dbmsghandle((DBMSGHANDLE_PROC)msg_handler);
#else
	dberrhandle(err_handler);
	dbmsghandle(msg_handler);
#endif
}

/* _mssql.MssqlRowIterator class methods *************************************/

static PyObject *_mssql_row_iterator_repr(_mssql_row_iterator *self) {
	return PyString_FromFormat("<_mssql.MssqlRowIterator at %p>", self);
}

static PyObject *_mssql_row_iterator__iter__(PyObject *self) {
	Py_INCREF(self);
	return self;
}

static PyObject *_mssql_row_iterator_iternext(_mssql_row_iterator *self) {
	if (PyErr_Occurred())  return NULL;
	assert_connected(self->conn);
	clr_err(self->conn);

    return fetch_next_row_dict(self->conn, /* raise StopIteration= */ 1);
}

void _mssql_row_iterator_dealloc(_mssql_row_iterator *self) {
	Py_CLEAR(self->conn);
	PyObject_Del(self);
}

/* _mssql.MssqlRowIterator class definition **********************************/

static char _mssql_row_iterator_doc[] =
"This object represents an iterator that iterates over rows\n\
from a result set.";

static PyTypeObject _mssql_row_iterator_type = {
	PyObject_HEAD_INIT(NULL)
	0,                                          /* ob_size           */
	"_mssql.MssqlRowIterator",                  /* tp_name           */
	sizeof(_mssql_row_iterator),                /* tp_basicsize      */
	0,                                          /* tp_itemsize       */
	(destructor)_mssql_row_iterator_dealloc,    /* tp_dealloc        */
	0,                                          /* tp_print          */
	0,                                          /* tp_getattr        */
	0,                                          /* tp_setattr        */
	0,                                          /* tp_compare        */
	(reprfunc)_mssql_row_iterator_repr,         /* tp_repr           */
	0,                                          /* tp_as_number      */
	0,                                          /* tp_as_sequence    */
	0,                                          /* tp_as_mapping     */
	0,                                          /* tp_hash           */
	0,                                          /* tp_call           */
	0,                                          /* tp_str            */
	0,                                          /* tp_getattro       */
	0,                                          /* tp_setattro       */
	0,                                          /* tp_as_buffer      */
	Py_TPFLAGS_DEFAULT,                         /* tp_flags          */
	_mssql_row_iterator_doc,                    /* tp_doc            */
	0,                                          /* tp_traverse       */
	0,                                          /* tp_clear          */
	0,                                          /* tp_richcompare    */
	0,                                          /* tp_weaklistoffset */
	_mssql_row_iterator__iter__,                /* tp_iter           */
	(iternextfunc)_mssql_row_iterator_iternext, /* tp_iternext       */
	0,                                          /* tp_methods        */
	0,                                          /* tp_members        */
	0,                                          /* tp_getset         */
	0,                                          /* tp_base           */
	0,                                          /* tp_dict           */
	0,                                          /* tp_descr_get      */
	0,                                          /* tp_descr_set      */
	0,                                          /* tp_dictoffset     */
	0,                                          /* tp_init           */
	NULL,                                       /* tp_alloc          */
	NULL,                                       /* tp_new            */
	NULL,                                       /* tp_free Low-level free-memory routine */
	0,                                          /* tp_bases          */
	0,                                          /* tp_mro method resolution order */
	0,                                          /* tp_defined        */
};


/* internal functions ********************************************************/

/* rmv_lcl() -- strip off all locale formatting

   buf is supplied to make this solution thread-safe; conversion will succeed
   when buf is the same size as s (or larger); s is the string rep of the
   number to strip; scientific formats are not supported;
   buf can be == s (it can fix numbers in-place.)
   return codes: 0 - conversion failed (buf too small or buf or s is null)
               <>0 - conversion succeeded, new len is returned

   Idea by Mark Pettit. */

int rmv_lcl(char *s, char *buf, size_t buflen) {
	char c, *lastsep = NULL, *p = s, *b = buf;
	size_t  l;

	if (b == (char *)NULL) return 0;

	if (s == (char *)NULL) {
		*b = 0;
		return 0;
	}

	/* find last separator and length of s */
	while ((c = *p)) {
		if ((c == '.') || (c == ','))   lastsep = p;
		++p;
	}

	l = p - s;   // strlen(s)
	if (buflen < l) return 0;

	/* copy the number skipping all but last separator and all other chars */
	p = s;
	while ((c = *p)) {
		if (((c >= '0') && (c <= '9')) || (c == '-') || (c == '+'))
			*b++ = c;
		else if (p == lastsep)
			*b++ = '.';
		++p;
	}

	*b = 0;

	// cast to int to make x64 happy, can do it because numbers are not so very long
	return (int)(b - buf);  // return new len
}

/* This is a helper function, which does most work needed by any
   execute_*() function. It returns NULL on error, non-NULL on success.
   Actually it returns Py_None, but there's no need to DECREF it. Also, we
   can't use int as retcode here because assert_connected and other macros
   return NULL on failure. */

PyObject *format_and_run_query(_mssql_connection *self, PyObject *args) {
	RETCODE rtc;
	char *query;
	PyObject *format = NULL, *params = NULL, *formatted = NULL, *tuple;

	if (PyErr_Occurred())  return NULL;
	assert_connected(self);
	clr_err(self);

	if (!PyArg_ParseTuple(args, "O|O", &format, &params))
		return NULL;

	// format the string then convert it to char *
	// Warning: don't put params != Py_None here as None is a valid value!
	if (params != NULL) {
		tuple = PyTuple_New(2);
		if (tuple == NULL)  return NULL;

		Py_INCREF(format); Py_INCREF(params);
		PyTuple_SET_ITEM(tuple, 0, format);
		PyTuple_SET_ITEM(tuple, 1, params);
		formatted = _mssql_format_sql_command(NULL, tuple);
		Py_DECREF(tuple);
		if (formatted == NULL)  return NULL;
		query = PyString_AsString(formatted); // remember to DECREF later
	} else {
		query = PyString_AsString(format);
	}

	if (query == NULL)  return NULL;

	db_cancel(self);  // cancel any pending results

	if (self->debug_queries) {
		fprintf(stderr, "#%s#\n", query);
		fflush(stderr);
	}

	// execute the query
	Py_BEGIN_ALLOW_THREADS
	dbcmd(self->dbproc, query);
	rtc = dbsqlexec(self->dbproc);
	Py_END_ALLOW_THREADS

	// remember to DECREF this as soon as 'query' is no longer needed
	// and before any possible return statement
	Py_XDECREF(formatted);

	check_cancel_and_raise(rtc, self);

	return Py_None;  // borrowed, but it doesn't matter, it's just a flag
}

/* This function advances to next result, and fetch column names and types,
   setting column_names and column_types properties. If the result appears
   to be already read, function does nothing. It returns NULL on error and
   non-NULL on success. Actually it returns Py_None, but there's no need
   to DECREF it. This function skips over all result sets that have no
   columns (for example the query: "DECLARE @a INT; SELECT 1" returns
   two result sets: one with zero columns, followed by one with one column. */

PyObject *get_result(_mssql_connection *conn) {
	int col;

	if (conn->last_dbresults)
		// already read, return success
		return Py_None;  // borrowed, but it doesn't matter, it's just a flag

	clr_metadata(conn);

	// find a result set that has at least one column
	conn->last_dbresults = SUCCEED;
	while (conn->last_dbresults == SUCCEED &&
			(conn->num_columns = dbnumcols(conn->dbproc)) <= 0) {
		Py_BEGIN_ALLOW_THREADS
		conn->last_dbresults = dbresults(conn->dbproc);
		Py_END_ALLOW_THREADS
	}

	check_cancel_and_raise(conn->last_dbresults, conn);

	if (conn->last_dbresults == NO_MORE_RESULTS)
		// no result, but no exception, so return success
		return Py_None;  // borrowed, but it doesn't matter, it's just a flag

	// we need the row affected value, but at this point it is probably 0,
	// unless user issued a statement that doesn't return rows
	conn->rows_affected = dbcount(conn->dbproc);
	conn->num_columns = dbnumcols(conn->dbproc);

	conn->column_names = PyTuple_New(conn->num_columns);
	if (!conn->column_names)  return NULL;

	conn->column_types = PyTuple_New(conn->num_columns);
	if (!conn->column_types)  return NULL;

	for (col = 1; col <= conn->num_columns; col++) {
		int coltype, apicoltype;
		char *colname = (char *) dbcolname(conn->dbproc, col);
		coltype = dbcoltype(conn->dbproc, col);

		switch (coltype) {
			case SQLBIT: case SQLINT1: case SQLINT2: case SQLINT4:
			case SQLINT8: case SQLINTN:
			case SQLFLT4: case SQLFLT8: case SQLFLTN:
				apicoltype = TYPE_NUMBER;
				break;

			case SQLMONEY: case SQLMONEY4: case SQLMONEYN:
			case SQLNUMERIC: case SQLDECIMAL:
				apicoltype = TYPE_DECIMAL;
				break;

			case SQLDATETIME: case SQLDATETIM4: case SQLDATETIMN:
				apicoltype = TYPE_DATETIME;
				break;

			case SQLVARCHAR: case SQLCHAR: case SQLTEXT:
				apicoltype = TYPE_STRING;
				break;

			//case SQLVARBINARY: case SQLBINARY: case SQLIMAGE:
			default:
				apicoltype = TYPE_BINARY;
		}

#ifdef PYMSSQLDEBUG
		// DB-Library for C is truncating column names to 30 characters...
		// thanks stefan <pontifor@users.sourceforge.net>
		fprintf(stderr, "Got column name '%s', name length = %d, coltype=%d, apicoltype=%d\n",
				colname, strlen(colname), coltype, apicoltype);
#endif

		if (PyTuple_SetItem(conn->column_names, col-1, PyString_FromString(colname)) != 0)
			return NULL;

		if (PyTuple_SetItem(conn->column_types, col-1, PyInt_FromLong(apicoltype)) != 0)
			return NULL;
	}

	return Py_None;  // borrowed, but it doesn't matter, it's just a flag
}


#define GET_DATA(dbproc, rowinfo, x) \
	((rowinfo == REG_ROW)?(BYTE*)dbdata(dbproc, x):(BYTE*)dbadata(dbproc, rowinfo, x))
#define GET_TYPE(dbproc, rowinfo, x) \
	((rowinfo == REG_ROW)?dbcoltype(dbproc, x):dbalttype(dbproc, rowinfo, x))
#define GET_LEN(dbproc, rowinfo, x) \
	((rowinfo == REG_ROW)?dbdatlen(dbproc, x):dbadlen(dbproc, rowinfo, x))

#define NUMERIC_BUF_SZ 45

/* This function gets data from CURRENT row. Remember to call get_result()
   somewhere before calling this function. The result is a tuple with Pythonic
   representation of row data. I use it just because in general it's more
   convenient than C arrays especially WRT memory management. In most cases
   after calling this function the next thing is to create row dictionary. */

PyObject *get_row(_mssql_connection *conn, int rowinfo) {
	DBPROCESS *dbproc = conn->dbproc;
	int col, coltype, len;
	LPBYTE data;                // column data pointer
	long intdata;
	PY_LONG_LONG longdata;
	double ddata;
	PyObject *record;
	DBDATEREC di;
	DBDATETIME dt;
	PyObject *o;                // temporary object
	char buf[NUMERIC_BUF_SZ];   // buffer in which we store text rep of big nums
	DBCOL dbcol;
	BYTE prec;
	long prevPrec;
#ifdef PYMSSQLDEBUG
	static int DEBUGRowNumber=0;
#endif

	record = PyTuple_New(conn->num_columns);
	if (!record)
		raise_MssqlDriverException("Could not create record tuple");

#ifdef PYMSSQLDEBUG
	DEBUGRowNumber++;
#endif

	for (col = 1; col <= conn->num_columns; col++) {     // do for all columns

//#ifdef PYMSSQLDEBUG
//		fprintf(stderr, "Processing row %d, column %d\n", DEBUGRowNumber, col);
//#endif
		Py_BEGIN_ALLOW_THREADS

		// get pointer to column's data
		// rowinfo == FAIL and rowinfo == NO_MORE_ROWS are already handled in caller

		data = GET_DATA(dbproc, rowinfo, col);    // get pointer to column's data
		coltype = GET_TYPE(dbproc, rowinfo, col);
		Py_END_ALLOW_THREADS

		if (data == NULL) {                       // if NULL, use None
			Py_INCREF(Py_None);
			PyTuple_SET_ITEM(record, col-1, Py_None);
			continue;
		}

#ifdef PYMSSQLDEBUG
		fprintf(stderr, "Processing row %d, column %d. Got data=%x, coltype=%d, len=%d\n",
				DEBUGRowNumber, col, data, coltype,
				GET_LEN(dbproc, rowinfo, col));

#endif

		switch (coltype) {                        // else we have data
			case SQLBIT:
				intdata = (int) *(DBBIT *) data;
				PyTuple_SET_ITEM(record, col-1, PyBool_FromLong((long) intdata));
				break;

			case SQLINT1:
				intdata = (int) *(DBTINYINT *) data;
				PyTuple_SET_ITEM(record, col-1, PyInt_FromLong((long) intdata));
				break;

			case SQLINT2:
				intdata = (int) *(DBSMALLINT *) data;
				PyTuple_SET_ITEM(record, col-1, PyInt_FromLong((long) intdata));
				break;

			case SQLINT4:
				intdata = (int) *(DBINT *) data;
				PyTuple_SET_ITEM(record, col-1, PyInt_FromLong((long) intdata));
				break;

			case SQLINT8:
				longdata = *(PY_LONG_LONG *) data;
				PyTuple_SET_ITEM(record, col-1, PyLong_FromLongLong((PY_LONG_LONG) longdata));
				break;

			case SQLFLT4:
				ddata = *(DBFLT4 *)data;
				PyTuple_SET_ITEM(record, col-1, PyFloat_FromDouble(ddata));
				break;

			case SQLFLT8:
				ddata = *(DBFLT8 *)data;
				PyTuple_SET_ITEM(record, col-1, PyFloat_FromDouble(ddata));
				break;

			case SQLMONEY: case SQLMONEY4: case SQLNUMERIC: case SQLDECIMAL:
				dbcol.SizeOfStruct = sizeof(dbcol);

				if (dbcolinfo(dbproc, (rowinfo == REG_ROW) ? CI_REGULAR : CI_ALTERNATE,
						col, (rowinfo == REG_ROW) ? 0 : rowinfo, &dbcol) == FAIL)
					raise_MssqlDriverException("Could not obtain column info");

				if (coltype == SQLMONEY || coltype == SQLMONEY4)
					prec = 4;
				else
					prec = dbcol.Scale;

				o = PyObject_GetAttrString(_decimal_context, "prec");
				if (o == NULL)  return NULL;
				prevPrec = PyInt_AsLong(o);
				Py_DECREF(o);

				o = PyInt_FromLong((long) prec);
				if (PyObject_SetAttrString(_decimal_context, "prec", o) == -1)
					raise_MssqlDriverException("Could not set decimal precision");
				Py_DECREF(o);

				len = dbconvert(dbproc, coltype, data, -1, SQLCHAR, (LPBYTE)buf, NUMERIC_BUF_SZ);
				buf[len] = 0;                   // null terminate the string

				len = rmv_lcl(buf, buf, NUMERIC_BUF_SZ);
				if (!len)
					raise_MssqlDriverException("Could not remove locale formatting");

				o = PyObject_CallFunction(_decimal_class, "s", buf);  // new ref
				if (o == NULL)  return NULL;

				PyTuple_SET_ITEM(record, col-1, o);  // steals ref from CallFunction()

				o = PyInt_FromLong((long) prevPrec);
				if (PyObject_SetAttrString(_decimal_context, "prec", o) == -1)
					raise_MssqlDriverException("Could not restore decimal precision");
				Py_DECREF(o);

				break;

			case SQLDATETIM4:
				dbconvert(dbproc, coltype, data, -1, SQLDATETIME, (LPBYTE)&dt, -1);
				data = (LPBYTE) &dt;            // smalldatetime converted to full datetime
				// fall through

			case SQLDATETIME:
				dbdatecrack(dbproc, &di, (DBDATETIME*)data);

				// see README.freetds for info about date problem with FreeTDS
				o = PyDateTime_FromDateAndTime(
						di.year, di.month, di.day, di.hour,
						di.minute, di.second, di.millisecond*1000);
				PyTuple_SET_ITEM(record, col-1, o);
				break;

			case SQLVARCHAR: case SQLCHAR: case SQLTEXT:
				// Convert the strings from the encoding provided by the user
				// If there is none, just return the strings as is.
				if (*conn->charset)
					PyTuple_SET_ITEM(record,col-1,PyUnicode_Decode((char *) data,
							GET_LEN(dbproc,rowinfo,col), conn->charset, NULL));
				else
					// return as-is
					PyTuple_SET_ITEM(record, col-1, PyString_FromStringAndSize(
							(const char *)data, GET_LEN(dbproc, rowinfo, col)));

				break;

			//case SQLBINARY: case SQLVARBINARY: case SQLIMAGE:
			default:                            // return as is (binary string)
				PyTuple_SET_ITEM(record, col-1, PyString_FromStringAndSize(
						(const char *)data, GET_LEN(dbproc, rowinfo, col)));
		} // end switch
	} // end for

	return record;
}

/* This function fetches NEXT ROW of data and returns it as a dictionary.
   It is used by execute_row() and by row iterator iternext(). */

PyObject *fetch_next_row_dict(_mssql_connection *conn, int raise) {
	PyObject *row, *dict;
	RETCODE rtc;
	int col;

	if (get_result(conn) == NULL)  return NULL;

	// ok, we did everything to set up results, if there aren't any,
	// just stop the iteration

	if (conn->last_dbresults == NO_MORE_RESULTS) {
		clr_metadata(conn);
		if (raise) {
			PyErr_SetNone(PyExc_StopIteration);
			return NULL;
		}
		Py_RETURN_NONE;
	}

	// iterate and build row dictionary
	Py_BEGIN_ALLOW_THREADS
	rtc = dbnextrow(conn->dbproc);
	Py_END_ALLOW_THREADS

	check_cancel_and_raise(rtc, conn);

	if (rtc == NO_MORE_ROWS) {
		clr_metadata(conn);
		// 'rows affected' is nonzero only after all records are read
		conn->rows_affected = dbcount(conn->dbproc);
		conn->last_dbresults = 0;  // force next results, if any
		if (raise) {
			PyErr_SetNone(PyExc_StopIteration);
			return NULL;
		}
		Py_RETURN_NONE;
	}

	if ((dict = PyDict_New()) == NULL)  return NULL;

	row = get_row(conn, rtc); // pass constant REG_ROW or compute id
	if (row == NULL)  return NULL;

	for (col = 1; col <= conn->num_columns; col++) {
		PyObject *name, *val;

		name = PyTuple_GetItem(conn->column_names, col-1);
		if (name == NULL)  return NULL;

		val = PyTuple_GetItem(row, col-1);
		if (val == NULL)  return NULL;

		// add key by column name, do not add if name == ''
		if (strlen(PyString_AS_STRING(name)) != 0)
			if ((PyDict_SetItem(dict, name, val)) == -1)
				return NULL;

		// add key by column number
		if ((PyDict_SetItem(dict, PyInt_FromLong(col-1), val)) == -1)
			return NULL;
	}

	Py_DECREF(row);  // row data no longer needed
	return dict;
}


/* clear error condition so we can start accumulating error messages again */

void clr_err(_mssql_connection *self) {
	*MSSQL_LASTMSGSTR(self) = '\0';

	if (self != NULL) {
		self->last_msg_no = 0;
		self->last_msg_severity = 0;
		self->last_msg_state = 0;
	} else {
		_mssql_last_msg_no = 0;
		_mssql_last_msg_severity = 0;
		_mssql_last_msg_state = 0;
	}
}

/* Check whether accumulated severity is equal to or higher than
   min_error_severity, and if so, set exception and return true;
   else return false (no need to raise exception) */

int maybe_raise_MssqlDatabaseException(_mssql_connection *self) {
	PyObject *o;
	long lo;
	char *errptr;

	o = PyObject_GetAttr(_mssql_module, PyString_FromString("min_error_severity"));
	lo = PyInt_AS_LONG(o);
	Py_DECREF(o);

	if (MSSQL_LASTMSGSEVERITY(self) < lo)
		return 0;

	// severe enough to raise error
	errptr = MSSQL_LASTMSGSTR(self);
	if (!errptr || !*errptr)  errptr = "Unknown error";

	PyObject_SetAttrString(_mssql_MssqlDatabaseException, "number",
			PyInt_FromLong(MSSQL_LASTMSGNO(self)));
	PyObject_SetAttrString(_mssql_MssqlDatabaseException, "severity",
			PyInt_FromLong(MSSQL_LASTMSGSEVERITY(self)));
	PyObject_SetAttrString(_mssql_MssqlDatabaseException, "state",
			PyInt_FromLong(MSSQL_LASTMSGSTATE(self)));
	PyObject_SetAttrString(_mssql_MssqlDatabaseException, "message",
			PyString_FromString(errptr));
	PyErr_SetString(_mssql_MssqlDatabaseException, errptr);

	// cancel the (maybe partial, invalid) results
	db_cancel(self);
	return 1;
}

/* cancel pending results */

RETCODE db_cancel(_mssql_connection *conn) {
	RETCODE rtc;

	// db_cancel() may be called from maybe_raise_MssqlDatabaseException()
	// after failed call to dbopen(), so we must handle all cases
	if (conn == NULL)
		return SUCCEED;

	if (conn->dbproc == NULL)
		return SUCCEED;

	Py_BEGIN_ALLOW_THREADS
	rtc = dbcancel(conn->dbproc);
	Py_END_ALLOW_THREADS

	clr_metadata(conn);
	return rtc;
}

/* EOF */
