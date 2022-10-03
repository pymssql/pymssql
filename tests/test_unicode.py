# -*- coding: utf-8 -*-
"""
Test unicode usage in queries.
"""

import unittest

import pytest

from .helpers import pymssqlconn

@pytest.mark.mssql_server_required
class TestUnicode(unittest.TestCase):

    def setUp(self):
        self.conn = pymssqlconn()

    def test_unicode(self):
        # This test is for http://code.google.com/p/pymssql/issues/detail?id=60
        # Thanks to tonal.promsoft for reporting the issue and submitting a
        # patch.

        cursor = self.conn.cursor()
        cursor.execute(
            'select %s, %s',
            ('Здравствуй',
             'Мир'))  # Russian strings

        a, b = cursor.fetchone()

        self.assertEqual(a, 'Здравствуй')
        self.assertEqual(b, 'Мир')
