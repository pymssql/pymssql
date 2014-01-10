.. pymssql documentation master file, created by
   sphinx-quickstart on Sat Dec 28 22:08:07 2013.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

====================
pymssql Introduction
====================

.. image:: https://travis-ci.org/pymssql/pymssql.png?branch=master
        :target: https://travis-ci.org/pymssql/pymssql

.. image:: https://pypip.in/d/pymssql/badge.png
        :target: https://crate.io/packages/pymssql

.. image:: https://pypip.in/v/pymssql/badge.png
        :target: https://crate.io/packages/pymssql

A simple database interface to `Microsoft SQL Server`_ (MS-SQL) for `Python`_
that builds on top of `FreeTDS`_ to provide a Python DB-API (`PEP-249`_)
interface to *SQL Server*.


The 2.x branch of pymssql is built on the latest release of FreeTDS which 
**removes many of the limitations** found with older FreeTDS versions and 
the 1.x branch.

Resources
---------


* `Docs & Project Home`_

  * Quick Start: coming soon :)
  * `FAQ & Troubleshooting`_
 
* `PYPI Project`_
* GitHub_
* Discussion_ 
* `FreeTDS User Guide`_

Features
--------

* Unicode friendly
* Python 3 friendly
* Works on most popular operating systems
* Written in Cython_ for performance
* Includes a supported and documented low-level module (``_mssql``) that you
  can use instead of the DB-API
* Supports stored procedures with both return values and output parameters
* A comprehensive test suite

License
-------

pymssql is licensed under the terms of the GNU LGPL license.

Survey
------

Can you take a minute and fill out this survey to help us prioritize development tasks?

https://www.surveymonkey.com/s/KMQ8BM5

Recent Changes
--------------

<Need to import>

.. _Docs & Project Home: http://pymssql.org
.. _Microsoft SQL Server: http://www.microsoft.com/sqlserver/
.. _Python: http://www.python.org/
.. _PEP-249: http://www.python.org/dev/peps/pep-0249/
.. _FreeTDS: http://www.freetds.org/
.. _Cython: http://cython.org
.. _FAQ & Troubleshooting: http://pymssql.org/faq.html
.. _PYPI Project: https://pypi.python.org/pypi/pymssql/
.. _GitHub: https://github.com/pymssql/pymssql
.. _FreeTDS User Guide:  http://www.freetds.org/userguide/
.. _Discussion: https://groups.google.com/forum/?fromgroups#!forum/pymssql


Documentation 
=============

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
