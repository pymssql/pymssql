# -*- coding: utf-8 -*-

import time
import pytest
import pymssql


def test_connect_timeout():

    for to in range(2,20,2):
        t = time.time()
        try:
            pymssql.connect(server="www.google.com", port=81, user='username', password='password',
                                login_timeout=to)
        except pymssql.OperationalError:
            pass
        t = time.time() - t
        #print(to, t)
        assert t == pytest.approx(to, 1)
