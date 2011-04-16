from __future__ import with_statement
from os import path, makedirs, environ
import shutil

from nose.plugins.skip import SkipTest

import _mssql

from .helpers import config
server = config.server
username = config.user
password = config.password
database = config.database
port = config.port
ipaddress = config.ipaddress
instance = config.instance

cdir = path.dirname(__file__)
tmpdir = path.join(cdir, 'tmp')
config_dump_path = path.join(tmpdir, 'freetds-config-dump.txt')
dump_path = path.join(tmpdir, 'freetds-dump.txt')

def setup_module():
    if not path.isdir(tmpdir):
        makedirs(tmpdir)

class TestCons(object):
    def connect(self, **kwargs):
        environ['TDSDUMPCONFIG'] = config_dump_path
        environ['TDSDUMP'] = dump_path
        _mssql.connect(**kwargs)
        with open(config_dump_path, 'rb') as fh:
            return fh.read()

    def test_connection_by_dns_name(self):
        cdump = self.connect(server=server, port=port, user=username, password=password)
        assert 'server_name = %s' % server in cdump
        assert 'server_host_name = %s' % server in cdump
        assert 'user_name = %s' % username in cdump
        assert 'port = %s' % port in cdump

    def test_connection_by_ip(self):
        cdump = self.connect(server=ipaddress, port=port, user=username, password=password)
        assert 'server_name = %s' % ipaddress in cdump
        assert 'server_host_name = %s' % ipaddress in cdump

    def test_port_override_ipaddress(self):
        server_join = '%s:%s' % (ipaddress, port)
        cdump = self.connect(server=server_join, user=username, password=password)
        assert 'server_name = %s' % server_join in cdump
        assert 'server_host_name = %s' % ipaddress in cdump
        assert 'port = %s' % port in cdump

    def test_port_override_name(self):
        server_join = '%s:%s' % (server, port)
        cdump = self.connect(server=server_join, user=username, password=password)
        assert 'server_name = %s' % server_join in cdump
        assert 'server_host_name = %s' % server in cdump
        assert 'port = %s' % port in cdump

    def test_instance(self):
        if not instance:
            raise SkipTest
        server_join = r'%s\%s' % (server, instance)
        cdump = self.connect(server=server_join, user=username, password=password)
        assert 'server_name = %s' % server_join in cdump
        assert 'server_host_name = %s' % server in cdump
        assert 'port = 0' in cdump
