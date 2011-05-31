import decimal
import ConfigParser
import os

from nose.plugins import Plugin

import tests.helpers as th
from .helpers import cfgpath, clear_db

_parser = ConfigParser.ConfigParser({
    'server': 'localhost',
    'username': 'sa',
    'password': '',
    'database': 'tempdb',
    'port': '1433',
    'ipaddress': '127.0.0.1',
    'instance': '',
})

class ConfigPlugin(Plugin):
    enabled = True
    config_section = ''

    def options(self, parser, env=os.environ):
        """Add command-line options for this plugin"""
        env_opt = 'NOSE_WITH_%s' % self.name.upper()

        parser.add_option("--pymssql-section",
                          type="string",
                          default=env.get('PYMSSQL_TEST_CONFIG', 'DEFAULT'),
                          help="The name of the section to use from tests.cfg"
                        )

        Plugin.options(self, parser, env=env)

    def configure(self, options, config):
        """Configure the plugin"""

        _parser.read(cfgpath)
        section = options.pymssql_section

        if not _parser.has_section(section) and section != 'DEFAULT':
            raise ValueError('the tests.cfg file does not have section: %s' % section)

        th.config.server = _parser.get(section, 'server')
        th.config.user= _parser.get(section, 'username')
        th.config.password = _parser.get(section, 'password')
        th.config.database = _parser.get(section, 'database')
        th.config.port = _parser.get(section, 'port')
        th.config.ipaddress = _parser.get(section, 'ipaddress')
        th.config.instance = _parser.get(section, 'instance')
        th.config.orig_decimal_prec = decimal.getcontext().prec

    def begin(self):
        clear_db()
