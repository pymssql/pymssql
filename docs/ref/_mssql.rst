===========================
``_mssql`` module reference
===========================

.. py:module:: _mssql

Complete documentation of ``_mssql`` module classes, methods and properties.

``_mssql`` module properties
============================

.. py:data:: login_timeout

    Timeout for connection and login in seconds, default 60.

.. py:data:: min_error_severity

   Minimum severity of errors at which to begin raising exceptions. The default
   value of 6 should be appropriate in most cases.

``_mssql`` module methods
=========================

.. py:function:: set_max_connections(number)

    Sets maximum number of simultaneous connections allowed to be open at any
    given time. Default is 25.

.. py:function:: get_max_connections()

    Gets current maximum number of simultaneous connections allowed to be open
    at any given time.

``MSSQLConnection`` class
=========================

.. py:class:: MSSQLConnection

    This class represents an MS SQL database connection. You can make queries
    and obtain results through a database connection.

    You can create an instance of this class by calling constructor
    :func:`_mssql.connect()`. It accepts the following arguments. Note that you
    can use keyword arguments, instead of positional arguments.

    :param str server: Database server and instance you want to connect to.
                       Valid examples are:

                       * ``r'.\SQLEXPRESS'`` -- SQLEXPRESS instance on local machine (Windows only)
                       * ``r'(local)\SQLEXPRESS'`` -- Same as above (Windows only)
                       * ``'SQLHOST'`` -- Default instance at default port (Windows only)
                       * ``'SQLHOST'`` -- Specific instance at specific port set up in freetds.conf (Linux/\*nix only)
                       * ``'SQLHOST,1433'`` -- Specified TCP port at specified host
                       * ``'SQLHOST:1433'`` -- The same as above
                       * ``'SQLHOST,5000'`` -- If you have set up an instance to listen on port 5000
                       * ``'SQLHOST:5000'`` -- The same as above

    :param str user: Database user to connect as

    :param str password: User's password

    :param bool trusted: Bolean value signalling whether to use Windows
                         Integrated Authentication to connect instead of SQL
                         autentication with user and password (Windows only)

    :param str charset: Character set name to set for the connection.

    :param str database: The database you want initially to connect to, by
                         default *SQL Server* selects the database which is set as
                         default for specific user

``MSSQLConnection`` object properties
-------------------------------------

.. py:attribute:: MSSQLConnection.connected

   True if the connection object has an open connection to a database, false
   otherwise.

.. py:attribute:: MSSQLConnection.charset

   Character set name that was passed to _mssql.connect().

.. py:attribute:: MSSQLConnection.identity

   Returns identity value of last inserted row. If previous operation did not
   involve inserting a row into a table with identity column, None is returned.
   Example usage -- assume that persons table contains an identity column in
   addition to name column::

       conn.execute_non_query("INSERT INTO persons (name) VALUES('John Doe')")
       print "Last inserted row has id = " + conn.identity

.. py:attribute:: MSSQLConnection.query_timeout

   Query timeout in seconds, default is 0, what means to wait indefinitely for
   results. Due to the way DB-Library for C works, setting this property affects
   all connections opened from current Python script (or, very technically, all
   connections made from this instance of dbinit()).

.. py:attribute:: MSSQLConnection.rows_affected

   Number of rows affected by last query. For SELECT statements this value is
   only meaningful after reading all rows.

.. py:attribute:: MSSQLConnection.debug_queries

   If set to true, all queries are printed to stderr after formatting and
   quoting, just before being sent to *SQL Server*. It may be helpful if you
   suspect problems with formatting or quoting.

.. py:attribute:: MSSQLConnection.tds_version

   The TDS version used by this connection. Can be one of 4.2, 7.0 and 8.0.

``MSSQLConnection`` object methods
----------------------------------

.. py:method:: MSSQLConnection.cancel()

   Cancel all pending results from the last SQL operation. It can be called more
   than one time in a row. No exception is raised in this case.

.. py:method:: MSSQLConnection.close()

   Close the connection and free all memory used. It can be called more than one
   time in a row. No exception is raised in this case.

.. py:method:: MSSQLConnection.execute_query(query_string)
               MSSQLConnection.execute_query(query_string, params)

   This method sends a query to the *MS SQL Server* to which this object
   instance is connected. An exception is raised on failure. If there are
   pending results or rows prior to executing this command, they are silently
   discarded. After calling this method you may iterate over the connection
   object to get rows returned by the query. You can use Python formatting and
   all values get properly quoted. Please see examples for details. This method
   is intented to be used on queries that return results, i.e. ``SELECT.``

.. py:method:: MSSQLConnection.execute_non_query(query_string)
    execute_non_query(query_string, params)

   This method sends a query to the *MS SQL Server* to which this object instance
   is connected. After completion, its results (if any) are discarded. An
   exception is raised on failure. If there are pending results or rows prior to
   executing this command, they are silently discarded. You can use Python
   formatting and all values get properly quoted. Please see examples for
   details. This method is useful for ``INSERT``, ``UPDATE``, ``DELETE``, and
   for Data Definition Language commands, i.e. when you need to alter your
   database schema.

.. py:method:: MSSQLConnection.execute_scalar(query_string)
               MSSQLConnection.execute_scalar(query_string, params)

   This method sends a query to the *MS SQL Server* to which this object instance
   is connected, then returns first column of first row from result. An
   exception is raised on failure. If there are pending results or rows prior to
   executing this command, they are silently discarded. You can use Python
   formatting and all values get properly quoted. Please see examples for
   details. This method is useful if you want just a single value from a query,
   as in the example below. This method works in the same way as
   ``iter(conn).next()[0]``. Remaining rows, if any, can still be iterated after
   calling this method. Example usage::

       count = conn.execute_scalar("SELECT COUNT(*) FROM employees")

