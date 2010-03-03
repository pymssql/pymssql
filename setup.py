#!/usr/bin/env python

import os
import sys
from setuptools import setup, Extension
from Cython.Distutils import build_ext

_extra_compile_args = [
    '-DMSDBLIB'
]

if sys.platform == 'win32':
    freetds_dir = os.path.join(os.path.dirname(__file__), 'win32',
        'freetds')
    include_dirs = [os.path.join(freetds_dir, 'include')]
    library_dirs = [os.path.join(freetds_dir, 'lib')]
    libraries = [
        'msvcrt',
        'kernel32',
        'user32',
        'gdi32',
        'winspool',
        'ws2_32',
        'comdlg32',
        'advapi32',
        'shell32',
        'ole32',
        'oleaut32',
        'uuid',
        'odbc32',
        'odbccp32',
        'libTDS',
        'dblib'
    ]

else:
    include_dirs = [
        '/usr/local/include', '/usr/local/include/freetds',  # first local install
        '/usr/include', '/usr/include/freetds',   # some generic Linux paths
        '/usr/include/freetds_mssql',             # some versions of Mandriva 
        '/usr/local/freetds/include',             # FreeBSD
        '/usr/pkg/freetds/include'	              # NetBSD
    ]
    library_dirs = [
        '/usr/local/lib', '/usr/local/lib/freetds',
        '/usr/lib64',
        '/usr/lib', '/usr/lib/freetds',
        '/usr/lib/freetds_mssql', 
        '/usr/local/freetds/lib',
        '/usr/pkg/freetds/lib'
    ]
    libraries = [ "sybdb" ]   # on Mandriva you may have to change it to sybdb_mssql

if sys.platform == 'darwin':
    fink = '/sw/'
    include_dirs.insert(0, fink + 'include')
    library_dirs.insert(0, fink + 'lib')

setup(
    name  = 'pymssql',
    version = '1.9.903',
    description = 'A simple database interface to MS-SQL for Python.',
    long_description = 'A simple database interface to MS-SQL for Python.',
    author = 'Damien Churchill',
    author_email = 'damoxc@gmail.com',
    license = 'LGPL',
    url = 'http://pymssql.sourceforge.net',
    cmdclass = {'build_ext': build_ext},
    ext_modules = [Extension('_mssql', ['_mssql.pyx'],
                             extra_compile_args = _extra_compile_args,
                             include_dirs = include_dirs,
                             library_dirs = library_dirs,
                             libraries = libraries),
                   Extension('pymssql', ['pymssql.pyx'],
                             extra_compile_args = _extra_compile_args,
                             include_dirs = include_dirs,
                             library_dirs = library_dirs,
                             libraries = libraries)]
)
