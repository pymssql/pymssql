===============================
Building and developing pymssql
===============================

Building
========

To build pymssql you should have:

* Python >= 2.7 including development files. Please research your OS usual
  software distribution channels, e.g, ``python-dev`` or ``python-devel``
  packages.
* Cython >= 0.19.1
* FreeTDS >= 0.91 including development files. Please research your OS usual
  software distribution channels, e.g, ``freetds-dev`` or ``freetds-devel``
  packages.
* Microsoft SQL Server

.. note::
    If developing on Windows you will want to make sure you install debug symbols.
    For more information see https://docs.python.org/3/using/windows.html#installation-steps
.. note::
    If you need to connect to Azure make sure FreeTDS is built with SSL support.
    Instructions on how to do this are out of the scope of this document.

Windows
-------


Required Tools
______________
In addition to the requirements above when developing ``pymssql`` on the Windows
platform you will need these additional tools installed:

* Visual Studio C++ Compiler Tools
* Developer Command Prompt for Visual Studio
* `Cmake <https://cmake.org/download/>`_
* `7Zip <https://www.7-zip.org/download.html>`_

For C++ and the Developer Command Prompt the easiest path is installing Visual Studio.
When installing make sure you select the C++ libraries and components. Also make sure that
Visual Studio installs nmake with the C++ library installs.

* https://visualstudio.microsoft.com/vs/community/

.. note::
    One thing to be aware of is which version of Python you are using relative to which
    C++ compilers you have installed. When building on Windows you should make sure you
    have the required compiler, pip and setuptools versions installed. For more 
    information see https://wiki.python.org/moin/WindowsCompilers


Required Libraries
__________________

Developing ``pymssql`` on Windows also requires the following libraries:

* `FreeTDS <http://www.freetds.org/>`_
* `iconv <https://www.gnu.org/software/libiconv/>`_

For development you will want ``freetds`` to be available in your project path.
You can find prebuilt artifacts at the `FreeTDS Appveyor project <https://ci.appveyor.com/project/FreeTDS/freetds?branch=master>`_

To download select the job name that matches your environment (platform, version and tds
version) and then click the artifacts tag. You can download the zip file with or without
ssl depending on your needs.


.. note::
    Remove the existing ``freetds0.95`` directory in the ``pymssql`` project directory

Extract the .zip artifact into your project path into a directory named ``freetds``

    ``C:\\%USERPATH%\\pymssql\\freetds``

You will also need to remove the branch tag from the artifact directory (for instance
``master`` from ``vs2015_64-master``) or update the ``INCLUDE`` and ``LIB`` environment
variables so that the compiler and linker are able to find the path to
``%PROJECTROOT%\\freetds\\<artifact folder>\\include`` and
``%PROJECTROOT%\\freetds\\<artifact folder>\\lib``
in the build step.


.. note::
    If you decide to add the directories to ``INCLUDE`` and ``LIB`` the below provide example
    commands

    .. code-block::

        set INCLUDE=%INCLUDE%;%USERPROJECTS%\\pymssql\\freetds\\vs2015_64-master\\include

        set LIB=%LIB%;%USERPROJECTS%\\pymssql\\freetds\\vs2015_64-master\\lib

In addition to ``freetds`` you will want ``iconv`` available on your project path. For iconv
on Windows we recommend https://github.com/win-iconv/win-iconv.git. We will retrieve this in
an upcoming build step.

If you prefer to build FreeTDS on your own please refer to the FreeTDS `config <http://www.freetds.org/>`_ and
`os issues <http://www.freetds.org/userguide/osissues.htm>`_ build pages.


Required Environment Variables
______________________________

You will need to set the following environment variables in
Visual Studio Developer Command Prompt before installing iconv.

* set PYTHON_VERSION=<Python Version>
* set PYTHON_ARCH=<Python Architecture>
* set VS_VER=<MSVC Compiler Version>

Example:

    .. code-block::

        set PYTHON_VERSION=3.6.6
        set PYTHON_ARCH=64
        set VS_VER=2015


Installing iconv
________________

``pymssql`` expects ``iconv`` header and lib objects and to be available in the ``build\\include``
and ``build\\bin`` directories

From the root of your project (pymssql directory) run:

.. code-block::

    powershell dev\appveyor\install-win-iconv.ps1

This is a powershell script that will download `win-iconv <https://github.com/win-iconv/win-iconv/>`_
from the previously mentioned GitHub repository, build and move the artifacts to the
directory that ``pymssql`` will use with ``Cython``.

.. note::

    If you receive the following TLS error that is probably due to a mismatch between powershells
    TLS version and GitHub.

    .. code-block::

        Exception calling "DownloadFile" with "2" argument(s): "The request was aborted: Could not create SSL/TLS secure channel."

    You can add this line to ``%PROJECTROOT%\\dev\\appveyor\\install-win-iconv.ps1``

    .. code-block:: PowerShell

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    On line 3 and the powershell script should run with TLS1.2. See issue `547 <https://github.com/pymssql/pymssql/issues/547>`_
    for more information


Required Python Packages
________________________
For Python you will need the following packages installed into your virtual environment:

* Cython
* pytest == 3.2.5
* SQLAlchemy
* wheel


Running the build
_________________

With the above libraries, pacakges and potential environment variables in place we are ready to
build.

At the root of the project with your virtual environment activated run

.. code-block::

    python setup.py build

If there are no errors you are then ready to run

.. code-block::

    python setup.py install

or continue on to the `Testing`_ documentation which advises using

.. code-block::

    python setup.py develop.

To report any issues with building on Windows please use the `mailing list <https://groups.google.com/forum/#!forum/pymssql>`_


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
