<?php require ('pageheader.php'); ?>

<h3 style="display:inline">pymssql module reference</h3>

<h4>pymssqlCnx class</h4>
<blockquote>
This class represents an MS SQL database connection. You can create an instance of this class
by calling constructor <code>
<span class="ty">pymssql</span><span class="o">.</span><span class="me">connect</span>()</code>.
It accepts following arguments. Note that in most cases you will want to use keyword arguments,
instead of positional arguments.<br />
<blockquote>

<b>dsn</b><div class="desc">colon-delimited string of the form <code>host:dbase:user:pass:opt:tty</code>,
  primarily for compatibility with previous versions of pymssql.</div> 
  <b>user</b><div class="desc">database user to connect as.</div>
  <b>password</b><div class="desc">user&#39;s password.</div>
  <b>trusted</b><div class="desc">bolean value signalling whether to use Windows Integrated 
  Authentication to connect instead of SQL autentication with user and password [<i>Windows only</i>]</div>
  
  <b>host</b><div class="desc">database host and instance you want to connect to. Valid examples are:
  <blockquote>
  <code class="s">r&#39;.\SQLEXPRESS&#39;</code> -- SQLEXPRESS instance on local machine [<i>Windows only</i>]<br />
  <code class="s">r&#39;(local)\SQLEXPRESS&#39;</code> -- same as above [<i>Windows only</i>]<br />
  <code class="s">r&#39;SQLHOST&#39;</code> -- default instance at default port [<i>Windows only</i>]<br />
  <code class="s">r&#39;SQLHOST&#39;</code> -- specific instance at specific port set up in 
        <code>freetds.conf </code>[<i>Linux/*nix only</i>]<br />
  <code class="s">r&#39;SQLHOST,1433&#39;</code> -- specified TCP port at specified host<br />
  <code class="s">r&#39;SQLHOST:1433&#39;</code> -- the same as above<br />
  <code class="s">r&#39;SQLHOST,5000&#39;</code> -- if you have set up an instance to listen on port 5000<br />
  <code class="s">r&#39;SQLHOST:5000&#39;</code> -- the same as above<br />
</blockquote>
<code class="s">&#39;.&#39;</code> (the local host) is assumed if host is not provided.<br /><br />
</div>

  <b>database</b><div class="desc">the database you want initially to connect to, by default
  SQL Server selects the database which is set as default for specific user.</div>
  <b>timeout</b><div class="desc">query timeout in seconds, default is 0 (wait indefinitely).</div>
  <b>login_timeout</b><div class="desc">timeout for connection and login in seconds, default 60.</div>
  <b>charset</b><div class="desc">character set with which to connect to the database.</div>
  <b>as_dict</b><div class="desc">whether rows should be returned as dictionaries instead of tuples
    <i>(added in pymssql 1.0.2)</i>.</div>
  <b>max_conn</b><div class="desc">how many simultaneous connections to allow; default is 25,
  maximum on Windows is 1474559; trying to set it to higher value results in error &#39;Attempt 
  to set maximum number of DBPROCESSes lower than 1.&#39; (error 10073 severity 7)
  <i>(added in pymssql 1.0.2)</i>.</div>
</blockquote>

<h4>pymssqlCnx object properties.</h4>

<blockquote>This class has no useful properties and data members.</blockquote>

<h4>pymssqlCnx object methods.</h4>

<blockquote>
<code class="me">autocommit</code><code>(status)</code><br />
<div class="desc"><code>status</code> is 
a boolean value. This method turns autocommit mode on or off. By default, autocommit mode 
is off, what means every transaction must be explicitly committed if changed data
is to be persisted in the database. You can turn autocommit mode on, what means
every single operation commits itself as soon as it succeeds.</div><br />
<code class="me">close</code><code>()</code>
<div class="desc">Close the connection.</div><br />
<code class="me">cursor</code><code>()</code>
<div class="desc">Return a cursor object, that can be used
to make queries and fetch results from the database.</div><br />
<code class="me">commit</code><code>()</code>
<div class="desc">Commit current transaction. <b>You must call this method to persist 
your data</b> if you leave <code>autocommit</code> at its default value, which is 
<code>False</code>. See also pymssql example at the top of this page.</div>
<br />
<code class="me">rollback</code><code>()</code>
<div class="desc">Roll back current transaction.</div><br />
</blockquote>
</blockquote>

<h4>pymssqlCursor class</h4>
<blockquote>

This class represents a Cursor (in terms of Python DB-API specs) that is used to
make queries against the database and obtaining results. You create pymssqlCursor instances
by calling <code class="me">cursor</code><code>()</code> method on an open pymssqlCnx
connection object.

<h4>pymssqlCursor object properties.</h4>
<blockquote>

<code class="me">rowcount</code>
<div class="desc">Returns number of rows affected by last operation. In case of
<code>SELECT</code> statements it returns meaningful information only after all
rows have been fetched.
</div><br />

<code class="me">connection</code>
<div class="desc">
<i>This is the extension of the DB-API specification.</i>
Returns a reference to the connection object on which the cursor was created.
</div><br />

<code class="me">lastrowid</code>
<div class="desc">
<i>This is the extension of the DB-API specification.</i>
Returns identity value of last inserted row. If previous operation
did not involve inserting a row into a table with identity column,
<code class="ty">None</code> is returned.
</div><br />

<code class="me">rownumber</code>
<div class="desc">
<i>This is the extension of the DB-API specification.</i>
Returns current 0-based index of the cursor in the result set.
</div><br />

</blockquote>
<h4>pymssqlCursor object methods.</h4>
<blockquote>

<code class="me">close</code><code>()</code>
<div class="desc">Close the cursor. The cursor is unusable from this point.</div><br />

<code class="me">execute</code><code>(operation)</code><br />
<code class="me">execute</code><code>(operation, params)</code>
<div class="desc"><code>operation</code> is a string and <code>params</code>, if specified,
is a simple value, a tuple, or <code class="ty">None</code>.
Performs the operation against the database, possibly replacing parameter placeholders
with provided values. This should be preferred method
of creating SQL commands, instead of concatenating strings manually, what makes a
potential of <a href="http://en.wikipedia.org/wiki/SQL_injection">SQL Injection attacks</a>.
This method accepts the same formatting as Python&#39;s builtin 
<a href="http://docs.python.org/library/stdtypes.html#string-formatting">string 
interpolation operator</a>.<br />
If you call <code>execute()</code> with one argument, you can use % sign as usual in 
your query string, for example in <code>LIKE</code> operator
(it loses its special meaning). See the example at the top.

</div><br />

<code class="me">executemany</code><code>(operation, params_seq)</code>
<div class="desc"><code>operation</code> is a string and <code>params_seq</code> 
is a sequence of tuples (e.g. a list). Execute a database operation repeatedly for each element
in parameter sequence.
</div><br />

<code class="me">fetchone</code><code>()</code>
<div class="desc">Fetch the next row of a query result, returning a tuple,
or a dictionary if <code>as_dict</code> was passed to <code>pymssql.connect()</code>, or 
<code class="ty">None</code> if no more data is available. 
Raises <code class="ty">OperationalError</code> if previous call to 
<code class="me">execute*</code><code>()</code>
did not produce any result set or no call was issued yet.
</div><br />

<code class="me">fetchmany</code><code>(size=<code class="ty">None</code>)</code>
<div class="desc">Fetch the next batch of rows of a query result,
returning a list of tuples, or a list of dictionaries if <code>as_dict</code> 
was passed to <code>pymssql.connect()</code>,
or an empty list if no more data is available.
You can adjust the batch size using the <code>size</code> parameter,
which is preserved across many calls to this method.
Raises <code class="ty">OperationalError</code> if previous call to 
<code class="me">execute*</code><code>()</code>
did not produce any result set or no call was issued yet.
</div><br />

<code class="me">fetchall</code><code>()</code>
<div class="desc">Fetch all remaining rows of a query result, returning a list
of tuples, or a list of dictionaries if <code>as_dict</code> was passed to <code>pymssql.connect()</code>,
or an empty list if no more data is available. 
Raises <code class="ty">OperationalError</code> if previous call to 
<code class="me">execute*</code><code>()</code>
did not produce any result set or no call was issued yet.
</div><br />

<code class="me">fetchone_asdict</code><code>()</code>
<div class="desc"><i>Warning: this method is not part of DB-API.
<span style="color:#884488">This method is deprecated as of pymsssql 1.0.2.
It was replaced by <code>as_dict</code> parameter to <code>pymssql.connect()</code></span></i><br />
Fetch the next row of a query result, returning a dictionary, or
<code class="ty">None</code> if no more data is available.
Data can be accessed by 0-based numeric column index, or by column name.
Raises <code class="ty">OperationalError</code> if previous call to 
<code class="me">execute*</code><code>()</code>
did not produce any result set or no call was issued yet.
</div><br />

<code class="me">fetchmany_asdict</code><code>(size=<code class="ty">None</code>)</code>
<div class="desc"><i>Warning: this method is not part of DB-API.
<span style="color:#884488">This method is deprecated as of pymsssql 1.0.2.
It was replaced by <code>as_dict</code> parameter to <code>pymssql.connect()</code></span></i><br />
Fetch the next batch of rows of a query result, returning a list of dictionaries.
An empty list is returned if no more data is available.
Data can be accessed by 0-based numeric column index, or by column name.
You can adjust the batch size using the <code>size</code> parameter,
which is preserved across many calls to this method.
Raises <code class="ty">OperationalError</code> if previous call to 
<code class="me">execute*</code><code>()</code>
did not produce any result set or no call was issued yet.<br />
</div><br />

<code class="me">fetchall_asdict</code><code>()</code>
<div class="desc"><i>Warning: this method is not part of DB-API.
<span style="color:#884488">This method is deprecated as of pymsssql 1.0.2.
It was replaced by <code>as_dict</code> parameter to <code>pymssql.connect()</code></span></i><br />
Fetch all remaining rows of a query result, returning a list of dictionaries.
An empty list is returned if no more data is available.
Data can be accessed by 0-based numeric column index, or by column name.
Raises <code class="ty">OperationalError</code> if previous call to 
<code class="me">execute*</code><code>()</code>
did not produce any result set or no call was issued yet.<br />
<i>The idea and original implementation of this method by Sterling Michel
	&lt;sterlingmichel_at_gmail_dot_com&gt;</i>
</div><br />

<code class="me">nextset</code><code>()</code>
<div class="desc">This method makes the cursor skip to the next
available result set, discarding any remaining rows from the current set.
Returns True value if next result is available, None if not.
</div><br />

<code class="me">__iter__</code><code>()</code>, <code class="me">next</code><code>()</code>
<div class="desc">These methods faciliate
<a href="http://docs.python.org/library/stdtypes.html#iterator-types">Python iterator protocol</a>.
You most likely will not call them directly, but indirectly by using iterators.
</div><br />

<code class="me">setinputsizes</code><code>()</code>, <code class="me">setoutputsize</code><code>()</code>
<div class="desc">These methods do nothing, as permitted by DB-API specs.
</div><br />

</blockquote>
</blockquote>

<?php require ('pagefooter.php'); ?>
