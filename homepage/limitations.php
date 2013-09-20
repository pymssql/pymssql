<?php require ('pageheader.php'); ?>

<h3 style="display:inline">Limitations and known issues</h3><br />
<blockquote>
pymssql does not support an &#39;elegant&#39; way of handling stored procedures.
Nonetheless you can fully utilize stored procedures, pass values to them,
fetch rows and output parameter values. See <a href="examples__mssql.php">_mssql examples</a>.
<br /><br />

DB-Library for C is not supported by Microsoft any more. You can find the info <a
    href="http://msdn.microsoft.com/en-us/library/aa936940.aspx">on this MSDN page</a>. 
This is why some of the features may not work as expected. Here are some known 
issues and workarounds. You should note that <i>none of these issues are imposed 
by pymssql</i>. You will observe them all also in PHP driver for MSSQL, for 
instance.
<ul>

<li><b><code>image</code> data is truncated to 4000 characters.</b><br />
    This is known limitation of DB-Library for C. I know of no workaround.
    This issue is also present in PHP, the solution suggested was to use
    ODBC protocol.
<br /><br /></li>

<li><b><code>varchar</code> and <code>nvarchar</code> data is limited to 255 
    characters, and longer strings are silently trimmed.</b><br />
    This is known limitation of TDS protocol.
    A workaround is to <code style="color:fuchsia">CAST</code> or 
    <code style="color:fuchsia">CONVERT</code> that row 
    or expression to <code>text</code> data type, which is capable of returning
	4000 characters.
<br /><br /></li>

<li><b>column names are limited to 30 characters and longer names are silently 
    truncated.</b><br />
    There&#39;s no workaround for this. You have to use names (or aliases as in <code>
    <span style="color:blue">SELECT</span> column <span style="color:blue">AS</span> 
    alias</code>) that are not longer than 30 characters.
<br /><br /></li>

<li><b>&quot;<code>SELECT &#39;&#39;</code>&quot; statement returns a string containing 
one space instead of an empty string.</b><br />
    There&#39;s no workaround for this. You cannot distinguish between <br />

<code>&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue">SELECT</span
> <span class="s">&#39;&#39;</span>&nbsp;&nbsp;&nbsp;<i class="c">-- empty string</i></code><br />
and<br />
<code>&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue">SELECT</span
> <span class="s">&#39; &#39;</span>&nbsp;&nbsp;<i class="c">-- one space</i></code><br /><br /></li>

<li><b>&quot;<code>SELECT CAST(NULL AS BIT)</code>&quot; 
returns False instead of None.</b><br />
    There&#39;s no workaround for this. You cannot distinguish between<br />
    <code>&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue">SELECT</span> <span style="color:fuchsia"
>CAST</span>(<span style="color:#808080">NULL</span> <span style="color:blue"
>AS</span> <span style="color:blue">BIT</span>)</code><br />
and<br />
<code>&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue">SELECT</span> <span style="color:fuchsia"
>CAST</span>(<span style="color:black">0</span> <span style="color:blue"
>AS</span> <span style="color:blue">BIT</span>)</code><br /><br />
You should avoid <code style="color:#808080">NULL</code> bit fields.
Just assign a default value to them and update all records to the default value.
I would recommend not using <code style="color:blue">BIT</code> datatype at all, if possible change 
it to <code style="color:blue">TINYINT</code> for example.
The problem will disappear, and storage overhead is unnoticeable.

This issue is also known for example in Microsoft&#39;s own product, Access, see
<a href="http://support.microsoft.com/kb/278696" target="_blank">KB278696</a> article.<br />
<br /></li>

<li><b>New features of SQL Server 2005 and SQL Server 2008 are not supported.</b><br />
Some of the features of SQL Server versions newer than 2000 just don&#39;t work.
For example you can&#39;t use MARS feature (Multiple Active Result Sets). You have
to arrange your queries so that result sets are fetched one after another.<br /><br /></li>

<li><b>The newest version of <code>ntwdblib.dll</code> library 
v. 2000.80.2273.0 is unusable.</b><br />
If on Windows, please use the library bundled with pymssql package. Older or newer versions
may introduce unexpected problems, the version mentioned above causes memory violation errors,
but only in certain scenarios, making tracing the cause very difficult. 
More information is also available on <a href="faq.php">FAQ page</a>.<br /><br /></li>


</ul>
</blockquote>

<?php require ('pagefooter.php'); ?>
