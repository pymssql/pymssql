================================
Connecting to Azure SQL Database
================================

Starting with version 2.1.1 pymssql can be used to connect to *Microsoft Azure
SQL Database*.

Make sure the following requirements are met:

* Use FreeTDS 0.91 or newer
* Use TDS protocol 7.1 or newer
* Make sure FreeTDS is built with SSL support
* Specify the database name you are connecting to in the *database* parameter of
  the relevant ``connect()`` call
* **IMPORTANT**: Do not use ``username@server.database.windows.net`` for the
  *user* parameter of the relevant ``connect()`` call! You must use the shorter
  ``username@server`` form instead!

Example::

    pymssql.connect("xxx.database.windows.net", "username@xxx", "password", "db_name")

or, if you've defined ``myalias`` in the ``freetds.conf`` FreeTDS config file::

    [myalias]
    host = xxx.database.windows.net
    tds version = 7.1
    ...

then you could use::

    pymssql.connect("myalias", "username@xxx", "password", "db_name")
