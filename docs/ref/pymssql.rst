============================
``pymssql`` module reference
============================

.. py:module:: pymssql

Complete documentation of ``pymssql`` module classes, methods and properties.

``pymssql`` methods
===================

.. py:function:: set_max_connections(number)

    Sets maximum number of simultaneous database connections allowed to be open
    at any given time. Default is 25.

.. py:function:: get_max_connections()

    Gets current maximum number of simultaneous database connections allowed to
    be open at any given time.

Connection (``pymssqlCnx``) class
=================================

.. py:class:: pymssqlCnx(user, password, host, database, timeout, \
                         login_timeout, charset, as_dict)

    This class represents an MS SQL database connection. You can create an
    instance of this class by calling constructor ``pymssql.connect()``. It accepts
    the following arguments. Note that in most cases you will want to use
    keyword arguments, instead of positional arguments.

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

.. py:method:: pymssqlCnx.autocommit(status)

   Where *status* is a boolean value. This method turns autocommit mode on or
   off. By default, autocommit mode is off, what means every transaction must
   be explicitly committed if changed data is to be persisted in the database.
   You can turn autocommit mode on, what means every single operation commits
   itself as soon as it succeeds.

.. py:method:: pymssqlCnx.close()

   Close the connection.

.. py:method:: pymssqlCnx.cursor()

   Return a cursor object, that can be used to make queries and fetch results
   from the database.

.. py:method:: pymssqlCnx.commit()

   Commit current transaction. You must call this method to persist your data if
   you leave autocommit at its default value, which is False. See also
   :doc:`pymssql examples </pymssql_examples>`.

.. py:method:: pymssqlCnx.rollback()

   Roll back current transaction.

Cusor (``pymssqlCursor``) class
===============================

.. py:class:: pymssqlCursor

This class represents a Cursor (in terms of Python DB-API specs) that is used to
make queries against the database and obtaining results. You create
``pymssqlCursor`` instances by calling :py:meth:`~pymssqlCnx.cursor()` method on
an open :py:class:`pymssqlCnx` connection object.

Cusor object properties
-----------------------

.. py:attribute:: pymssqlCursor.rowcount

   Returns number of rows affected by last operation. In case of ``SELECT``
   statements it returns meaningful information only after all rows have been
   fetched.

.. py:attribute:: pymssqlCursor.connection

   This is the extension of the DB-API specification. Returns a reference to the
   connection object on which the cursor was created.

.. py:attribute:: pymssqlCursor.lastrowid

   This is the extension of the DB-API specification. Returns identity value of
   last inserted row. If previous operation did not involve inserting a row into
   a table with identity column, None is returned.

.. py:attribute:: pymssqlCursor.rownumber

   This is the extension of the DB-API specification. Returns current 0-based
   index of the cursor in the result set.

Cusor object methods
--------------------

.. py:method:: pymssqlCursor.close()

   Close the cursor. The cursor is unusable from this point.

.. py:method:: pymssqlCursor.execute(operation)
               pymssqlCursor.execute(operation, params)

    *operation* is a string and *params*, if specified, is a simple value, a
    tuple, or ``None``. Performs the operation against the database, possibly
    replacing parameter placeholders with provided values. This should be
    preferred method of creating SQL commands, instead of concatenating strings
    manually, what makes a potential of `SQL Injection attacks`_. This method
    accepts the same formatting as Python's builtin :ref:`string interpolation
    operator <python:string-formatting>`. If you call ``execute()`` with
    one argument, the ``%`` sign loses its special meaning, so you can use it as
    usual in your query string, for example in ``LIKE`` operator. See the
    :doc:`examples </pymssql_examples>`.  You must call
    :meth:`pymssqlCnx.commit()` after ``execute()`` or your data will not be
    persisted in the database. You can also set ``connection.autocommit`` if you
    want it to be done automatically. This behaviour is required by DB-API, if
    you don't like it, just use the :mod:`_mssql` module instead.

.. py:method:: pymssqlCursor.executemany(operation, params_seq)

   *operation* is a string and *params_seq* is a sequence of tuples (e.g. a
   list).  Execute a database operation repeatedly for each element in parameter
   sequence.

.. py:method:: pymssqlCursor.fetchone()

   Fetch the next row of a query result, returning a tuple, or a dictionary if
   as_dict was passed to ``pymssql.connect()``, or ``None`` if no more data is
   available. Raises ``OperationalError`` (:pep:`249#operationalerror`) if
   previous call to ``execute*()`` did not produce any result set or no call was
   issued yet.

.. py:method:: pymssqlCursor.fetchmany(size=None)

   Fetch the next batch of rows of a query result, returning a list of tuples,
   or a list of dictionaries if *as_dict* was passed to
   :func:`pymssql.connect()`, or an empty list if no more data is available. You
   can adjust the batch size using the *size* parameter, which is preserved
   across many calls to this method. Raises ``OperationalError``
   (:pep:`249#operationalerror`) if previous call to ``execute*()`` did not
   produce any result set or no call was issued yet.

.. py:method:: pymssqlCursor.fetchall()

   Fetch all remaining rows of a query result, returning a list of tuples, or a
   list of dictionaries if as_dict was passed to ``pymssql.connect()``, or an
   empty list if no more data is available. Raises ``OperationalError``
   (:pep:`249#operationalerror`) if previous call to ``execute*()`` did not
   produce any result set or no call was issued yet.

.. py:method:: pymssqlCursor.nextset()

   This method makes the cursor skip to the next available result set,
   discarding any remaining rows from the current set. Returns ``True`` value if
   next result is available, ``None`` if not.

.. py:method:: pymssqlCursor.__iter__()
               pymssqlCursor.next()

   These methods facilitate :ref:`Python iterator protocol <python:typeiter>`.
   You most likely will not call them directly, but indirectly by using
   iterators.

.. py:method:: pymssqlCursor.setinputsizes()
               pymssqlCursor.setoutputsize()

   These methods do nothing, as permitted by DB-API specs.

.. _SQL Injection attacks: http://en.wikipedia.org/wiki/SQL_injection
