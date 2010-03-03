from sqlfront cimport DBPROCESS, BYTE

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
    cdef fetch_next_row_dict(self, int)
    cdef format_and_run_query(self, query_string, params=?)
    cdef get_result(self)
    cdef get_row(self, int)

cdef class MSSQLRowIterator:
    cdef MSSQLConnection conn
