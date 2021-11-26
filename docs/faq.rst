==========================
Frequently asked questions
==========================

Cannot connect to SQL Server
============================

If your Python program/script can't connect to a *SQL Server* instance, try the
following:

* By default *SQL Server* 2005 and newer don't accept remote connections, you
  have to use *SQL Server Surface Area Configuration* and/or *SQL Server
  Configuration Manager* to enable specific protocols and network adapters;
  don't forget to restart *SQL Server* after making these changes,

* If *SQL Server* is on a remote machine, check whether connections are not
  blocked by any intermediate firewall device, firewall software, antivirus
  software, or other security facility,

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

* If you use pymssql on Linux/Unix with FreeTDS, check that FreeTDS's
  configuration is ok and that it can be found by pymssql. The easiest way is to
  test connection using ``tsql`` utility which can be found in FreeTDS package.
  See :doc:`FreeTDS Configuration </freetds>` for more info,

Returned dates are not correct
==============================

If you use pymssql on Linux/\*nix and you suspect that returned dates are not
correct, please read the :doc:`FreeTDS and dates <freetds_and_dates>` page.

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
newer types in SQL Server, Microsoft never added support for them to db-lib
and FreeTDS added support for them in version 0.95.

If you need support for these data types (i.e. they get returned from the
database as their native corresponding Python data types instead of as strings)
as well as for the ``DATETIME2`` one, then make sure the following conditions
are met:

* You are connecting to SQL Server 2008 or newer.
* You are using FreeTDS 0.95 or newer.
* You are using TDS protocol version 7.3 or newer.

Shared object "libsybdb.so.3" not found
=======================================

On Linux/\*nix you may encounter the following behaviour::

    >>> from pymssql import _mssql
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

    >>> from pymssql import _mssql
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

Unable to use long username and password
========================================

This is a solved FreeTDS problem but you need to be using FreeTDS 0.95 or newer,
if you are stuck with 0.91 then keep in mind this limitation, even when you can
get usernames, passwords longer than 30 to work on tsql.

More troubleshooting
====================

If the above hasn't covered the problem you can send a message describing it to
the pymssql mailing list. You can also consult FreeTDS troubleshooting `page for
issues related to the TDS protocol`_.

.. _page for issues related to the TDS protocol: http://www.freetds.org/userguide/troubleshooting.htm
