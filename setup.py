# -*- coding: utf-8 -*-
#!/usr/bin/env python
#
# setup.py
#
# Copyright (C) 2009 Damien Churchill <damoxc@gmail.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301  USA
#

import os
from os.path import exists, join, splitext
from pathlib import Path
import platform
import struct
import sys

from setuptools import setup, Extension
from setuptools.command.test import test as TestCommand

from distutils import log
from distutils.cmd import Command
from distutils.command.clean import clean as _clean

have_c_files = exists('pymssql/_mssql.c') and exists('pymssql/_pymssql.c')
if have_c_files:
    from distutils.command.build_ext import build_ext as _build_ext
else:
    # Force `setup_requires` stuff like Cython to be installed before proceeding
    from setuptools.dist import Distribution
    Distribution(dict(setup_requires='Cython>=0.29.21'))
    from Cython.Distutils import build_ext as _build_ext

def check_env(env_name, default):
    val = os.getenv(env_name, default)
    if val.upper() in ('1', 'YES', 'TRUE'):
       return True
    elif val.upper() in ('0', 'NO', 'FALSE'):
       return False
    else:
       raise Exception(f"Unsupported environment value {env_name}={val}")

LINK_FREETDS_STATICALLY = check_env('LINK_FREETDS_STATICALLY', 'YES')
LINK_OPENSSL = check_env('LINK_OPENSSL', 'YES')

# 32 bit or 64 bit system?
BITNESS = struct.calcsize("P") * 8
WINDOWS = platform.system() == 'Windows'

include_dirs = []
library_dirs = []
libraries = ['sybdb']

prefix = None
if os.getenv('PYMSSQL_FREETDS'):
    prefix = os.path.abspath(os.getenv('PYMSSQL_FREETDS').strip())
elif exists("/usr/local/includes/sqlfront.h"):
    prefix = "/usr/local"
elif exists("/usr/local/opt/freetds/includes/sqlfront.h"): # brew macOS on Intel
    prefix = "/usr/local/opt/freetds"
elif exists("/opt/homebrew/opt/freetds/includes/sqlfront.h"): # brew macOS on Apple Silicon/ARM
    prefix = "/opt/homebrew/opt/freetds"
elif exists("/opt/local/includes/sqlfront.h"): # MacPorts
    prefix = "/opt/local"
elif exists("/sw/includes/sqlfront.h"): # Fink
    prefix = "/sw"

if prefix:
    print(f"prefix='{prefix}'")
    include_dirs = [ join(prefix, "include") ]
    if BITNESS == 64 and exists(join(prefix, "lib64")):
        library_dirs = [ join(prefix, "lib64") ]
    else:
        library_dirs = [ join(prefix, "lib") ]

if os.getenv('PYMSSQL_FREETDS_INCLUDEDIR'):
    include_dirs = [ os.getenv('PYMSSQL_FREETDS_INCLUDEDIR') ]

if os.getenv('PYMSSQL_FREETDS_LIBDIR'):
    library_dirs = [ os.getenv('PYMSSQL_FREETDS_LIBDIR') ]

print("setup.py: platform.system() =>", platform.system())
print("setup.py: platform.architecture() =>", platform.architecture())
if not WINDOWS:
    print("setup.py: platform.libc_ver() =>", platform.libc_ver())
print("setup.py: include_dirs =>", include_dirs)
print("setup.py: library_dirs =>", library_dirs)

if not WINDOWS:
    # check for clock_gettime, link with librt for glibc<2.17
    from dev import ccompiler
    compiler = ccompiler.new_compiler()
    if not compiler.has_function('clock_gettime(0,NULL)', includes=['time.h']):
        if compiler.has_function('clock_gettime(0,NULL)', includes=['time.h'], libraries=['rt']):
            libraries.append('rt')
        else:
            print("setup.py: could not locate 'clock_gettime' function required by FreeTDS.")
            sys.exit(1)


class build_ext(_build_ext):
    """
    Subclass the Cython build_ext command so it:
    * Can handle different C compilers on Windows
    * Links in the libraries we collected
    """

    def build_extensions(self):
        global library_dirs, include_dirs, libraries

        if WINDOWS:
            # Detect the compiler so we can specify the correct command line switches
            # and libraries
            from distutils.cygwinccompiler import Mingw32CCompiler
            extra_cc_args = []
            if isinstance(self.compiler, Mingw32CCompiler):
                # Compiler is Mingw32
                extra_cc_args = [
                    '-Wl,-allow-multiple-definition',
                    '-Wl,-subsystem,windows-mthreads',
                    '-mwindows',
                    '-Wl,--strip-all'
                ]
                libraries = [
                    'libiconv', 'iconv',
                    'sybdb',
                    'ws2_32', 'wsock32', 'kernel32',
                ]
            else:
                # Assume compiler is Visual Studio
                if LINK_FREETDS_STATICALLY:
                    libraries = [
                        'replacements',
                        'db-lib', 'tds', 'tdsutils',
                        'ws2_32', 'wsock32', 'kernel32', 'shell32',
                    ]
                    if LINK_OPENSSL:
                        libraries.extend([
                            'libssl_static', 'libcrypto_static',
                            'crypt32', 'advapi32', 'gdi32', 'user32',
                        ])
                else:
                    libraries = [
                        'ct', 'sybdb',
                        'ws2_32', 'wsock32', 'kernel32', 'shell32',
                    ]
                    if LINK_OPENSSL:
                        libraries.extend(['libssl', 'libcrypto'])

            for e in self.extensions:
                e.extra_compile_args.extend(extra_cc_args)
                e.libraries.extend(libraries)
                if LINK_OPENSSL:
                    if BITNESS == 32:
                        e.library_dirs.append("c:/Program Files (x86)/OpenSSL-Win32/lib")
                    else:
                        e.library_dirs.append("c:/Program Files/OpenSSL-Win64/lib")

        else:
            if LINK_OPENSSL and LINK_FREETDS_STATICALLY:
                libraries.extend([ 'ssl', 'crypto' ])

            for e in self.extensions:
                e.libraries.extend(libraries)

        _build_ext.build_extensions(self)


