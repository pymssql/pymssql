import unittest

from .helpers import pymssqlconn

class TestUnicode(unittest.TestCase):

    def setUp(self):
        self.conn = pymssqlconn()

    def test_unicode(self):
        # This test is for http://code.google.com/p/pymssql/issues/detail?id=60
        # Thanks to tonal.promsoft for reporting the issue and submitting a
        # patch.

        cursor = self.conn.cursor()
        cursor.execute(
            u'select %s, %s',
            (u'\u0417\u0434\u0440\u0430\u0432\u0441\u0442\u0432\u0443\u0439',
             u'\u041c\u0438\u0440'))  # Russian strings

        a, b = cursor.fetchone()

        self.assertEquals(a, u'\u0417\u0434\u0440\u0430\u0432\u0441\u0442\u0432\u0443\u0439')
        self.assertEquals(b, u'\u041c\u0438\u0440')
