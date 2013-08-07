#!/usr/bin/env python
#
# setup.py
#
# Copyright (C) 2009 Damien Churchill <damoxc@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.    See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.    If not, write to:
#   The Free Software Foundation, Inc.,
#   51 Franklin Street, Fifth Floor
#   Boston, MA    02110-1301, USA.
#

import contextlib
import os
import os.path as osp
import sys
import getpass
import platform

# Hack to prevent stupid TypeError: 'NoneType' object is not callable error on
# exit of python setup.py test in multiprocessing/util.py _exit_function when
# running python setup.py test (see
# http://www.eby-sarna.com/pipermail/peak/2010-May/003357.html)
try:
    import multiprocessing
except ImportError:
    pass

sys.path.append(osp.join(osp.dirname(__file__), '.pyrex'))

try:
    from setuptools import setup, Extension
    from setuptools.command.develop import develop as STDevelopCmd
except ImportError:
    import ez_setup
    ez_setup.use_setuptools()
    from setuptools import setup, Extension
    from setuptools.command.develop import develop as STDevelopCmd

# Work around Setuptools' broken (Cython-unaware) monkeypatching
# to support Pyrex. This monkeypatching makes the Cython step get skipped if
# using setuptools (not distribute) and Pyrex is not installed.
# (from https://github.com/sampsyo/pylastfp/blob/master/setup.py)
# http://code.google.com/p/pymssql/issues/detail?id=14
try:
    import setuptools.dist
except ImportError:
    pass
else:
    Extension.__init__ = setuptools.dist._get_unpatched(setuptools.extension.Extension).__init__

#
# Force `setup_requires` stuff like Cython to be installed before proceeding
#
from setuptools.dist import Distribution
Distribution(dict(setup_requires='Cython>=0.13.1'))

from distutils import log
from distutils.cmd import Command
from distutils.command.clean import clean as _clean
from distutils import ccompiler
from Cython.Distutils import build_ext as _build_ext
import struct

@contextlib.contextmanager
def stdchannel_redirected(stdchannel, dest_filename):
    """
    A context manager to temporarily redirect stdout or stderr

    e.g.:

    with stdchannel_redirected(sys.stderr, os.devnull):
        ...
    """

    try:
        oldstdchannel = os.dup(stdchannel.fileno())
        dest_file = open(dest_filename, 'w')
        os.dup2(dest_file.fileno(), stdchannel.fileno())

        yield
    finally:
        if oldstdchannel is not None:
            os.dup2(oldstdchannel, stdchannel.fileno())
        if dest_file is not None:
            dest_file.close()

def add_dir_if_exists(filtered_dirs, *dirs):
    for d in dirs:
        if osp.exists(d):
            filtered_dirs.append(d)

compiler = ccompiler.new_compiler()

_extra_compile_args = [
    '-DMSDBLIB'
]

ROOT = osp.abspath(osp.dirname(__file__))
WINDOWS = False
SYSTEM = platform.system()

# 32 bit or 64 bit system?
BITNESS = struct.calcsize("P") * 8

if sys.platform == 'win32':
    WINDOWS = True
    include_dirs = []
    library_dirs = []
else:
    include_dirs = []
    library_dirs = []

    FREETDS = None

    if not os.getenv('PYMSSQL_DONT_BUILD_WITH_BUNDLED_FREETDS'):
        if sys.platform == 'darwin':
            FREETDS = osp.join(ROOT, 'freetds', 'darwin_%s' % BITNESS)
        elif SYSTEM == 'Linux':
            FREETDS = osp.join(ROOT, 'freetds', 'nix_%s' % BITNESS)

    if FREETDS and osp.exists(FREETDS):
        print('setup.py: Using bundled FreeTDS in %s' % FREETDS)
        include_dirs.append(osp.join(FREETDS, 'include'))
        library_dirs.append(osp.join(FREETDS, 'lib'))
    else:
        print('setup.py: Not using bundled FreeTDS')

    libraries = ['sybdb']

    with stdchannel_redirected(sys.stderr, os.devnull):
        if compiler.has_function('clock_gettime', libraries=['rt']):
            libraries.append('rt')

if sys.platform == 'darwin':
    fink = '/sw'
    if osp.exists(fink):
        add_dir_if_exists(include_dirs, osp.join(fink, 'include'))
        add_dir_if_exists(library_dirs, osp.join(fink, 'lib'))

    macports = '/opt/local'
    if osp.exists(macports):
        # some mac ports paths
        add_dir_if_exists(
            include_dirs,
            osp.join(macports, 'include'),
            osp.join(macports, 'include/freetds'),
            osp.join(macports, 'freetds/include')
        )
        add_dir_if_exists(
            library_dirs,
            osp.join(macports, 'lib'),
            osp.join(macports, 'lib/freetds'),
            osp.join(macports, 'freetds/lib')
        )

if sys.platform != 'win32':
    # Windows uses a different piece of code to detect these
    print('setup.py: include_dirs = %r' % include_dirs)
    print('setup.py: library_dirs = %r' % library_dirs)

