<?php require ('pageheader.php'); ?>


<h3 style="display:inline">Compilation and installation from source</h3>
<p>
    If you need to compile pymssql, check whether requirements shown below are
    met, unpack source files to a directory of your choice and issue (as root):<br />
    <tt># python setup.py install</tt><br />
    This will compile and install pymssql.</p>
<h3>Build Requirements</h3>
<blockquote>
    <ul>
        <li>Python language. Please check <a href="platforms.php">platforms</a> page for version info.</li>
        <li>Python development package -- 
        when needed by your OS (for example python-dev or libpython2.5-devel).</li>
        <li>Linux, *nix and Mac OS X: <a href="http://www.freetds.org/">FreeTDS</a> 0.63 or
            newer (you need freetds-dev or freetds-devel or similar named package -- thanks
            Scott Barr for pointing that out).<br />
            <i>NOTE: FreeTDS must be configured with --enable-msdblib to return correct dates! 
            See <a href="freetds_dates.php">FreeTDS and Dates</a> for details.</i></li>
        <li>Windows: SQL Developer Tools, to be found on MS SQL 2000 installation media.</li>
        <li>Windows: If you compile pymssql for Python 2.4 or 2.5, you need either Microsoft Visual
            C++ .NET 2003 or Microsoft Visual Studio .NET 2003. It will complain if you will try 
            to use newer versions.</li>
        <li>Windows: If you compile pymssql for Python
            2.6 or newer, you need Microsoft Visual Studio 2005 or Microsoft Visual Studio 2008. 
            I think that downloadable <a href="http://www.microsoft.com/express/download/"
            target="_blank">Microsoft Visual C++ Express edition</a> can be used.</li>
    </ul>
</blockquote>
    <h3>Platform-specific issues</h3>
    <h4>Mandriva Linux</h4>
    <blockquote>
    <p>
    If you use some older versions of Mandriva Linux and want to compile pymssql, 
    you may have to edit setup.py and change:<br />
    <code>&nbsp;&nbsp;&nbsp;&nbsp;libraries = [<span class="s">"sybdb"</span>]</code><br />
    into:<br />
    <code>&nbsp;&nbsp;&nbsp;&nbsp;libraries = [<span class="s">"sybdb_mssql"</span>]</code><br />
    Be sure to install <code>libfreetds_mssql0</code> package first.</p>
    </blockquote>

    <h4>Windows</h4>
    <blockquote>
        <p>FreeTDS on Windows is not supported.</p>
    </blockquote>
<br />
<b>Please also consult <a href="freetds_dates.php">FreeTDS and Dates</a> document.</b>
<br /><br />

<?php require ('pagefooter.php'); ?>
