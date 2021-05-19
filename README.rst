
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

pymssql wheels are available from PyPi. To install it run:

.. code-block:: bash

    pip install -U pip
    pip install pymssql

Most of the times this should be all what's needed.
The official pymssql wheels bundle a static copy of FreeTDS
and have SSL support so they can be used to connect to Azure.

.. note::
   On some Linux distributions `pip` version is too old to support all
   the flavors of manylinux wheels, so upgrading `pip` is necessary.
   An example of such distributions would be Ubuntu 18.04 or
   Python3.6 module in RHEL8 and CentOS8.


Basic example
=============

.. code-block:: python

    conn = pymssql.connect(server, user, password, "tempdb")
    cursor = conn.cursor(as_dict=True)

    cursor.execute('SELECT * FROM persons WHERE salesrep=%s', 'John Doe')
    for row in cursor:
        print("ID=%d, Name=%s" % (row['id'], row['name']))

    conn.close()
