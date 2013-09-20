<?php require ('pageheader.php'); ?>
<h3 style="display:inline">FreeTDS and dates</h3>
<blockquote>
	<p><b>
		Summary: make sure that FreeTDS is compiled with <code>--enable-msdblib</code> configure option,
		or your queries will return wrong dates -- 2009-00-01 instead of 2009-01-01.
	</b></p>
	<p>
		There&#39;s an obscure problem on Linux/*nix that results in dates shifted back by 1 month.
		This behaviour is caused by different <code>dbdatecrack()</code> prototypes in Sybase Open Client
		DB-Library/C and the Microsoft SQL DB Library for C. The first one returns month as 0..11
		whereas the second gives month as 1..12. See 
		<a href="http://lists.ibiblio.org/pipermail/freetds/2002q3/008336.html">
		this FreeTDS mailing list post</a>, 
		<a href="http://msdn.microsoft.com/en-us/library/aa937027(SQL.80).aspx">
		Microsoft manual for dbdatecrack()</a>, and 
		<a href="http://manuals.sybase.com/onlinebooks/group-cnarc/cng1110e/dblib/@Generic__BookTextView/15108">
		Sybase manual for dbdatecrack()</a> for details.
	</p>
	<p>
		FreeTDS, which is used on Linux/*nix to connect to Sybase and MS SQL servers, tries
		to imitate both modes:</p>
		<ul>
			<li>default behaviour, when compiled <i>without</i> <code>--enable-msdblib</code>, gives
				<code>dbdatecrack()</code> which is Sybase-compatible,</li>
			<li>when configured with <code>--enable-msdblib</code>, the <code>dbdatecrack()</code>
				function is compatible with MS SQL specs.</li>
		</ul>
	<p>
		pymssql requires MS SQL mode, evidently. Unfortunately at runtime we can&#39;t 
		reliably detect which mode FreeTDS was compiled in (as of FreeTDS 0.63). 
		Thus at runtime it may turn out that dates are not correct. If there was a way to
		detect the setting, pymssql would be able to correct dates on the fly.
	</p>
	<p>
		If you can do nothing about FreeTDS, there&#39;s a workaround. You can redesign your
		queries to return string instead of bare date:<br />
		&nbsp;&nbsp;&nbsp;&nbsp;<code><span style="color:blue">SELECT</span> datecolumn 
		<span style="color:blue">FROM</span> tablename</code><br />
		can be rewritten into:<br />
		&nbsp;&nbsp;&nbsp;&nbsp;<code><span style="color:blue">SELECT</span> 
		<span style="color:fuchsia">CONVERT</span>(<span style="color:blue">CHAR</span>(10),datecolumn,120)
		<span style="color:blue">AS</span> datecolumn <span style="color:blue">FROM</span> tablename</code>                                     <br />
		This way SQL will send you string representing the date instead of binary date in
		datetime or smalldatetime format, which has to be processed by FreeTDS and pymssql.
	</p>
	On Windows there&#39;s no problem at all, because we link with MS library, which 
	is compatible with SQL Server, obviously.</blockquote>
	
	<br /><br />

<?php require ('pagefooter.php'); ?>
