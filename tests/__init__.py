import time

from .helpers import mssqlconn

MSSQLCONN = None

def setup_package():
    global MSSQLCONN

    MSSQLCONN = mssqlconn()
    get_app_lock(MSSQLCONN)

def teardown_package():
    release_app_lock(MSSQLCONN)

def get_app_lock(mssqlconn):
    t1 = time.time()
    print("*** %d: Grabbing app lock for pymssql tests" % (t1,))
    mssqlconn.execute_query("""
    DECLARE @result INTEGER;
    EXEC @result = sp_getapplock
        @Resource = 'pymssql_tests',
        @LockMode = 'Exclusive',
        @LockOwner = 'Session';
    SELECT @result AS result;
    """)
    t2 = time.time()
    for row in mssqlconn:
        print("*** %d: sp_getapplock for 'pymssql_tests' returned %d - it took %d seconds" % (t2, row['result'], t2 - t1))

def release_app_lock(mssqlconn):
    t1 = time.time()
    mssqlconn.execute_query("""
    DECLARE @result INTEGER;
    EXEC @result = sp_releaseapplock
        @Resource = 'pymssql_tests',
        @LockOwner = 'Session';
    SELECT @result AS result;
    """)
    print("*** %d: sp_releaseapplock for 'pymssql_tests' returned" % (t1,))
    for row in mssqlconn:
        print("*** %d: sp_releaseapplock for 'pymssql_tests' returned %d" % (t1, row['result'],))