.. py:method:: MSSQLConnection.execute_row(query_string)
               MSSQLConnection.execute_row(query_string, params)

   This method sends a query to the *MS SQL Server* to which this object
   instance is connected, then returns first row of data from result. An
   exception is raised on failure. If there are pending results or rows prior to
   executing this command, they are silently discarded. You can use Python
   formatting and all values get properly quoted. Please see examples for
   details. This method is useful if you want just a single row and don't want
   or don't need to iterate over the connection object. This method works in the
   same way as ``iter(conn).next()`` to obtain single row. Remaining rows, if
   any, can still be iterated after calling this method. Example usage::

       empinfo = conn.execute_row("SELECT * FROM employees WHERE empid=10")

.. py:method:: MSSQLConnection.get_header()

   This method is infrastructure and don't need to be called by your code. It
   gets the Python DB-API compliant header information. Returns a list of
   7-element tuples describing current result header. Only name and DB-API
   compliant type is filled, rest of the data is ``None``, as permitted by the
   specs.

.. py:method:: MSSQLConnection.init_procedure(name)

   Create an MSSQLStoredProcedure object that will be used to invoke stored
   procedure with given name.

.. py:method:: MSSQLConnection.nextresult()

   Move to the next result, skipping all pending rows. This method fetches and
   discards any rows remaining from current operation, then it advances to next
   result (if any). Returns ``True`` value if next set is available, ``None``
   otherwise. An exception is raised on failure.

.. py:method:: MSSQLConnection.select_db(dbname)

   This function makes given database the current one. An exception is raised on
   failure.

.. py:method:: MSSQLConnection.__iter__()
               MSSQLConnection.next()

   These methods faciliate Python iterator protocol. You most likely will not
   call them directly, but indirectly by using iterators.

``MSSQLStoredProcedure`` class
==============================

.. py:class:: MSSQLStoredProcedure

    This class represents a stored procedure. You create an object of this class
    by calling :meth:`~MSSQLConnection.init_procedure()` method on
    :class:`MSSQLConnection` object.

``MSSQLStoredProcedure`` object properties
------------------------------------------

.. py:attribute:: MSSQLStoredProcedure.connection

   An underlying MSSQLConnection object.

.. py:attribute:: MSSQLStoredProcedure.name

   The name of the procedure that this object represents.

.. py:attribute:: MSSQLStoredProcedure.parameters

   The parameters that have been bound to this procedure.

``MSSQLStoredProcedure`` object methods
---------------------------------------

.. py:method:: MSSQLStoredProcedure.bind(value, dbtype, name=None, \
                                        output=False, null=False, max_length=-1)

   This method binds a parameter to the stored procedure. *value* and *dbtype*
   are mandatory arguments, the rest is optional.

   :param value: Is the value to store in the parameter

   :param dbtype: Is one of: ``SQLBINARY``, ``SQLBIT``, ``SQLBITN``,
                  ``SQLCHAR``, ``SQLDATETIME``, ``SQLDATETIM4``,
                  ``SQLDATETIMN``, ``SQLDECIMAL``, ``SQLFLT4``, ``SQLFLT8``,
                  ``SQLFLTN``, ``SQLIMAGE``, ``SQLINT1``, ``SQLINT2``,
                  ``SQLINT4``, ``SQLINT8``, ``SQLINTN``, ``SQLMONEY``,
                  ``SQLMONEY4``, ``SQLMONEYN``, ``SQLNUMERIC``, ``SQLREAL``,
                  ``SQLTEXT``, ``SQLVARBINARY``, ``SQLVARCHAR``, ``SQLUUID``

   :param name: Is the name of the parameter

   :param output: Is the direction of the parameter: ``True`` indicates that it
                   is also an output parameter that returns value after
                   procedure execution

   :param null: TBD

   :param max_length: Is the maximum data length for this parameter to be
                      returned from the stored procedure.

.. py:method:: MSSQLStoredProcedure.execute()

   Execute the stored procedure.

``_mssql`` module exceptions
============================

Exception hierarchy::

    MSSQLException
    |
    +-- MSSQLDriverException
    |
    +-- MSSQLDatabaseException

.. py:exception:: MSSQLDriverException

   ``MSSQLDriverException`` is raised whenever there is a problem within
   ``_mssql`` -- e.g. insufficient memory for data structures, and so on.

.. py:exception:: MSSQLDatabaseException

    ``MSSQLDatabaseException`` is raised whenever there is a problem with the
    database -- e.g. query syntax error, invalid object name and so on. In this
    case you can use the following properties to access details of the error:

   .. py:attribute:: MSSQLDatabaseException.number

      The error code, as returned by *SQL Server*.

   .. py:attribute:: MSSQLDatabaseException.severity

      The so-called severity level, as returned by *SQL Server*. If value of this
      property is less than the value of :ref:`_mssql.min_error_severity`, such
      errors are ignored and exceptions are not raised.

   .. py:attribute:: MSSQLDatabaseException.state

      The third error code, as returned by *SQL Server*.

   .. py:attribute:: MSSQLDatabaseException.message

      The error message, as returned by *SQL Server*.

You can find an example of how to use this data at the bottom of :doc:`_mssql
examples page </_mssql_examples>`.
