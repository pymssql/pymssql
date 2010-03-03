from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

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

setup(
    cmdclass = {'build_ext': build_ext},
    ext_modules = [Extension('_mssql', ['_mssql.pyx'],
                             include_dirs = include_dirs,
                             library_dirs = library_dirs,
                             libraries = libraries)]
)
