==========================
Migrating from 1.x to 2.x
==========================

Because of the DB-API standard and because effort was made to make the
interface of pymssql 2.x similar to that of pymssql 1.x, there are only a few
differences and usually upgrading is pretty easy.

There are a few differences though...

``str`` vs. ``unicode``
=======================

Note that we are talking about Python 2, because pymssql 1.x doesn't work on
Python 3.

pymssql 1.x will return ``str`` instances::

    >>> pymssql.__version__
    '1.0.3'
    >>> conn.as_dict = True
    >>> cursor = conn.cursor()
    >>> cursor.execute("SELECT 'hello' AS str FROM foo")
    >>> cursor.fetchall()
    [{0: 'hello', 'str': 'hello'}]

whereas pymssql 2.x will return ``unicode`` instances::

    >>> pymssql.__version__
    u'2.0.1.2'
    >>> conn.as_dict = True
    >>> cursor = conn.cursor()
    >>> cursor.execute("SELECT 'hello' AS str FROM foo")
    >>> cursor.fetchall()
    [{u'str': u'hello'}]

If your application has code that deals with ``str`` and ``unicode``
differently, then you may run into issues.

You can always convert a ``unicode`` to a ``str`` by encoding::

    >>> cursor.execute("SELECT 'hello' AS str FROM foo")
    >>> s = cursor.fetchone()['str']
    >>> s
    u'hello'
    >>> s.encode('utf-8')
    'hello'

Handling of ``uniqueidentifier`` columns
========================================

SQL Server has a data type called `uniqueidentifier
<http://technet.microsoft.com/en-us/library/ms187942.aspx>`_.

In pymssql 1.x, ``uniqueidentifier`` columns are returned in results as
byte strings with 16 bytes; if you want a :class:`python:uuid.UUID` instance,
then you have to construct it yourself from the byte string::

    >>> cursor.execute("SELECT * FROM foo")
    >>> id_value = cursor.fetchone()['uniqueidentifier']
    >>> id_value
    'j!\xcf\x14D\xce\xe6B\xab\xe0\xd9\xbey\x0cMK'
    >>> type(id_value)
    <type 'str'>
    >>> len(id_value)
    16
    >>> import uuid
    >>> id_uuid = uuid.UUID(bytes_le=id_value)
    >>> id_uuid
    UUID('14cf216a-ce44-42e6-abe0-d9be790c4d4b')

In pymssql 2.x, ``uniqueidentifier`` columns are returned in results as
instances of :class:`python:uuid.UUID` and if you want the bytes, like in
pymssql 1.x, you have to use :attr:`python:uuid.UUID.bytes_le` to get them::

    >>> cursor.execute("SELECT * FROM foo")
    >>> id_value = cursor.fetchone()['uniqueidentifier']
    >>> id_value
    UUID('14cf216a-ce44-42e6-abe0-d9be790c4d4b')
    >>> type(id_value)
    <class 'uuid.UUID'>
    >>> id_value.bytes_le
    'j!\xcf\x14D\xce\xe6B\xab\xe0\xd9\xbey\x0cMK'

Arguments to ``pymssql.connect``
================================

The arguments are a little bit different. Some notable differences:

In pymssql 1.x, the parameter to specify the host is called ``host`` and it can contain a host and port -- e.g.:

::

    conn = pymssql.connect(host='SQLHOST:1433')  # specified TCP port at a host

There are some other syntaxes for the ``host`` parameter that allow using a
comma instead of a colon to delimit host and port, to specify Windows hosts, to
specify a specific SQL Server instance, etc.

::

    conn = pymssql.connect(host=r'SQLHOST,5000')  # specified TCP port at a host
    conn = pymssql.connect(host=r'(local)\SQLEXPRESS')  # named instance on local machine [Win]

In pymssql 2.x, the ``host`` parameter is supported (I am unsure if it has all
of the functionality of pymssql 1.x). There is also a parameter to specify the
host that is called ``server``. There is a separate parameter called ``port``.

::

    conn = pymssql.connect(server='SQLHOST', port=1500)

Parameter substitution
======================

For parameter substitution, pymssql 2.x supports the ``format`` and
``pyformat`` `PEP 249 paramstyles
<http://www.python.org/dev/peps/pep-0249/#paramstyle>`_.

Note that for ``pyformat``, PEP 249 only shows the example of a string substitution -- e.g.::

    %(name)s

It is not clear from PEP 249 whether other types should be supported, like::

    %(name)d
    %(name)f

However, in this `mailing list thread
<http://python.6.x6.nabble.com/Some-obscurity-with-paramstyle-td2163302.html>`_,
the general consensus is that the string format should be the only one
required.

Note that pymssql 2.x does not support ``%(name)d``, whereas pymssql 1.x did.
So you may have to change code that uses this notation::

    >>> pymssql.__version__
    u'2.0.1.2'
    >>> pymssql.paramstyle
    'pyformat'

    >>> cursor.execute("select 'hello' where 1 = %(name)d", dict(name=1))
    Traceback (most recent call last):
      File "<stdin>", line 1, in <module>
      File "pymssql.pyx", line 430, in pymssql.Cursor.execute (pymssql.c:5900)
        if not self._source._conn.nextresult():
    pymssql.ProgrammingError: (102, "Incorrect syntax near '('.
    DB-Lib error message 20018, severity 15:\n
    General SQL Server error: Check messages from the SQL Server\n")

to::

    >>> cursor.execute("select 'hello' where '1' = %(name)s", dict(name='1'))
    >>> cursor.fetchall()
    [(u'hello',)]

or::

    >>> cursor.execute("select 'hello' where 1 = %d", 1)
    >>> cursor.fetchall()
    [(u'hello',)]

Examples of this problem:

* `Google Group post: paramstyle changed? <https://groups.google.com/forum/?fromgroups=#!searchin/pymssql/param/pymssql/sSriPxHfZNk/VoOrl-84MQwJ>`_
* `GitHub issue #155: pymssql 2.x does not support "%(foo)d" parameter substitution style; pymssql 1.x did <https://github.com/pymssql/pymssql/issues/155>`_

