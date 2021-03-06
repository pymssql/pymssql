=======
FreeTDS
=======

Installation
============

Linux
-----

On Linux you can choose between (for the two former choices, when you start the
the pymssql installation process it will look for and pick the header files and
libraries for FreeTDS in some usual system-wide locations):

* Use the FreeTDS installation provided by the packages/ports system.

* `Build it and install yourself <http://www.freetds.org/userguide/build.htm>`_.

* Use the bundled static FreeTDS libraries:

  .. code-block:: bash

      export PYMSSQL_BUILD_WITH_BUNDLED_FREETDS=1
      pip install pymssql

  These static libraries are built on a x86_64 Ubuntu 14.04 system by using the
  following sequence:

  .. code-block:: bash

      export CFLAGS="-fPIC"  # for the 64 bits version

  or

  .. code-block:: bash

      export CFLAGS="-m32 -fPIC" LDFLAGS="-m32"  # for the 32 bits version

  and then:

  .. code-block:: bash

      ./configure --enable-msdblib \
        --prefix=/usr --sysconfdir=/etc/freetds --with-tdsver=7.1 \
        --disable-apps --disable-server --disable-pool --disable-odbc \
        --with-openssl=no --with-gnutls=no
      make

  .. versionchanged:: 2.1.3
    Version of FreeTDS Linux static libraries bundled with pymssql is
    `0.95.95`_.

  .. versionchanged:: 2.1.2
    Version of FreeTDS Linux static libraries bundled with pymssql is
    `0.95.81`_ obtained from branch `Branch-0_95`_ of the official Git
    repository. Up to 2.1.1 the version of FreeTDS bundled was 0.91.

.. _0.95.95: https://github.com/FreeTDS/freetds/tree/c9d284c767e569c9ae58ca0e2ad9dcd7c2cc9e55
.. _0.95.81: https://github.com/FreeTDS/freetds/tree/110179b9c83fe9af88d4c29658dca05e5295ecbb
.. _Branch-0_95: https://github.com/FreeTDS/freetds/tree/Branch-0_95

Mac OS X (with `Homebrew <http://brew.sh/>`_)
---------------------------------------------

.. code-block:: bash

    brew install freetds

Windows
-------

You can:

#. Simply use our official Wheels which include FreeTDS statically linked and
   have no SSL support.

#. Build pymssql yourself. In this case you have the following choices regarding
   FreeTDS:

   * Use binaries we maintain at https://github.com/ramiro/freetds/releases

     Choose the .zip file appropriate for your architecture (``x86`` vs.
     ``x86_64``) and your Python version (``vs2008`` for Python 2.7, ``vs2010``
     for Python 3.3 and 3.4, ``vs2015`` for Python 3.5 and 3.6).

     Those builds include iconv support (via
     `win-iconv <https://github.com/win-iconv/win-iconv>`_ statically linked).

     They provide both static and dynamic library versions of FreeTDS and
     versions built both with and without SSL support via OpenSSL (only
     dinamically linked).

     To install OpenSSL you'll need the distribution that can be downloaded from
     http://www.npcglib.org/~stathis/blog/precompiled-openssl/. Choose the right
     .7z file for your Python version (``vs2008`` for Python 2.7, ``vs2010`` for
     Python 3.3 and 3.4, ``vs2015`` for Python 3.5 and 3.6).

   * Or you can `build it yourself <http://www.freetds.org/userguide/build.htm>`_.

.. versionchanged:: 2.1.3
    FreeTDS is linked statically again on our official Windows binaries.

    pymssql version 2.1.2 included a change in the official Windows Wheels by
    which FreeTDS was dinamically linked. Read the relevant change log entry for
    the rationale behind that decision.

    Given the fact this didn't have a good reception from our users, this change
    has been undone in 2.1.3, FreeTDS is statically linked like it happened
    until version 2.1.1.

Configuration
=============

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
https://www.freetds.org/userguide/

Testing the connection
----------------------

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
