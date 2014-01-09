==========================
Frequently asked questions
==========================

Cannot connect to SQL Server
============================

If your script can't connect to a *SQL Server* instance, try the following:

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
with this change, if you specify `as_dict=True` and omit column names, an
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

Python on Windows dies with memory access violation error on connect() when incorrect password is given
=======================================================================================================

This may happen if you use different version of ``ntwdblib.dll`` than the one
included in pymssql package. For example the version 2000.80.2273.0 is unable
to handle ``dberrhandle()`` callbacks properly, and causes access violation
error in ``err_handler()`` function on return ``INT_CANCEL``. I have given up
after several hours of investigating the issue, and just reverted to previous
version of the ``ntwdblib.dll`` and the error disappeared.

"Not enough storage is available to complete this operation" error appears
==========================================================================

On Windows you may encounter the following behaviour::

    >>> import _mssql
    >>> c=_mssql.connect('hostname:portnumber','user','pass')
    Traceback (most recent call last):
    File "<pyshell#1>", line 1, in -toplevel-
    File "E:\Python24\Lib\site-packages\pymssql.py", line 310, in connect
    con = _mssql.connect(dbhost, dbuser, dbpasswd)
    error: DB-Lib error message 10004, severity 9:
    Unable to connect: SQL Server is unavailable or does not exist. Invalid connection.
    Net-Lib error during ConnectionOpen (ParseConnectParams()).
    Error 14 - Not enough storage is available to complete this operation.

This may happen most likely on earlier versions of pymssql. It happens always if
you use a colon ``":"`` to separate hostname from port number. On Windows you
should use comma ``","`` instead. pymssql 1.0 has a workaround, so you do not
have to care about that anymore.

More troubleshooting
====================

If the above hasn't covered the problem, please also check Limitations and
known issues page. You can also consult FreeTDS troubleshooting `page for issues
related to the TDS protocol`_.

.. _page for issues related to the TDS protocol: http://www.freetds.org/userguide/troubleshooting.htm
