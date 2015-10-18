# Configure SQL server so it accepts TCP connections.
#
# This Windows PowerShell script is used on the Appveyor hosted CI plaform when
# running the FreeTDS test suite but could be useful to automate the task in
# other scenarios.
#
# See
# http://www.appveyor.com/docs/services-databases#enabling-tcp-ip-named-pipes-and-setting-instance-alias
# https://gist.githubusercontent.com/FeodorFitsner/d971c5a98782d211640d/raw/sql-server-ip-and-alias.ps1
# http://geekswithblogs.net/TedStatham/archive/2014/06/13/setting-the-ports-for-a-named-sql-server-instance-using.aspx

[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | Out-Null

$serverName = $env:COMPUTERNAME
$instanceName = $env:INSTANCENAME
$smo = 'Microsoft.SqlServer.Management.Smo.'
$wmi = new-object ($smo + 'Wmi.ManagedComputer')

# Enable TCP/IP
$uri = "ManagedComputer[@Name='$serverName']/ServerInstance[@Name='$instanceName']/ServerProtocol[@Name='Tcp']"
$Tcp = $wmi.GetSmoObject($uri)
$Tcp.IsEnabled = $true
foreach ($ipAddress in $Tcp.IPAddresses)
{
    $ipAddress.IPAddressProperties["TcpDynamicPorts"].Value = ""
    $ipAddress.IPAddressProperties["TcpPort"].Value = "1433"
}
$Tcp.alter()

# Service needs to be restarted
# Restart service
Restart-Service "MSSQL`$$instanceName"
