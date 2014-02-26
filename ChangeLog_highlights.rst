Recent Changes
==============

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
	module -- e.g.:

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

- GH-142 ("Change how *.pyx files are included in package") - this
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

Version 2.0.1 - 2013-10-27 - `Marc Abramowitz <http://marc-abramowitz.com/>`_
-----------------------------------------------------------------------------
* MANIFEST.in: Add "\*.rst" to prevent install error: "IOError: [Errno 2] No
  such file or directory: 'ChangeLog_highlights.rst'"

Version 2.0.0 - 2013-10-25 - `Marc Abramowitz <http://marc-abramowitz.com/>`_
-----------------------------------------------------------------------------
* First official release of pymssql 2.X (`Cython`_-based code) to `PyPI`_!
* Compared to pymssql 1.X, this version offers:

  * Better performance
  * Thread safety
  * Fuller test suite
  * Support for Python 3
  * Continuous integration via `Travis CI`_
  * Easier to understand code, due to `Cython`_

See `ChangeLog`_ for older history...

.. _PyPI: https://pypi.python.org/pypi/pymssql/2.0.0
.. _Travis CI: https://travis-ci.org/pymssql/pymssql
.. _Cython: http://cython.org/
.. _ChangeLog: https://github.com/pymssql/pymssql/blob/master/ChangeLog
