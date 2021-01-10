# -*- coding: utf-8 -*-
"""
Run SQLAlchemy tests with pymssql connection.
"""

import configparser
import os
import sys
import tarfile
import urllib

SQLALCHEMY_VERSION     = "1.2.11"
SQLALCHEMY_DIR         = "SQLAlchemy-%s" % SQLALCHEMY_VERSION
SQLALCHEMY_TAR_GZ      = "%s.tar.gz" % SQLALCHEMY_DIR
SQLALCHEMY_TAR_GZ_URL = "https://pypi.python.org/packages/source/S/SQLAlchemy/%s" % SQLALCHEMY_TAR_GZ


def download_sqlalchemy_tarball():
    sys.stdout.write('Downloading %s... ' % SQLALCHEMY_TAR_GZ_URL)
    sys.stdout.flush()
    urllib.urlretrieve(SQLALCHEMY_TAR_GZ_URL, SQLALCHEMY_TAR_GZ)
    sys.stdout.write('DONE\n')

def extract_sqlalchemy_tarball():
    tarball = tarfile.open(SQLALCHEMY_TAR_GZ, 'r:gz')
    sys.stdout.write('Extracting %s... ' % SQLALCHEMY_TAR_GZ)
    sys.stdout.flush()
    tarball.extractall('.')
    sys.stdout.write('DONE\n')

def run_sqlalchemy_tests():
    dburi = get_dburi()

    if dburi:
        sys.argv.append('--dburi=%s' % dburi)

    os.chdir('SQLAlchemy-%s' % SQLALCHEMY_VERSION)
    sys.path.append('.')
    sys.stdout.write('Running SQLAlchemy tests...\n\n')
    sys.stdout.flush()

    import sqla_nose

def get_dburi():
    config = configparser.SafeConfigParser()

    config.read(os.path.join(os.path.dirname(__file__), 'tests.cfg'))

    username = config.get('DEFAULT', 'username')
    password = config.get('DEFAULT', 'password')
    server = config.get('DEFAULT', 'server')
    port = config.get('DEFAULT', 'port')
    database = config.get('DEFAULT', 'database')

    return 'mssql+pymssql://%(username)s:%(password)s@%(server)s:%(port)s/%(database)s' % dict(
        username=username,
        password=password,
        server=server,
        port=port,
        database=database)


if not os.path.exists(SQLALCHEMY_TAR_GZ):
    download_sqlalchemy_tarball()

if not os.path.exists(SQLALCHEMY_DIR):
    extract_sqlalchemy_tarball()

run_sqlalchemy_tests()
