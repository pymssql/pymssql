<?php require ('pageheader.php'); ?>

<h3 style="display:inline">Architecture and configuration</h3>

<h4>pymssql on Windows</h4>
<blockquote>
pymssql on Windows doesn&#39;t require any additional components to be installed.
The only required library, <code>ntwdblib.dll</code>, is included with pymssql,
and it&#39;s all that is needed to make connections to Microsoft SQL Servers.
It is called DB Libary for C, and is documented
<a href="http://msdn.microsoft.com/en-us/library/aa298003.aspx"
>here</a>. This library is
responsible for low level communication with SQL Servers, and is extensively
used by <code class="ty">_mssql</code> module.<br /><br />
Typically you don&#39;t need any configuration in order to make it work. However
I wrote a few paragraphs about more sophisticated configuration in
<a href="advancedinfo.php">Advanced information</a>.
<br /><br />
On Windows in addition to authenticating to SQL using user name and password,
you can also authenticate using so called Windows Authentication,
or Trusted Connection. In this mode SQL Server validates the connection
using user&#39;s <i>security token</i> provided by the operating system.
In other words, user&#39;s identity is confirmed by Windows, so SQL trusts it
(hence trusted connection).
It is suggested method of connecting, because is eliminates the need 
for hard coding passwords in clear text in scripts.<br />
</blockquote>
<table border="0" align="center" class="syntax"><tr><td>
	<span class="c"># An example on how to connect using Windows Integrated Authentication.</span><br />
	conn = <span class="ty">_mssql</span>.<span class="me">connect</span>(<span class="s"
	>&#39;sqlhost&#39;</span>, trusted=<span class="ty">True</span>)
	<br />
	conn = <span class="ty">pymssql</span>.<span class="me">connect</span>(host=<span class="s"
	>&#39;sqlhost&#39;</span>, trusted=<span class="ty">True</span>)
</td></tr></table>


<h4>pymssql on Linux/*nix</h4>
<blockquote>
Linux/*nix on this webpage refers to any operating system different than
Microsoft Windows, i.e. Linux, BSD, Solaris, MacOS etc.<br />
pymssql on these platforms require a low level driver that is able to
speak to SQL Servers. This driver is implemented by <a href="http://www.freetds.org/"
><code>FreeTDS</code></a> package. FreeTDS can speak to both Microsoft SQL Servers
and Sybase servers, however there is a problem with dates, which is 
described in more details on <a href="freetds_dates.php">FreeTDS and Dates</a> page.
<br /><br />
You will need to configure FreeTDS. It needs nonempty configuration
in order to work. Below you will find a simple examples, but for more sophisticated
configurations you will need to consult <a href="http://www.freetds.org/userguide/"
>FreeTDS User Guide</a>.<br /><br />
</blockquote>

<table border="0" align="center" class="syntax"><tr><td>
	<span class="c"># Minimal valid freetds.conf that is known to work.</span><br />
	[<span class="me">global</span>]<br />
	&nbsp;&nbsp;&nbsp;&nbsp;<span class="kn">tds version</span> = 7.0<br /><br />
	You can connect using explicit host name and port number:<br /><br />
	conn = <span class="ty">_mssql</span>.<span class="me">connect</span>(<span class="s"
	>&#39;sqlhost:portnum&#39;</span>, <span class="s">&#39;user&#39;</span
	>, <span class="s">&#39;password&#39;</span>)
	<br />
	conn = <span class="ty">pymssql</span>.<span class="me">connect</span>(host=<span class="s"
	>&#39;sqlhost:portnum&#39;</span>, user=<span class="s">&#39;user&#39;</span
	>, password=<span class="s">&#39;password&#39;</span>)
</td></tr></table>

<br /><br />

<table border="0" align="center" class="syntax"><tr><td>
sSample FreeTDS configuration:<br /><br />
<span class="c"># The default instance on a host.</span><br />
[<span class="me">SQL_A</span>]<br />
&nbsp;&nbsp;&nbsp;&nbsp;<span class="kn">host</span> = <span class="s">sqlserver.example.com</span><br />
&nbsp;&nbsp;&nbsp;&nbsp;<span class="kn">port</span> = 1433<br />
&nbsp;&nbsp;&nbsp;&nbsp;<span class="kn">tds version</span> = 7.0<br />
<br />
<span class="c"># Second (named) instance on the same host. The instance name is</span><br />
<span class="c"># not used on Linux/*nix.</span><br />
<span class="c"># This instance is configured to listen on TCP port 1444:</span><br />
<span class="c">#&nbsp;&nbsp;- for SQL 2000 use Enterprise Manager, Network configuration, TCP/IP,</span><br />
<span class="c">#&nbsp;&nbsp;&nbsp;&nbsp;Properties, Default port</span><br />
<span class="c">#&nbsp;&nbsp;- for SQL 2005 and newer use SQL Server Configuration Manager,</span><br />
<span class="c">#&nbsp;&nbsp;&nbsp;&nbsp;Network Configuration, Protocols for ..., TCP/IP, IP Addresses tab,</span><br />
<span class="c">#&nbsp;&nbsp;&nbsp;&nbsp;typically IPAll at the end.</span><br />
[<span class="me">SQL_B</span>]<br />
&nbsp;&nbsp;&nbsp;&nbsp;<span class="kn">host</span> = <span class="s">sqlserver.example.com</span><br />
&nbsp;&nbsp;&nbsp;&nbsp;<span class="kn">port</span> = 1444<br />
&nbsp;&nbsp;&nbsp;&nbsp;<span class="kn">tds version</span> = 7.0<br />
<br />
An example of how to use the above configuration in _mssql:<br /><br />
conn_a = <span class="ty">_mssql</span>.<span class="me">connect</span>(<span class="s">&#39;SQL_A&#39;</span>, <span class="s">&#39;userA&#39;</span>, <span class="s">&#39;passwordA&#39;</span>)<br />
conn_b = <span class="ty">_mssql</span>.<span class="me">connect</span>(<span class="s">&#39;SQL_B&#39;</span>, <span class="s">&#39;userB&#39;</span>, <span class="s">&#39;passwordB&#39;</span>)
</td></tr></table>
<br /><br /><br /><br />

<?php require ('pagefooter.php'); ?>
