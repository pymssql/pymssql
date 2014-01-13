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

Iterating through results
=========================

You can also use iterators instead of while loop. Iterators are pymssql
extensions to the DB-API.

::

    conn = pymssql.connect(server, user, password, "tempdb")
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM persons WHERE salesrep=%s', 'John Doe')

    for row in cursor:
        print('row = %r' % (row,))

    conn.close()

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
