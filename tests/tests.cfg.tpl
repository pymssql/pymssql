# in order for the tests to work correctly, the value for server
# SHOULD NOT appear in any freetds.conf file.
#
# Ideally, the test DB server would be a non-default instance which allows full
# tests of the instance and port parameters.


[DEFAULT]
server = sqlserver
username = sa
password = YourStrong!Passw0rd
database = tempdb
port = 1433
ipaddress = 10.5.0.5
# Instance isn't working with docker even though select @@servicename returns MSSQLSERVER
# instance = MSSQLSERVER

# this shows all options need to run all tests
[AllTestsWillRun]
server = mydbserver
ipaddress = 192.168.1.1
username = foouser
password = somepass
database = testdb
port = 1435
instance = testinst

[DOCKER_2019]
#
# docker pull mcr.microsoft.com/mssql/server:2019-latest
# docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=sqlServerPassw0rd" -p 1433:1433 --name sql2019 -hostname sql2 -d mcr.microsoft.com/mssql/server:2019-latest
# docker start/stop sql2019
#
server = localhost
username = sa
password = sqlServerPassw0rd
database = tempdb
port = 1433
ipaddress = 127.0.0.1
encryption = require

[AZURE]
server = pymssqlserver.database.windows.net
username = azureuser
password = PyMSSQLSERVERpassword!
port = 1433
database = mySampleDatabase
#database = testdb
ipaddress = 40.78.225.32
