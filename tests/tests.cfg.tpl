# in order for the tests to work correctly, the value for server
# SHOULD NOT appear in any freetds.conf file.
#
# Ideally, the test DB server would be a non-default instance which allows full
# tests of the instance and port parameters.


[DEFAULT]
server = mydbserver
# IP Address should be included as well as it allows us to test connections
# to the database in different ways.
ipaddress = 192.168.1.1
username = foouser
password = somepass
database = testdb

# this shows all options need to run all tests
[AllTestsWillRun]
server = mydbserver
ipaddress = 192.168.1.1
username = foouser
password = somepass
database = testdb
port = 1435
instance = testinst
