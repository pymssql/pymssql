======
Docker
======

(Experimental)

There is a pymssql Docker image on the Docker Registry at:

https://registry.hub.docker.com/u/pymssql/pymssql/

The image bundles:

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

See the Docker docs for installation instructions for a number of platforms;
you can try this link: https://docs.docker.com/installation/#installation
