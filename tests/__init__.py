from .helpers import mssqlconn

MSSQLCONN = None

def setup_package():
    global MSSQLCONN

    MSSQLCONN = mssqlconn()
    get_app_lock(MSSQLCONN)

def teardown_package():
    release_app_lock(MSSQLCONN)

def get_app_lock(mssqlconn):
    print("*** Grabbing app lock for pymssql tests")
    mssqlconn.execute_non_query("""
    sp_getapplock
        @Resource = 'pymssql_tests',
        @LockMode = 'Exclusive',
        @LockOwner = 'Session';
    """)

def release_app_lock(mssqlconn):
    print("*** Releasing app lock for pymssql tests")
    mssqlconn.execute_non_query("""
    sp_releaseapplock
        @Resource = 'pymssql_tests',
        @LockOwner = 'Session';
    """)
