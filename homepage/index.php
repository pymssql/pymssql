<?php require ('pageheader.php'); ?>

<h3 style="display: inline">News</h3><br />

<table border="0" class="news" align="center"><tr><td>
2009-04-28: pymssql 1.0.2 has been released.
<ul>
    <li>fixed severe bug introduced in 1.0.0 that caused some queries to be truncated 
        or overwritten with binary garbage - many thanks to Igor Nazarenko who found
        the exact cause of the bug,</li>
    <li>fixed bug - if a query batch contained <code style="color:blue">DECLARE</code> 
        or possibly some other T-SQL statements, query results were not available 
        (<code style="color:blue">DECLARE</code> yielded additional result with no columns)
        - thanks Corey Bertram and Wes McKinney,</li>
    <li>fixed incompatibility - a % character in query without parameters is treated like any other
        character; it gains its special meaning as a formatting specifier only if any
        arguments are given. This allows for straightforward queries similar to the
        following: <code><span style="color:blue">SELECT</span> *
        <span style="color:blue">FROM</span> sysobjects <span style="color:blue">WHERE</span> name 
        <span style="color:gray">LIKE</span> <span class="s">&#39;s%&#39;</span></code>,</li>
    <li>updated <a href="http://www.nagios.org/" target="_blank">Nagios</a> plugin
        - thanks Josselin Mouette for the patch,</li>
    <li>pymssql on Linux/*NIX understands <code style="color:blue">BIGINT</code> natively
        - thanks Alexandr Zamaraev for the patch (on Windows it is returned as 
        <code>SQLNUMERIC</code> data type by the DB Library, which is converted to 
        Python <code>Decimal</code> value),</li>
    <li>new feature: <code>pymssql.<span class="me">connect</span>()</code> method understands new argument:
        <code>as_dict</code> - which allows to return rows as dictionaries instead of tuples
        - thanks Daniel Watrous for the idea and draft patch,</li>
    <li>new feature: <code>pymssql.<span class="me">connect</span>()</code> and
        <code>_mssql.<span class="me">connect</span>()</code> methods understand new argument:
        <code>max_conn</code> - which helps increase the default 25 concurrent connections limit
        - thanks Daniel Watrous for the idea and draft patch,</li>
    <li>important doc update: documented that with the technology pymssql currently uses 
        (DB Library for C), it is not possible to read or write BLOBs 
        longer than 4096 bytes,</li>
    <li>further webpage changes to improve access to information.</li>
</ul>
If you find any problems, please consult <a href="documentation.php">Documentation</a> page, 
then <a href="support.php">Support</a> information.
In any case just send me an e-mail if you want.
</td></tr>
<tr><td><hr /></td></tr>
</table>

<table border="0" class="news" align="center"><tr><td>
2009-02-05: pymssql 1.0.1 has been released.
<ul>
    <li>fixed bug in <code>execute()</code> function introduced in 1.0.0,</li>
    <li>added <a href="http://www.nagios.org/" target="_blank">Nagios</a> plugin, 
        thanks to Josselin Mouette and Julien Blache from Debian team,</li>
    <li>some 64-bit issues were fixed,</li>
    <li>charset bug was fixed, thanks again Josselin Mouette,</li>
    <li>pymssql was tested on more platforms, see <a href="platforms.php">Platforms</a> page
    for details.</li>
</ul>
If you find any problems, please consult <a href="support.php">Support</a> information.
In any case just send me an e-mail if you want.
</td></tr>
<tr><td><hr /></td></tr>
</table>


<table border="0" class="news" align="center"><tr><td>
2009-01-29: pymssql 1.0.0 has been released. It was almost rewritten from scratch, and
it addresses all requests that I received from users. There are <b>many new features</b>, 
improvements, bugfixes and cleanups:
<ul>
    <li>pymssql no longer fetches all rows into memory, instead it implements convenient
        <b>iterators</b> that get data from SQL server row by row,</li>
    <li>row data is a <b>dictionary </b>that can be accessed by <b>column index </b>or<b>
        column name</b>,</li>
    <li><b>identity value</b> of last inserted row can be obtained easily,</li>
    <li><b>number of rows affected</b> by last database operation is available,</li>
    <li>it is possible to connect to database using <b>Windows Authentication</b>
        (so called &quot;<b>trusted connection</b>&quot;) on Windows,</li>
    <li>more DB-API extensions has been implemented: <b>.lastrowid, .rownumber, .connection,
        cursor iterators</b> (see <a href="http://www.python.org/dev/peps/pep-0249/">DB-API
        Specification</a> if you&#39;re interested), and <b>the scripts that used pymssql DB-API
        compliant methods will continue to work</b>,</li>
    <li>_mssql module has many new convenient features, see <a href="documentation.php">Documentation</a>
        and examples for details,</li>
    <li>exceptions and return codes have been reworked to be more intuitive and usable,</li>
    <li>the module now has decent <b>inline documentation</b>: just use <span class="codebold">
        help(pymssql)</span> or <span class="codebold">help(_mssql)</span> to see many notes
        and examples,</li>
    <li>pymssql 1.0.0 is compatible with Python 2.4, 2.5 and 2.6,</li>
    <li>tested with SQL 2000, SQL 2005, and SQL 2008,</li>
    <li>BEWARE however, if you were using the lower level <b>_mssql module</b>, it <b>changed
        in incompatible way</b>. You will need to change your scripts, or continue to use
        pymssql 0.8.0. This is why major version number was incremented.</li>
</ul>
                
The webpage is also new, there is reference documentation, more examples, and
notes. I&nbsp;hope it will be easy to navigate and readable.<br /><br />
If you find any problems, please consult <a href="support.php">Support</a> information.
In any case just send me an e-mail if you want.
<br />
</td></tr></table>

<?php require ('pagefooter.php'); ?>
