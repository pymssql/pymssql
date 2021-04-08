# -*- coding: utf-8 -*-

import time
import pytest
import pymssql


@pytest.mark.timeout(120)
@pytest.mark.xfail(strict=False)
@pytest.mark.parametrize('to', [2])
def test_remote_connect_timeout(to):

    t = time.time()
    try:
        pymssql.connect(server="www.google.com", port=81, user='username', password='password',
                            login_timeout=to)
    except pymssql.OperationalError:
        pass
    t = time.time() - t
    print('remote: requested {} -> {} actual timeout'.format(to, t))
    assert t == pytest.approx(to, 5), "{} != {}".format(t, to)
