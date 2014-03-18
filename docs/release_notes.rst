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

* Marc Abramowitz <msabramo_at_gmail_com> who joined the project in Jan 2013 and
  is responsible for the actual release of the 2.0 version by fixing many old
  tickets, coding the port to Python 3 and driving the migration to Git and
  GitHub.
* Randy Syring who converted the repository to Mercurial, extended tests and
  ported them to nose, enhanced the code in several fronts like multi-platform
  (compilers, OSes) compatibility, error handling, support of new data types,
  SQLAlchemy compatibility and expanded the documentation.
* Damien Churchill <damoxc_at_gmail_com> who set the foundations of the new
  Cython-based code base, release engineering, new site features like Sphinx,
  SimpleJSON and others,
* Andrzej Kukuła <akukula_at_gmail_com> who did all the docs, site migration,
  and other boring but necessary stuff.
* Jooncheol Park <jooncheol_at_gmail_com> who did develop the initial version
  of pymssql (until 0.5.2). Now just doing boring translation docs for Korean.

``pymssql`` module
------------------

* Rewritten from scratch in C, you should observe even better performance than before
* ``dsn`` parameter to :func:`pymssql.connect()` has been removed
* ``host`` parameter to :func:`pymssql.connect()` has been renamed to ``server``
  to be consistent with ``_mssql`` module
* ``max_conn`` parameter to :func:`pymssql.connect()` has been removed

``Connection`` class
~~~~~~~~~~~~~~~~~~~~

* ``autocommit()`` function has been changed to
  :attr:`pymssql.Connection.autocommit` property that you can set or get
  its current state.

``Cursor`` class
~~~~~~~~~~~~~~~~

* ``fetchone_asdict()`` method has been removed. Just use
  :func:`pymssql.connect()` with ``as_dict=True``, then use regular
  :meth:`~pymssql.Cursor.fetchone()`
* ``fetchmany_asdict()`` method has been removed. Just use
  :func:`pymssql.connect()` with ``as_dict=True``, then use regular
  :meth:`~pymssql.Cursor.fetchmany()`
* ``fetchall_asdict()`` method has been removed. Just use
  :func:`pymssql.connect()` with ``as_dict=True``, then use regular
  :meth:`~pymssql.Cursor.fetchall()`

``_mssql`` module
-----------------

* Added native support for stored procedures
  (:class:`~_mssql.MSSQLStoredProcedure` class)
* ``maxconn`` parameter to :func:`_mssql.connect()` has been removed
* ``timeout`` and ``login_timeout`` parameter to :func:`_mssql.connect()` has
  been added
* :func:`~_mssql.get_max_connections()` and :func:`~_mssql.set_max_connections()`
  module-level methods have been added
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

``MSSQLConnection`` class
~~~~~~~~~~~~~~~~~~~~~~~~~

* Added :attr:`~_mssql.MSSQLConnection.tds_version` property.
