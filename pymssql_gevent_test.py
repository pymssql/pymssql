import datetime
import gevent
import os
import pymssql
#import random

server = os.getenv("PYMSSQL_TEST_SERVER")
user = os.getenv("PYMSSQL_TEST_USERNAME")
password = os.getenv("PYMSSQL_TEST_PASSWORD")
database = os.getenv("PYMSSQL_TEST_DATABASE")

def run(num):
#    gevent.sleep(random.randint(0, 2) * 0.001)

    now = datetime.datetime.now()
    print("%s connecting at time: %s" % (num, now))
    conn = pymssql.connect(host=server,
                           database=database,
                           user=user,
                           password=password)
    cur = conn.cursor()
    cur.execute("""
    WAITFOR DELAY '00:00:05'  -- sleep for 5 seconds
    SELECT CURRENT_TIMESTAMP
    """)
    row = cur.fetchone()
    print("    CURRENT_TIMESTAMP = %r" % (row[0],))
    conn.close()

def do_test():
    greenlets = []

    dt1 = datetime.datetime.now()

    for i in range(5):
        greenlets.append(gevent.spawn(run, i))

    gevent.joinall(greenlets)

    dt2 = datetime.datetime.now()

    print("Done running - elapsed time: %s" % (dt2 - dt1))


print("**** Running test WITHOUT gevent.sleep wait_callback...\n")
do_test()

print("\n***** Running test WITH gevent.sleep wait_callback...\n")
def wait_callback(dbproc):
    print("    *** wait_callback called with dbproc = %r" % (dbproc,))
    gevent.sleep()

pymssql.set_wait_callback(wait_callback)

do_test()
