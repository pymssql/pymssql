.. pymssql documentation master file, created by
   sphinx-quickstart on Sat Dec 28 22:08:07 2013.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

=======
pymssql
=======

A simple database interface for `Python`_ that builds on top of `FreeTDS`_ to
provide a Python DB-API (`PEP-249`_) interface to `Microsoft SQL Server`_.

The 2.x branch of pymssql is built on the latest release of FreeTDS which
**removes many of the limitations** found with older FreeTDS versions and
the 1.x branch.

Resources
---------


* `Docs & Project Home`_

  * :doc:`Quick Start <pymssql_examples>`
  * :doc:`FAQ & Troubleshooting <faq>`

* `PyPI Project`_
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
* Compatible with cooperative multi-tasking systems (gevent, etc.)
* Can be used to connect to Azure

License
-------

pymssql is licensed under the terms of the GNU LGPL license.

Survey
------

Can you take a minute and fill out this survey to help us prioritize development tasks?

https://www.surveymonkey.com/s/KMQ8BM5

Survey Results
^^^^^^^^^^^^^^

* Excel (.xls) -- http://cl.ly/1R0m2B342I0k/download/SurveySummary_04092014.xls
* PDF -- http://cl.ly/2P3o1N1K2h3p/download/Data_All_140409.pdf

.. _Docs & Project Home: http://pymssql.org
.. _Python: http://www.python.org/
.. _FreeTDS: http://www.freetds.org/
.. _PEP-249: http://www.python.org/dev/peps/pep-0249/
.. _Microsoft SQL Server: http://www.microsoft.com/sqlserver/
.. _Cython: http://cython.org
.. _PyPI Project: https://pypi.python.org/pypi/pymssql/
.. _GitHub: https://github.com/pymssql/pymssql
.. _FreeTDS User Guide:  http://www.freetds.org/userguide/
.. _Discussion: https://groups.google.com/forum/?fromgroups#!forum/pymssql


Documentation
-------------

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
   azure
   docker
   changelog
   todo

Indices and tables
------------------

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
