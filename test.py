import _mssql
mssql=_mssql.connect('127.0.0.1','sa','')
mssql.select_db('tempdb')

query="create table pymssql (no int, fno float, comment varchar(50));"
ret = mssql.query(query)
if ret:
    print "create table: %d" % ret
    print mssql.fetch_array()
else:
    print mssql.errmsg()


for x in range(10):
    query="insert into pymssql (no,fno,comment) values (%d,%d.%d,'%dth comment');" % (x+1,x+1,x+1,x+1)
    ret=mssql.query(query)
    if ret:
        print "insert table: %d" % ret
        print mssql.fetch_array()
    else:
        print mssql.errmsg()



for x in range(10):
    query="update pymssql set comment='%dth hahaha.' where no = %d" % (x+1,x+1)
    ret=mssql.query(query)
    if ret:
        print "update table: %d" % ret
        print mssql.fetch_array()
    else:
        print mssql.errmsg()




query="EXEC sp_tables; select * from pymssql;"
for x in range(10):
    if mssql.query(query):
        header=mssql.fetch_array()
        for y in header:
            print y
        #print x,header[0][0][0],len(header[0][1][0])
    else:
        print mssql.errmsg()
        print mssql.stdmsg()




query="drop table pymssql;"
ret = mssql.query(query)
if ret:
    print "drop table: %d" % ret
    print mssql.fetch_array()
else:
    print mssql.errmsg()




mssql.close()
