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

    # TODO:
    char * dbname(DBPROCESS *)
    void dbexit()
    
    DBBOOL DBDEAD(DBPROCESS *)
    RETCODE DBSETLAPP(LOGINREC *x, char *y)
    RETCODE DBSETLHOST(LOGINREC *x, char *y)
    RETCODE DBSETLPWD(LOGINREC *x, char *y)
    RETCODE DBSETLUSER(LOGINREC *x, char *y)
    RETCODE DBSETLCHARSET(LOGINREC *x, char *y)
    
    BYTE * dbgetuserdata(DBPROCESS *)
#	complex double __builtin_csinh(complex double)
    int DBNUMORDERS(DBPROCESS *)
#	complex long double __builtin_csinl(complex long double)
    DBBOOL bcp_getl(LOGINREC *)
#	complex float __builtin_csinf(complex float)
    RETCODE dbmny4minus(DBPROCESS *, DBMONEY4 *, DBMONEY4 *)
#	complex float __builtin_cpowf(complex float, complex float)
    ctypedef void DBSORTORDER
    DBSORTORDER * dbloadsort(DBPROCESS *)
    RETCODE dbreginit(DBPROCESS *, DBCHAR *, DBSMALLINT)
#	complex long double __builtin_ccosl(complex long double)
#	complex double __builtin_ccosh(complex double)
    DBBOOL db12hour(DBPROCESS *, char *)
#	complex float __builtin_ccosf(complex float)
    RETCODE dbregnowatch(DBPROCESS *, DBCHAR *, DBSMALLINT)
    RETCODE dbbind(DBPROCESS *, int, int, DBINT, BYTE *)
    int dbiowdesc(DBPROCESS *)
    RETCODE dbmnyndigit(DBPROCESS *, DBMONEY *, DBCHAR *, DBBOOL *)
    RETCODE bcp_colfmt(DBPROCESS *, int, int, int, DBINT, BYTE *, int, int)
    RETCODE bcp_writefmt(DBPROCESS *, char *)
    RETCODE dbsafestr(DBPROCESS *, char *, DBINT, char *, DBINT, int)
    float __builtin_fabsf(float)
    DBBINARY * dbtxtimestamp(DBPROCESS *, int)
    long double __builtin_fabsl(long double)
    RETCODE dbmny4sub(DBPROCESS *, DBMONEY4 *, DBMONEY4 *, DBMONEY4 *)
    RETCODE dbmnymaxpos(DBPROCESS *, DBMONEY *)
    RETCODE dbnpcreate(DBPROCESS *)
    RETCODE dbaltutype(DBPROCESS *, int, int)
    DBBOOL dbcharsetconv(DBPROCESS *)
    RETCODE dbmnysub(DBPROCESS *, DBMONEY *, DBMONEY *, DBMONEY *)

    RETCODE dbmnycopy(DBPROCESS *, DBMONEY *, DBMONEY *)
    RETCODE dbsetopt(DBPROCESS *, int, char *, int)
    char * dbcolname(DBPROCESS *, int)
    bool __builtin_isinf()
#	complex long double __builtin_cexpl(complex long double)
    char * dbgetchar(DBPROCESS *, int)
    int dbstrsort(DBPROCESS *, char *, int, char *, int, DBSORTORDER *)
#	complex float __builtin_cexpf(complex float)
    
    RETCODE dbcursorcolinfo(DBCURSOR *, DBINT, DBCHAR *, DBINT *, DBINT *, DBINT *)
    RETCODE dbregdrop(DBPROCESS *, DBCHAR *, DBSMALLINT)
#	complex double __builtin_cexp(complex double)
    DBINT dbvarylen(DBPROCESS *, int)
    int dbgetpacket(DBPROCESS *)
    bool __builtin_islessequal()
