============
Introduction
============

Getting started
===============

Generally, you will want to install pymssql with:

.. code-block:: bash

    pip install -U pip
    pip install pymssql

Most of the times this should be all what's needed.
If you want to build pymssql module against locally installed libraries then
install required software (see :doc:`building_and_developing` for more details)
and run:

  .. code-block:: bash

    pip install --no-binary=pymssql pymssql


  .. note::
    On some Linux distributions `pip` version is too old to support all
    the flavors of manylinux wheels, so upgrading `pip` is necessary.
    An example of such distributions would be Ubuntu 18.04 or
    Python3.6 module in RHEL8 and CentOS8.

  .. note::
    Starting with pymssql version 2.1.3 we provide such wheel packages
    that bundle a static copy of FreeTDS so no additional dependency download or
    compilation steps are necessary.

  .. note::
    Starting with pymssql version 2.2.0 official pymssql wheel packages for
    Linux, Mac OS and Windows have SSL support so they can be used to
    connect to :doc:`Azure <azure>`.

* Anaconda / Miniconda

  A conda install of pymssql will mitigate the need to edit config files
  outside of the user's home directory on some unix-like systems.
  This is especially useful when root access is restricted and/or Homebrew
  can't be installed.  This method requires no additional compilation or
  configuration.

  .. code-block:: bash

      conda install pymssql

See Installation and :doc:`building_and_developing` for more advanced scenarios.

**Docker**

(Experimental)

Another possible way to get started quickly with pymssql is to use a
:doc:`docker` image.

.. _domain logins: http://www.freetds.org/userguide/domains.htm

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

:Python: Python 3.x: 3.6 or newer.
:FreeTDS: 1.2.18 or newer.
:Cython: 0.29 or newer.
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

.. _pip: https://pip.pypa.io
.. _Python Package Index (PyPI): https://pypi.python.org
