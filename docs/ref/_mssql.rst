===========================
``_mssql`` module reference
===========================

.. module:: _mssql

Complete documentation of ``_mssql`` module classes, methods and properties.

Module-level symbols
====================

.. data:: __version__

   See :data:`pymssql.__version__`.

.. data:: VERSION

   See :data:`pymssql.VERSION`.

   .. versionadded:: 2.2.0

.. data:: __full_version__

   See :data:`pymssql.__full_version__`.

Variables whose values you can change to alter behavior on a global basis:

.. data:: login_timeout

    Timeout for connection and login in seconds, default 60.

.. data:: min_error_severity

   Minimum severity of errors at which to begin raising exceptions. The default
   value of 6 should be appropriate in most cases.

Functions
=========

.. function:: get_dbversion()

    Wrapper around DB-Library's ``dbversion()`` function which returns the
    version of FreeTDS (actually the version of DB-Lib) in string form. E.g.
    ``"freetds v1.2.5"``.

   .. versionadded:: 2.2.0

.. function:: set_max_connections(number)

    Sets maximum number of simultaneous connections allowed to be open at any
    given time. Default is 25.

.. function:: get_max_connections()

    Gets current maximum number of simultaneous connections allowed to be open
    at any given time.

``MSSQLConnection`` class
=========================

.. class:: MSSQLConnection

    This class represents an MS SQL database connection. You can make queries
    and obtain results through a database connection.

    You can create an instance of this class by calling
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

    :param str charset: Character set name to set for the connection.

    :param str database: The database you want to initially to connect to; by
                         default, *SQL Server* selects the database which is set as
                         the default for the specific user

    :param str appname: Set the application name to use for the connection

    :param str port: the TCP port to use to connect to the server

    :param str tds_version: TDS protocol version to ask for. Default value: ``None``

    :param conn_properties: SQL queries to send to the server upon connection
                            establishment. Can be a string or another kind
                            of iterable of strings. Default value:

    .. code-block:: sql

        SET ARITHABORT ON;
        SET CONCAT_NULL_YIELDS_NULL ON;
        SET ANSI_NULLS ON;
        SET ANSI_NULL_DFLT_ON ON;
        SET ANSI_PADDING ON;
        SET ANSI_WARNINGS ON;
        SET ANSI_NULL_DFLT_ON ON;
        SET CURSOR_CLOSE_ON_COMMIT ON;
        SET QUOTED_IDENTIFIER ON;
        SET TEXTSIZE 2147483647; -- http://msdn.microsoft.com/en-us/library/aa259190%28v=sql.80%29.aspx

    .. versionadded:: 2.1.1
        The *conn_properties* parameter.

    .. versionchanged:: 2.1.1
        Before 2.1.1, the initialization queries now specified by
        *conn_properties* wasn't customizable and its value was hard-coded to
        the literal shown above.

    .. note::
        If you need to connect to Azure read the relevant :doc:`topic </azure>`.

    .. versionadded:: 2.1.1
        The ability to connect to Azure.

    .. versionchanged:: 2.2.0
        The default value of the *tds_version* parameter was changed to ``None``.
        Between versions 2.0.0 and  2.1.2 its default value was ``'7.1'``.

    .. warning::
      The *tds_version* parameter has a default value of ``None``. This means two
      things:

      #. You can't rely anymore in the old ``'7.1'`` default value and
      #. Now you'll need to either

        * Specify its value explicitly by passing a value for this parameter or
        * Configure it using facilities provided by FreeTDS (see `here
          <http://www.freetds.org/userguide/freetdsconf.htm#TAB.FREETDS.CONF>`__
          and `here <http://www.freetds.org/userguide/envvar.htm>`__)

      This might look cumbersome but at the same time means you can now fully
      configure the characteristics of a connection to SQL Server when using
      pymssql/_mssql without using a stanza for the server in the
      ``freetds.conf`` file or even with no ``freetds.conf`` at all. Starting
      with pymssql version 2.0.0 and up to version 2.1.2 it was already possible
      to set the TDS protocol version to ask for when connecting to the server
      but version 7.1 was used if not specified.

    .. warning::
      FreeTDS added sopport for TDS protocol version 7.3 in version 0.95. You
      need to be careful of not asking for TDS 7.3 if you know the undelying
      FreeTDS used by pymssql is version 0.91 as it won't raise any error nor
      keep you from passing such an invalid value.

    .. warning::
      FreeTDS added support for TDS protocol version 7.3 in version 0.95. You
      need to be careful of not asking for TDS 7.3 if you know the undelying
      FreeTDS used by pymssql is older as it won't raise any error nor keep you
      from passing such an invalid value.

``MSSQLConnection`` object properties
-------------------------------------

.. attribute:: MSSQLConnection.connected

   ``True`` if the connection object has an open connection to a database,
   ``False`` otherwise.

.. attribute:: MSSQLConnection.charset

   Character set name that was passed to _mssql.connect().

