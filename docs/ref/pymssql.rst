============================
``pymssql`` module reference
============================

.. module:: pymssql

Complete documentation of ``pymssql`` module classes, methods and properties.

Module-level symbols
====================

Constants, required by the DB-API 2.0 (:pep:`249`) specification.

.. data:: apilevel

   ``'2.0'`` -- ``pymssql`` strives for compliance with DB-API 2.0.

.. data:: paramstyle

   ``'pyformat'`` -- ``pymssql`` uses extended python format codes.

.. data:: threadsafety

   ``1`` -- Module may be shared, but not connections.

Functions
=========

.. function:: connect(server='.', user='', password='', database='', \
                      timeout=0, login_timeout=60, charset='UTF-8', \
                      as_dict=False, host='', appname=None, port='1433')

    Constructor for creating a connection to the database. Returns a
    :class:`Connection` object.

    :param server: database host
    :type server: string
    :param user: database user to connect as
    :type user: string
    :param password: user's password
    :type password: string
    :param database: the database to initially connect to
    :type database: string
    :param timeout: query timeout in seconds, default 0 (no timeout)
    :type timeout: int
    :param login_timeout: timeout for connection and login in seconds, default 60
    :type login_timeout: int
    :param charset: character set with which to connect to the database
    :type charset: string
    :keyword as_dict: whether rows should be returned as dictionaries instead of tuples
    :type as_dict: boolean
    :keyword appname: Set the application name to use for the connection
    :type appname: string
    :keyword port: the TCP port to use to connect to the server
    :type port: string
    :keyword conn_properties: SQL queries to send to the server upon connection
                              establishment. Can be a string or another kind
                              of iterable of strings. Default value: See
                              :class:`_mssql.connect <_mssql.MSSQLConnection>`

    .. note::
        If you need to connect to Azure make sure you:
        * Use FreeTDS 0.91 or newer.
        * Specify the database name you are connecting to in the ``connect()`` call.

    .. versionadded:: 2.1.1
        The ability to connect to Azure.

    .. versionadded:: 2.1.1
        The *conn_properties* argument.

.. function:: get_dbversion()

    TBD

    A pymssql extension to the DB-API 2.0.

.. todo:: Document ``pymssql`` connection ``get_dbversion()``.

.. function:: set_max_connections(number)

    Sets maximum number of simultaneous database connections allowed to be open
    at any given time. Default is 25.

    A pymssql extension to the DB-API 2.0.

.. function:: get_max_connections()

    Gets current maximum number of simultaneous database connections allowed to
    be open at any given time.

    A pymssql extension to the DB-API 2.0.

.. function:: set_wait_callback(wait_callback_callable)

    .. versionadded:: 2.1.0

    Allows pymssql to be used along cooperative multi-tasking systems and have
    it call a callback when it's waiting for a response from the server.

    The passed callback callable should receive one argument: The file
    descriptor/handle of the network socket connected to the server, so its
    signature must be::

        def wait_callback_callable(read_fileno):
            #...
            pass

    Its body should invoke the appropiate API of the multi-tasking framework you
    are using use that results in the current greenlet yielding the CPU to its
    siblings whilst there isn't incoming data in the socket.

    See the :doc:`pymssql examples document </pymssql_examples>` for a more
    concrete example.

    A pymssql extension to the DB-API 2.0.

``Connection`` class
====================

.. class:: Connection(user, password, host, database, timeout, \
                      login_timeout, charset, as_dict)

    This class represents an MS SQL database connection. You can create an
    instance of this class by calling constructor :func:`pymssql.connect()`. It
    accepts the following arguments. Note that in most cases you will want to
    use keyword arguments, instead of positional arguments.

    :param str user: Database user to connect as

    :param str password: User's password

    :param str host: Database host and instance you want to connect to. Valid
                     examples are:

                     * ``r'.\SQLEXPRESS'`` -- SQLEXPRESS instance on local machine (Windows only)
                     * ``r'(local)\SQLEXPRESS'`` -- same as above (Windows only)
                     * ``'SQLHOST'`` -- default instance at default port (Windows only)
                     * ``'SQLHOST'`` -- specific instance at specific port set up in freetds.conf (Linux/\*nix only)
                     * ``'SQLHOST,1433'`` -- specified TCP port at specified host
                     * ``'SQLHOST:1433'`` -- the same as above
                     * ``'SQLHOST,5000'`` -- if you have set up an instance to listen on port 5000
                     * ``'SQLHOST:5000'`` -- the same as above

                     ``'.'`` (the local host) is assumed if host is not provided.

    :param str database: The database you want initially to connect to, by
                         default *SQL Server* selects the database which is set as
                         default for specific user

    :param int timeout: Query timeout in seconds, default is 0 (wait indefinitely)

    :param int login_timeout: Timeout for connection and login in seconds,
                              default 60

    :param str charset: Character set with which to connect to the database

    :param bool as_dict: Whether rows should be returned as dictionaries instead
                         of tuples. You can access columns by 0-based index or
                         by name. Please see :doc:`examples </pymssql_examples>`

Connection object properties
----------------------------

