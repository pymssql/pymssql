# Since Cython needs to know what you are using from header files this
# definition is provided so it knows exactly what we are using from
# FreeTDS.

cdef extern from "sqlfront.h":

    ## Type Definitions ##
    cdef struct tds_dblib_dbprocess:
        pass
    cdef struct tds_sysdep_real32_type:
        pass
    cdef struct tds_sysdep_real64_type:
        pass

    ctypedef tds_dblib_dbprocess DBPROCESS
    cdef struct tds_dblib_loginrec:
        pass
    ctypedef tds_dblib_loginrec LOGINREC
    ctypedef void DBCURSOR
    ctypedef int BOOL
    ctypedef short int SHORT
    ctypedef unsigned char BYTE
    ctypedef int RETCODE
    ctypedef short unsigned int DBUSMALLINT

    ctypedef unsigned char DBBINARY
    ctypedef int           DBBIT
    ctypedef unsigned char DBBOOL
    ctypedef char          DBCHAR
    ctypedef int           DBINT
    ctypedef tds_sysdep_real32_type DBREAL
    ctypedef tds_sysdep_real64_type DBFLT8
    cdef struct            DBMONEY:
        DBINT mnyhigh
        unsigned int mnylow
    cdef struct            DBMONEY4:
        DBINT mny4
    ctypedef unsigned char DBTINYINT
    ctypedef short int     DBSMALLINT

    ctypedef struct        DBDATETIME:
        DBINT dtdays
        DBINT dttime
    ctypedef struct        DBDATETIME4:
        DBUSMALLINT days
        DBUSMALLINT minutes

    ctypedef struct        DBCOL:
        DBINT SizeOfStruct
        DBCHAR * Name
        DBCHAR * ActualName
        DBCHAR * TableName
        SHORT Type
        DBINT UserType
        DBINT MaxLength
        BYTE Precision
        BYTE Scale
        BOOL VarLength
        BYTE Null
        BYTE CaseSensitive
        BYTE Updatable
        BOOL Identity

    ctypedef struct            DBDATEREC:
        DBINT year
        DBINT month
        DBINT day
        DBINT dayofyear
        DBINT weekday
        DBINT hour
        DBINT minute
        DBINT second
        DBINT millisecond
        DBINT tzone

    # Error handler callback
    ctypedef int(*EHANDLEFUNC)(DBPROCESS *, int, int, int, char *, char *)

    # Message handler callback
    ctypedef int(*MHANDLEFUNC)(DBPROCESS *, DBINT, int, int, char *, char *, char *, int)

    ## Constants ##
    int FAIL
    int SUCCEED
    int INT_CANCEL
    int NO_MORE_ROWS
    int NO_MORE_RESULTS
    int REG_ROW
    int DBNOERR
    int DBRPCRETURN

    int CI_ALTERNATE
    int CI_CURSOR
    int CI_REGULAR
    int MAXCOLNAMELEN

    ## Version Constants ##
    int DBVERSION_42
    int DBVERSION_70
    int DBVERSION_71
    int DBVERSION_72
    int DBVERSION_80

    ## Type Constants ##
    cdef enum:
        SYBBINARY
        SYBBIT
        SYBCHAR
        SYBDATETIME
        SYBDATETIME4
        SYBDATETIMN
        SYBDECIMAL
        SYBFLT8
        SYBFLTN
        SYBIMAGE
        SYBINT1
        SYBINT2
        SYBINT4
        SYBINT8
        SYBINTN
        SYBMONEY
        SYBMONEY4
        SYBMONEYN
        SYBNUMERIC
        SYBREAL
        SYBTEXT
        SYBVARBINARY
        SYBVARCHAR

    ## Primary functions ##
    # Get address of compute column data.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #     computeid of COMPUTE clause to which we're referring.
    #     column    Nth column in computeid, starting from 1.
    #
    #   Returns:
    #     pointer to columns' data buffer.
    #
    #   Return values:
    #     NULL no such compute id or column.
    BYTE * dbadata(DBPROCESS *, int, int) nogil

    # Get address of compute column data.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #     computeid of COMPUTE clause to which we're referring.
    #     column    Nth column in computeid, starting from 1.
    #
    #   Returns:
    #     size of the data, in bytes
    #
    #   Return values:
    #     -1 no such column or computeid.
    #      0 data is NULL.
    DBINT dbadlen(DBPROCESS *, int, int) nogil

    # Get datatype for a compute column data.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #     computeid of COMPUTE clause to which we're referring.
    #     column    Nth column in computeid, starting from 1.
    #
    #   Returns:
    #     SYB* datatype token
    #
    #   Return values:
    #     -1 no such column or computeid.
    int dbalttype(DBPROCESS *, int, int) nogil

    # Cancel the current command batch
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #
    #   Returns:
    #     SUCCEED always
    RETCODE dbcancel(DBPROCESS *) nogil

    # Close a connection to the server and free associated resources.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    void dbclose(DBPROCESS *) nogil

    # Close a connection to the server and free associated resources.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #     cmdstring SQL to append to the command buffer.
    #
    #   Returns:
    #     SUCCEED   success
    #     FAIL      insufficient memory
    RETCODE dbcmd(DBPROCESS *, char *)

    # Return name of a regular result column.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #     column    Nth in the result set, starting with 1.
    #
    #   Returns:
    #     pointer to ASCII null-terminated string, the name of the column.
    #
    #   Return values:
    #     NULL      column is not in range.
    char * dbcolname(DBPROCESS *, int)

    # Get the datatype of a regular result set column.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #     column    Nth column in computeid, starting from 1.
    #
    #   Returns:
    #     SYB* datatype token value, or zero if column is out of range.
    int dbcoltype(DBPROCESS *, int) nogil

    # Convert one datatype to another.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #     srctype   datatype of the data to convert
    #     src       buffer to convert
    #     srclen    length of src
    #     desttype  target datatype
    #     dest      output buffer
    #     destlen   size of dest
    #
    #   Returns:
    #     On success, the count of output bytes in dest, else -1. On
    #     failure, it will call any user-supplied error handler.
    DBINT dbconvert(DBPROCESS *, int, BYTE *, DBINT, int, BYTE *, DBINT)


    # Get count of rows processed.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #   Returns:
    #     * for insert/update/delete, count of rows affected.
    #     * for select, count of rows returned, after all rows have been
    #       fetched.
    DBINT dbcount(DBPROCESS *) nogil

    # Check if dbproc is an ex-parrot.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #   Returns:
    #     * for insert/update/delete, count of rows affected.
    #     * for select, count of rows returned, after all rows have been
    DBBOOL dbdead(DBPROCESS *)

    # Get address of data in a regular result column.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #     column    Nth column in computeid, starting from 1.
    #
    #   Returns:
    #     pointer to the data, or NULL if data is NULL, or if column is
    #     out of range
    BYTE * dbdata(DBPROCESS *, int) nogil

    # Break a DBDATETIME value into useful pieces.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #     di        output: structure to contain the exploded parts of
    #                       datetime.
    #     datetime  input: DBDATETIME to be converted.
    #
    #   Return values:
    #     SUCCEED always
    RETCODE dbdatecrack(DBPROCESS *, DBDATEREC *, DBDATETIME *)

    # Get size of current row's data in a regular result column.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #     column    Nth column in computeid, starting from 1.
    #
    #   Returns:
    #     size of the data, in bytes
    DBINT dbdatlen(DBPROCESS *, int) nogil

    # Set an error handler, for messages from db-lib.
    #
    #   Parameters:
    #       handler pointer to callback function that will handle errors.
    #               Pass NULL to restore the default handler.
    #
    #   Returns:
    #       address of prior handler, or NULL if none was previously
    #       installed.
    EHANDLEFUNC dberrhandle(EHANDLEFUNC)

    # Close server connections and free all related structures.
    void dbexit()

    # Get maximum simultaneous connections db-lib will open to the server.
    #
    #   Returns:
    #     size of the data, in bytes
    int dbgetmaxprocs()

    # Initialize db-lib
    #
    #   Return values:
    #     SUCCEED   normal
    #     FAIL      cannot allocate an array of TDS_MAX_CONN TDSSOCKET
    #               pointers.
    RETCODE dbinit()

    # Allocate a LOGINREC structure.
    #
    #   Return values:
    #     NULL      the LOGINREC cannot be allocated.
    #     LOGINREC* to valid memory
    LOGINREC * dblogin()

    # free the LOGINREC
    void dbloginfree(LOGINREC *)

    # Set a message handler, for messages from the server.
    #
    #   Parameters:
    #       handler address of the function that will process the messages.
    MHANDLEFUNC dbmsghandle(MHANDLEFUNC)

    # Get name of current database.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #
    #   Returns:
    #     current database name, as null-terminated ASCII string.
    char * dbname(DBPROCESS *)

    # Read result row into the row buffer and into any bound host variables.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #
    #   Return values:
    #     REG_ROW   regular row has been read.
    #     BUF_FULL  reading the next row would cause the buffer to be
    #               exceeded. No row was read from the server.
    #
    #   Returns:
    #     computeid when a compute row is read.
    RETCODE dbnextrow(DBPROCESS *) nogil

    # Return number of regular columns in a result set.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #
    #   Returns:
    #     number of columns in the result set row.
    int dbnumcols(DBPROCESS *)

    # Form a connection with the server.
    #
    #   Parameters:
    #     login   LOGINREC* carrying the account information
    #     server  name of the dataserver to connect to
    #
    #   Returns:
    #     value pointer on successful login.
    #
    #   Return values:
    #     NULL insufficient memory, unable to connect for any reason
    DBPROCESS * dbopen(LOGINREC *, char *)

    # Set up query results.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #
    #   Return values:
    #     SUCCEED   some result are available.
    #     FAIL      query was not processed successfully by the server.
    #     NO_MORE_RESULTS   query produced no results.
    RETCODE dbresults(DBPROCESS *) nogil

    # Set maximum seconds db-lib waits for a server response to a login
    # attempt.
    #
    #   Parameters:
    #     seconds   New limit for application.
    #
    #   Returns:
    #     SUCCEED always
    RETCODE dbsetlogintime(int)

    # Set maximum simultaneous connections db-lib will open to the server.
    #
    #   Parameters:
    #     maxprocs  Limit for process.
    #
    #   Returns:
    #     SUCCEED always
    RETCODE dbsetmaxprocs(int)

    # Set maximum seconds db-lib waits for a server response to query.
    #
    #   Parameters:
    #     seconds   New limit for application.
    #
    #   Returns:
    #     SUCCEED always
    RETCODE dbsettime(int)

    # Send the SQL command to the server and wait for an answer.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #
    #   Return values:
    #     SUCCEED   query was processed without errors.
    #     FAIL      was returned by dbsqlsend() or dbsqlok()
    RETCODE dbsqlexec(DBPROCESS *) nogil

    # Wait for results of a query from the server.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #
    #   Return values:
    #     SUCCEED   everything worked, fetch results with dbnextresults().
    #     FAIL      SQL syntax error, typically.
    RETCODE dbsqlok(DBPROCESS *) nogil

    # Get the TDS version in use for dbproc.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #
    #   Returns:
    #     a DBTDS* token.
    #
    #   Remarks:
    #     The integer values of the constants are counterintuitive.
    int dbtds(DBPROCESS *)

    # Change current database
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #     name      database to use.
    #
    #   Return values:
    #     SUCCEED query was processed without errors.
    #     FAIL    query was not processed
    RETCODE dbuse(DBPROCESS *, char *) nogil

    ## End Primary functions ##

    ## Remote Procedure functions ##
    # Determine if query generated a return status number
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #   Return values:
    #     TRUE      fetch return status with dbretstatus().
    #     FALSE     no return status
    DBBOOL dbhasretstat(DBPROCESS *)

    # Get count of output parameters filled by a stored procedure
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #   Returns:
    #     How many, possibly zero.
    int dbnumrets(DBPROCESS *)

    # Get value of an output parameter filled by a stored procedure.
    #
    #   Parameters:
    #     dbproc 	contains all information needed by db-lib to manage
    #               communications with the server.
    #     retnum    Nth parameter between 1 and the return value from
    #               dbnumrets()
    #   Returns:
    #     Address of a return parameter value, or NULL if no such retnum.
    BYTE * dbretdata(DBPROCESS *, int) nogil

    # Get size of an output parameter filled by a stored procedure.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #     retnum    Nth parameter between 1 and the return value from
    #               dbnumrets()
    #   Returns:
    #     Size of a return parameter value, or NULL if no such retnum.
    int dbretlen(DBPROCESS *, int) nogil

    # Get name of an output parameter filled by a stored procedure.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #     retnum    Nth parameter between 1 and the return value from
    #               dbnumrets()
    #   Returns:
    #     ASCII null-terminated string, NULL if no such retnum.
    char * dbretname(DBPROCESS *, int) nogil

    # Fetch status value returned by query or remote procedure call.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #   Returns:
    #     The return value of the rpc call
    DBINT dbretstatus(DBPROCESS *) nogil

    # Get datatype of a stored procedure's return parameter.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #     retnum    Nth parameter between 1 and the return value from
    #               dbnumrets()
    #   Returns:
    #     SYB* datatype token, or -1 if retnum is out of range.
    int dbrettype(DBPROCESS *, int) nogil

    # Initialize a remote procedure call.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #     rpcname   name of the stored procedure to be run.
    #     options   Only supported option would be DBRPCRECOMPILE, which causes
    #               the stored procedure to be recompiled before executing.
    #   Return values:
    #     SUCCEED   normal
    #     FAIL      on error
    RETCODE dbrpcinit(DBPROCESS *, char *, DBSMALLINT) nogil

    # Add a parameter to a remote procedure call.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #     paramname literal name of the parameter, according to the stored
    #               procedure (starts with '@'). Optional. If not used,
    #               parameters will be passed in order instead of by name.
    #     status    must be DBRPCRETURN, if this parameter is a return
    #               parameter, else 0.
    #     type      datatype of the value parameter e.g. SYBINT4, SYBCHAR
    #     maxlen    Maximum output size of the parameter's value to be returned
    #               by the stored procedure, usually the size of your host
    #               variable. Fixed-length datatypes take -1 (NULL or not).
    #               Non-OUTPUT parameters also use -1. Use 0 to send a NULL
    #               value for a variable length datatype.
    #     datalen   For variable-length datatypes, the byte size of the data
    #               to be sent, exclusive of any null terminator. For
    #               fixed-length datatypes use -1. To send a NULL value, use 0.
    #     value     Address of your host variable.
    #
    #   Return values:
    #     SUCCEED   normal
    #     FAIL      on error
    RETCODE dbrpcparam(DBPROCESS *, char *, BYTE, int, DBINT, DBINT, BYTE *) nogil

    # Execute the procedure and free associated memory.
    #
    #   Parameters:
    #     dbproc    contains all information needed by db-lib to manage
    #               communications with the server.
    #   Return values:
    #     SUCCEED   normal
    #     FAIL      on error
    RETCODE dbrpcsend(DBPROCESS *) nogil
    ## End Remote Procedure functions ##

    ## Macros ##
    DBBOOL DBDEAD(DBPROCESS *)
    RETCODE DBSETLAPP(LOGINREC *x, char *y)
    RETCODE DBSETLHOST(LOGINREC *x, char *y)
    RETCODE DBSETLPWD(LOGINREC *x, char *y)
    RETCODE DBSETLUSER(LOGINREC *x, char *y)
    RETCODE DBSETLCHARSET(LOGINREC *x, char *y)
    RETCODE DBSETLVERSION(LOGINREC *login, BYTE version)

ctypedef int LINE_T
