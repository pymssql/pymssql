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

Another possible way to get started quickly with pymssql is to use a `Docker
<https://www.docker.com/>`_ image.

See the Docker docs for installation instructions for a number of platforms;
you can try this link: https://docs.docker.com/installation/#installation

There is a pymssql docker image on the Docker Registry at:

https://registry.hub.docker.com/u/pymssql/pymssql/

It is a Docker image with:

* Ubuntu 14.04 LTS (trusty)
* Python 2.7.6
* pymssql 2.1.2.dev
* FreeTDS 0.91
* SQLAlchemy 0.9.8
* Alembic 0.7.4
* Pandas 0.15.2
* Numpy 1.9.1
* IPython 2.3.1

To try it, first download the image (this requires Internet access and could
take a while):

.. code-block:: bash

    docker pull pymssql/pymssql

Then run a Docker container using the image with:

.. code-block:: bash

    docker run -it --rm pymssql/pymssql

By default, if no command is specified, an `IPython <http://ipython.org>`_
shell is invoked. You can override the command if you wish -- e.g.:

.. code-block:: bash

    docker run -it --rm pymssql/pymssql bin/bash

Here's how using the Docker container looks in practice:

.. code-block:: bash

    $ docker pull pymssql/pymssql
    ...
    $ docker run -it --rm pymssql/pymssql
    Python 2.7.6 (default, Mar 22 2014, 22:59:56)
    Type "copyright", "credits" or "license" for more information.

    IPython 2.1.0 -- An enhanced Interactive Python.
    ?         -> Introduction and overview of IPython's features.
    %quickref -> Quick reference.
    help      -> Python's own help system.
    object?   -> Details about 'object', use 'object??' for extra details.

    In [1]: import pymssql; pymssql.__version__
    Out[1]: u'2.1.1'

    In [2]: import sqlalchemy; sqlalchemy.__version__
    Out[2]: '0.9.7'

    In [3]: import pandas; pandas.__version__
    Out[3]: '0.14.1'


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
:FreeTDS: 0.82 or newer.
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