.. attribute:: MSSQLConnection.identity

   Returns identity value of last inserted row. If previous operation did not
   involve inserting a row into a table with identity column, None is returned.
   Example usage -- assume that persons table contains an identity column in
   addition to name column::

       conn.execute_non_query("INSERT INTO persons (name) VALUES('John Doe')")
       print "Last inserted row has id = " + conn.identity

.. attribute:: MSSQLConnection.query_timeout

   Query timeout in seconds, default is 0, which means to wait indefinitely for
   results. Due to the way DB-Library for C works, setting this property affects
   all connections opened from the current Python script (or, very technically, all
   connections made from this instance of dbinit()).

.. attribute:: MSSQLConnection.rows_affected

   Number of rows affected by last query. For SELECT statements this value is
   only meaningful after reading all rows.

.. attribute:: MSSQLConnection.debug_queries

   If set to true, all queries are printed to stderr after formatting and
   quoting, just before being sent to *SQL Server*. It may be helpful if you
   suspect problems with formatting or quoting.

.. attribute:: MSSQLConnection.tds_version

   The TDS version used by this connection. Can be one of ``4.2``, ``5.0``
   ``7.0``, ``7.1``, ``7.2``, ``7.3`` or ``None`` if no TDS version could be
   detected.

   .. versionchanged:: 2.1.4
       For correctness and consistency the value used to indicate TDS 7.1
       changed from ``8.0`` to ``7.1`` on pymssql 2.1.4.

   .. versionchanged:: 2.1.3
      ``7.3`` was added as a possible value.

.. attribute:: MSSQLConnection.tds_version_tuple

   .. versionadded:: 2.2.0

   The TDS version used by this connection in tuple form which is more easily
   handled (parse, compare) programmatically. Can be one of ``(4, 2)``,
   ``(5, 0)``, ``(7, 0)``, ``(7, 1)``, ``(7, 2)``, ``(7, 3)`` or ``None`` if no
   TDS version could be detected.

   .. versionchanged:: 2.1.3
      ``7.3`` was added as a possible value.

``MSSQLConnection`` object methods
----------------------------------

.. method:: MSSQLConnection.cancel()

   Cancel all pending results from the last SQL operation. It can be called more
   than one time in a row. No exception is raised in this case.

.. method:: MSSQLConnection.close()

   Close the connection and free all memory used. It can be called more than one
   time in a row. No exception is raised in this case.

.. method:: MSSQLConnection.execute_query(query_string)
            MSSQLConnection.execute_query(query_string, params)

   This method sends a query to the *MS SQL Server* to which this object
   instance is connected. An exception is raised on failure. If there are
   pending results or rows prior to executing this command, they are silently
   discarded.

   After calling this method you may iterate over the connection object to get
   rows returned by the query.

   You can use Python formatting and all values get properly quoted. Please see
   examples for details.

   This method is intented to be used on queries that return results, i.e.
   ``SELECT.``

.. method:: MSSQLConnection.execute_non_query(query_string)
            MSSQLConnection.execute_non_query(query_string, params)

   This method sends a query to the *MS SQL Server* to which this object instance
   is connected. After completion, its results (if any) are discarded. An
   exception is raised on failure. If there are pending results or rows prior to
   executing this command, they are silently discarded.

   You can use Python formatting and all values get properly quoted. Please see
   examples for details.

   This method is useful for ``INSERT``, ``UPDATE``, ``DELETE``, and for Data
   Definition Language commands, i.e. when you need to alter your database
   schema.

.. method:: MSSQLConnection.execute_scalar(query_string)
            MSSQLConnection.execute_scalar(query_string, params)

   This method sends a query to the *MS SQL Server* to which this object instance
   is connected, then returns first column of first row from result. An
   exception is raised on failure. If there are pending results or rows prior to
   executing this command, they are silently discarded.

   You can use Python
   formatting and all values get properly quoted. Please see examples for
   details.

   This method is useful if you want just a single value from a query, as in the
   example below. This method works in the same way as ``iter(conn).next()[0]``.
   Remaining rows, if any, can still be iterated after calling this method.

   Example usage::

       count = conn.execute_scalar("SELECT COUNT(*) FROM employees")

.. method:: MSSQLConnection.execute_row(query_string)
            MSSQLConnection.execute_row(query_string, params)

   This method sends a query to the *MS SQL Server* to which this object
   instance is connected, then returns first row of data from result. An
   exception is raised on failure. If there are pending results or rows prior to
   executing this command, they are silently discarded.

   You can use Python formatting and all values get properly quoted. Please see
   examples for details.

   This method is useful if you want just a single row and don't want
   or don't need to iterate over the connection object. This method works in the
   same way as ``iter(conn).next()`` to obtain single row. Remaining rows, if
   any, can still be iterated after calling this method.

   Example usage::

       empinfo = conn.execute_row("SELECT * FROM employees WHERE empid=10")

.. method:: MSSQLConnection.get_header()

   This method is infrastructure and doesn't need to be called by your code. It
   gets the Python DB-API compliant header information. Returns a list of
   7-element tuples describing current result header. Only name and DB-API
   compliant type is filled, rest of the data is ``None``, as permitted by the
   specs.

