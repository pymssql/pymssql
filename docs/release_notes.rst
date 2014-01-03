=============
Release notes
=============

Release notes -- All breaking changes and other noteworthy things.

pymssql 2.0.0
=============

This is a new major version of pymssql. It is totally rewritten from scratch in
Cython. Our goals for this version were to:

* Provide support for Python 3.0 and newer,
* Implement support for stored procedures,
* Rewrite DB-API compilant pymssql module in C (actually in Cython) for
  increased performance,
* Clean up the module API and the code.

That's why we decided to bump major version number. Unfortunately new version
introduces incompatible changes in API. Existing scripts may not work with it,
and you'll have to audit them. If you care about compatibility, just continue
using pymssql 1.0.x and slowly move to 2.0.

Project hosting has also changed. Now pymssql is developed on GitHub:
http://github.com/pymssql/pymssql.

Credits for the release go to:

* Damien Churchill <damoxc_at_gmail_com> who did all coding, release
  engineering, new site features like Sphinx, SimpleJSON and others,
* Andrzej Kukuła <akukula_at_gmail_com> who did all the docs, site migration,
  and other boring but necessary stuff.
* Jooncheol Park <jooncheol_at_gmail_com> who did develop the initial version
  of pymssql (until 0.5.2). Now just doing boring translation docs for Korean.

pymssql module
--------------

* Rewritten from scratch in C, you should observe even better performance than before
* ``dsn`` parameter to ``pymssql.connect()`` has been removed
* ``host`` parameter to pymssql.connect() has been renamed to server to be
  consistent with ``_mssql`` module
* ``max_conn`` parameter to pymssql.connect() has been removed

pymssqlConnection class
~~~~~~~~~~~~~~~~~~~~~~~

* autocommit() function has been changed to ``autocommit`` property that you can
  set or get its current state.

pymssqlCursor class
~~~~~~~~~~~~~~~~~~~

* fetchone_asdict() method has been removed. Just use pymssql.connect() with ``as_dict=True``, then use regular fetchone()
* fetchmany_asdict() method has been removed. Just use pymssql.connect() with ``as_dict=True``, then use regular fetchmany()
* fetchall_asdict() method has been removed. Just use pymssql.connect() with ``as_dict=True``, then use regular fetchall()

_mssql module
-------------

* Added native support for stored procedures (MSSQLStoredProcedure class)
* ``maxconn`` parameter to _mssql.connect() has been removed
* ``timeout`` and ``login_timeout`` parameter to _mssql.connect() has been added
* get_max_connections() and set_max_connections() module-level methods have been added
* Class names have changed:

======================  ======================
Old Name                New name
======================  ======================
MssqlException          MSSQLException
MssqlDriverException    MSSQLDriverException
MssqlDatabaseException  MSSQLDatabaseException
MssqlRowIterator        MSSQLRowIterator
MssqlConnection         MSSQLConnection
======================  ======================

MSSQLConnection class
~~~~~~~~~~~~~~~~~~~~~

* Added ``tds_version`` property.
