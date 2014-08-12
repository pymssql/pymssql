==========================
Frequently asked questions
==========================

Cannot connect to SQL Server
============================

If your script can't connect to a *SQL Server* instance, try the following:

* Check that you can connect with another tool.

    If you are using `FreeTDS <http://www.freetds.org/>`_, then you can use the
    included ``tsql`` command to try to connect -- it looks like this::

        $ tsql -H sqlserverhost -p 1433 -U user -P password -D tempdb
        locale is "en_US.UTF-8"
        locale charset is "UTF-8"
        using default charset "UTF-8"
        Setting tempdb as default database in login packet
        1> SELECT @@VERSION
        2> GO

        Microsoft SQL Server 2012 - 11.0.2100.60 (X64)
                Feb 10 2012 19:39:15
                Copyright (c) Microsoft Corporation
                Developer Edition (64-bit) on Windows NT 6.1 <X64> (Build 7601: Service Pack 1)

        (1 row affected)

    .. note::

        Note that I use the ``-H`` option rather than the ``-S`` option to
        ``tsql``. This is because with ``-H``, it will bypass reading settings
        from the ``freetds.conf`` file like ``port`` and ``tds version``, and
        so this is more similar to what happens with pymssql.

    If you **can't** connect with ``tsql`` or other tools, then the problem is
    probably not pymssql; you probably have a problem with your server
    configuration (see below), :doc:`FreeTDS Configuration </freetds>`,
    network, etc.

    If you **can** connect with ``tsql``, then you should be able to connect
    with pymssql with something like this::

        >>> import pymssql
        >>> conn = pymssql.connect(
        ...     server="sqlserverhost",
        ...     port=1433,
        ...     user="user",
        ...     password="password",
        ...     database="tempdb")
        >>> conn
        <pymssql.Connection object at 0x10107a3f8>
        >>> cursor = conn.cursor()
        >>> cursor.execute("SELECT @@VERSION")
        >>> print(cursor.fetchone()[0])
        Microsoft SQL Server 2012 - 11.0.2100.60 (X64)
          Feb 10 2012 19:39:15
          Copyright (c) Microsoft Corporation
          Developer Edition (64-bit) on Windows NT 6.1 <X64> (Build 7601: Service Pack 1)

    If something like the above doesn't work, then you can try to diagnose by
    setting one or both of the following `FreeTDS environment variables that control logging <http://www.freetds.org/userguide/logging.htm>`_:

    * ``TDSDUMP``
    * ``TDSDUMPCONFIG``

    Either or both of these can be set. They can be set to a filename or to
    ``stdout`` or ``stderr``.

    These will cause FreeTDS to output a ton of information about what it's doing
    and you may very well spot that it's not using the port that you expected or
    something similar. For example::

        >>> import os
        >>> os.environ['TDSDUMP'] = 'stdout'
        >>>
        >>> import pymssql
        >>> conn = pymssql.connect(server="sqlserverhost")
        log.c:194:Starting log file for FreeTDS 0.92.dev.20140102
          on 2014-01-09 14:05:32 with debug flags 0x4fff.
        config.c:731:Setting 'dump_file' to 'stdout' from $TDSDUMP.
        ...
        dblib.c:7934:20013: "Unknown host machine name"
        dblib.c:7955:"Unknown host machine name", client returns 2 (INT_CANCEL)
        util.c:347:tdserror: client library returned TDS_INT_CANCEL(2)
        util.c:370:tdserror: returning TDS_INT_CANCEL(2)
        login.c:418:IP address pointer is empty
        login.c:420:Server sqlserverhost:1433 not found!
        ...

    .. note::

        Note that pymssql will use a default port of 1433, despite any ports
        you may have specified in your ``freetds.conf`` file.  So if you have
        SQL Server running on a port other than 1433, you must explicitly
        specify the ``port`` in your call to ``pymssql.connect``.  You cannot
        rely on it to pick up the port in your ``freetds.conf``, even though
        ``tsql -S`` might do this. This is why I recommend using ``tsql -H``
        instead for diagnosing connection problems.

    It is also useful to know that ``tsql -C`` will output a lot of information
    about FreeTDS, that can be useful for diagnosing problems::

        $ tsql -C
        Compile-time settings (established with the "configure" script)
                                    Version: freetds v0.92.dev.20140102
                     freetds.conf directory: /usr/local/etc
             MS db-lib source compatibility: no
                Sybase binary compatibility: no
                              Thread safety: yes
                              iconv library: yes
                                TDS version: 5.0
                                      iODBC: yes
                                   unixodbc: no
                      SSPI "trusted" logins: no
                                   Kerberos: no
                                    OpenSSL: no
                                     GnuTLS: no

