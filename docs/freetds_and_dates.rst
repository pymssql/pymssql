=================
FreeTDS and dates
=================

Explanation of how pymssql and FreeTDS can break dates.

Summary
=======

Make sure that FreeTDS is compiled with ``--enable-msdblib`` ``configure``
option, or your queries will return wrong dates -- ``"2010-00-01"`` instead of
``"2010-01-01"``.

Details
=======

There's an obscure problem on Linux/\*nix that results in dates shifted back by
1 month. This behaviour is caused by different ``dbdatecrack()`` prototypes in
*Sybase Open Client DB-Library/C* and the *Microsoft SQL DB Library for C*. The
first one returns month as 0..11 whereas the second gives month as 1..12. See
this `FreeTDS mailing list post`_, `Microsoft manual for dbdatecrack()`_,
and `Sybase manual for dbdatecrack()`_ for details.

FreeTDS, which is used on Linux/\*nix to connect to *Sybase* and *MS SQL*
servers, tries to imitate both modes:

* Default behaviour, when compiled without ``--enable-msdblib``, gives
  ``dbdatecrack()`` which is Sybase-compatible,
* When configured with ``--enable-msdblib``, the ``dbdatecrack()`` function is
  compatible with *MS SQL* specs.

pymssql requires *MS SQL* mode, evidently. Unfortunately at runtime we can't
reliably detect which mode FreeTDS was compiled in (as of FreeTDS 0.63). Thus at
runtime it may turn out that dates are not correct. If there was a way to detect
the setting, pymssql would be able to correct dates on the fly.

If you can do nothing about FreeTDS, there's a workaround. You can redesign your
queries to return string instead of bare date:

.. code-block:: sql

    SELECT datecolumn FROM tablename

can be rewritten into:

.. code-block:: sql

    SELECT CONVERT(CHAR(10),datecolumn,120) AS datecolumn FROM tablename

This way SQL will send you string representing the date instead of binary date
in datetime or smalldatetime format, which has to be processed by FreeTDS and
pymssql.

.. _FreeTDS mailing list post: http://lists.ibiblio.org/pipermail/freetds/2002q3/008336.html
.. _Microsoft manual for dbdatecrack(): http://msdn.microsoft.com/en-us/library/aa937027(SQL.80).aspx
.. _Sybase manual for dbdatecrack(): http://manuals.sybase.com/onlinebooks/group-cnarc/cng1110e/dblib/@Generic__BookTextView/15108
