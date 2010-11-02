from cpython cimport bool
from sqlfront cimport DBPROCESS, BYTE

cdef void log(char *, ...)

cdef struct _mssql_parameter_node:
    _mssql_parameter_node *next
    BYTE                  *value

cdef class MSSQLConnection:

    # class property variables
    cdef bint _connected
    cdef int _rows_affected
    cdef int _query_timeout
    cdef char *_charset

    # class internal variables
    cdef DBPROCESS *dbproc
    cdef int last_msg_no
    cdef int last_msg_severity
    cdef int last_msg_state
    cdef int last_msg_line
    cdef int last_dbresults
    cdef int num_columns
    cdef int debug_queries
    cdef char *last_msg_str
    cdef char *last_msg_srv
    cdef char *last_msg_proc
    cdef tuple column_names
    cdef tuple column_types

    cpdef cancel(self)
    cdef void clear_metadata(self)
    cdef object convert_db_value(self, BYTE *, int, int)
    cdef int convert_python_value(self, object value, BYTE **, int*, int*) except -1
    cpdef execute_query(self, query, params=?)
    cpdef execute_non_query(self, query, params=?)
    cpdef execute_row(self, query, params=?)
    cpdef execute_scalar(self, query, params=?)
    cdef fetch_next_row(self, int)
    cdef fetch_next_row_dict(self, int)
    cdef format_and_run_query(self, query_string, params=?)
    cdef format_sql_command(self, format, params=?)
    cdef get_result(self)
    cdef get_row(self, int)

cdef class MSSQLRowIterator:
    cdef MSSQLConnection conn

cdef class MSSQLStoredProcedure:
    cdef MSSQLConnection conn
    cdef DBPROCESS *dbproc
    cdef char *procname
    cdef int param_count
    cdef bool had_positional
    cdef list output_indexes
    cdef dict params
    cdef _mssql_parameter_node *params_list
