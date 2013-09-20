<?php require ('pageheader.php'); ?>

<h3 style="display:inline">Advanced information</h3>
<blockquote>
<h4>Connections: hosts, protocols and aliases.</h4>

<blockquote>
This information covers Windows clients. I documented it here because I found 
no other place where these details are described. The same advanced options
are available for Linux/*nix clients using FreeTDS library, you can set up host
aliases in <code>freetds.conf</code> file. Look for information in the 
<a href="http://www.freetds.org/userguide/install.htm">FreeTDS documentation</a>.
<br /><br />

If you need to connect to a host using specified protocol, e.g. named pipes,
you can set up a specific aliased connection for the host
using Client Network Utility, which is bundled on SQL Server 2000 installation media. 
If you don&#39;t have one, you can do the same by creating Registry entries. Here are some examples 
of how to proceed by making changes to the Registry.<br /><br />
These entries in fact create <i>aliases</i> for host names.<br /><br />

<b>Example 1</b>. Connect to host <code>sqlhost3</code> with named pipes.<br />
Execute the following command from the command line (this is one line, don&#39;t break it):<br />
<blockquote class="syntax">
<code>
REG ADD &quot;HKLM\Software\Microsoft\MSSQLServer\Client\ConnectTo&quot; 
/v sqlhost3 /t REG_SZ /d &quot;DBNMPNTW,\\sqlhost3\pipe\sql\query&quot;
</code><br />
</blockquote>
then from pymssql connect as usual, giving just the string <code class="s">&#39;sqlhost3&#39;</code>
as host parameter to <code class="me">connect</code><code>()</code> method. This way
you only provide the alias <code>sqlhost3</code> and the driver looks for the settings
in Registry. The above path <code>\\sqlhost3\pipe\sql\query</code> usually means
default SQL Server instance on <code>sqlhost3</code> machine. You have to consult
your configuration (either with Server Network Utility or SQL Server Configuration Manager)
to obtain path for a named instance.<br /><br />

<b>Example 2</b>. Connect to host <code>sqlhost4</code> with TCP/IP protocol.<br />
It may seem strange at first, but there are chances that the client machine&#39;s Registry 
is set up so preferred protocol is named pipes, and one may want to set an alias for
a specific machine manually.
Execute the following command from the command line (this is one line, don&#39;t break it):<br />
<blockquote class="syntax">
<code>
REG ADD &quot;HKLM\Software\Microsoft\MSSQLServer\Client\ConnectTo&quot; 
/v sqlhost4 /t REG_SZ /d &quot;DBMSSOCN,sqlhost4.example.com,1433&quot;
</code><br />
</blockquote>
then from pymssql connect as usual, giving just the string <code class="s">&#39;sqlhost4&#39;</code>
as host parameter to <code class="me">connect</code><code>()</code> method. This way
you only provide the alias <code>sqlhost4</code> and the driver looks for the settings
in Registry. As you can see, there is host name and TCP port number hard coded for the alias
<code>sqlhost4</code>.

</blockquote>
</blockquote>

<?php require ('pagefooter.php'); ?>
