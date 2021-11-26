====================
``pymssql`` examples
====================

Example scripts using ``pymssql`` module.

Basic features (strict DB-API compliance)
=========================================

::

    from os import getenv
    import pymssql

    server = getenv("PYMSSQL_TEST_SERVER")
    user = getenv("PYMSSQL_TEST_USERNAME")
    password = getenv("PYMSSQL_TEST_PASSWORD")

    conn = pymssql.connect(server, user, password, "tempdb")
    cursor = conn.cursor()
    cursor.execute("""
    IF OBJECT_ID('persons', 'U') IS NOT NULL
        DROP TABLE persons
    CREATE TABLE persons (
        id INT NOT NULL,
        name VARCHAR(100),
        salesrep VARCHAR(100),
        PRIMARY KEY(id)
    )
    """)
    cursor.executemany(
        "INSERT INTO persons VALUES (%d, %s, %s)",
        [(1, 'John Smith', 'John Doe'),
         (2, 'Jane Doe', 'Joe Dog'),
         (3, 'Mike T.', 'Sarah H.')])
    # you must call commit() to persist your data if you don't set autocommit to True
    conn.commit()

    cursor.execute('SELECT * FROM persons WHERE salesrep=%s', 'John Doe')
    row = cursor.fetchone()
    while row:
        print("ID=%d, Name=%s" % (row[0], row[1]))
        row = cursor.fetchone()

    conn.close()

Connecting using Windows Authentication
=======================================

When connecting using Windows Authentication, this is how to combine the
database's hostname and instance name, and the Active Directory/Windows Domain
name and the username. This example uses
`raw strings <https://docs.python.org/3/reference/lexical_analysis.html#string-and-bytes-literals>`_
(``r'...'``) for the strings that contain a backslash.

::

    conn = pymssql.connect(
        host=r'dbhostname\myinstance',
        user=r'companydomain\username',
        password=PASSWORD,
        database='DatabaseOfInterest'
    )

Iterating through results
=========================

You can also use iterators instead of while loop.

::

    conn = pymssql.connect(server, user, password, "tempdb")
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM persons WHERE salesrep=%s', 'John Doe')

    for row in cursor:
        print('row = %r' % (row,))

    conn.close()

.. note:: Iterators are a pymssql extension to the DB-API.

Important note about Cursors
============================

A connection can have only one cursor with an active query at any time.
If you have used other Python DBAPI databases, this can lead to surprising
results::

    c1 = conn.cursor()
    c1.execute('SELECT * FROM persons')

    c2 = conn.cursor()
    c2.execute('SELECT * FROM persons WHERE salesrep=%s', 'John Doe')

    print( "all persons" )
    print( c1.fetchall() )  # shows result from c2 query!

    print( "John Doe" )
    print( c2.fetchall() )  # shows no results at all!

In this example, the result printed after ``"all persons"`` will be the
result of the *second* query (the list where ``salesrep='John Doe'``)
and the result printed after "John Doe" will be empty.  This happens
because the underlying TDS protocol does not have client side cursors.
The protocol requires that the client flush the results from the first
query before it can begin another query.

(Of course, this is a contrived example, intended to demonstrate the
failure mode.  Actual use cases that follow this pattern are usually
much more complicated.)

Here are two reasonable workarounds to this:

- Create a second connection.  Each connection can have a query in
  progress, so multiple connections can execute multiple conccurent queries.

- use the fetchall() method of the cursor to recover all the results
  before beginning another query::

    c1.execute('SELECT ...')
    c1_list = c1.fetchall()

    c2.execute('SELECT ...')
    c2_list = c2.fetchall()

    # use c1_list and c2_list here instead of fetching individually from
    # c1 and c2

Rows as dictionaries
====================

Rows can be fetched as dictionaries instead of tuples. This allows for accessing
columns by name instead of index. Note the ``as_dict`` argument.

::

    conn = pymssql.connect(server, user, password, "tempdb")
    cursor = conn.cursor(as_dict=True)

    cursor.execute('SELECT * FROM persons WHERE salesrep=%s', 'John Doe')
    for row in cursor:
        print("ID=%d, Name=%s" % (row['id'], row['name']))

    conn.close()

