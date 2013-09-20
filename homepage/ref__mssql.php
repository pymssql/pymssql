<?php require ('pageheader.php'); ?>

<h3 style="display:inline">_mssql module reference</h3>

<h4>_mssql module properties</h4>
<blockquote>

<code class="me">login_timeout</code>
    <div class="desc">
    Timeout for connection and login in seconds, default 60.
    </div><br />

<code class="me">min_error_severity</code>
    <div class="desc">
    Minimum severity of errors at which to begin raising exceptions.
    The default value of 6 should be appropriate in most cases.
    </div><br />

</blockquote>

<h4>MssqlConnection class</h4>
<blockquote>
    This class represents an MS SQL database connection. You can make queries and obtain
    results through a database connection. 
    <br /><br />You can create an instance of this class 
    by calling constructor <code>
    <span class="ty">_mssql</span><span class="o">.</span><span class="me">connect</span>()</code>.
    It accepts following arguments. Note that you can use keyword  arguments,
    instead of positional arguments.

<blockquote>

      <b>server</b><div class="desc">database server and instance you want to connect to. Valid examples are:
      <blockquote>
      <code class="s">r&#39;.\SQLEXPRESS&#39;</code> -- SQLEXPRESS instance on local machine [<i>Windows only</i>]<br />
      <code class="s">r&#39;(local)\SQLEXPRESS&#39;</code> -- same as above [<i>Windows only</i>]<br />
      <code class="s">r&#39;SQLHOST&#39;</code> -- default instance at default port [<i>Windows only</i>]<br />
      <code class="s">r&#39;SQLHOST&#39;</code> -- specific instance at specific port set up in 
            <code>freetds.conf </code>[<i>Linux/*nix only</i>]<br />
      <code class="s">r&#39;SQLHOST,1433&#39;</code> -- specified TCP port at specified host<br />
      <code class="s">r&#39;SQLHOST:1433&#39;</code> -- the same as above<br />
      <code class="s">r&#39;SQLHOST,5000&#39;</code> -- if you have set up an instance to listen on port 5000<br />
      <code class="s">r&#39;SQLHOST:5000&#39;</code> -- the same as above
  </blockquote>
  </div>

      <b>user</b><div class="desc">database user to connect as.</div>
      <b>password</b><div class="desc">user&#39;s password.</div>
      <b>trusted</b><div class="desc">bolean value signalling whether to use Windows Integrated 
      Authentication to connect instead of SQL autentication with user and password [<i>Windows only</i>]</div>

      <b>charset</b><div class="desc">character set name to set for the connection.</div>
      <b>database</b><div class="desc">the database you want initially to connect to, by default
      SQL Server selects the database which is set as default for specific user.</div>
      <b>max_conn</b><div class="desc">how many simultaneous connections to allow; default is 25,
      maximum on Windows is 1474559; trying to set it to higher value results in error &#39;Attempt 
      to set maximum number of DBPROCESSes lower than 1.&#39; (error 10073 severity 7)
      <i>(added in pymssql 1.0.2)</i>.</div>
</blockquote>

<h4>MssqlConnection object properties.</h4>

<blockquote>

<code class="me">connected</code>
    <div class="desc">
    True if the connection object has an open connection to a database, false otherwise.
    </div><br />

<code class="me">charset</code>
    <div class="desc">
    Character set name that was passed to 
    <code><span class="ty">_mssql</span><span class="o">.</span><span class="me">connect</span>()</code>
    method.
    </div><br />

<code class="me">identity</code>
    <div class="desc">
    Returns identity value of last inserted row. If previous operation
    did not involve inserting a row into a table with identity column,
    None is returned. Example usage -- assume that &#39;persons&#39; table contains
    an identity column in addition to &#39;name&#39; column:</div><br />

    <table border="0" align="center" class="syntaxindent"><tr><td>
<span class="n">conn</span><span class="o">.</span><span class="me">execute_non_query</span><span
class="p">(</span><span class="s">&quot;INSERT INTO persons (name) VALUES(&#39;John Doe&#39;)&quot;</span><span
class="p">)</span><br />
<span class="k">print</span> <span class="s">&quot;Last inserted row has id = &quot;</span> + conn.<span class="me">identity</span><br />
</td></tr></table>
    <br />

<code class="me">query_timeout</code>
    <div class="desc">
    Query timeout in seconds, default is 0, what means to wait indefinitely for results.
    Due to the way DB-Library for C works, setting this property affects all connections
    opened from current Python script (or, very technically, all connections made from
    this instance of <code>dbinit()</code>).
    
    </div><br />

<code class="me">rows_affected</code>
    <div class="desc">
    Number of rows affected by last query. For <code>SELECT</code> statements
    this value is only meaningful after reading all rows.
    </div><br />

<code class="me">debug_queries</code>
    <div class="desc">
    If set to true, all queries are printed to stderr after formatting
    and quoting, just before being sent to SQL Server. It may be helpful 
    if you suspect problems with formatting or quoting.
    </div><br />

</blockquote>

<h4>MssqlConnection object methods.</h4>

<blockquote>
<code class="me">cancel</code><code>()</code>
    <div class="desc">
    Cancel all pending results from the last SQL operation. It can be called 
    more than one time in a row. No exception is raised in this case.
    </div><br />

<code class="me">close</code><code>()</code>
    <div class="desc">
    Close the connection and free all memory used. It can be called
    more than one time in a row. No exception is raised in this case.
    </div><br />

<code class="me">execute_query</code><code>(query_string)</code><br />
<code class="me">execute_query</code><code>(query_string, params)</code>
    <div class="desc">
    This method sends a query to the MS SQL Server to which
    this object instance is connected. An exception is raised on
    failure. If there are pending results or rows prior to executing
    this command, they are silently discarded. After calling this method 
    you may iterate over the connection object to get rows returned by 
    the query. You can use Python formatting and all values get
    properly quoted. Please see examples at the top of this page for details.
    This method is intented to be used on queries that return results,
    i.e. <code>SELECT</code>.
    </div><br />

<code class="me">execute_non_query</code><code>(query_string)</code><br />
<code class="me">execute_non_query</code><code>(query_string, params)</code>
    <div class="desc">
    This method sends a query to the MS SQL Server to which this object 
    instance is connected. After completion, its results (if any) are 
    discarded. An exception is raised on failure. If there are pending 
    results or rows prior to executing this command, they are silently 
    discarded. You can use Python formatting and all values get
    properly quoted. Please see examples at the top of this page for details.
    This method is useful for <code>INSERT</code>, <code>UPDATE</code>, 
    <code>DELETE</code>, and for Data Definition Language commands, i.e. 
    when you need to alter your database schema.                       
    </div><br />

<code class="me">execute_scalar</code><code>(query_string)</code><br />
<code class="me">execute_scalar</code><code>(query_string, params)</code>
    <div class="desc">
    This method sends a query to the MS SQL Server to which
    this object instance is connected, then returns first column
    of first row from result.
    An exception is raised on failure. If there are pending results 
    or rows prior to executing this command, they are silently discarded.
    You can use Python formatting and all values get
    properly quoted. Please see examples at the top of this page for details.                        
    This method is useful if you want just a single value from a query,
    as in the example below. This method works in the same way as 
    <code><span class="ty">iter</span>(conn).<span class="me">next</span>()[0]</code>. 
    Remaining rows, if any, can still be iterated after calling this method.
    Example usage:</div><br />
    <table border="0" class="syntaxindent" align="center"><tr><td>
    count = conn.<span class="me">execute_scalar</span>(<span class="s"
    >&quot;SELECT COUNT(*) FROM employees&quot;</span>)
    </td></tr></table>
    <br />

<code class="me">execute_row</code><code>(query_string)</code><br />
<code class="me">execute_row</code><code>(query_string, params)</code>
    <div class="desc">
    This method sends a query to the MS SQL Server to which
    this object instance is connected, then returns first row of data from result.
    An exception is raised on failure. If there are pending results 
    or rows prior to executing this command, they are silently discarded.
    You can use Python formatting and all values get
    properly quoted. Please see examples at the top of this page for details.
    This method is useful if you want just a single row and don&#39;t want
    or don&#39;t need to iterate over the connection object.
    This method works in the same way as 
    <code><span class="ty">iter</span>(conn).<span class="me">next</span>()</code> 
    to obtain single row. Remaining
    rows, if any, can still be iterated after calling this method.
    Example usage:</div><br />
    <table border="0" class="syntaxindent" align="center"><tr><td>
    empinfo = conn.<span class="me">execute_row</span>(<span class="s"
    >&quot;SELECT * FROM employees WHERE empid=10&quot;</span>)
    </td></tr></table>
    <br />

<code class="me">get_header</code><code>()</code>
    <div class="desc">
    <i>This method is infrastructure and don&#39;t need to be called by your code.</i>
    Get the Python DB-API compliant header information.
    Returns a list of 7-element tuples describing current 
    result header. Only name and DB-API compliant type is filled,
    rest of the data is None, as permitted by the specs.
    </div><br />

<code class="me">nextresult</code><code>()</code>
    <div class="desc">
    Move to the next result, skipping all pending rows.
    This method fetches and discards any rows remaining from current
    operation, then it advances to next result (if any).
    Returns True value if next set is available, <code class="ty">None</code> otherwise.
    An exception is raised on failure.
    </div><br />

<code class="me">select_db</code><code>(dbname)</code>
    <div class="desc">
    This function makes given database the current one.
    An exception is raised on failure.
    </div><br />

<code class="me">__iter__</code><code>()</code>, <code class="me">next</code><code>()</code>
    <div class="desc">These methods faciliate
    <a href="http://docs.python.org/library/stdtypes.html#iterator-types">Python iterator protocol</a>.
    You most likely will not call them directly, but indirectly by using iterators.
    </div><br />

</blockquote>

</blockquote>

<h4>_mssql module exceptions</h4>
<blockquote>

<h4>Exception hierarchy.</h4>
<blockquote>
<pre>
MssqlException
|
+-- MssqlDriverException
|
+-- MssqlDatabaseException
</pre>

<code class="ty">MssqlDriverException</code> is raised whenever there is a problem
within _mssql -- e.g. insufficient memory for data structures, and so on.<br /><br />
<code class="ty">MssqlDatabaseException</code> is raised whenever there is a problem
with the database -- e.g. query syntax error, invalid object name and so on.
In this case you can use the following properties to access details of the error:<br /><br />

<code class="me">number</code>
    <div class="desc">
    The error code, as returned by SQL Server.
    </div><br />

<code class="me">severity</code>
    <div class="desc">
    The so-called <i>severity level</i>, as returned by SQL Server. If value
    of this property is less than the value of <code>_mssql.min_error_severity</code>,
    such errors are ignored and exceptions are not raised.</div><br />

<code class="me">state</code>
    <div class="desc">
    The third error code, as returned by SQL Server.
    </div><br />

<code class="me">message</code>
    <div class="desc">
    The error message, as returned by SQL Server.
    </div><br />
    
You can find an example of how to use this data at the bottom of 
<a href="examples__mssql.php">_mssql examples</a> page.<br />
</blockquote>
</blockquote>

<?php require ('pagefooter.php'); ?>