#	double __builtin_carg(complex double)
    void dbprhead(DBPROCESS *)
    void __builtin_return(void *)
    int dbiordesc(DBPROCESS *)
    RETCODE bcp_collen(DBPROCESS *, DBINT, int)
    DBINT dbcurrow(DBPROCESS *)
    double __builtin_tan(double)
    RETCODE dbsetlversion(LOGINREC *, BYTE)
    ctypedef short unsigned int USHORT
    DBCURSOR * dbcursoropen(DBPROCESS *, BYTE *, SHORT, SHORT, USHORT, DBINT *)
    ctypedef void DBXLATE
    RETCODE dbload_xlate(DBPROCESS *, char *, char *, DBXLATE * *, DBXLATE * *)
    RETCODE dbmnydigit(DBPROCESS *, DBMONEY *, DBCHAR *, DBBOOL *)
    float __builtin_acosf(float)
    RETCODE dbmny4add(DBPROCESS *, DBMONEY4 *, DBMONEY4 *, DBMONEY4 *)
    cdef struct dbtypeinfo:
        DBINT precision
        DBINT scale
    ctypedef dbtypeinfo DBTYPEINFO
    RETCODE bcp_colfmt_ps(DBPROCESS *, int, int, int, DBINT, BYTE *, int, int, DBTYPEINFO *)
    DBINT dbdatepart(DBPROCESS *, int, DBDATETIME *)
    ctypedef int STATUS
    STATUS dbsetrow(DBPROCESS *, DBINT)
    long double __builtin_logl(long double)
    RETCODE dbaltlen(DBPROCESS *, int, int)
    bool __builtin_isgreater()
    RETCODE dbgetrow(DBPROCESS *, DBINT)
    double __builtin_ldexp(double, int)
    DBBOOL DRBUF(DBPROCESS *)
    DBBINARY * dbtxptr(DBPROCESS *, int)
    STATUS dbrowtype(DBPROCESS *)
    int dbspid(DBPROCESS *)
    RETCODE remove_xact(DBPROCESS *, DBINT, int)
    RETCODE dbsqlsend(DBPROCESS *)
    void dbclrbuf(DBPROCESS *, DBINT)
    double __builtin_cos(double)
    RETCODE dbnpdefine(DBPROCESS *, DBCHAR *, DBSMALLINT)
    float __builtin_asinf(float)
    float __builtin_ldexpf(float, int)
    long double __builtin_ldexpl(long double, int)
    void close_commit(DBPROCESS *)
    float __builtin_expf(float)
    bool __builtin_islessgreater()
    void dbsetavail(DBPROCESS *)
    long double __builtin_expl(long double)
    RETCODE bcp_colptr(DBPROCESS *, BYTE *, int)
    RETCODE bcp_init(DBPROCESS *, char *, char *, char *, int)
    ctypedef void DBLOGINFO
    RETCODE dbgetloginfo(DBPROCESS *, DBLOGINFO * *)
    RETCODE dbdatechar(DBPROCESS *, char *, int, int)
#	float __builtin_cargf(complex float)
#	long double __builtin_cargl(complex long double)
    char * dbtabsoruce(DBPROCESS *, int, int *)
    DBPROCESS * open_commit(LOGINREC *, char *)
    void * __builtin_frame_address(unsigned int)
    DBBOOL dbwillconvert(int, int)
    float __builtin_modff(float, float *)
    long double __builtin_modfl(long double, long double *)
    int __builtin_popcountl(long int)
    RETCODE dbcursor(DBCURSOR *, DBINT, DBINT, BYTE *, BYTE *)
    float __builtin_ceilf(float)
    RETCODE commit_xact(DBPROCESS *, DBINT)
    long double __builtin_ceill(long double)
    RETCODE dbmnydec(DBPROCESS *, DBMONEY *)
    RETCODE dbregwatchlist(DBPROCESS *)
    float __builtin_inff()
    void dbsetuserdata(DBPROCESS *, BYTE *)
    void dbfreebuf(DBPROCESS *)
    double __builtin_fabs(double)
    long double __builtin_infl()
    void __builtin_prefetch(void *)
    RETCODE dbwritepage(DBPROCESS *, char *, DBINT, DBINT, BYTE *)
    int dbtabcount(DBPROCESS *)
    RETCODE dbfreesort(DBPROCESS *, DBSORTORDER *)
    RETCODE dbstrcpy(DBPROCESS *, int, int, char *)
    DBPROCESS * tdsdbopen(LOGINREC *, char *, int)
    RETCODE dbnullbind(DBPROCESS *, int, DBINT *)
    RETCODE dbcursorinfo(DBCURSOR *, DBINT *, DBINT *)