.. note::
    The ``as_dict`` parameter to ``cursor()`` is a pymssql extension to the
    DB-API.

In some cases columns in a result set do not have a name.
In such a case if you specify ``as_dict=True`` an exception will be raised::

    >>> cursor.execute("SELECT MAX(x) FROM (VALUES (1), (2), (3)) AS foo(x)")
    Traceback (most recent call last):
      File "<stdin>", line 1, in <module>
      File "pymssql.pyx", line 426, in pymssql.Cursor.execute (pymssql.c:5828)
        raise ColumnsWithoutNamesError(columns_without_names)
    pymssql.ColumnsWithoutNamesError: Specified as_dict=True and there are columns with no names: [0]

To avoid this exception supply a name for all such columns -- e.g.::

    >>> cursor.execute("SELECT MAX(x) AS [MAX(x)] FROM (VALUES (1), (2), (3)) AS foo(x)")
    >>> cursor.fetchall()
    [{'MAX(x)': 3}]


Using the ``with`` statement (context managers)
===============================================

You can use Python's ``with`` statement with connections and cursors. This
frees you from having to explicitly close cursors and connections.

::

    with pymssql.connect(server, user, password, "tempdb") as conn:
        with conn.cursor(as_dict=True) as cursor:
            cursor.execute('SELECT * FROM persons WHERE salesrep=%s', 'John Doe')
            for row in cursor:
                print("ID=%d, Name=%s" % (row['id'], row['name']))

.. note::
    The context manager personality of connections and cursor is a pymssql
    extension to the DB-API.

Calling stored procedures
=========================

As of pymssql 2.0.0 stored procedures can be called using the rpc interface of
db-lib.

::

    with pymssql.connect(server, user, password, "tempdb") as conn:
        with conn.cursor(as_dict=True) as cursor:
            cursor.execute("""
            CREATE PROCEDURE FindPerson
                @name VARCHAR(100)
            AS BEGIN
                SELECT * FROM persons WHERE name = @name
            END
            """)
            cursor.callproc('FindPerson', ('Jane Doe',))
            for row in cursor:
                print("ID=%d, Name=%s" % (row['id'], row['name']))

Using pymssql with cooperative multi-tasking systems
====================================================

.. versionadded:: 2.1.0

You can use the :func:`pymssql.set_wait_callback` function to install a callback
function you should write yourself.

This callback can yield to another greenlet, coroutine, etc. For example, for
gevent_, you could use its :func:`gevent:gevent.socket.wait_read` function::

    import gevent.socket
    import pymssql

    def wait_callback(read_fileno):
        gevent.socket.wait_read(read_fileno)

    pymssql.set_wait_callback(wait_callback)

The above is useful if you're say, running a Gunicorn_ server with the gevent
worker. With this callback in place, when you send a query to SQL server and are
waiting for a response, you can yield to other greenlets and process other
requests. This is super useful when you have high concurrency and/or slow
database queries and lets you use less Gunicorn worker processes and still
handle high concurrency.

.. note:: set_wait_callback() is a pymssql extension to the DB-API 2.0.

.. _gevent: http://gevent.org
.. _wait_read: http://gevent.org/gevent.socket.html#gevent.socket.wait_read
.. _Gunicorn: http://gunicorn.org

Bulk copy
=========

.. versionadded:: 2.2.0

The fastest way to insert data to a SQL Server table is often to use the bulk copy functions, for example::

    conn = pymssql.connect(server, user, password, "tempdb")
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE example (
            col1 INT NOT NULL,
            col2 INT NOT NULL
        )
    """)
    cursor.close()

    conn.bulk_copy("example", [(1, 2)] * 1000000)

.. note:: ``bulk_copy`` does not verify columns data type.

For more detail on fast data loading in SQL Server, including on bulk copy, read
`The data loading performance guide`_ from Microsoft.

.. _The data loading performance guide: https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2008/dd425070(v=sql.100)?redirectedfrom=MSDN
