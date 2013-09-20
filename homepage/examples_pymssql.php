<?php require ('pageheader.php'); ?>
<h3 style="display:inline">pymssql examples (strict DB-API compliance):</h3>
<br /><br />
<table border="0" align="center" class="syntax"><tr><td>
	<span class="kn">import</span> <span class="ty">pymssql</span><br />
	<span class="n">conn</span> <span class="o">=</span> <span class="ty">pymssql</span><span
		class="o">.</span><span class="me">connect</span><span class="p">(</span>host=<span class="s">&#39;SQL01&#39;</span><span
			class="p">,</span> user=<span class="s">&#39;user&#39;</span><span class="p">,</span> password=<span
				class="s">&#39;password&#39;</span><span class="p">,</span> database=<span
				class="s">&#39;mydatabase&#39;</span><span class="p">)</span><br />
	<span class="n">cur</span> <span class="o">=</span> <span class="n">conn</span><span class="o">.</span><span class="me">cursor</span><span class="p">()</span><br />
	<span class="n">cur</span><span class="o">.</span><span class="me">execute</span><span
		class="p">(</span><span class="s">&#39;CREATE TABLE persons(id INT, name VARCHAR(100))&#39;</span><span
			class="p">)</span><br />
	<span class="n">cur</span><span class="o">.</span><span class="me">executemany</span><span
		class="p">(</span><span class="s">&quot;INSERT INTO persons VALUES(<span class="sf">%d</span>,
		 <span class="sf">%s</span>)&quot;</span><span class="p">,</span> \<br />
		&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">[ (</span>1, <span class="s">&#39;John Doe&#39;</span><span class="o">)</span><span
			class="p">,</span> <span class="p">(</span>2, <span class="s">&#39;Jane Doe&#39;</span><span class="p">) ])</span><br />
	<span class="n">conn</span><span class="o">.</span><span class="me">commit</span><span
		class="p">()</span>&nbsp;&nbsp;<span class="c"># you must call commit() to persist your data 
		if you don&#39;t set autocommit to True</span><br />
	<br />
	<span class="n">cur</span><span class="o">.</span><span class="me">execute</span><span
		class="p">(</span><span class="s">&#39;SELECT * FROM persons WHERE salesrep=<span class="sf">%s</span
		>&#39;</span>, <span class="s">&#39;John Doe&#39;</span><span class="p">)</span><br />
	<span class="n">row</span> <span class="o">=</span> cur<span class="p">.</span><span class="me">fetchone</span><span
		class="p">()</span><br />
	<span class="k">while</span> <span class="n">row</span><span class="p">:</span><br />
		&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">print</span> <span class="s">&quot;ID=</span><span class="sf">%d</span><span
			class="s">, Name=</span><span class="sf">%s</span><span class="s">&quot;</span> <span
				class="o">%</span> <span class="p">(</span><span class="n">row</span><span class="p">[</span>0<span class="p">],</span> <span class="n">row</span><span
						class="p">[</span>1<span class="p">])</span><br />
		&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">row</span> <span class="o">=</span> cur<span class="p">.</span><span class="me">fetchone</span><span
		class="p">()</span><br />
	<br />
	<span class="c"># if you call execute() with one argument, you can use % sign as usual<br />
	# (it loses its special meaning).</span><br />
	<span class="n">cur</span><span class="o">.</span><span class="me">execute</span><span
		class="p">(</span><span class="s">&quot;SELECT * FROM persons WHERE salesrep LIKE &#39;J%&#39;&quot;</span><span class="p">)</span><br />
	<br />
	<span class="n">conn</span><span class="o">.</span><span class="me">close</span><span class="p">()</span><br />
	<br />
	</td></tr>
	<tr><td>
		<span style="font-style: italic; color: #008800">You can also use iterators instead
		 of <code style="font-style: normal">while</code> loop. Iterators are DB-API extensions,
		 and are available since pymssql 1.0.</span>
	</td></tr>
</table>
<br /><hr />
<blockquote>
<h4>Rows as dictionaries</h4>
Since pymssql 1.0.2 rows can be fetched as dictionaries instead of tuples. This
allows for accessing columns by name instead of index.
<br /><br />
</blockquote>

<table border="0" align="center" class="syntax"><tr><td>
    <span class="kn">import</span> <span class="ty">pymssql</span><br />
    <span class="n">conn</span> <span class="o">=</span> <span class="ty">pymssql</span><span
        class="o">.</span><span class="me">connect</span><span class="p">(</span>host=<span class="s">&#39;SQL01&#39;</span><span
            class="p">,</span> user=<span class="s">&#39;user&#39;</span><span class="p">,</span> password=<span
                class="s">&#39;password&#39;</span><span class="p">,</span> database=<span
                class="s">&#39;mydatabase&#39;</span><span class="p">, <span style="background-color: #ffcccc">as_dict=<span class="kn">True</span></span>)</span><br />
    <span class="n">cur</span> <span class="o">=</span> <span class="n">conn</span><span class="o">.</span><span class="me">cursor</span><span class="p">()</span><br />
    <br />
    <span class="n">cur</span><span class="o">.</span><span class="me">execute</span><span
        class="p">(</span><span class="s">&#39;SELECT * FROM persons WHERE salesrep=<span class="sf">%s</span
        >&#39;</span>, <span class="s">&#39;John Doe&#39;</span><span class="p">)</span><br />
    <span class="k">for</span> row <span class="k">in</span> <span class="n">cur</span><span class="p">:</span><br />
        &nbsp;&nbsp;&nbsp;&nbsp;<span class="k">print</span> <span class="s">&quot;ID=</span><span class="sf">%d</span><span
            class="s">, Name=</span><span class="sf">%s</span><span class="s">&quot;</span> <span
                class="o">%</span> <span class="p">(</span><span style="background-color: #ffcccc"><span 
                class="n">row</span><span class="p">[</span><span
                class="s">&#39;id&#39;</span><span class="p">],</span> <span class="n">row</span><span
                class="p">[</span><span class="s">&#39;name&#39;</span><span class="p">]</span>)</span><br />
    <br />
    <span class="n">conn</span><span class="o">.</span><span class="me">close</span><span class="p">()</span><br />
    <br />
    </td></tr>
</table>


<br /><br /><br /><br />
<?php require ('pagefooter.php'); ?>
