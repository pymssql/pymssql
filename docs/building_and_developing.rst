===============================
Building and developing pymssql
===============================

Required software
_________________

To build ``pymssql`` you should have:

* `Python <https://python.org>`_ >= 3.6 including development files.
  Please research your OS usual software distribution channels,
  e.g, ``python-dev`` or ``python-devel`` packages on Linux.
* `Cython <https://cython.org>`_ -
  to compile ``pymssql`` source files to ``C``.
* `setuptools <https://pypi.org/project/setuptools>`_ -
  for ``setup.py`` support.
* `setuptools_scm <https://pypi.org/project/setuptools_scm>`_ -
  for extracting version information from ``git``.
* `wheel <https://pypi.org/project/wheel/>`_ -
  for building python wheels.
* `FreeTDS <https://freetds.org>`_ >= 1.2 including development files.
  Please research your OS usual software distribution channels,
  e.g, ``freetds-dev`` or ``freetds-devel`` packages on Linux.
* `GNU gperf <https://www.gnu.org/software/gperf/>`_ -
  a perfect hash function generator, needed for FreeTDS.
  On Windows prebuild version is available from
  `Chocolatey <https://chocolatey.org/packages/gperf>`_.
* `win-iconv <https://github.com/win-iconv/win-iconv>`_
  (Windows only) - developing ``pymssql`` on Windows also requires this library
  to build FreeTDS.
* `OpenSSL <https://openssl.org>`_ - If you need to connect to Azure make sure
  FreeTDS is built with SSL support.
  Please research your OS usual software distribution channels.
  On Windows one easy way is to get prebuild libraries from
  `Chocolatey <https://chocolatey.org/packages/openssl>`_.

For testing the follwing is required:

* Microsoft SQL Server.
  One possibility is to use official docker images for Microsoft SQL Server
  on Linux available `here <https://hub.docker.com/_/microsoft-mssql-server>`_.
* `pytest <https://pypi.org/project/pytest/>`_ -
  to run the tests.
* `pytest-timeout <https://pypi.org/project/pytest-timeout/>`_ -
  for limiting long running tests.
* `psutil <https://pypi.org/project/psutil/>`_ -
  for memory monitoring.
* `gevent <https://pypi.org/project/gevent/>`_
  (optional) - for async tests.
* `Sqlalchemy <https://pypi.org/project/SQLAlchemy/>`_ -
  (optional) - for basic Sqlalchemy testing.

To build documentation `Sphinx <https://pypi.org/project/Sphinx/>`_ and
`sphinx-rtd-theme <https://pypi.org/project/sphinx-rtd-theme/>`_ are also needed.


Windows
_______

In addition to the requirements above when developing ``pymssql`` on the Windows
platform you will need these additional tools installed:

* Visual Studio C++ Compiler Tools, see
  `Python documentation <https://devguide.python.org/setup/#windows>`_
  for instructions on what components to install.
* `Cmake <https://cmake.org/download/>`_
  for building FreeTDS and win-iconv.
* `curl <https://chocolatey.org/packages/curl>`_ -
  for downloading FreeTDS and win-iconv.

.. note::
    If Windows computer is not readily available then
    `virtual machine <https://developer.microsoft.com/en-us/windows/downloads/virtual-machines/>`_
    from Microsoft could be used.


Building ``pymssql`` wheel
__________________________

It is recommended to use python virtual environment for building ``pymssql``::

    python3 -m venv <path_to_pve>

if using ``bash``::

    source <path_to_pve>/bin/activate

or if on Windows::

    <path_to_pve>/scripts/activate.bat

then install required python packages::

    pip intall -U pip
    pip install dev/requirements-dev.txt

If and now build wheel::

    python3 setup.py bdist_wheel

or::

    pip wheel .


Environment Variables
_____________________

By default ``setup.py`` links against OpenSSL if it is available,
links FreeTDS statically and looks for FreeTDS headers and libraries
in places standard for the OS, but
there are several environment variables for build customization:

LINK_FREETDS_STATICALLY = [YES|NO|1|0|TRUE|FALSE]
    default - YES,
    defines if FreeTDS is linked statically or not.

LINK_OPENSSL = [YES|NO|1|0|TRUE|FALSE]
    default - YES,
    defines if ``pymssql`` is linked against OpenSSL.

PYMSSQL_FREETDS
    if defined, determines prefix of the FreeTDS installation.

PYMSSQL_FREETDS_INCLUDEDIR
    if defined, alows to fine tune where to search for FreeTDS headers.

PYMSSQL_FREETDS_LIBDIR
    if defined, alows to fine tune where to search for FreeTDS libraries.

Example:

    .. code-block:: console

        PYMSSQL_FREETDS=/tmp/freetds python3 setup.py bdist_wheel



Building FreeTDS and ``pymssql`` from scratch
_____________________________________________

If one wants to use some specific FreeTDS version then there is a script
``dev/build.py`` that downloads and builds required FreeTDS version sources
(and win-conv on Windows) and builds ``pymssql`` wheel.
Run::

    python dev/build.py --help

for supported options.


Testing
_______

.. danger::

  ALL DATA IN TESTING DBS WILL BE DELETED !!!!

You will need to install two additional packages for testing::

  easy_install pytest SQLAlchemy

You should build the package with::

  python setup.py develop

You need to setup a ``tests.cfg`` file in ``tests/`` with the correct DB
connection information for your environment::

  cp tests/tests.cfg.tpl tests/tests.cfg
  vim|emacs|notepad tests/tests.cfg

To run the tests::

  cd tests # optional
  py.test

Which will go through and run all the tests with the settings from the ``DEFAULT``
section of ``tests.cfg``.

To run with a different ``tests.cfg`` section::

  py.test --pymssql-section=<secname>

example::

  py.test --pymssql-section=AllTestsWillRun

to avoid slow tests::

  py.test -m "not slow"

to select specific tests to run::

  py.test tests/test_types.py
  py.test tests/test_types.py tests/test_sprocs.py
  py.test tests/test_types.py::TestTypes
  py.test tests/test_types.py::TestTypes::test_image
