import pymssql as pym

class TestDBBAPI2(object):
    def test_version(object):
        assert pym.__version__
        print pym.__version__