#	complex long double __builtin_csinhl(complex long double)
    float __builtin_coshf(float)
#	complex float __builtin_csinhf(complex float)
    long double __builtin_coshl(long double)
    float __builtin_powf(float, float)
    RETCODE dbanullbind(DBPROCESS *, int, int, DBINT *)
    ctypedef int(*INTFUNCPTR)(void *)
    RETCODE dbreghandle(DBPROCESS *, DBCHAR *, DBSMALLINT, INTFUNCPTR)
    RETCODE dbregexec(DBPROCESS *, DBUSMALLINT)
    double __builtin_powi(double, int)
    double __builtin_asin(double)
    RETCODE dbdatezero(DBPROCESS *, DBDATETIME *)
    void dbrpwclr(LOGINREC *)
    STATUS dbreadtext(DBPROCESS *, void *, DBINT)
    int dbnumcompute(DBPROCESS *)
    double __builtin_atan2(double, double)
    RETCODE bcp_readfmt(DBPROCESS *, char *)
    bool __builtin_isgreaterequal()
    void * __builtin_memchr(void *, int, unsigned int)
    RETCODE dbrows(DBPROCESS *)
    DBBOOL dbtabbrowse(DBPROCESS *, int)
    bool __builtin_isnormal()
    RETCODE dbmnyscale(DBPROCESS *, DBMONEY *, int, int)
    float __builtin_atanf(float)
#	complex double __builtin_clog(complex double)
    double __builtin_log(double)
    long double __builtin_atanl(long double)
    long double __builtin_log10l(long double)
    char * dateorder(DBPROCESS *, char *)
    float __builtin_log10f(float)
    RETCODE dbmny4divide(DBPROCESS *, DBMONEY4 *, DBMONEY4 *, DBMONEY4 *)
    double __builtin_atan(double)
    RETCODE dbsetnull(DBPROCESS *, int, int, BYTE *)
    long double __builtin_powl(long double, long double)
    long double __builtin_sinhl(long double)
    float __builtin_powif(float, int)
    float __builtin_sinhf(float)
    long double __builtin_powil(long double, int)
    ctypedef void * DBVOIDPTR
    RETCODE dbsendpassthru(DBPROCESS *, DBVOIDPTR)
    char * dbdayname(DBPROCESS *, char *, int)
#	complex double __builtin_ctan(complex double)
    RETCODE dbcursorbind(DBCURSOR *, int, int, DBINT, DBINT *, BYTE *, DBTYPEINFO *)
    DBINT dbspr1rowlen(DBPROCESS *)
    int dbtsnewlen(DBPROCESS *)
    RETCODE dbfree_xlate(DBPROCESS *, DBXLATE *, DBXLATE *)
    RETCODE dbmnyadd(DBPROCESS *, DBMONEY *, DBMONEY *, DBMONEY *)
    int dbcurcmd(DBPROCESS *)
    int dbxlate(DBPROCESS *, char *, int, char *, int, DBXLATE *, int *, DBBOOL, int)
    long double __builtin_nansl(char *)
    void * __builtin_return_address(unsigned int)
    RETCODE dbmny4mul(DBPROCESS *, DBMONEY4 *, DBMONEY4 *, DBMONEY4 *)
    float __builtin_cosf(float)
    RETCODE dbcanquery(DBPROCESS *)
    RETCODE dbmnyzero(DBPROCESS *, DBMONEY *)
    double __builtin_cosh(double)
    long double __builtin_cosl(long double)
    DBBOOL dbisopt(DBPROCESS *, int, char *)
    RETCODE dbsetllong(LOGINREC *, long int, int)
    RETCODE dbsetversion(DBINT)
    RETCODE dbmnydown(DBPROCESS *, DBMONEY *, int, int *)
    RETCODE dbmnydivide(DBPROCESS *, DBMONEY *, DBMONEY *, DBMONEY *)
