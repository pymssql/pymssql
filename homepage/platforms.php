<?php require ('pageheader.php'); ?>

<h3 style="display: inline">Tested platforms</h3>
<!-- body -->

<blockquote>
    <p>This is the matrix of tested platforms and pymssql versions:</p>
    <table cellspacing="1" border="1">
        <thead>
            <tr>
                <th rowspan="2" valign="bottom">pymssql</th>
                <th colspan="5">Python</th>
                <th colspan="6">Operating system</th>
            </tr>
            <tr>
                <th>&lt;2.4</th><th>2.4</th><th>2.5</th><th>2.6</th><th>3.0</th>
                <th>Windows</th><th>Linux</th><th>MacOS</th><th>FreeBSD</th><th>NetBSD</th><th>
                Solaris</th>
            </tr>
        </thead>
        <tr>
            <td>1.0.x</td>
            <td style="background: #ff8888; text-align: center">-</td>
            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #ff8888; text-align: center">-</td>

            <td style="background: #44ff44; text-align: center">+ <sup>5</sup></td>
            <td style="background: #44ff44; text-align: center">+ 32/64-bit</td>
            <td style="background: #44ff44; text-align: center">+ <sup>4</sup></td>
            <td style="background: #44ff44; text-align: center">+ 32/64 bit</td>
            <td style="background: #44ff44; text-align: center">+ 32/64 bit</td>
            <td style="background: #cccccc; text-align: center">ND</td>
        </tr>

        <tr>
            <td>0.8.0 *)</td>
            <td style="background: #ff8888; text-align: center">-</td>
            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #ff8888; text-align: center">-</td>
            <td style="background: #ff8888; text-align: center">-</td>

            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #cccccc; text-align: center">ND</td>
            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #44ff44; text-align: center">+ <sup>1</sup></td>
        </tr>

        <tr>
            <td>0.7.4 *)</td>
            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #ff8888; text-align: center">-</td>
            <td style="background: #ff8888; text-align: center">-</td>
            <td style="background: #ff8888; text-align: center">-</td>

            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #44ff44; text-align: center">+ <sup>2</sup></td>
            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #44ff44; text-align: center">+ <sup>1</sup></td>
        </tr>

        <tr>
            <td>0.7.1 *)</td>
            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #ff8888; text-align: center">-</td>
            <td style="background: #ff8888; text-align: center">-</td>
            <td style="background: #ff8888; text-align: center">-</td>

            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #44ff44; text-align: center">+ <sup>3</sup></td>
            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #44ff44; text-align: center">+</td>
            <td style="background: #44ff44; text-align: center">+ <sup>1</sup></td>
        </tr>
    </table>
    <span style="background:#bbbbbb">ND</span> = no data -- not tested and not 
    received any feedback.<br />
    *) pymssql 0.8.0 and earlier was only tested with 32-bit operating systems.<br />
    <sup>1</sup> Solaris 10/x86.<br />
    <sup>2</sup> thanks S&#233;bastien Arnaud for reporting.<br />
    <sup>3</sup> thanks Joseph Kocherhans for reporting.<br />
	<sup>4</sup> thanks MunShik JEONG, and Kurt Sutter for reporting.<br />
    <sup>5</sup> pymssql for Windows is available only for 32-bit Python. You can use it with 64-bit
    Windows. There is no native 64-bit pymssql, because Microsoft has not released
    64-bit version of <code>ntwdblib.dll</code> library, to which pymssql could link.

    <p>If you have experience with other platforms, just let me know and I&#39;ll add 
        the info here.</p>
</blockquote>
<h3 style="display:inline">Tested SQL Server versions</h3>
<blockquote>
    <p>
        pymssql was tested with the following servers:</p>
    <ul>
        <li>SQL Server 2000 Standard and Enterprise Editions,</li>
        <li>SQL Server 2000 Desktop Engine (MSDE 2000),</li>
        <li>SQL Server 2005 Standard and Enterprise Editions,</li>
        <li>SQL Server 2005 Express Edition,</li>
        <li>SQL Server 2008 Express Edition.</li>
    </ul>
    All SQL Server service pack levels are fine.
</blockquote>

<a id="limitations" />
<h3 style="display:inline">Limitations and known issues</h3><br />
<blockquote>
    You may encounter some issues using this software. They are
    summarized on <a href="limitations.php">this page</a>.
</blockquote>

<?php require ('pagefooter.php'); ?>
