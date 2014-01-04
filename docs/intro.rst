============
Introduction
============

Architecture
============

The pymssql package consists of two modules:

* :mod:`pymssql` -- use it if you care about DB-API compliance, or if you are
  accustomed to DB-API syntax,
* :mod:`_mssql` -- use it if you care about performance and ease of use
  (``_mssql`` module is easier to use than ``pymssql``).

Project Discussion
==================

Discussions and support take place on pymssql mailing list here:
http://groups.google.com/group/pymssql, you can participate via web, e-mail or
read-only subscribing to the mailing list feeds.

This is the best place to get help, please feel free to drop by and ask a
question.

Project Status
==============

**Current release**: 2.x is the branch under current development. It is a
complete rewrite using Cython and the latest FreeTDS libraries (which remove
many of the limitations of previous versions of FreeTDS).

**Legacy release**: 1.0.3 is the legacy version and is no longer under active
development.

Current Development
===================

Official development repositories and issue trackers have been moved to GitHub
at https://github.com/pymssq/pymssql.

We would be happy to have a couple more developers and community members that
can help with maintenance and refreshing this documentation. If interested,
please connect with us on the mailing list.

Things you might be interested in:

* `PYPI Page`_, recent changelog, and Downloads
* `FreeTDS User Guide`_

.. _PYPI Page: https://pypi.python.org/pypi/pymssql/
.. _FreeTDS User Guide: http://www.freetds.org/userguide/