class build_ext(_build_ext):
    """
    Subclass the Cython build_ext command so it extracts freetds.zip if it
    hasn't already been done.
    """

    def build_extensions(self):
        global library_dirs, include_dirs, libraries

        if WINDOWS:
            # Detect the compiler so we can specify the correct command line switches
            # and libraries
            from distutils.cygwinccompiler import Mingw32CCompiler
            extra_cc_args = []
            # Distutils bug: self.compiler can be a string or a CCompiler
            # subclass instance, see http://bugs.python.org/issue6377
            if isinstance(self.compiler, str):
                compiler = self.compiler
            elif isinstance(self.compiler, Mingw32CCompiler):
                compiler = 'mingw32'
                freetds_dir = 'ming'
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
                compiler = 'msvc'
                freetds_dir = 'vs2008'
                libraries = [
                    'db-lib', 'tds',
                    'ws2_32', 'wsock32', 'kernel32', 'shell32',
                ]

            FREETDS = osp.join(ROOT, 'freetds', '{0}_{1}'.format(freetds_dir, BITNESS))
            for e in self.extensions:
                e.extra_compile_args.extend(extra_cc_args)
                e.libraries.extend(libraries)
                e.include_dirs.append(osp.join(FREETDS, 'include'))
                e.library_dirs.append(osp.join(FREETDS, 'lib'))

        else:
            for e in self.extensions:
                e.libraries.extend(libraries)
        _build_ext.build_extensions(self)

class clean(_clean):
    """
    Subclass clean so it removes all the Cython generated C files.
    """

    def run(self):
        _clean.run(self)
        for ext in self.distribution.ext_modules:
            cy_sources = [s for s in ext.sources if s.endswith('.pyx')]
            for cy_source in cy_sources:
                c_source = cy_source[:-3] + 'c'
                if osp.exists(c_source):
                    log.info('removing %s', c_source)
                    os.remove(c_source)
                so_built = cy_source[:-3] + 'so'
                if osp.exists(so_built):
                    log.info('removing %s', so_built)
                    os.remove(so_built)

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
        self.username = None
        self.password = None
        self.store = None

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

        (name, version, fullname) = self.get_info()

        self.upload(fullname + '.zip', '%s %s source zipped' % (name, version))
        self.upload(fullname + '.win32.zip', '%s %s win32 zip installer' % (name, version))
        self.upload(fullname + '.win32-py2.6.exe', '%s %s windows installer' % (name, version))
        self.upload(fullname + '-py2.6-win32.egg', '%s %s windows egg' % (name, version))

    def release_unix(self):
        # generate linux source distributions
        sdist = self.distribution.get_command_obj('sdist')
        sdist.formats = 'gztar,bztar'
        sdist.ensure_finalized()
        sdist.run()

        (name, version, fullname) = self.get_info()
        self.upload(fullname + '.tar.gz', '%s %s source gzipped' % (name, version))
        self.upload(fullname + '.tar.bz2', '%s %s source bzipped' % (name, version))

    def get_info(self):
        """
        Return the project name and version
        """
        return (
            self.distribution.get_name(),
            self.distribution.get_version(),
            self.distribution.get_fullname()
        )

    def upload(self, filename, comment):
        from gc_upload import upload

        if self.username is None:
            username = raw_input('Username: ')
            password = getpass.getpass('Password: ')

            if self.store is None:
                store = raw_input('Store credentials for later use? [Y/n]')
                self.store = store in ('', 'y', 'Y')

            if self.store:
                self.username = username
                self.password = password

        else:
            username = self.username
            password = self.password

        filename = osp.join('dist', filename)
        log.info('uploading %s to googlecode', filename)
        (status, reason, url) = upload(filename, 'pymssql', username, password, comment)
        if not url:
            log.error('upload to googlecode failed: %s', reason)

class DevelopCmd(STDevelopCmd):
    def run(self):
        # add in the nose plugin only when we are using the develop command
        self.distribution.entry_points['nose.plugins'] = ['pymssql_config = tests.nose_plugin:ConfigPlugin']
        STDevelopCmd.run(self)

setup(
    name  = 'pymssql',
    version = '2.0.0b1',
    description = 'A simple database interface to MS-SQL for Python.',
    long_description = 'A simple database interface to MS-SQL for Python.',
    author = 'Damien Churchill',
    author_email = 'damoxc@gmail.com',
    license = 'LGPL',
    url = 'http://pymssql.sourceforge.net',
    cmdclass = {
        'build_ext': build_ext,
        'clean': clean,
        'release': release,
        'develop': DevelopCmd
    },
    data_files = [
        ('', ['_mssql.pyx', 'pymssql.pyx'])
    ],
    zip_safe = False,
    tests_require=['nose', 'unittest2'],
    test_suite='nose.collector',
    setup_requires=["Cython>=0.15.1"],
    ext_modules = [
        Extension('_mssql', ['_mssql.pyx'],
            extra_compile_args = _extra_compile_args,
            include_dirs = include_dirs,
            library_dirs = library_dirs
        ),
        Extension('pymssql', ['pymssql.pyx'],
            extra_compile_args = _extra_compile_args,
            include_dirs = include_dirs,
            library_dirs = library_dirs
        ),
    ],

    # don't remove this, otherwise the customization above in DevelopCmd
    # will break.  You can safely add to it though, if needed.
    entry_points = {}

)