This class has no useful properties and data members.

Connection object methods
-------------------------

.. method:: Connection.autocommit(status)

   Where *status* is a boolean value. This method turns autocommit mode on or
   off.

   By default, autocommit mode is off, what means every transaction must
   be explicitly committed if changed data is to be persisted in the database.

   You can turn autocommit mode on, what means every single operation commits
   itself as soon as it succeeds.

   A pymssql extension to the DB-API 2.0.

.. method:: Connection.close()

   Close the connection.

.. method:: Connection.cursor()

   Return a cursor object, that can be used to make queries and fetch results
   from the database.

.. method:: Connection.commit()

   Commit current transaction. You must call this method to persist your data if
   you leave autocommit at its default value, which is ``False``.

   See also :doc:`pymssql examples </pymssql_examples>`.

.. method:: Connection.rollback()

   Roll back current transaction.

``Cursor`` class
================

.. class:: Cursor

This class represents a Cursor (in terms of Python DB-API specs) that is used to
make queries against the database and obtaining results. You create
``Cursor`` instances by calling :py:meth:`~Connection.cursor()` method on
an open :py:class:`Connection` connection object.

Cusor object properties
-----------------------

.. attribute:: Cursor.rowcount

   Returns number of rows affected by last operation. In case of ``SELECT``
   statements it returns meaningful information only after all rows have been
   fetched.

.. attribute:: Cursor.connection

   This is the extension of the DB-API specification. Returns a reference to the
   connection object on which the cursor was created.

.. attribute:: Cursor.lastrowid

   This is the extension of the DB-API specification. Returns identity value of
   last inserted row. If previous operation did not involve inserting a row into
   a table with identity column, ``None`` is returned.

.. attribute:: Cursor.rownumber

   This is the extension of the DB-API specification. Returns current 0-based
   index of the cursor in the result set.

Cusor object methods
--------------------

.. method:: Cursor.close()

   Close the cursor. The cursor is unusable from this point.

.. method:: Cursor.execute(operation)
            Cursor.execute(operation, params)

    *operation* is a string and *params*, if specified, is a simple value, a
    tuple, or ``None``.

    Performs the operation against the database, possibly replacing parameter
    placeholders with provided values. This should be preferred method of
    creating SQL commands, instead of concatenating strings manually, what makes
    a potential of `SQL Injection attacks`_. This method accepts the same
    formatting as Python's builtin :ref:`string interpolation operator
    <python:string-formatting>`.

    If you call ``execute()`` with one argument, the ``%`` sign loses its
    special meaning, so you can use it as usual in your query string, for
    example in ``LIKE`` operator. See the :doc:`examples </pymssql_examples>`.

    You must call :meth:`Connection.commit()` after ``execute()`` or your data
    will not be persisted in the database. You can also set
    ``connection.autocommit`` if you want it to be done automatically. This
    behaviour is required by DB-API, if you don't like it, just use the
    :mod:`_mssql` module instead.

.. method:: Cursor.executemany(operation, params_seq)

   *operation* is a string and *params_seq* is a sequence of tuples (e.g. a
   list). Execute a database operation repeatedly for each element in parameter
   sequence.

.. method:: Cursor.fetchone()

   Fetch the next row of a query result, returning a tuple, or a dictionary if
   as_dict was passed to ``pymssql.connect()``, or ``None`` if no more data is
   available. Raises ``OperationalError`` (:pep:`249#operationalerror`) if
   previous call to ``execute*()`` did not produce any result set or no call was
   issued yet.

.. method:: Cursor.fetchmany(size=None)

   Fetch the next batch of rows of a query result, returning a list of tuples,
   or a list of dictionaries if *as_dict* was passed to
   :func:`pymssql.connect()`, or an empty list if no more data is available. You
   can adjust the batch size using the *size* parameter, which is preserved
   across many calls to this method. Raises ``OperationalError``
   (:pep:`249#operationalerror`) if previous call to ``execute*()`` did not
   produce any result set or no call was issued yet.

.. method:: Cursor.fetchall()

   Fetch all remaining rows of a query result, returning a list of tuples, or a
   list of dictionaries if as_dict was passed to ``pymssql.connect()``, or an
   empty list if no more data is available. Raises ``OperationalError``
   (:pep:`249#operationalerror`) if previous call to ``execute*()`` did not
   produce any result set or no call was issued yet.

.. method:: Cursor.nextset()

   This method makes the cursor skip to the next available result set,
   discarding any remaining rows from the current set. Returns ``True`` value if
   next result is available, ``None`` if not.

.. method:: Cursor.__iter__()
            Cursor.next()

   These methods facilitate :ref:`Python iterator protocol <python:typeiter>`.
   You most likely will not call them directly, but indirectly by using
   iterators.

   A pymssql extension to the DB-API 2.0.

.. method:: Cursor.setinputsizes()
            Cursor.setoutputsize()

   These methods do nothing, as permitted by DB-API specs.

.. todo:: Document all ``pymssql`` PEP 249-mandated exceptions.

.. _SQL Injection attacks: http://en.wikipedia.org/wiki/SQL_injection
