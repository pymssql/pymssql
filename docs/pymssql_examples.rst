====================
``pymssql`` examples
====================

Example scripts using ``pymssql`` module.

pymssql examples (strict DB-API compliance)
===========================================

::

    import pymssql
    conn = pymssql.connect(host='SQL01', user='user', password='password', database='mydatabase')
    cur = conn.cursor()
    cur.execute('CREATE TABLE persons(id INT, name VARCHAR(100))')
    cur.executemany("INSERT INTO persons VALUES(%d, %s)", \
        [ (1, 'John Doe'), (2, 'Jane Doe') ])
    conn.commit()  # you must call commit() to persist your data if you don't set autocommit to True

    cur.execute('SELECT * FROM persons WHERE salesrep=%s', 'John Doe')
    row = cur.fetchone()
    while row:
        print "ID=%d, Name=%s" % (row[0], row[1])
        row = cur.fetchone()

    # if you call execute() with one argument, you can use % sign as usual
    # (it loses its special meaning).
    cur.execute("SELECT * FROM persons WHERE salesrep LIKE 'J%'")

    conn.close()

    # You can also use iterators instead of while loop. Iterators are
    # pymssql extensions to the DB-API.

Rows as dictionaries
====================

Rows can be fetched as dictionaries instead of tuples. This allows for accessing
columns by name instead of index. Note the ``as_dict`` argument.

::

    import pymssql
    conn = pymssql.connect(host='SQL01', user='user', password='password', database='mydatabase', as_dict=True)
    cur = conn.cursor()

    cur.execute('SELECT * FROM persons WHERE salesrep=%s', 'John Doe')
    for row in cur:
        print "ID=%d, Name=%s" % (row['id'], row['name'])

    conn.close()

Calling stored procedures
=========================

As of pymssql 2.0.0 stored procedures can be called using the rpc interface of
db-lib.

::

    import pymssql
    conn = pymssql.connect(host='SQL01', user='user', password='password', database='mydatabase', as_dict=True)
    cur = conn.cursor()

    cur.callproc('findPerson', ('John Doe',))
    for row in cur:
        print "ID=%d, Name=%s" % (row['id'], row['name'])

    conn.close()