* By default *SQL Server* 2005 and newer don't accept remote connections, you
  have to use *SQL Server Surface Area Configuration* and/or *SQL Server
  Configuration Manager* to enable specific protocols and network adapters;
  don't forget to restart *SQL Server* after making these changes,

* If *SQL Server* is on a remote machine, check whether connections are not
  blocked by any intermediate firewall device, firewall software, antivirus
  software, or other security facility,

* If you use pymssql on Linux/Unix with FreeTDS, check that FreeTDS's
  configuration is ok and that it can be found by pymssql. The easiest way is to
  test connection using ``tsql`` utility which can be found in FreeTDS package.
  See :doc:`FreeTDS Configuration </freetds>` for more info,

* If you use pymssql on Windows and the server is on local machine, you can try
  the following command from the command prompt::

     REG ADD HKLM\Software\Microsoft\MSSQLServer\Client /v SharedMemoryOn /t REG_DWORD /d 1 /f

Returned dates are not correct
==============================

If you use pymssql on Linux/\*nix and you suspect that returned dates are not
correct, please read the :doc:`FreeTDS and dates <freetds_and_dates>` page.

Queries return no rows
======================

There is a known issue where some versions of pymssql 1.x (pymssql 1.0.2 is
where I've seen this) work well with FreeTDS 0.82, but return no rows when used
with newer versions of FreeTDS, such as FreeTDS 0.91. At `SurveyMonkey
<https://www.surveymonkey.com/>`_, we ran into this problem when we were using
`pymssql 1.0.2 <https://pypi.python.org/pypi/pymssql/1.0.2>`_ and then upgraded
servers from Ubuntu 10 (which includes FreeTDS 0.82) to Ubuntu 12 (which
includes FreeTDS 0.91).

E.g.::

    >>> import pymssql
    >>> pymssql.__version__
    '1.0.2'
    >>> conn = pymssql.connect(host='127.0.0.1:1433', user=user,
    ...                        password=password, database='tempdb')
    >>> cursor = conn.cursor()
    >>> cursor.execute('SELECT 1')
    >>> cursor.fetchall()
    []

See `GitHub issue 137: pymssql 1.0.2: No result rows are returned from queries
with newer versions of FreeTDS
<https://github.com/pymssql/pymssql/issues/137>`_.

There are two way to fix this problem:

1. (Preferred) Upgrade to pymssql 2.x. pymssql 1.x is not actively being worked
   on. pymssql 2.x is rewritten in Cython, is actively maintained, and offers
   better performance, Python 3 support, etc. E.g.::

       >>> import pymssql
       >>> pymssql.__version__
       u'2.0.1.2'
       >>> conn = pymssql.connect(host='127.0.0.1:1433', user=user,
       ...                        password=password, database='tempdb')
       >>> cursor = conn.cursor()
       >>> cursor.execute('SELECT 1')
       >>> cursor.fetchall()
       [(1,)]

2. Upgrade to `pymssql 1.0.3 <https://pypi.python.org/pypi/pymssql/1.0.3>`_.
   This is identical to pymssql 1.0.2 except that it has a very small change
   that makes it so that it works with newer versions of FreeTDS as well as
   older versions.

   E.g.::

       >>> import pymssql
       >>> pymssql.__version__
       '1.0.3'
       >>> conn = pymssql.connect(host='127.0.0.1:1433', user=user,
       ...                        password=password, database='tempdb')
       >>> cursor = conn.cursor()
       >>> cursor.execute('SELECT 1')
       >>> cursor.fetchall()
       [(1,)]

Results are missing columns
===========================

One possible cause of your result rows missing columns is if you are using a
connection or cursor with ``as_dict=True`` and your query has columns without
names -- for example::

    >>> cursor = conn.cursor(as_dict=True)
    >>> cursor.execute("SELECT MAX(x) FROM (VALUES (1), (2), (3)) AS foo(x)")
    >>> cursor.fetchall()
    [{}]

Whoa, what happened to ``MAX(x)``?!?!

In this case, pymssql does not know what name to use for the dict key, so it
omits the column.

The solution is to supply a name for all columns -- e.g.::

    >>> cursor.execute("SELECT MAX(x) AS [MAX(x)] FROM (VALUES (1), (2), (3)) AS foo(x)")
    >>> cursor.fetchall()
    [{u'MAX(x)': 3}]

This behavior was changed in https://github.com/pymssql/pymssql/pull/160 --
with this change, if you specify ``as_dict=True`` and omit column names, an
exception will be raised::

    >>> cursor.execute("SELECT MAX(x) FROM (VALUES (1), (2), (3)) AS foo(x)")
    Traceback (most recent call last):
      File "<stdin>", line 1, in <module>
      File "pymssql.pyx", line 426, in pymssql.Cursor.execute (pymssql.c:5828)
        raise ColumnsWithoutNamesError(columns_without_names)
    pymssql.ColumnsWithoutNamesError: Specified as_dict=True and there are columns with no names: [0]

Examples of this problem:

* `Google Group post: pymssql with MAX(values) function does not appear to work <https://groups.google.com/forum/?fromgroups#!topic/pymssql/JoZpmNZFtxM>`_

pymssql does not unserialize ``DATE`` and ``TIME`` columns to ``datetime.date`` and ``datetime.time`` instances
===============================================================================================================

You may notice that pymssql will unserialize a ``DATETIME`` column to a
:class:`python:datetime.datetime` instance, but it will unserialize ``DATE``
and ``TIME`` columns as simple strings. For example::

    >>> cursor.execute("""
    ... CREATE TABLE dates_and_times (
    ...     datetime DATETIME,
    ...     date DATE,
    ...     time TIME,
    ... )
    ... """)
    >>> cursor.execute("INSERT INTO dates_and_times VALUES (GETDATE(), '20140109', '6:17')")
    >>> cursor.execute("SELECT * FROM dates_and_times")
    >>> cursor.fetchall()
    [{u'date': u'2014-01-09', u'time': u'06:17:00.0000000',
      u'datetime': datetime.datetime(2014, 1, 9, 12, 41, 59, 403000)}]
    >>> cursor.execute("DROP TABLE dates_and_times")

Yep, so the problem here is that ``DATETIME`` has been supported by `FreeTDS
<http://www.freetds.org/>`_ for a long time, but ``DATE`` and ``TIME`` are
newer types in SQL Server and Microsoft never added support for them to db-lib
and FreeTDS never added support for them either.

There was some discussion of adding it to FreeTDS, but I think that stalled.
See this thread:

http://lists.ibiblio.org/pipermail/freetds/2013q2/thread.html#28348

So we would need to get FreeTDS to support it and then the user would have to
make sure to use a very recent FreeTDS (unless pymssql links in said version of
FreeTDS).

Links:

* https://github.com/pymssql/pymssql/issues/156
* `Discussion of adding support for DATE and TIME to FreeTDS <http://lists.ibiblio.org/pipermail/freetds/2013q2/thread.html#28348>`_

Shared object "libsybdb.so.3" not found
=======================================

On Linux/\*nix you may encounter the following behaviour::

    >>> import _mssql
    Traceback (most recent call last):
    File "<stdin>", line 1, in ?
    ImportError: Shared object "libsybdb.so.3" not found

It may mean that the FreeTDS library is unavailable, or that the dynamic linker is
unable to find it. Check that it is installed and that the path to ``libsybdb.so``
is in ``/etc/ld.so.conf`` file. Then do ``ldconfig`` as root to refresh linker
database. On Solaris, I just set the ``LD_LIBRARY_PATH`` environment variable to
the directory with the library just before launching Python.

pymssql 2.x bundles the FreeTDS ``sybdb`` library for supported platforms. This
error may show up in 2.x versions if you are trying to build with your own
FreeTDS.

"DB-Lib error message 20004, severity 9: Read from SQL server failed" error appears
===================================================================================

On Linux/\*nix you may encounter the following behaviour::

    >>> import _mssql
    >>> c=_mssql.connect('hostname:portnumber','user','pass')
    Traceback (most recent call last):
    File "<stdin>", line 1, in <module>
    _mssql.DatabaseException: DB-Lib error message 20004, severity 9:
    Read from SQL server failed.
    DB-Lib error message 20014, severity 9:
    Login incorrect.

It may happen when one of the following is true:

* ``freetds.conf`` file cannot be found,
* ``tds version`` in ``freetds.conf`` file is not ``7.0`` or ``4.2``,
* any character set is specified in ``freetds.conf``,
* an unrecognized character set is passed to :func:`_mssql.connect()` or
  :func:`pymssql.connect()` method.

``"Login incorrect"`` following this error is spurious, real ``"Login
incorrect"`` messages has code=18456 and severity=14.

More troubleshooting
====================

If the above hasn't covered the problem you can send a message describing it to
the pymssql mailing list. You can also consult FreeTDS troubleshooting `page for
issues related to the TDS protocol`_.

.. _page for issues related to the TDS protocol: http://www.freetds.org/userguide/troubleshooting.htm
