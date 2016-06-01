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

      ./configure --enable-msdblib --enable-sspi \
        --prefix=/usr --sysconfdir=/etc/freetds --with-tdsver=7.1 \
        --disable-apps --disable-server --disable-pool --disable-odbc \
        --with-openssl=no --with-gnutls=no
      make

  .. versionchanged:: 2.1.2

    Version of FreeTDS Linux static libraries bundled with pymssql is
    `0.95.81`_ obtained from branch `Branch-0_95`_ of the official Git
    repository. Up to 2.1.1 the version of FreeTDS bundled was 0.91.

.. _0.95.81: https://github.com/FreeTDS/freetds/tree/110179b9c83fe9af88d4c29658dca05e5295ecbb
.. _Branch-0_95: https://github.com/FreeTDS/freetds/tree/Branch-0_95

Mac OS X (with `Homebrew <http://brew.sh/>`_)
---------------------------------------------

.. code-block:: bash

    brew install freetds

Windows
-------

#. You can:

   * Use binaries we maintain at https://github.com/ramiro/freetds/releases

     Those are built with SSL support via OpenSSL (see below) and iconv (via
     `win-iconv <https://github.com/win-iconv/win-iconv>`_ statically linked).

     Choose the .zip file appropriate for your architecture (``x86`` vs.
     ``x86_64``) and your Python version (``vs2008`` for Python 2.7, ``vs2010``
     for Python 3.3 and 3.4, ``vs2015`` for Python 3.5). Download and uncompress
     it. You will need to add the appropriate ``lib`` or ``lib-nossl`` directory
     to your ``%PATH%`` environment variable or copy the DLLs to a directory
     already in ``%PATH%``.
   * Or you can `build it yourself <http://www.freetds.org/userguide/build.htm>`_.

#. If you chose the FreeTDS binaries linked above then you'll need to install
   OpenSSL. The binaries you'll need can be downloaded from
   http://www.npcglib.org/~stathis/blog/precompiled-openssl/

   Choose the right .7z file for your Python version (``vs2008`` for Python 2.7,
   ``vs2010`` for Python 3.3 and 3.4, ``vs2015`` for Python 3.5). Download and
   uncompress it. You must add the appropriate ``bin`` or ``bin64`` directory to your
   ``%PATH%`` environment variable or copy the relevant DLLs to a directory already
   in ``%PATH%``.

   This is needed because the FreeTDS DLLs are compiled with the feature to use
   SSL-wrapped connections to SQL Server (and Azure for which it's a mandatory
   requirement) turned on.

#. If applicable, add the directories that hold the above DLLs to your
   ``PATH`` environment variable.

.. note:: FreeTDS is now linked in dynamically on Windows

    pymssql version 2.1.2 includes a change in the official Windows binaries:
    FreeTDS isn't statically linked as it happened up to release 2.1.1, as that
    FreeTDS copy lacked SSL support.

    Given the fact OpenSSL is a relatively fast-moving target and a sensitive one
    security-wise, we've chosen to not link it statically either so it can be
    updated independently to future releases which include security fixes.

    We are trying to find a balance between security and convenience and will
    be evaluating the situation for future releases. Your feedback is greatly
    welcome.

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
http://www.freetds.org/userguide/freetdsconf.htm

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
