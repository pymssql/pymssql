# -*- coding: utf-8 -*-
"""
Pytest configuration.
"""

from os.path import dirname
import sys

# When using tox, it can accidentally pick up a {pymssql,_mssql}.so file in the
# root directory and then get ImportError because of incompatibility in Python
# versions. By removing the root directory from the sys.path, it forces tox to
# import the library from correct place in the tox virtualenv.
if '.tox' in sys.executable:
    root_dir = dirname(dirname(__file__))
    sys.path.remove(root_dir)

import decimal
import os
from configparser import ConfigParser

import pytest

import tests.helpers as th
from .helpers import cfgpath, clear_db, get_app_lock, release_app_lock

_parser = ConfigParser({
    'server': 'localhost',
    'username': 'sa',
    'password': 'sqlServerPassw0rd',
    'database': 'tempdb',
    'port': '1433',
    'ipaddress': '127.0.0.1',
    'instance': '',
})

optional_markers = {
    "slow": {"help": "Skip long tests",
             "marker-descr": "Mark tests that run longer than ~3 seconds",
             "skip-reason": "Test runs too long."},
    "mssql_server_required": {"help": "Skip tests that require MSSQL server",
             "marker-descr": "Mark tests that require MSSQL server",
             "skip-reason": "Test only runs if MSSQL server is available."},
    # add further markers here
}

def pytest_addoption(parser):
    parser.addoption(
        "--pymssql-section",
        type=str,
        default=os.environ.get('PYMSSQL_TEST_CONFIG', 'DEFAULT'),
        help="The name of the section to use from tests.cfg"
    )
    for marker, info in optional_markers.items():
        parser.addoption("--skip-{}".format(marker.replace('_','-')), action="store_true",
                         default=False, help=info['help'])

def pytest_configure(config):
    _parser.read(cfgpath)
    section = config.getoption('--pymssql-section')

    if not _parser.has_section(section) and section != 'DEFAULT':
        raise ValueError('the tests.cfg file does not have section: %s' % section)

    th.config.server = os.getenv('PYMSSQL_TEST_SERVER') or _parser.get(section, 'server')
    th.config.user = os.getenv('PYMSSQL_TEST_USERNAME') or _parser.get(section, 'username')
    th.config.password = os.getenv('PYMSSQL_TEST_PASSWORD') or _parser.get(section, 'password')
    th.config.database = os.getenv('PYMSSQL_TEST_DATABASE') or _parser.get(section, 'database')
    th.config.port = os.getenv('PYMSSQL_TEST_PORT') or _parser.get(section, 'port')
    th.config.ipaddress = os.getenv('PYMSSQL_TEST_IPADDRESS') or _parser.get(section, 'ipaddress')
    th.config.instance = os.getenv('PYMSSQL_TEST_INSTANCE') or _parser.get(section, 'instance')
    th.config.orig_decimal_prec = decimal.getcontext().prec

    for marker, info in optional_markers.items():
        config.addinivalue_line("markers",
                                "{}: {}".format(marker, info['marker-descr']))

    if get_app_lock():
        clear_db()

def pytest_unconfigure(config):
    release_app_lock()


def pytest_collection_modifyitems(config, items):

    marker = "mssql_server_required"
    info = optional_markers[marker]
    if th.global_mssqlconn is None or config.getoption("--skip-{}".format(marker.replace('_','-'))):
        skip = pytest.mark.skip(reason=info['skip-reason'])
        for item in items:
            if marker in item.keywords:
                item.add_marker(skip)
    marker = "slow"
    info = optional_markers[marker]
    if th.global_mssqlconn is None or config.getoption("--skip-{}".format(marker)):
        skip = pytest.mark.skip(reason=info['skip-reason'])
        for item in items:
            if marker in item.keywords:
                item.add_marker(skip)
