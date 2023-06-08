# -*- coding: utf-8 -*-
"""
Test charset usage in queries.
"""

import unittest

import pytest

from .helpers import pymssqlconn


@pytest.mark.mssql_server_required
class TestCharset(unittest.TestCase):

    def setUp(self):
        self.conn = pymssqlconn(charset='WINDOWS-1251')

    def test_charset(self):
        cursor = self.conn.cursor()

        try:
            cursor.execute(
                'select %s, %s',
                ('Здравствуй', 'Мир')  # Russian strings
            )
        except UnicodeDecodeError as e:
            self.fail("cursor.execute() raised %s unexpectedly: %s" % (e.__class__.__name__, e))

        a, b = cursor.fetchone()

        self.assertEqual(a, 'Здравствуй')
        self.assertEqual(b, 'Мир')
