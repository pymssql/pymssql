============
Introduction
============

Getting started
===============

Generally, you will want to install pymssql with:

.. code-block:: bash

    pip install pymssql

Most of the times this should be all what's needed.

* Linux

  First make sure you are using pip_ version 8.1.0 or newer so you can take
  advantage of its support for :pep:`513` Linux *manylinux1* binary Wheel
  packages. Starting with pymssql version 2.1.3 we provide such wheel packages
  that bundle a static copy of FreeTDS so no additional dependency download or
  compilation steps are necessary.

  Then run:

  .. code-block:: bash

      pip install pymssql

  it will fetch the package from the `Python Package Index (PyPI)`_ and install
  it.

  .. note::

    The statically-linked FreeTDS version bundled with our official pymssql
    Linux Wheel package doesn't have SSL support so it can't be used to connect
    to :doc:`Azure <azure>`. Also it doesn't have Kerberos support so it can't
    be used to perform `domain logins`_ to SQL Server.

* Mac OS X

  (with `Homebrew <http://brew.sh/>`_):

  Run:

  .. code-block:: bash

      brew install freetds
      pip install pymssql

  it will fetch the source distribution from the `Python Package Index
  (PyPI)`_, build and install pymssql.

* Windows

  First make sure you are using pip_ version 6.0 or newer so you can take
  advantage of its support for Windows binary Wheel packages. Starting with
  pymssql version 2.1.3 we provide such wheel packages that bundle a static copy
  of FreeTDS so no additional download or compilation steps are necessary.

  Then run:

  .. code-block:: bash

      pip install pymssql

  it will fetch the package from the `Python Package Index (PyPI)`_ and install
  it.

  .. note::

    The statically-linked FreeTDS version bundled with our official pymssql
    Windows Wheel package doesn't have SSL support so it can't be used to
    connect to :doc:`Azure <azure>`.

See Installation and :doc:`freetds` for more advanced scenarios.

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
