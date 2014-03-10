=====================
FreeTDS configuration
=====================

pymssql uses FreeTDS package to connect to SQL Server instances. You have to
tell it how to find your database servers. The most basic info is host name,
port number, and protocol version to use.

The system-wide FreeTDS configuration file is ``/etc/freetds.conf`` or
``C:\freetds.conf``, depending upon your system. It is also possible to use a
user specific configuration file, which is ``$HOME/.freetds.conf`` on Linux and
``%APPDATA%\.freetds.conf`` on Windows. Suggested contents to start with is at
least::

    [global]
        port = 1433
        tds version = 7.0

With this config you will be able to enter just the hostname to
:func:`pymssql.connect()` and :func:`_mssql.connect()`::

    import pymssql
    connection = pymssql.connect(server='mydbserver', ...)

Otherwise you will have to enter the portname as in::

    connection = pymssql.connect(server='mydbserver:1433', ...)

To connect to instance other than the default, you have to know either the
instance name or port number on which the instance listens::

    connection = pymssql.connect(server='mydbserver\\myinstancename', ...)
    # or by port number (suppose you confirmed that this instance is on port 1237)
    connection = pymssql.connect(server='mydbserver:1237', ...)

Please see also the :doc:`pymssql module reference <ref/pymssql>`, :doc:`_mssql
module reference <ref/_mssql>`, and :doc:`FAQ <faq>` pages.

For more information on configuring FreeTDS please go to
http://www.freetds.org/userguide/freetdsconf.htm

Testing the connection
======================

If you're sure that your server is reachable, but pymssql for some reason don't
let you connect, you can check the connection with ``tsql`` utility which is
part of FreeTDS package::

    $ tsql
    Usage:  tsql [-S <server> | -H <hostname> -p <port>] -U <username> [-P <password>] [-I <config file>] [-o <options>] [-t delim] [-r delim] [-D database]
    (...)
    $ tsql -S mydbserver -U user

.. note:: Use the above form if and only if you specified server alias for
          mydbserver in freetds.conf. Otherwise use the host/port notation::

              $ tsql -H mydbserver -p 1433 -U user

You'll be prompted for a password and if the connection succeeds, you'll see
the SQL prompt::

    1>

You can then enter queries and terminate the session with ``exit``.

If the connection fails, ``tsql`` utility will display appropriate message.
