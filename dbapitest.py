#***************************************************************************
#                          dbapitest.py  -  description
#
#    begin                : 2003-03-03
#    copyright            : (C) 2003-03-03 by Joon-cheol Park
#    email                : jooncheol@gmail.com
#    homepage             : http://www.exman.pe.kr
#
#***************************************************************************

#***************************************************************************
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301  USA
#***************************************************************************

import pymssql
con = pymssql.connect(host='127.0.0.1',user='sa',password='',database='tempdb')
cur = con.cursor()


"""
try:
    cur.execute("create database hohomama")
    result=cur.fetchall()
except Exception, detail:
    print detail


try:
    cur.execute("drop database hohomama")
    result=cur.fetchall()
except Exception, detail:
    print str(detail)

"""



query="create table pymssql (no int, fno float, comment varchar(50));"
cur.execute(query)
print "create table: %d" % cur.rowcount

for x in range(10):
    query="insert into pymssql (no,fno,comment) values (%d,%d.%d,'%dth comment');" % (x+1,x+1,x+1,x+1)
    ret=cur.execute(query)
    print "insert table: %d" % cur.rowcount
    

for x in range(10):
    query="update pymssql set comment='%dth hahaha.' where no = %d" % (x+1,x+1)
    ret=cur.execute(query)
    print "update table: %d" % cur.rowcount
    


query="EXEC sp_tables; select * from pymssql;"
for x in range(10):
    cur.execute(query)
    while 1:
	print cur.fetchall()
	if 0 == cur.nextset():
	    break




query="drop table pymssql;"
cur.execute(query)
print "drop table: %d" % cur.rowcount

con.commit()
con.close()
