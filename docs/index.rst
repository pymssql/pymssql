.. pymssql documentation master file, created by
   sphinx-quickstart on Sat Dec 28 22:08:07 2013.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

=======
pymssql
=======

Contents:

.. toctree::
   :maxdepth: 1

   pymssql_examples
   _mssql_examples
   release_notes
   freetds
   ref/pymssql
   ref/_mssql
   faq

Introduction
============

pymssql is the Python language extension module that provides access to
Microsoft SQL Servers from Python scripts. It is compliant with Python DB-API
2.0 Specification and works on most popular operating systems.

The pymssql package consists of two modules:

* ``pymssql`` -- use it if you care about DB-API compliance, or if you are
  accustomed to DB-API syntax,
* ``_mssql`` -- use it if you care about performance and ease of use (``_mssql``
  module is easier to use than ``pymssql``).

Project Discussion
==================

Discussions and support take place on pymssql mailing list here:
http://groups.google.com/group/pymssql, you can participate via web, e-mail or
read-only subscribing to the mailing list feeds.

This is the best place to get help, please feel free to drop by and ask a
question.

Project Status
==============

Current release: 2.x is the branch under current development. It is a complete
rewrite using Cython and the latest FreeTDS libraries (which remove many of the
limitations of previous versions of FreeTDS).

Legacy release: 1.0.3 is the legacy version and is no longer under active
development.

Current Development
===================

Official development repositories and issue trackers have been moved to GitHub
at https://github.com/pymssq/pymssql.

We would be happy to have a couple more developers help with maintenance and
refreshing our documentation. If interested, please connect with us on the
mailing list.

Things you might be interested in:

* `PYPI Page`_, recent changelog, and Downloads
* pymssql `mailing list`_
* `FreeTDS User Guide`_

.. _PYPI Page: https://pypi.python.org/pypi/pymssql/
.. _mailing list: http://groups.google.com/group/pymssql

.. _FreeTDS User Guide: http://www.freetds.org/userguide/

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
