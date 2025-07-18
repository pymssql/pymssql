Recent Changes
==============


Version 2.3.7 - 2025-07-10 - Mikhail Terekhov
=============================================

General
-------

- Allow to specify openssl dependency on macos, thanks to dwt (PR #934).


Version 2.3.6 - 2025-06-28 - Mikhail Terekhov
=============================================

General
-------

- Build manylinux wheels using manylinux2014 image.

Version 2.3.5 - 2025-06-24 - Mikhail Terekhov
=============================================

General
-------

- Build ARM wheels for MacOS (closes #612, #727, #731, #763, #768, #822, #882).
- Fix Windows wheels build (closes #930, #931).
- Make mssql cython 3.1.0 compatible, thanks to Timotheus Bachinger (closes #937, #939, #945, #946, #948).
- Fix manylinux1 build for Cython-3.1.0.
- Fix sqlalchemy.orm.exc.MappedAnnotationError in tests, thanks to Timotheus Bachinger.

Internals
---------

- Use cibuildwheel in GitHub Actions.

Version 2.3.4 - 2025-04-01 - Mikhail Terekhov
=============================================

General
-------

- Update packaging to fix metadata, thanks to AbigailColwell.


Version 2.3.3 - 2025-03-31 - Mikhail Terekhov
=============================================

General
-------

- Update FreeTDS to 1.4.26.
- Add py.typed which marks pymssql as suporting typechecks, thanks Niklas Mertsch (closes #925).


Version 2.3.2 - 2024-11-20 - Mikhail Terekhov
=============================================

General
-------

- Update FreeTDS to 1.4.23.
- Build wheels for Python-3.13 on Windows and MacOS.

Internals
---------

- Fix build wheels for Python-3.13 on Windows.
- Drop build in actions for Python 3.6, 3.7 and 3.8.
- Add build in actions for Python-3.13.
- Workaround setuptools-74.0 changes.


Version 2.3.1 - 2024-08-25 - Mikhail Terekhov
=============================================

General
-------

- Fix SP returning NULL (closes #441).
- Update FreeTDS to 1.4.22 (closes #895).
- Require Cython>3.0.10.
- Add python 3.13 Linux wheels (closes #900).
- Drop manylinux2010 wheels.
- Drop 3.7 and 3.8 wheels on MacOS.
- Drop 3.6 wheels on Linux.

Version 2.3.0 - 2024-04-06 - Mikhail Terekhov
=============================================

General
-------

- Add python 3.12 support (fix #851). Thanks to Raphael Jacob.
- Update FreeTDS to 1.4.10.
- Add read_only parameter for connection.
- Add encryption parameter to connect.
- Add use_datetime2 parameter to connect.
- Use utf-8 for connection properties.
- Implement batching in executemany based on optional batch_size parameter.
  with default equal arraysize cursor attribute (closes #332, #462).
- Build aarch64 wheels. Thanks to Jun Tang.
- Build musllinux wheels.
- Some documentation fixes. Thanks to Casey Korver and Quentin LEGAY.
- FAQ update: #877.
- Add stubs  (closes #767).
- Fix DBAPI-2.0 compliance - DataError must be a subclass of DatabaseError.
- Fix DBAPI-2.0 compliance: rename `batchsize` cursor attribute to `arraysize`.
- Implement DATETIMEOFFSET handling for stored procedures.
- Implement DATETIMEOFFSET handling for insert and select queries (fixes #649).
- Return instance of datetime.datetime on select from SQLDATETIM4, SQLDATETIME, SQLDATETIME2 columns (closes #662, #695, #792, #844).

Bug fixes
---------

- Fix SQLDATETIME2 handling in convert_python_value().
- Use four digits for the year in SP args binding (fix #454).
- Fix convert_python_value to work with datetime.date. Thanks to Testsr.
- Check if C compiler is installed if check for clock_gettime fails (fix #825).
- Add missing `charset` parameter in the `_substitute_params` method when
  calling `ensure_bytes` (fix #650). Thans to Andrey Yuroshev.
- Fix empty, zero or None parameter substitution. (fix #609).

Internals
---------

- Add tests for fetchall(), fetchmany(), fetchone() and next() with SP.
- Add test for #134.
- Require Cython>3.0.7.
- Use Cython 3 for compilation.
- Use docker image for MSSQL2019 as a default for tests.
- Take FreeTDS version for PyPI wheels from pyproject.toml.
- Check sdist with twine.
- Use OpenSSL-1.1.1.2100 for Windows x86 wheels. Thanks to PrimozGodec (fixes #839).
- Use OpenSSL-3.1.1 for Windows x64 wheels (FreeTDS build fails with OpenSSL-3.2.1).
- Add SQLTIME and SQLDATETIME2 to convert_python_value.
- Use dbanydatecrack() function instead of dbdatecrack().
- Replace DEF with cdef enum for buffer array size (compatibility with Cython 3).
- Remove references to tox. Thanks to Christoph Wegener.
- Update readthedocs configuration.
- Add tests for timeout in wait callback (#305).
- Clean up some legacy FreeTDS shims.
- Add tests for tds_version parameter.
- Move check for clock_gettime to dev/ccompiler.py.
- Remove some Python2 remnants.
- Move FreeTDS version from workflow files to pyproject.toml.
- Move exceptions into separate module.
- Use strftime for date & time conversion.
- Simplify parameters quoting.
- Add tests for _quote_simple_value.

Version 2.2.11 - 2023-12-03  - Mikhail Terekhov
===============================================

General
-------

- Use FreeTDS-1.4.9 for official wheels on PyPi.
- Add workflow for aarch64 wheel. Thanks to juntangc (fix #692, #759, #791, #819, #826, #858).
- Add datetime.date to SQLDATE conversion.
- Add encription parameter to connect (fix  #797).

Bug fixes
---------

- Fix version parsing in development.
- Add missing `charset` parameter when formatting query (fix #650).
- Use four digits for the year in SP args binding (fix #454).
- Fix convert_python_value to work with datetime.date (fix #811).

Version 2.2.10 - 2023-10-20  - Mikhail Terekhov
===============================================

General
-------

- Publish Linux wheels for Python-3.12

Version 2.2.9 - 2023-10-13  - Mikhail Terekhov
==============================================

General
-------

- Use FreeTDS-1.4.3 for official wheels on PyPi (fix #847).
- Build wheels for Python-3.12. Thanks to Raphael Jacob (fix #851, #855).
- Use manylinux_2_28 instead of manylinux_2_24 when building wheels in GitHub actions.
- Fix build with OpenSSL on Windows. Thanks to PrimozGodec (fix #839).


Version 2.2.8 - 2023-07-30  - Mikhail Terekhov
==============================================

General
-------

- Compatibility with Cython. Thanks to matusvalo (Matus Valo) (fix #826).

Version 2.2.7 - 2022-11-15  - Mikhail Terekhov
==============================================

General
-------

- Build wheels for Python-3.6 (fix 787).

Version 2.2.6 - 2022-11-12  - Mikhail Terekhov
==============================================

General
-------

- Build wheels for Python-3.11.
- Use FreeTDS-1.3.13 for official wheels on PyPi.
- Fix build on Alpine Linux (fix #762).
- Fill in result description in cursor.callproc (fix #772).
- Add explicit link to krb5 (fix #776), thanks to James Coder.
- Some small doc fixes, thanks to guillaumep and Logan Elandt.

Version 2.2.5 - 2022-04-12  - Mikhail Terekhov
==============================================

General
-------

- Added bytes and bytearray to support bulk_copy types, thanks to steve-strickland (#756).
- Use FreeTDS-1.3.9 for official wheels on PyPi.
- Enable krb5 in Linux wheels, this time for real (#754).

Version 2.2.4 - 2022-01-23 - Mikhail Terekhov
=============================================

General
-------

- Build wheels for Python-3.10 on Linux.
- Fix include paths in setup.py.

Version 2.2.3 - 2021-12-21 - Mikhail Terekhov
=============================================

General
-------

- Build wheels for Python-3.10.
- Use FreeTDS-1.3.4 for official wheels on PyPi.
- Enable krb5 in Linux wheels (#734).
- Fix UnicodeEncodeError for non-ascii database name (#484).
- Fix pymssql.Binary (#504).
- On macOS check for FreeTDS in homebrew prefix when building.
- Some documentation changes.


Version 2.2.2 - 2021-07-24 - Mikhail Terekhov
=============================================

General
-------

- Use FreeTDS-1.3 for official wheels on PyPi.
- On macOS use delocate to bundle dependencies when building wheels.
- Some documentation changes.


Version 2.2.1 - 2021-04-15 - Mikhail Terekhov
=============================================

General
-------

- Publish Linux wheels for the all supported platforms.
  manylinux1 wheels are not compatible with modern glibc and OpenSSL.
- Add readthedocs configuration file.


Version 2.2.0 - 2021-04-08 - Mikhail Terekhov
=============================================

General
-------

- Add Python-3.9 to the build and test matrix.
- Drop support for Python2 and Python3 < 3.6.
- Use FreeTDS-1.2.18 for official wheels on PyPi.

Features
--------

- Support bulk copy (#279). Thanks to Simon.StJG (PR-689).
- Wheels on PyPI link FreeTDS statically.
- Wheels on PyPI linked against OpenSSL.
- Convert pymssql to a package. **Potential compatibility issue:** projects using
  low level *_mssql* module need to import it from *pymssql* first.

Bug fixes
---------

- Fixed a deadlock caused by a missing release of GIL (#540), thanks to
  filip.stefanak (PR-541) and Juraj Bubniak (PR-683).
- Prevents memory leak on login failure. Thanks to caogtaa and Simon.StJG (PR-690).
- Fix check for TDS version (#652 and #669).
- Documentation fixes. Thanks to Simon Biggs, Shane Kimble, Simon.StJG and Dale Evans.

Internals
---------

- Introduce script dev/build.py to build FreeTDS and pymssql wheels.
- Simplify setup.py, introduce environment variables to select FreeTDS includes
  and libraries.



Version 2.1.5 - 2020-09-17 - Mikhail Terekhov
=============================================

General
-------

- Revert deprecation

- Support Python-3.8. Update tests for Python-3.8 compatibility.

- Use correct language level for building Cython extension.

- Fix FreeTDS version checks. Add check for version 7.4.

- Use Github Actions for building wheels for Linux, macOS and Windows.

- Drop bundled FreeTDS-0.95 binaries.

- Unless some critical bug is discovered, this will be the last release with Python2
  support.


Version 2.1.4 - 2018-08-28 - Alex Hagerman
==========================================

General
-------

- Drop support for versions of FreeTDS older than 0.91.

- Add Python 3.7 support

- Drop Python 3.3 support

Features
--------

- Support for new in SQL Server 2008 ``DATE``, ``TIME`` and ``DATETIME2`` data
  types (GH-156). The following conditions need to be additionally met so
  values of these column types can be returned from the database as their
  native corresponding Python data types instead of as strings:

  * Underlying FreeTDS must be 0.95 or newer.
  * TDS protocol version in use must be 7.3 or newer.

  Thanks Ed Avis for the implementation. (GH-331)

Bug fixes
---------

- Fix ``tds_version``  ``_mssql`` connection property value for TDS version.
  7.1 is actually 7.1 and not 8.0.

Version 2.1.3 - 2016-06-22 - Ramiro Morales
===========================================

- We now publish Linux PEP 513 manylinux wheels on PyPI.
- Windows official binaries: Rollback changes to Windows binaries we had
  implemented in pymssql 2.1.2; go back to using:

  * A statically linked version of FreeTDS (v0.95.95)
  * No SSL support

Version 2.1.2 - 2016-02-10 - Ramiro Morales
===========================================

.. attention:: Windows users: You need to download and install additional DLLs

    pymssql version 2.1.2 includes a change in the official Windows binaries:
    FreeTDS isn't statically linked as it happened up to release 2.1.1, as that
    FreeTDS copy lacked SSL support.

    Please see http://pymssql.org/en/latest/freetds.html#windows for futher
    details.

    We are trying to find a balance between security and convenience and will
    be evaluating the situation for future releases. Your feedback is greatly
    welcome.

Features
--------

- Add ability to set TDS protocol version from pymssql when connecting to SQL
  Server. For the remaining pymssql 2.1.x releases its default value will be 7.1
  (GH-323)

- Add Dockerfile and a Docker image and instructions on how to use it (GH-258).
  This could be a convenient way to use pymssql without having to build stuff.
  See http://pymssql.readthedocs.org/en/latest/intro.html#docker
  Thanks Marc Abramowitz.

- Floating point values are now accepted as Stored Procedure arguments
  (GH-287). Thanks Runzhou Li (Leo) for the report and Bill Adams for the
  implementation.

- Send pymssql version in the appname TDS protocol login record field when the
  application doesn't provide one (GH-354)

Bug fixes
---------

- Fix a couple of very common causes of segmentation faults in presence of
  network a partition between a pymssql-based app and SQL Server (GH-147,
  GH-271) Thanks Marc Abramowitz. See also GH-373.

- Fix failures and inconsistencies in query parameter interpolation when
  UTF-8-encoded literals are present (GH-185). Thanks Bill Adams. Also, GH-291.

- Fix ``login_timeout`` parameter of ``pymssql.connect()`` (GH-318)

- Fixed some cases of ``cursor.rowcont`` having a -1 value after iterating
  over the value returned by pymssql cursor ``fetchmany()`` and ``fetchone()``
  methods (GH-141)

- Remove automatic treatment of string literals passed in queries that start
  with ``'0x'`` as hexadecimal values (GH-286)

- Fix build fatal error when using Cython >= 0.22 (GH-311)

Internals
---------

- Add Appveyor hosted CI setup for running tests on Windows (GH-347)

- Travis CI: Use newer, faster, container-based infrastructure. Also, test
  against more than one FreeTDS version.

- Make it possible to build official release files (sdist, wheels) on Travis &
  AppVeyor.

Version 2.1.1 - 2014-11-25 - Ramiro Morales
===========================================

Features
--------

- Custom message handlers (GH-139)

  The DB-Library API includes a callback mechanism so applications can provide
  functions known as *message handlers* that get passed informative messages
  sent by the server which then can be logged, shown to the user, etc.

  ``_mssql`` now allows you to install your own *message handlers* written in
  Python. See the ``_msssql`` examples and reference sections of the
  documentation for more details.

  Thanks Marc Abramowitz.

- Compatibility with Azure

  It is now possible to transparently connect to `SQL Server instances`_
  accessible as part of the Azure_ cloud services.

  .. note:: If you need to connect to Azure make sure you use FreeTDS 0.91 or
            newer.

- Customizable per-connection initialization SQL clauses (both in ``pymssql``
  and ``_mssql``) (GH-97)

  It is now possible to customize the SQL statements sent right after the
  connection is established (e.g. ``'SET ANSI_NULLS ON;'``). Previously
  it was a hard-coded list of queries. See the ``_mssql.MSSQLConnection``
  documentation for more details.

  Thanks Marc Abramowitz.

- Added ability to handle instances of ``uuid.UUID`` passed as parameters for
  SQL queries both in ``pymssql`` and ``_mssql``. (GH-209)

  Thanks Marat Mavlyutov.

- Allow using `SQL Server autocommit mode`_ from ``pymssql`` at connection
  opening time. This allows e.g. DDL statements like ``DROP DATABASE`` to be
  executed. (GH-210)

  Thanks Marat Mavlyutov.

- Documentation: Explicitly mention minimum versions supported of Python (2.6)
  and SQL Server (2005).

- Incremental enhancements to the documentation.

.. _SQL Server instances: http://www.windowsazure.com/en-us/services/sql-database/
.. _Azure: https://www.windowsazure.com/
.. _SQL Server autocommit mode: http://msdn.microsoft.com/en-us/library/ms187878%28v=sql.105%29.aspx

Bug fixes
---------

- Handle errors when calling Stored Procedures via the ``.callproc()`` pymssql
  cursor method. Now it will raise a DB-API ``DatabaseException``; previously
  it allowed a ``_mssql.MSSQLDatabaseException`` exception to surface.

- Fixes in ``tds_version`` ``_mssql`` connections property value

  Made it work with TDS protocol version 7.2. (GH-211)

  The value returned for TDS version 7.1 is still 8.0 for backward
  compatibility (this is because such feature got added in times when
  Microsoft documentation labeled the two protocol versions that followed 7.0
  as 8.0 and 9.0; later it changed them to 7.1 and 7.2 respectively) and will
  be corrected in a future release (2.2).

- PEP 249 compliance (GH-251)

  Added type constructors to increase compatibility with other libraries.

  Thanks Aymeric Augustin.

- pymssql: Made handling of integer SP params more robust (GH-237)

- Check lower bound value when convering integer values from to Python to SQL
  (GH-238)

Internals
---------

- Completed migration of the test suite from nose to py.test.

- Added a few more test cases to our suite.

- Tests: Modified a couple of test cases so the full suite can be run against
  SQL Server 2005.

- Added testing of successful build of documentation to Travis CI script.

- Build process: Cleanup intermediate and ad-hoc anciliary files (GH-231,
  GH-273)

- setup.py: Fixed handling of release tarballs contents so no extraneous files
  are shipped and the documentation tree is actually included. Also, removed
  unused code.

Version 2.1.0 - 2014-02-25 - `Marc Abramowitz <http://marc-abramowitz.com/>`_
=============================================================================

Features
--------

- Sphinx-based documentation (GH-149)

  Read it online at http://pymssql.org/

  Thanks, Ramiro Morales!

  See:

  * https://github.com/pymssql/pymssql/pull/149
  * https://github.com/pymssql/pymssql/pull/162
  * https://github.com/pymssql/pymssql/pull/164
  * https://github.com/pymssql/pymssql/pull/165
  * https://github.com/pymssql/pymssql/pull/166
  * https://github.com/pymssql/pymssql/pull/167
  * https://github.com/pymssql/pymssql/pull/169
  * https://github.com/pymssql/pymssql/pull/174
  * https://github.com/pymssql/pymssql/pull/175

- "Green" support (GH-135)

  Lets you use pymssql with cooperative multi-tasking systems like
  gevent and have pymssql call a callback when it is waiting for a
  response from the server. You can set this callback to yield to
  another greenlet, coroutine, etc. For example, for gevent, you could
  do::

      def wait_callback(read_fileno):
          gevent.socket.wait_read(read_fileno)

      pymssql.set_wait_callback(wait_callback)

  The above is useful if you're say, running a gunicorn server with the
  gevent worker. With this callback in place, when you send a query to
  SQL server and are waiting for a response, you can yield to other
  greenlets and process other requests. This is super useful when you
  have high concurrency and/or slow database queries and lets you use
  less gunicorn worker processes and still handle high concurrency.

  See https://github.com/pymssql/pymssql/pull/135

- Better error messages.

  E.g.: For a connection failure, instead of:

      pymssql.OperationalError: (20009, 'Net-Lib error during Connection
      refused')

  the dberrstr is also included, resulting in:

      pymssql.OperationalError: (20009, 'DB-Lib error message 20009,
      severity 9:\nUnable to connect: Adaptive Server is unavailable or
      does not exist\nNet-Lib error during Connection refused\n')

  See:
  * https://github.com/pymssql/pymssql/pull/151

  In the area of error messages, we also made this change:

  execute: Raise ColumnsWithoutNamesError when as_dict=True and missing
  column names (GH-160)

  because the previous behavior was very confusing; instead of raising
  an exception, we would just return row dicts with those columns
  missing. This prompted at least one question on the mailing list
  (https://groups.google.com/forum/?fromgroups#!topic/pymssql/JoZpmNZFtxM),
  so we thought it was better to handle this explicitly by raising an
  exception, so the user would understand what went wrong.

  See:
  * https://github.com/pymssql/pymssql/pull/160
  * https://github.com/pymssql/pymssql/pull/168

- Performance improvements

  You are most likely to notice a difference from these when you are
  fetching a large number of rows.

  * Reworked row fetching (GH-159)

    There was a rather large amount of type conversion occuring when
    fetching a row from pymssql. The number of conversions required have
    been cut down significantly with these changes.
    Thanks Damien, Churchill!

    See:
    * https://github.com/pymssql/pymssql/pull/158
    * https://github.com/pymssql/pymssql/pull/159

  * Modify get_row() to use the CPython tuple API (GH-178)

    This drops the previous method of building up a row tuple and switches
    to using the CPython API, which allows you to create a correctly sized
    tuple at the beginning and simply fill it in. This appears to offer
    around a 10% boost when fetching rows from a table where the data is
    already in memory.
    Thanks Damien, Churchill!

    See:
    * https://github.com/pymssql/pymssql/pull/178

- MSSQLConnection: Add `with` (context manager) support (GH-171)

  This adds `with` statement support for MSSQLConnection in the `_mssql`
  module -- e.g.::

      with mssqlconn() as conn:
          conn.execute_query("SELECT @@version AS version")

  We already have `with` statement support for the `pymssql` module.
  See:

  * https://github.com/pymssql/pymssql/pull/171

- Allow passing in binary data (GH-179)

  Use the bytesarray type added in Python 2.6 to signify that this is
  binary data and to quote it accordingly. Also modify the handling of
  str/bytes types checking the first 2 characters for b'0x' and insert
  that as binary data.
  See:

  * https://github.com/pymssql/pymssql/pull/179

- Add support for binding uuid.UUID instances to stored procedures input
  params (GH-143)
  Thanks, Ramiro Morales!

  See:
  * https://github.com/pymssql/pymssql/pull/143
  * https://github.com/pymssql/pymssql/commit/1689c83878304f735eb38b1c63c31e210b028ea7

- The version number is now stored in one place, in pymssql_version.h
  This makes it easier to update the version number and not forget any
  places, like I did with pymssql 2.0.1

  * See https://github.com/pymssql/pymssql/commit/fd317df65fa62691c2af377e4661defb721b2699

- Improved support for using py.test as test runner (GH-183)

  * See: https://github.com/pymssql/pymssql/pull/183

- Improved PEP-8 and pylint compliance

Bug Fixes
---------

- GH-142 ("Change how ``*.pyx`` files are included in package") - this
  should prevent pymssql.pyx and _mssql.pyx from getting copied into the
  root of your virtualenv. Thanks, @Arfrever!

  * See: https://github.com/pymssql/pymssql/issues/142

- GH-145 ("Prevent error string growing with repeated failed connection
  attempts.")

  See:

  * https://github.com/pymssql/pymssql/issues/145
  * https://github.com/pymssql/pymssql/pull/146

- GH-151 ("err_handler: Don't clobber dberrstr with oserrstr")

  * https://github.com/pymssql/pymssql/pull/151

- GH-152 ("_mssql.pyx: Zero init global last_msg_* vars")
  See: https://github.com/pymssql/pymssql/pull/152

- GH-177 ("binary columns sometimes are processed as varchar")
  Better mechanism for pymssql to detect that user is passing binary
  data.

  See: https://github.com/pymssql/pymssql/issues/177

- buffer overflow fix (GH-182)

  * See: https://github.com/pymssql/pymssql/pull/181
  * See: https://github.com/pymssql/pymssql/pull/182

- Return uniqueidentifer columns as uuid.UUID objects on Python 3


See `ChangeLog.old`_ for older history...

.. _PyPI: https://pypi.python.org/pypi/pymssql/2.0.0
.. _Travis CI: https://travis-ci.org/pymssql/pymssql
.. _Cython: http://cython.org/
.. _ChangeLog.old: https://github.com/pymssql/pymssql/blob/master/ChangeLog.old