#	complex long double __builtin_cpowl(complex long double, complex long double)
    double __builtin_inf()
    int __builtin_ctzl(long int)
    int __builtin_popcountll(long long int)
    RETCODE dbtxtsput(DBPROCESS *, DBBINARY, int)
    double __builtin_log10(double)
    void dbfreequal(char *)
    double __builtin_exp(double)
    RETCODE dbregparam(DBPROCESS *, char *, int, DBINT, BYTE *)
    long double __builtin_acosl(long double)
    RETCODE bcp_batch(DBPROCESS *)
    DBTYPEINFO * dbcoltypeinfo(DBPROCESS *, int)
    int __builtin_ctzll(long long int)
    int dbgetlusername(LOGINREC *, BYTE *, int)
    char * dbtabname(DBPROCESS *, int)
    char * dbprtype(int)
#	complex float __builtin_ctanhf(complex float)
#	complex long double __builtin_ctanhl(complex long double)
    ctypedef int(*DBWAITFUNC)()
    ctypedef void(*DB_DBIDLE_FUNC)(DBWAITFUNC, void *)
    void dbsetidle(DBPROCESS *, DB_DBIDLE_FUNC)
    DBINT start_xact(DBPROCESS *, char *, char *, int)
    long double __builtin_atan2l(long double, long double)
    float __builtin_atan2f(float, float)
    int dbmny4cmp(DBPROCESS *, DBMONEY4 *, DBMONEY4 *)
    double __builtin_floor(double)
    DBBOOL dbcolbrowse(DBPROCESS *, int)
    double __builtin_acos(double)
    void dbsetifile(char *)
#	complex long double __builtin_csqrtl(complex long double)
    RETCODE dbpoll(DBPROCESS *, long int, DBPROCESS * *, int *)
    RETCODE dbmnyminus(DBPROCESS *, DBMONEY *, DBMONEY *)
#	complex float __builtin_csqrtf(complex float)
    RETCODE bcp_done(DBPROCESS *)
#	complex double __builtin_ccos(complex double)
    RETCODE bcp_control(DBPROCESS *, int, DBINT)
    RETCODE dbmny4zero(DBPROCESS *, DBMONEY4 *)
    RETCODE dbsetdeflang(char *)
#	complex double __builtin_csqrt(complex double)
#	complex double __builtin_cpow(complex double, complex double)
#	double __builtin_cabs(complex double)
    RETCODE dbtsput(DBPROCESS *, DBBINARY *, int, int, char *)
    int dbaltcolid(DBPROCESS *, int, int)
    long int __builtin_expect(long int, long int)
