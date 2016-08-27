============
Introduction
============

Getting started
===============

Generally, you will want to install pymssql with:

.. code-block:: bash

    pip install pymssql

`FreeTDS <http://www.freetds.org/>`_ is required. On some platforms, we provide
a pre-compiled FreeTDS to make installing easier, but you may want to install
FreeTDS before doing ``pip install pymssql`` if you run into problems or need
features or bug fixes in a newer version of FreeTDS. You can `build FreeTDS
from source <http://www.freetds.org/userguide/build.htm>`_ if you want the
latest. If you're okay with the latest version that your package manager
provides, then you can use your package manager of choice to install FreeTDS.
E.g.:

* Ubuntu/Debian:

  .. code-block:: bash

      sudo apt-get install freetds-dev

* Mac OS X with `Homebrew <http://brew.sh/>`_:

  .. code-block:: bash

      brew install freetds

Docker
------

(Experimental)

Another possible way to get started quickly with pymssql is to use a
:doc:`docker` image.

Architecture
============

.. image:: images/pymssql-stack.png

The pymssql package consists of two modules:

* :mod:`pymssql` -- use it if you care about DB-API compliance, or if you are
  accustomed to DB-API syntax,
* :mod:`_mssql` -- use it if you care about performance and ease of use
  (``_mssql`` module is easier to use than ``pymssql``).

And, as of version 2.1.x it uses the services of the ``db-lib`` component of
FreeTDS. See the `relevant FreeTDS documentation`_ for additional details.

.. _relevant FreeTDS documentation: http://www.freetds.org/which_api.html

Supported related software
==========================

:Python: Python 2.x: 2.7 or newer. Python 3.x: 3.3 or newer.
:FreeTDS: 0.91 or newer.
:Cython: 0.15 or newer.
:Microsoft SQL Server: 2005 or newer.

Install
=======

Remember to install :doc:`/freetds` first.

pip
---

.. code-block:: console

    pip install pymssql

will install pymssql from `PyPI <https://pypi.python.org/pypi/pymssql>`_. This
PyPI page contains:

- source distribution (``.tar.gz``)
- wheels (``.whl``) for Windows

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
