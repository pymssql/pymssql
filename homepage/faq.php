<?php require ('pageheader.php'); ?>

<h3 style="display: inline">Frequently asked questions / troubleshooting page</h3>
<!-- body -->
<p class="q">Cannot connect to SQL Server.</p>
<blockquote>If you can&#39;t connect to the SQL Server instance, try the following:
<ul>
    <li>by default SQL Server 2005 and newer doesn&#39;t accept remote connections,
    you have to use SQL Server Surface Area Configuration and/or 
    SQL Server Configuration Manager to enable specific protocols and network adapters; don&#39;t
    forget to restart SQL Server after making these changes,
    <br /><br /></li>

    <li>if SQL Server is on remote machine, check whether connections are not blocked
    by any intermediate firewall device, firewall software, antivirus software, or other
    security facility,<br /><br /></li>

    <li>if you use pymssql on Linux/*nix with FreeTDS, check that FreeTDS&#39;s configuration
    is ok and that it can be found by pymssql. The easiest way is to test connection using <code>tsql</code>
    utility which can be found in FreeTDS package.<br /><br />
    </li>
    
    <li>if you use pymssql on Windows and the server is on local machine, 
    you can try the following command from the command prompt:<br />
    <code>REG ADD HKLM\Software\Microsoft\MSSQLServer\Client /v SharedMemoryOn /t REG_DWORD /d 1 /f</code><br />
    </li>
</ul>

</blockquote>

<p class="q">&quot;Unicode data in a Unicode-only collation or ntext data cannot 
be sent to clients using DB-Library&quot; error appears.</p>
<blockquote>
In SQL 2000 SP4 or newer, SQL 2005 or SQL 2008, if you do a query that returns <code>NTEXT</code> type data,
you may encounter the following exception:<br />
<code>
_mssql.MssqlDatabaseError: SQL Server message 4004, severity 16, state 1, line 1:<br />
<b>Unicode data in a Unicode-only collation or ntext data cannot be sent to clients 
using DB-Library (such as ISQL) or ODBC version 3.7 or earlier.</b>
</code><br /><br />
It means that SQL Server is unable to send Unicode data to pymssql, because of 
shortcomings of DB-Library for C. You have to <code style="color:fuchsia">CAST</code> 
or <code style="color:fuchsia">CONVERT</code> the data to equivalent 
<code style="color:Blue">NVARCHAR</code> data type, which does not exhibit this behaviour.
</blockquote>

<p class="q">Column names get silently truncated to 30 characters.</p>
<blockquote>
The only workaround is to alias column names to something shorter. Thanks 
Sebastian Auriol for the suggestion.<br /><br />
<code>&nbsp;&nbsp;&nbsp;&nbsp;
<code style="color:blue">SELECT</code>
very_very_long_column_name_longer_than_30_characters 
 <code style="color:blue">AS</code> col1</code><br />
</blockquote>

<p class="q">CHAR(n) and VARCHAR(n) strings get truncated to 255 characters.</p>
<blockquote>
This is known limitation of TDS protocol. You can <code style="color:fuchsia">CAST</code> 
or <code style="color:fuchsia">CONVERT</code> the data to <code style="color:blue">TEXT</code> 
data type to workaround this issue.
</blockquote>

<p class="q">Returned dates are not correct.</p>
<blockquote>
If you use pymssql on Linux/*nix and you suspect that returned dates are not correct, 
please read <a href="freetds_dates.php">FreeTDS and dates</a> page.
</blockquote>

<p class="q">Shared object &quot;libsybdb.so.3&quot; not found.</p>
<blockquote>
On Linux/*nix you may encounter the following behaviour:<br />
<code>
>>> <span class="kn">import</span> <span class="ty">_mssql</span><br />
Traceback (most recent call last):<br />
File &quot;&lt;stdin&gt;&quot;, line 1, in ?<br />
<b>ImportError: Shared object &quot;libsybdb.so.3&quot; not found</b><br />
</code><br />
It may mean that FreeTDS library is unavailable, or that dynamic linker is unable to find it.
Check that it is installed and that the path to <code>libsybdb.so</code>
is in <code>/etc/ld.so.conf</code> file. Then do <code>ldconfig</code> as root
to refresh linker database. On Solaris I just set <code>LD_LIBRARY_PATH</code> environment
variable to directory with the library just before launching Python.
</blockquote>
                        
<p class="q">&quot;DB-Lib error message 20004, severity 9: Read from SQL server failed&quot; error appears.</p>
<blockquote>
On Linux/*nix you may encounter the following behaviour:<br />
<code>
>>> <span class="kn">import</span> <span class="ty">_mssql</span><br />
>>> c=<span class="ty">_mssql</span>.<span class="me">connect</span
>(<span class="s">&#39;hostname:portnumber&#39;</span>,<span class="s"
>&#39;user&#39;</span>,<span class="s">&#39;pass&#39;</span>)<br />
Traceback (most recent call last):<br />
  File &quot;&lt;stdin&gt;&quot;, line 1, in &lt;module&gt;<br />
_mssql.DatabaseException: DB-Lib error message 20004, severity 9:<br />
<b>Read from SQL server failed.</b><br />
DB-Lib error message 20014, severity 9:<br />
Login incorrect.<br />
</code><br />
It may happen when one of the following is true:
<ul>
<li><code>freetds.conf</code> file cannot be found,</li>
<li><code>tds version</code> in <code>freetds.conf</code> file is not 7.0 or 4.2,</li>
<li>any character set is specified in <code>freetds.conf</code>,</li>
<li>an unrecognized character set is passed to 
<code><span class="ty">_mssql</span>.<span class="me">connect</span>()</code>
or <code><span class="ty">pymssql</span>.<span class="me">connect</span>()</code> method.
</li>
</ul>

&quot;Login incorrect&quot; following this error is spurious, real &quot;Login incorrect&quot;
messages has code=18456 and severity=14.
</blockquote>

<p class="q">Python on Windows dies with memory access violation error on <code>connect()</code>
when incorrect password is given.</p>
<blockquote>
This may happen if you use different version of <code>ntwdblib.dll</code> than the one
included in pymssql package. For example the version 2000.80.2273.0 is unable to handle
<code>dberrhandle()</code> callbacks properly, and causes access violation error 
in <code>err_handler()</code> function on <code>return INT_CANCEL</code>. I have
given up after several hours of investigating the issue, and just reverted to previous
version of the <code>ntwdblib.dll</code> and error disappeared.
</blockquote>

<p class="q">&quot;Not enough storage is available to complete this operation&quot; error appears.</p>
<blockquote>
On Windows you may encounter the following behaviour:<br />
<code>
>>> <span class="kn">import</span> <span class="ty">_mssql</span><br />
>>> c=<span class="ty">_mssql</span>.<span class="me">connect</span
>(<span class="s">&#39;hostname:portnumber&#39;</span>,<span class="s"
>&#39;user&#39;</span>,<span class="s">&#39;pass&#39;</span>)<br />
Traceback (most recent call last):<br />
File &quot;&lt;pyshell#1&gt;&quot;, line 1, in -toplevel-<br />
File &quot;E:\Python24\Lib\site-packages\pymssql.py&quot;, line 310, in connect<br />
con = _mssql.connect(dbhost, dbuser, dbpasswd)<br />
error: DB-Lib error message 10004, severity 9:<br />
<b>Unable to connect: SQL Server is unavailable or does not exist. Invalid connection.</b><br />
Net-Lib error during ConnectionOpen (ParseConnectParams()).<br />
<b>Error 14 - Not enough storage is available to complete this operation.</b><br />
</code><br />
This may happen most likely on earlier versions of pymssql. It happens always
if you use a colon &quot;:&quot; to separate hostname from port number.
On Windows you should use comma &quot;,&quot; instead. pymssql 1.0
has a workaround, so you do not have to care about that.
</blockquote>

<p class="q">More troubleshooting.</p>
<blockquote>
If the above hasn&#39;t covered the problem, please also check 
<a href="limitations.php">Limitations and known issues</a> page.
You can also consult <a href="http://www.freetds.org/userguide/troubleshooting.htm">
FreeTDS troubleshooting page for issues related to the TDS protocol.</a>
</blockquote><br />


<?php require ('pagefooter.php'); ?>