#	complex float __builtin_ctanf(complex float)
#	complex double __builtin_ctanh(complex double)
#	complex long double __builtin_ctanl(complex long double)
    char * dbmonthname(DBPROCESS *, char *, int, DBBOOL)
    int dbnumalts(DBPROCESS *, int)
    RETCODE dbbind_ps(DBPROCESS *, int, int, DBINT, BYTE *, DBTYPEINFO *)
    float __builtin_floorf(float)
    DBBINARY * dbtsnewval(DBPROCESS *)
    long double __builtin_floorl(long double)
    char * dbqual(DBPROCESS *, int, char *)
    RETCODE dbdate4zero(DBPROCESS *, DBDATETIME4 *)
    char * dbgetnatlanf(DBPROCESS *)
    RETCODE dbmnyinit(DBPROCESS *, DBMONEY *, int, DBBOOL *)
    double __builtin_frexp(double, int *)
    ctypedef DBWAITFUNC(*DB_DBBUSY_FUNC)(void *)
    void dbsetbusy(DBPROCESS *, DB_DBBUSY_FUNC)
    int dbgettime()
    RETCODE bcp_bind(DBPROCESS *, BYTE *, int, DBINT, BYTE *, int, int, int)
    ctypedef unsigned char DBTINYINT
    RETCODE dbwritetext(DBPROCESS *, char *, DBBINARY *, DBTINYINT, DBBINARY *, DBBOOL, DBINT, BYTE *)
    ctypedef int(*DB_DBCHKINTR_FUNC)(void *)
    ctypedef int(*DB_DBHNDLINTR_FUNC)(void *)
    void dbsetinterrupt(DBPROCESS *, DB_DBCHKINTR_FUNC, DB_DBHNDLINTR_FUNC)
    char * dbcolsource(DBPROCESS *, int)
    RETCODE dbcmdrow(DBPROCESS *)
    RETCODE bcp_sendrow(DBPROCESS *)
    double __builtin_sin(double)
    DBINT dbreadpage(DBPROCESS *, char *, DBINT, BYTE *)
    int dbordercol(DBPROCESS *, int)
    bool __builtin_isless()
    RETCODE dbsetlshort(LOGINREC *, int, int)
    RETCODE abort_xact(DBPROCESS *, DBINT)
    bool __builtin_isnan()
    RETCODE dbrecvpassthru(DBPROCESS *, DBVOIDPTR *)
    RETCODE dbmnymul(DBPROCESS *, DBMONEY *, DBMONEY *, DBMONEY *)
    RETCODE dbmnyinc(DBPROCESS *, DBMONEY *)

    DBINT dbconvert_ps(DBPROCESS *, int, BYTE *, DBINT, int, BYTE *, DBINT, DBTYPEINFO *)
    RETCODE dbsprhead(DBPROCESS *, char *, DBINT)
    DBINT dbcolutype(DBPROCESS *, int)
    DBINT stat_xact(DBPROCESS *, DBINT)
    RETCODE dbaltbind(DBPROCESS *, int, int, int, DBINT, BYTE *)
    RETCODE dbreglist(DBPROCESS *)
    int bcp_getbatchsize(DBPROCESS *)
    float __builtin_tanhf(float)
    long double __builtin_tanhl(long double)
    int __builtin_popcount(int)
    int dbstrbuild(DBPROCESS *, char *, int, char *, char *)
    RETCODE scan_xact(DBPROCESS *, DBINT)
    RETCODE dbspr1row(DBPROCESS *, char *, DBINT)
    RETCODE bcp_options(DBPROCESS *, int, BYTE *, int)
    RETCODE dbmoretext(DBPROCESS *, DBINT, BYTE *)
    RETCODE dbcursorfetch(DBCURSOR *, DBINT, DBINT)
    char * dbgetcharset(DBPROCESS *)
#	complex double __builtin_csin(complex double)
    DBINT dbtextsize(DBPROCESS *)
    void build_xact_string(char *, char *, DBINT, char *)
    DBBINARY * dbtxtsnewval(DBPROCESS *)
    float __builtin_tanf(float)
    double __builtin_tanh(double)
    long double __builtin_tanl(long double)
#	complex float __builtin_clogf(complex float)
#	complex long double __builtin_clogl(complex long double)
    double __builtin_sqrt(double)
    bool __builtin_isunordered()
    float __builtin_nansf(char *)
    RETCODE bcp_exec(DBPROCESS *, DBINT *)
    RETCODE dbclropt(DBPROCESS *, int, char *)
    float __builtin_sinf(float)
    RETCODE * dbsechandle(DBINT, INTFUNCPTR)
    long double __builtin_sinl(long double)
    bool __builtin_isfinite()
    double __builtin_sinh(double)