.. method:: MSSQLConnection.init_procedure(name)

   Create an MSSQLStoredProcedure object that will be used to invoke thestored
   procedure with the given name.

.. method:: MSSQLConnection.nextresult()

   Move to the next result, skipping all pending rows. This method fetches and
   discards any rows remaining from current operation, then it advances to next
   result (if any). Returns ``True`` value if next set is available, ``None``
   otherwise. An exception is raised on failure.

.. method:: MSSQLConnection.select_db(dbname)

   This function makes the given database the current one. An exception is raised on
   failure.

.. method:: MSSQLConnection.__iter__()
            MSSQLConnection.next()

   .. versionadded:: 2.1.0

   These methods implement the Python iterator protocol. You most likely will
   not call them directly, but indirectly by using iterators.

.. method:: MSSQLConnection.set_msghandler(handler)

   .. versionadded:: 2.1.1

   This method allows setting a message handler function for the connection to
   allow a client to gain access to the messages returned from the server.

   The signature of the message handler function *handler* passed to this
   method must be::

        def my_msg_handler(msgstate, severity, srvname, procname, line, msgtext):
            # The body of the message handler.

   *msgstate*, *severity* and *line* will be integers, *srvname*, *procname* and
   *msgtext* will be strings.

``MSSQLStoredProcedure`` class
==============================

.. class:: MSSQLStoredProcedure

    This class represents a stored procedure. You create an object of this class
    by calling the :meth:`~MSSQLConnection.init_procedure()` method on
    :class:`MSSQLConnection` object.

``MSSQLStoredProcedure`` object properties
------------------------------------------

.. attribute:: MSSQLStoredProcedure.connection

   An underlying MSSQLConnection object.

.. attribute:: MSSQLStoredProcedure.name

   The name of the procedure that this object represents.

.. attribute:: MSSQLStoredProcedure.parameters

   The parameters that have been bound to this procedure.

``MSSQLStoredProcedure`` object methods
---------------------------------------

.. method:: MSSQLStoredProcedure.bind(value, dbtype, name=None, \
                                      output=False, null=False, max_length=-1)

   This method binds a parameter to the stored procedure. *value* and *dbtype*
   are mandatory arguments, the rest is optional.

   :param value: Is the value to store in the parameter.

   :param dbtype: Is one of: ``SQLBINARY``, ``SQLBIT``, ``SQLBITN``,
                  ``SQLCHAR``, ``SQLDATETIME``, ``SQLDATETIM4``,
                  ``SQLDATETIMN``, ``SQLDECIMAL``, ``SQLFLT4``, ``SQLFLT8``,
                  ``SQLFLTN``, ``SQLIMAGE``, ``SQLINT1``, ``SQLINT2``,
                  ``SQLINT4``, ``SQLINT8``, ``SQLINTN``, ``SQLMONEY``,
                  ``SQLMONEY4``, ``SQLMONEYN``, ``SQLNUMERIC``, ``SQLREAL``,
                  ``SQLTEXT``, ``SQLVARBINARY``, ``SQLVARCHAR``, ``SQLUUID``.

   :param name: Is the name of the parameter. Needs to be in ``"@name"`` form.

   :param output: Is the direction of the parameter. ``True`` indicates that it
                  is an output parameter i.e. it returns a value after procedure
                  execution (in SQL DDL they are declared by using the
                  ``"output"`` suffix, e.g. ``"@aname varchar(10) output"``).

   :param null: Boolean. Signals than NULL must be the value to be bound to the
                argument of this input parameter.

   :param max_length: Is the maximum data length for this parameter to be
                      returned from the stored procedure.

.. method:: MSSQLStoredProcedure.execute()

   Execute the stored procedure.

Module-level exceptions
=======================

Exception hierarchy::

    MSSQLException
    |
    +-- MSSQLDriverException
    |
    +-- MSSQLDatabaseException

.. exception:: MSSQLDriverException

   ``MSSQLDriverException`` is raised whenever there is a problem within
   ``_mssql`` -- e.g. insufficient memory for data structures, and so on.

.. exception:: MSSQLDatabaseException

    ``MSSQLDatabaseException`` is raised whenever there is a problem with the
    database -- e.g. query syntax error, invalid object name and so on. In this
    case you can use the following properties to access details of the error:

   .. attribute:: MSSQLDatabaseException.number

      The error code, as returned by *SQL Server*.

   .. attribute:: MSSQLDatabaseException.severity

      The so-called severity level, as returned by *SQL Server*. If value of this
      property is less than the value of :data:`_mssql.min_error_severity`, such
      errors are ignored and exceptions are not raised.

   .. attribute:: MSSQLDatabaseException.state

      The third error code, as returned by *SQL Server*.

   .. attribute:: MSSQLDatabaseException.message

      The error message, as returned by *SQL Server*.

You can find an example of how to use this data at the bottom of :doc:`_mssql
examples page </_mssql_examples>`.
