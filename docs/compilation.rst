====================
How to build pymssql
====================

Instructions of compilation and installation from source.

Compilation and installation from source
========================================

If you need to compile pymssql, check whether requirements shown below are met,
unpack source files to a directory of your choice and issue (as root):

.. code-block:: bash

   # python setup.py install

This will compile and install pymssql.

Build requirements
==================

* Python language. Please check platforms page for version info.
* Python development package -- if needed by your OS (for example ``python-dev``
  or ``libpython2.5-devel``).
* Linux, \*nix and Mac OS X: FreeTDS 0.63 or newer (you need ``freetds-dev`` or
  ``freetds-devel`` or similarly named package -- thanks Scott Barr for pointing
  that out).

      .. note::

          FreeTDS must be configured with ``--enable-msdblib`` to return correct
          dates! See :doc:`FreeTDS and dates <freetds_and_dates>` for details.

Platform-specific issues
========================

Windows
-------

FreeTDS on Windows is not supported. But this is going to change soon. Our goal
is to use FreeTDS on every supported platform.

Please also consult FreeTDS and Dates document.
