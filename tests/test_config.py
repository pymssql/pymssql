# -*- coding: utf-8 -*-
"""
Test connection config.
"""

from __future__ import with_statement
from os import path, makedirs, environ
import shutil

from pymssql import _mssql

from .helpers import tmpdir, skip_test, mssql_server_required
config_dump_path = path.join(tmpdir, 'freetds-config-dump.txt')

def setup_module():
    if not path.isdir(tmpdir):
        makedirs(tmpdir)

@mssql_server_required
class TestConfig(object):
    def connect(self, **kwargs):
        environ['TDSDUMPCONFIG'] = config_dump_path
        try:
            _mssql.connect(**kwargs)
            assert False
        except _mssql.MSSQLDriverException as e:
            # we get this when the name of the server is not valid
            if 'Connection to the database failed' not in str(e):
                raise
        except _mssql.MSSQLDatabaseException as e:
            # we get this when the name or IP can be obtained but the connection
            # can not be made
            if e.args[0][0] != 20009:
                raise
        with open(config_dump_path, 'r') as fh:
            return fh.read()

    def test_config_values(self):
        config_dump = self.connect(
            server='dontnameyourserverthis',
            user = 'bob',
            database = 'tempdb',
            tds_version='7.1'
            )
        assert 'user_name = bob' in config_dump
        assert 'database = tempdb\n' in config_dump
        # test default port
        assert 'port = 1433' in config_dump
        # not sure why 7.1 version is used instead of 8.0 which is the
        # default
        assert 'major_version = 7' in config_dump
        assert 'minor_version = 1' in config_dump

    def test_tds_protocol_version_42(self):
        config_dump = self.connect(
            server='dontnameyourserverthis',
            tds_version='4.2'
            )
        assert 'major_version = 4' in config_dump
        assert 'minor_version = 2' in config_dump

    def test_tds_protocol_version_70(self):
        config_dump = self.connect(
            server='dontnameyourserverthis',
            tds_version='7.0'
            )
        assert 'major_version = 7' in config_dump
        assert 'minor_version = 0' in config_dump

    def test_tds_protocol_version_71(self):
        config_dump = self.connect(
            server='dontnameyourserverthis',
            tds_version='7.1'
            )
        assert 'major_version = 7' in config_dump
        assert 'minor_version = 1' in config_dump

    def test_tds_protocol_version_80(self):
        # follow-up: turns out 8.0 was erroneous.  MS named the new protocol
        # 7.1 instead of 8.0, so FreeTDS will accept 8.0 but shows as 7.1.
        # got that from the FreeTDS mailling list.  New FreeTDS docs,built from
        # source, have a page that describes the protocol and that page lists
        # versions 7.0, 7.1, and 7.2 among others.

        config_dump = self.connect(
            server='dontnameyourserverthis',
            tds_version='8.0'
            )
        assert 'major_version = 7' in config_dump
        assert 'minor_version = 1' in config_dump

    def test_tds_protocol_version_72(self):
        config_dump = self.connect(
            server='dontnameyourserverthis',
            tds_version='7.2'
            )
        assert 'major_version = 7' in config_dump
        assert 'minor_version = 2' in config_dump

    def test_tds_protocol_version_invalid(self):
        try:
            self.connect(tds_version='1.0')
            assert False
        except _mssql.MSSQLException as e:
            assert 'unrecognized tds version: 1.0' == str(e)

    def test_tds_nonstandard_port_int(self):
        #it should convert it to a string
        config_dump = self.connect(port=1435)
        assert 'port = 1435' in config_dump
