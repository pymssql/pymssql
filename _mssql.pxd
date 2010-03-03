from sqlfront cimport DBPROCESS, BYTE

cdef struct _mssql_parameter_node:
    _mssql_parameter_node *next
    BYTE                  *value

cdef class MSSQLConnection:

    # class property variables
    cdef bint _connected
    cdef int _rows_affected
    cdef char *_charset

    # class internal variables
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

    cdef void clear_metadata(self)
    cdef convert_db_value(self, BYTE *, int, int)
    cdef BYTE *convert_python_value(self, value, int*, int*)
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
    cdef dict params
    cdef _mssql_parameter_node *params_list

    cdef void _bind(self, value, int, char *, int, int, int)
