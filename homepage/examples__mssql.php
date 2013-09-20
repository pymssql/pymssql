<?php require ('pageheader.php'); ?>
<h3 style="display:inline">_mssql examples (no DB-API overhead)</h3>
<blockquote>This module allows for easy communication with SQL Server.</blockquote>
<blockquote><b>Quickstart usage of various features:</b></blockquote>
                            
<table border="0" align="center" class="syntax"><tr><td>
	<span class="kn">import</span> <span class="ty">_mssql</span><br />
	<span class="n">conn</span> <span class="o">=</span> <span class="ty">_mssql</span><span
		class="o">.</span><span class="me">connect</span><span class="p">(</span>server=<span class="s">&#39;SQL01&#39;</span><span
			class="p">,</span> user=<span class="s">&#39;user&#39;</span><span class="p">,</span> password=<span
				class="s">&#39;password&#39;</span><span class="p">, \<br /></span> 
	&nbsp;&nbsp;&nbsp;&nbsp;database=<span class="s">&#39;mydatabase&#39;</span><span class="p">)</span><br />
	<span class="n">conn</span><span class="o">.</span><span class="me">execute_non_query</span><span
		class="p">(</span><span class="s">&#39;CREATE TABLE persons(id INT, name VARCHAR(100))&#39;</span><span
			class="p">)</span><br />
	<span class="n">conn</span><span class="o">.</span><span class="me">execute_non_query</span><span
		class="p">(</span><span class="s">&quot;INSERT INTO persons VALUES(1, &#39;John Doe&#39;)&quot;</span><span
			class="p">)</span><br />
	<span class="n">conn</span><span class="o">.</span><span class="me">execute_non_query</span><span
		class="p">(</span><span class="s">&quot;INSERT INTO persons VALUES(2, &#39;Jane Doe&#39;)&quot;</span><span
			class="p">)</span>

<br /><br /><hr /><br />

	<span class="c"># how to fetch rows from a table</span><br />
	<span class="n">conn</span><span class="o">.</span><span class="me">execute_query</span><span
		class="p">(</span><span class="s">&#39;SELECT * FROM persons WHERE salesrep=<span class="sf">%s</span>&#39;</span>,
		 <span class="s">&#39;John Doe&#39;</span><span class="p">)</span><br />
	<span class="k">for</span> <span class="n">row</span> <span class="ow">in</span> <span
		class="n">conn</span><span class="p">:</span><br />
		&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">print</span> <span class="s">&quot;ID=</span><span class="si">%d</span><span
			class="s">, Name=</span><span class="si">%s</span><span class="s">&quot;</span> <span
				class="o">%</span> <span class="p">(</span><span class="n">row</span><span class="p">[</span><span
					class="s">&#39;id&#39;</span><span class="p">],</span> <span class="n">row</span><span
						class="p">[</span><span class="s">&#39;name&#39;</span><span class="p">])</span>

<br /><br /><hr /><br />

	<span class="c"># examples of other query functions</span><br />
	numemployees = <span class="n">conn</span><span class="o">.</span><span class="me">execute_scalar</span><span
		class="p">(</span><span class="s">&quot;SELECT COUNT(*) FROM employees&quot;</span><span
			class="p">)</span><br />
	numemployees = <span class="n">conn</span><span class="o">.</span><span class="me">execute_scalar</span><span
		class="p">(</span><span class="s">&quot;SELECT COUNT(*) FROM employees WHERE name LIKE &#39;J%&#39;&quot;</span><span
			class="p">)</span>&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># note that &#39;%&#39; is not a special character here</span><br />
	employeedata = <span class="n">conn</span><span class="o">.</span><span class="me">execute_row</span><span
		class="p">(</span><span class="s">&quot;SELECT * FROM employees WHERE id=<span class="sf">%d</span>&quot;</span>, 13<span
			class="p">)</span>

<br /><br /><hr /><br />

	<span class="c"># how to fetch rows from a stored procedure</span><br />
	<span class="n">conn</span><span class="o">.</span><span class="me">execute_query</span><span
		class="p">(</span><span class="s">&#39;sp_spaceused&#39;</span><span class="p">)</span>
		&nbsp;&nbsp;<span class="c"># sp_spaceused without arguments returns 2 result sets</span><br />
	res1 = [ row <span class="kn">for</span> row <span class="kn">in</span
	> conn ]&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># 1st result</span><br />
	res2 = [ row <span class="kn">for</span> row <span class="kn">in</span
	> conn ]&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># 2nd result</span>

<br /><br /><hr /><br />

	<span class="c"># how to get an output parameter from a stored procedure</span><br />
	sqlcmd = <span class="s">&quot;&quot;&quot;<br />
	DECLARE @res INT<br />
	EXEC usp_mystoredproc @res OUT<br />
	SELECT @res<br />
	&quot;&quot;&quot;</span><br />
	res = <span class="n">conn</span><span class="o">.</span><span class="me">execute_scalar</span><span
		class="p">(</span>sqlcmd<span class="p">)</span>

<br /><br /><hr /><br />

	<span class="c"># how to get more output parameters from a stored procedure</span><br />
	sqlcmd = <span class="s">&quot;&quot;&quot;<br />
	DECLARE @res1 INT, @res2 TEXT, @res3 DATETIME<br />
	EXEC usp_getEmpData <span class="sf">%d</span>, <span class="sf">%s</span>, @res1 OUT, @res2 OUT, @res3 OUT<br />
	SELECT @res1, @res2, @res3<br />
	&quot;&quot;&quot;</span><br />
	res = <span class="n">conn</span><span class="o">.</span><span class="me">execute_row</span><span
		class="p">(</span>sqlcmd<span class="p">, (13, <span class="s">&#39;John Doe&#39;</span>))</span>

<br /><br /><hr /><br />

	<span class="c"># examples of queries with parameters</span><br />
	<span class="n">conn</span><span class="o">.</span><span class="me">execute_query</span
	>(<span class="s">&#39;SELECT * FROM empl WHERE id=<span class="sf">%d</span>&#39;</span>, 13)<br />
	<span class="n">conn</span><span class="o">.</span><span class="me">execute_query</span
	>(<span class="s">&#39;SELECT * FROM empl WHERE name=<span class="sf">%s</span>&#39;</span>, <span class="s">&#39;John Doe&#39;</span>)<br />
	<span class="n">conn</span><span class="o">.</span><span class="me">execute_query</span
	>(<span class="s">&#39;SELECT * FROM empl WHERE id IN (<span class="sf">%s</span>)&#39;</span>, ((5, 6),))<br />
	<span class="n">conn</span><span class="o">.</span><span class="me">execute_query</span
	>(<span class="s">&#39;SELECT * FROM empl WHERE name LIKE <span class="sf">%s</span>&#39;</span>, <span class="s">&#39;J%&#39;</span>)<br />
	<span class="n">conn</span><span class="o">.</span><span class="me">execute_query</span
	>(<span class="s">&#39;SELECT * FROM empl WHERE name=<span class="sf">%(name)s</span> AND city=<span class="sf">%(city)s</span>&#39;</span>, \<br />
	&nbsp;&nbsp;&nbsp;&nbsp;{ <span class="s">&#39;name&#39;</span>: <span class="s">&#39;John Doe&#39;</span>, 
	<span class="s">&#39;city&#39;</span>: <span class="s">&#39;Nowhere&#39;</span> } )<br />
	<span class="n">conn</span><span class="o">.</span><span class="me">execute_query</span
	>(<span class="s">&#39;SELECT * FROM cust WHERE salesrep=<span class="sf">%s</span> AND id IN (<span class="sf"
	>%s</span>)&#39;</span>, \<br />
	&nbsp;&nbsp;&nbsp;&nbsp;(<span class="s">&#39;John Doe&#39;</span>, (1, 2, 3)))<br />
	<span class="n">conn</span><span class="o">.</span><span class="me">execute_query</span
	>(<span class="s">&#39;SELECT * FROM empl WHERE id IN (<span class="sf">%s</span>)&#39;</span>, (<span class="ty">tuple</span
	>(<span class="ty">xrange</span>(4)),))<br />
	<span class="n">conn</span><span class="o">.</span><span class="me">execute_query</span
	>(<span class="s">&#39;SELECT * FROM empl WHERE id IN (<span class="sf">%s</span>)&#39;</span>, \<br />
	&nbsp;&nbsp;&nbsp;&nbsp;(<span class="ty">tuple</span>([3, 5, 7, 11]),))

<br /><br /><hr /><br />


	<span class="n">conn</span><span class="o">.</span><span class="me">close</span><span
		class="p">()</span><br /><br />

	</td></tr>
	<tr><td>
		<span style="font-style: italic; color: #008800">Please note the usage of iterators and ability
		to access results by column name. Also please note that parameters to 
		<code style="font-style: normal">connect</code> method have  
		different names than in pymssql module.</span>
	</td></tr>
	</table><br />

<blockquote><b>An example of exception handling:</b></blockquote>

		 <table border="0" align="center" class="syntax"><tr><td>
	<span class="kn">import</span> <span class="ty">_mssql</span><br />
	<span class="kn">try</span>:<br />
		&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">conn</span> <span class="o">=</span> <span class="ty">_mssql</span><span
		class="o">.</span><span class="me">connect</span><span class="p">(</span>server=<span class="s">&#39;SQL01&#39;</span><span
			class="p">,</span> user=<span class="s">&#39;user&#39;</span><span class="p">,</span> password=<span
				class="s">&#39;password&#39;</span><span class="p">,</span> \<br />
				&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;database=<span
				class="s">&#39;mydatabase&#39;</span><span class="p">)</span><br />
		&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">conn</span>.<span class="me">execute_non_query</span>(<span class="s">&#39;CREATE TABLE t1(id INT, name VARCHAR(50))&#39;</span>)<br />
	<span class="kn">except</span> <span class="ty">_mssql</span>.<span class="ty">MssqlDatabaseException</span>,e:<br />
		&nbsp;&nbsp;&nbsp;&nbsp;<span class="kn">if</span> e.<span class="me">number</span> == 2714 <span class="kn">and</span> e.<span 
		class="me">severity</span> == 16:<br />
			&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c"># table already existed, so quieten the error</span><br />
		&nbsp;&nbsp;&nbsp;&nbsp;<span class="kn">else</span>:<br />
			&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="kn">raise</span>   <span class="c"># re-raise real error</span><br />
	<span class="kn">finally</span>:<br />
		&nbsp;&nbsp;&nbsp;&nbsp;conn.<span class="me">close</span>()<br /><br />
	<span class="c">Please see more info on exceptions below.</span>
</td></tr></table>
<br /><br /><br /><br />
<?php require ('pagefooter.php'); ?>
