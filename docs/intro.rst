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

Supported related software
==========================

:Python: Python 2.x: 2.6 or newer. Python 3.x: 3.3 or newer.
:FreeTDS: 0.82 or newer.
:Cython: 0.15 or newer.
:Microsoft SQL Server: 2005 or newer.

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

.. note:: This documentation is for pymssql 2.x.

    The document set you are reading describes exclusively the code base of
    pymssql 2.x and newer. All description of functionality, workarounds,
    limitations, dependencies, etc. of older revisions has been removed.

    If you need help for building/using pymssql 1.x please refer to the old
    `Google Code documentation Wiki`_.

.. _Google Code documentation Wiki: https://code.google.com/p/pymssql/wiki/Documentation

Current Development
===================

Official development repositories and issue trackers have been moved to GitHub
at https://github.com/pymssql/pymssql.

We would be happy to have:

* A couple more developers
* Help from the community with maintenance of this documentation.

If interested, please connect with us on the mailing list.
