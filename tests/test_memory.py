# -*- coding: utf-8 -*-

import gc
import sys
import psutil
import pymssql
import pytest


@pytest.mark.xfail(sys.platform == "win32", reason="Memory test is not stable on Windows")
def test_memory_leak_on_unsuccessful_connect():

    p = psutil.Process()
    m0 = p.memory_full_info()
    for i in range(10):
        gc.collect()
        try:
            pymssql.connect(server="www.google.com", port=81, user='username',
                            password='password', login_timeout=1)
        except:
            pass
        gc.collect()
        m1 = p.memory_full_info()
        duss = m1.uss - m0.uss
        print(i, "uss=", m1.uss, "duss:", duss)
        if i > 5:
            assert duss == 0
        m0 = m1


if __name__ == '__main__':

    test_memory_leak_on_unsuccessful_connect()
