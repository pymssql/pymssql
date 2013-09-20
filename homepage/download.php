<?php require ('pageheader.php'); ?>
<h3 style="display: inline">Download</h3>
<!-- body -->
<p>
    Latest version is pymssql 1.0.2 released 2009-04-28.</p>
<p>
    <a href="https://sourceforge.net/project/showfiles.php?group_id=40059&amp;package_id=32202&amp;release_id=679018"
        target="_blank" style="font-weight:bold">Download from Sourceforge.net</a><br />
</p>


<h3 style="display: inline">Runtime Requirements</h3>
<p>In order to run pymssql, you need the following:</p>
<blockquote>
    <ul>
        <li>Python language. Please check <a href="platforms.php">Platforms</a> page for version info.</li>
        <li>Linux, *nix and Mac OS X: <a href="http://www.freetds.org/">FreeTDS</a> 0.63 or
            newer. Your OS may have a package for that, example names are libfreetds0, lib64freetds0,
            freetds0. On FreeBSD there is a port <code>databases/freetds-msdblib</code>.<br />
            <i>NOTE: FreeTDS must be configured with --enable-msdblib to return correct dates!
            <a href="freetds_dates.php">FreeTDS and Dates</a> document for details.</i></li>
        <li>NOTE: pymssql doesn&#39;t invalidate the requirement for an SQL Client Access Licence
            for every host you want to run it on, be it Windows or *nix, if your SQL Server
            is licenced per user or per device connected.</li>
    </ul>
    </blockquote>

<p style="font-style:italic; font-size:small">More info: pymssql on Windows is equipped with 
    ntwdblib.dll library version 2000.80.2187.0 which is distributed
    by Microsoft in SQL 2000 SP4 package. This is not the newest available version, but there
    was a problem with newest version 2000.80.2273.0.
    This library is redistributable -- 
    see REDIST.txt on the SQL Server 2000 installation media,
    in SQL Server 2000 SP4 installation package, or <a href="REDIST.txt">here</a>
    (it is copied here just to have a reference of these rights). You don&#39;t have to install full 
    MS SQL Client Tools package unless you need to use advanced
    client configuration tools available there, for example Client Network Utility.
</p>
<br /><hr /><br />
<h3 style="display: inline">Compilation and installation from source</h3>
<p>
	If you need to compile pymssql from source, please see <a href="compilation.php">Compilation</a>.
</p>
<br />

<?php require ('pagefooter.php'); ?>
