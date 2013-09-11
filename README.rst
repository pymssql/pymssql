pymssql
#######

.. image:: https://pypip.in/d/pymssql/badge.png
        :target: https://crate.io/packages/pymssql

.. image:: https://pypip.in/v/pymssql/badge.png
        :target: https://crate.io/packages/pymssql

Introduction
============

pymssql is the Python language extension module that provides access to Microsoft SQL Servers from Python scripts. It is compliant with `Python DB-API 2.0 Specification <http://www.python.org/dev/peps/pep-0249/>` and works on most popular operating systems.

Building
========

To build pymssql you should have:

* python >= 2.5 including development files. Please research your OS usual
  software distribution channels, e.g, ``python-dev`` or ``python-devel``
  packages.
* Cython >= 0.15
* FreeTDS >= 0.91 including development files. Please research your OS usual
  software distribution channels, e.g, ``freetds-dev`` or ``freetds-devel``
  packages.

Windows
-------

MinGW
^^^^^

Add to the above requirements:

* MinGW

then you can run::

  python setup.py build -c mingw32

which will build pymssql in the normal python fashion.

MS Visual C++
^^^^^^^^^^^^^

Environment Setup:
~~~~~~~~~~~~~~~~~~

The commands below should be ran inside a Visual Studio command prompt or a
command prompt window where the ``vcsvars*.bat`` file has been previously run so
it can set the needed environment vars.

Building FreeTDS:
~~~~~~~~~~~~~~~~~

Build FreeTDS from the current_ or stable_ tarball.

.. _current: http://ibiblio.org/pub/Linux/ALPHA/freetds/current/
.. _stable: http://ibiblio.org/pub/Linux/ALPHA/freetds/stable/

Use ``nmake`` (included with VS C++) to build FreeTDS.  To do that,

Define in the environment or on the command line:

1. ``CONFIGURATION`` = ``debug``/``release``
2. ``PLATFORM`` = ``win32``/``x64``

These will determine what is built and where outputs are placed.

Example invocations::

  nmake.exe -f Nmakefile -nologo PLATFORM=win32 CONFIGURATION=debug
  nmake.exe -f Nmakefile -nologo build-win32d

Fixing build errors:  I ran into a couple build errors when using VS 2008, see
the following links for resolutions:

- http://www.freetds.org/userguide/osissues.htm
- http://lists.ibiblio.org/pipermail/freetds/2010q4/026343.html

When this is done, the following files should be available (depending on
``CONFIGURATION`` and ``PLATFORM`` used above)::

  src\dblib\<PLATFORM>\<CONFIGURATION>\db-lib.lib
  src\tds\<PLATFORM>\<CONFIGURATION>\tds.lib

for example::

  src\dblib\win32\release\db-lib.lib
  src\dblib\win32\release\tds.lib

Those files should then be copied to::

  <pymssql root>\freetds\vs2008_<bitness>\lib\

for example::

  <pymssql root>\freetds\vs2008_32\lib\
  <pymssql root>\freetds\vs2008_64\lib\

The location obviously depends on whether you are performing a 32 or 64 bit
build.

.. note::

  This process is currently only tested with Visual Studio 2008 targeting a
  32-bit build. If you run into problems, please post to the mailing list.

Then you can simply run::

  python setup.py build

or other ``setup.py`` commands as needed.

Unix
----

To build on Unix you must also have:

* gcc

Then you can simply run::

  python setup.py build

or other ``setup.py`` commands as needed.

Testing
=======

.. danger::

  ALL DATA IN TESTING DBS WILL BE DELETED !!!!

You will need to install two additional packages for testing::

  easy_install nose SQLAlchemy

You should build the package with::

  python setup.py develop

You need to setup a ``tests.cfg`` file in ``tests/`` with the correct DB
connection information for your environement::

  cd tests/
  cp tests.cfg.tpl tests.cfg
  vim|emacs|notepad tests.cfg

To run the tests::

  cd tests/
  nosetests

Which will go through and run all the tests with the settings from the ``DEFAULT``
section of ``tests.cfg``.

To run with a different ``tests.cfg`` section::

  nosetests --pymssql-section=<secname>

example::

  nosetests --pymssql-section=AllTestsWillRun

to avoid slow tests::

  nosetests -a '!slow'

to select specific tests to run::

  nosetests test_types.py
  nosetests test_types.py test_sprocs.py
  nosetests test_types.py:TestTypes
  nosetests test_types.py:TestTypes.test_image
