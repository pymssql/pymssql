.. pymssql documentation master file, created by
   sphinx-quickstart on Sat Dec 28 22:08:07 2013.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

=================================================
pymssql -- SQL Server database adapter for Python
=================================================

A simple database interface to `Microsoft SQL Server`_ (MS-SQL) for `Python`_
that builds on top of `FreeTDS`_ to provide a Python DB-API (`PEP-249`_)
interface to *SQL Server*.

Features include:

* Unicode friendly
* Python 3 friendly
* Works on most popular operating systems
* Written in Cython_ for performance
* Includes a supported and documented low-level module (``_mssql``) that you
  can use instead of the DB-API
* Supports stored procedures with both return values and output parameters
* A comprehensive test suite

pymssql is licensed under the terms of the GNU LGPL license.

.. _Microsoft SQL Server: http://www.microsoft.com/sqlserver/
.. _Python: http://www.python.org/
.. _PEP-249: http://www.python.org/dev/peps/pep-0249/
.. _FreeTDS: http://www.freetds.org/
.. _Cython: http://cython.org


Contents
========

.. toctree::
   :maxdepth: 2

   intro
   pymssql_examples
   _mssql_examples
   release_notes
   freetds
   ref/pymssql
   ref/_mssql
   migrate_1_x_to_2_x
   faq
   building_and_developing
   freetds_and_dates
   todo
   changelog
   history

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
