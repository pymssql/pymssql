
pymssql - DB-API interface to Microsoft SQL Server
==================================================

.. image:: https://github.com/pymssql/pymssql/workflows/Linux/badge.svg
        :target: https://github.com/pymssql/pymssql/actions?query=workflow%3A%22Linux%22

.. image:: https://github.com/pymssql/pymssql/workflows/macOS/badge.svg
        :target: https://github.com/pymssql/pymssql/actions?query=workflow%3A%22macOS%22

.. image:: https://github.com/pymssql/pymssql/workflows/Windows/badge.svg
        :target: https://github.com/pymssql/pymssql/actions?query=workflow%3A%22Windows%22

.. image:: http://img.shields.io/pypi/dm/pymssql.svg
        :target: https://pypi.python.org/pypi/pymssql/

.. image:: http://img.shields.io/pypi/v/pymssql.svg
        :target: https://pypi.python.org/pypi/pymssql/

A simple database interface for `Python`_ that builds on top of `FreeTDS`_ to
provide a Python DB-API (`PEP-249`_) interface to `Microsoft SQL Server`_.

.. _Microsoft SQL Server: http://www.microsoft.com/sqlserver/
.. _Python: http://www.python.org/
.. _PEP-249: http://www.python.org/dev/peps/pep-0249/
.. _FreeTDS: http://www.freetds.org/

Detailed information on pymssql is available on the website:

`pymssql.readthedocs.io <https://pymssql.readthedocs.io/en/stable/>`_

New development is happening on GitHub at:

`github.com/pymssql/pymssql <https://github.com/pymssql/pymssql>`_

There is a Google Group for discussion at:

`groups.google.com <https://groups.google.com/forum/?fromgroups#!forum/pymssql>`_


Getting started
===============

Generally, you will want to install pymssql with:

.. code-block:: bash

    pip install pymssql

Most of the times this should be all what's needed.

  .. note::

    The official pymssql wheel packages for Linux, Mac OS and Windows
    bundle a static copy of FreeTDS so no additional dependency download or
    compilation steps are necessary
    and have SSL support so they can be used to connect to Azure.