#	long double __builtin_cabsl(complex long double)
    void dbcursorclose(DBCURSOR *)
#	float __builtin_cabsf(complex float)
    BYTE * dbbylist(DBPROCESS *, int, int *)
    RETCODE dbresults_r(DBPROCESS *, int)
    RETCODE dbdatecmp(DBPROCESS *, DBDATETIME *, DBDATETIME *)
    void dbrecftos(char *)
    DBBOOL dbisavail(DBPROCESS *)
    cdef enum:
        CI_REGULAR = 1
    cdef enum:
        CI_ALTERNATE = 2
    cdef enum:
        CI_CURSOR = 3
    cdef enum CI_TYPE:
        CI_REGULAR = 1
        CI_ALTERNATE = 2
        CI_CURSOR = 3
    RETCODE dbcolinfo(DBPROCESS *, int, DBINT, DBINT, DBCOL *)
    int dbdatename(DBPROCESS *, char *, int, DBDATETIME *)
    int __builtin_ctz(int)
    int dbmnycmp(DBPROCESS *, DBMONEY *, DBMONEY *)
    RETCODE dbsetlname(LOGINREC *, char *, int)
    DBINT dblastrow(DBPROCESS *)
    RETCODE dbmorecmds(DBPROCESS *)
    long double __builtin_asinl(long double)
    RETCODE bcp_moretext(DBPROCESS *, DBINT, BYTE *)
    char * dbservcharset(DBPROCESS *)
    RETCODE dbsetlbool(LOGINREC *, int, int)
    RETCODE dbaltbind_ps(DBPROCESS *, int, int, int, DBINT, BYTE *, DBTYPEINFO *)
    RETCODE dbprrow(DBPROCESS *)
    char * dbchange(DBPROCESS *)
    long double __builtin_sqrtl(long double)
    double __builtin_nans(char *)
    int dbgetoff(DBPROCESS *, DBUSMALLINT, int)
    float __builtin_sqrtf(float)
    RETCODE dbmnymaxneg(DBPROCESS *, DBMONEY *)
    int dbbufsize(DBPROCESS *)
    DBINT dbfirstrow(DBPROCESS *)
    RETCODE dbsetloginfo(LOGINREC *, DBLOGINFO *)
    RETCODE dbmny4copy(DBPROCESS *, DBMONEY4 *, DBMONEY4 *)
    char * dbversion()
    DBINT dbcollen(DBPROCESS *, int)
    RETCODE dbtablecolinfo(DBPROCESS *, DBINT, DBCOL *)
    RETCODE dbrpwset(LOGINREC *, char *, char *, int)
    float __builtin_frexpf(float, int *)
    long double __builtin_frexpl(long double, int *)
    RETCODE dbfcmd(DBPROCESS *, char *)
    RETCODE dbsprline(DBPROCESS *, char *, DBINT, DBCHAR)
    bool __builtin_va_arg_pack()
    int dbstrcmp(DBPROCESS *, char *, int, char *, int, DBSORTORDER *)
    int dbaltop(DBPROCESS *, int, int)
    RETCODE dbsetdefcharset(char *)
#	complex long double __builtin_ccoshl(complex long double)
#	complex float __builtin_ccoshf(complex float)
    int dbstrlen(DBPROCESS *)
    int dbdate4cmp(DBPROCESS *, DBDATETIME4 *, DBDATETIME4 *)
    RETCODE dbregwatch(DBPROCESS *, DBCHAR *, DBSMALLINT, DBUSMALLINT)
    RETCODE bcp_columns(DBPROCESS *, int)
    double __builtin_ceil(double)
    float __builtin_fmodf(float, float)
    long double __builtin_fmodl(long double, long double)
    int EXCOMM = 9

ctypedef int LINE_T