class clean(_clean):
    """
    Subclass clean so it removes all the Cython generated files.
    """

    def run(self):
        _clean.run(self)
        for ext in self.distribution.ext_modules:
            cy_sources = [splitext(s)[0] for s in ext.sources]
            for cy_source in cy_sources:
                # .so/.pyd files are created in place when using 'develop'
                for ext in ('.c', '.so', '.pyd'):
                    generated = cy_source + ext
                    if exists(generated):
                        log.info('removing %s', generated)
                        os.remove(generated)


class release(Command):
    """
    Setuptools command to run all the required commands to perform
    a release. This acts differently depending on the platform it
    is being run on.
    """

    description = "Run all the commands required for a release."

    user_options = []

    def initialize_options(self):
        pass

    def finalize_options(self):
        pass

    def run(self):
        if WINDOWS:
            self.release_windows()
        else:
            self.release_unix()

    def release_windows(self):
        # generate windows source distributions
        sdist = self.distribution.get_command_obj('sdist')
        sdist.formats = 'zip'
        sdist.ensure_finalized()
        sdist.run()

        # generate a windows egg
        self.run_command('bdist_egg')

        # generate windows installers
        bdist = self.reinitialize_command('bdist')
        bdist.formats = 'zip,wininst'
        bdist.ensure_finalized()
        bdist.run()

    def release_unix(self):
        # generate linux source distributions
        sdist = self.distribution.get_command_obj('sdist')
        sdist.formats = 'gztar,bztar'
        sdist.ensure_finalized()
        sdist.run()

def ext_modules():
    if have_c_files:
        source_extension = 'c'
    else:
        source_extension = 'pyx'

    ext_modules = [
        Extension('pymssql._mssql', [join('src', 'pymssql', '_mssql.%s' % source_extension)],
            extra_compile_args = [ '-DMSDBLIB' ],
            include_dirs = include_dirs,
            library_dirs = library_dirs,
        ),
        Extension('pymssql._pymssql', [join('src', 'pymssql', '_pymssql.%s' % source_extension)],
            extra_compile_args = [ '-DMSDBLIB' ],
            include_dirs = include_dirs,
            library_dirs = library_dirs,
        ),
    ]
    for e in ext_modules:
        e.cython_directives = {'language_level': sys.version_info[0]}
    return ext_modules


def mk_long_description():

    readme = (Path('__file__').parent / 'README.rst').read_text()
    chlog = Path('__file__').parent / 'ChangeLog.rst'
    lines = []
    with chlog.open('r') as f:
        count = 0
        l = f.readline()
        while l:
            if l.startswith('Version 2'):
                count += 1
            if count > 1:
                break
            lines.append(l)
            l = f.readline()
    return readme + "\n\n" + ''.join(lines).strip()


setup(
    name  = 'pymssql',
    use_scm_version = {
        "write_to": "src/pymssql/version.h",
        "write_to_template": '#define PYMSSQL_VERSION "{version}"',
        "local_scheme": "no-local-version",
    },
    description = 'DB-API interface to Microsoft SQL Server for Python. (new Cython-based version)',
    long_description = mk_long_description(),
    author = 'Damien Churchill',
    author_email = 'damoxc@gmail.com',
    maintainer = 'pymssql development team',
    maintainer_email = 'pymssql@googlegroups.com',
    license = 'LGPL',
    platforms = 'any',
    keywords = ['mssql', 'SQL Server', 'database', 'DB-API'],
    project_urls={
        "Documentation": "http://pymssql.readthedocs.io",
        "Source": "https://github.com/pymssql/pymssql",
        "Changelog": "https://github.com/pymssql/pymssql/blob/master/ChangeLog.rst",
    },
    cmdclass = {
        'build_ext': build_ext,
        'clean': clean,
        'release': release,
    },
    classifiers=[
      "Development Status :: 5 - Production/Stable",
      "Intended Audience :: Developers",
      "License :: OSI Approved :: GNU Library or Lesser General Public License (LGPL)",
      "Programming Language :: Python",
      "Programming Language :: Python :: 3.6",
      "Programming Language :: Python :: 3.7",
      "Programming Language :: Python :: 3.8",
      "Programming Language :: Python :: 3.9",
      "Programming Language :: Python :: Implementation :: CPython",
      "Topic :: Database",
      "Topic :: Database :: Database Engines/Servers",
      "Topic :: Software Development :: Libraries :: Python Modules",
      "Operating System :: Microsoft :: Windows",
      "Operating System :: POSIX",
      "Operating System :: Unix",
    ],
    zip_safe = False,
    setup_requires=['setuptools_scm', 'Cython'],
    tests_require=['psutil', 'pytest', 'pytest-timeout'],
    ext_modules = ext_modules(),
    packages = [ 'pymssql'],
    package_dir = {'': 'src'},
)
