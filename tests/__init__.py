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
    mssqlconn.execute_non_query("""
    sp_getapplock
        @Resource = 'pymssql_tests',
        @LockMode = 'Exclusive',
        @LockOwner = 'Session';
    """)
    t2 = time.time()
    print("*** %d: Got app lock for pymssql tests - it took %d seconds" % (t2, t2 - t1))

def release_app_lock(mssqlconn):
    t1 = time.time()
    print("*** %d: Releasing app lock for pymssql tests" % (t1,))
    mssqlconn.execute_non_query("""
    sp_releaseapplock
        @Resource = 'pymssql_tests',
        @LockOwner = 'Session';
    """)
