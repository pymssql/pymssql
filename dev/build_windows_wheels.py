# -*- coding: utf-8 -*-

from distutils.util import get_platform
from distutils.msvccompiler import get_build_version
from subprocess import check_call, check_output, Popen, CalledProcessError
import os
import os.path
import shutil
import sys

from setuptools import msvc



def check_shell(cmd, cwd=None, env=None):

    process = Popen(cmd, cwd=cwd, env=env, stdout=None, shell=True)
    stdout, _ = process.communicate()
    exitcode = process.wait()
    if exitcode != 0:
        raise CalledProcessError(exitcode, cmd)


def find_vcvarsall3():

    from distutils import _msvccompiler as _msvcc

    plat_name = get_platform()
    plat_spec = _msvcc.PLAT_TO_VCVARS[plat_name]
    vcvarsall, _ = _msvcc._find_vcvarsall(plat_spec)
    return vcvarsall, plat_spec


def find_vcvarsall2():

    PLAT_TO_VCVARS = {
        'win32' : 'x86',
        'win-amd64' : 'amd64',
    }
    build_version = get_build_version()
    plat_name = get_platform()
    plat_spec = PLAT_TO_VCVARS[plat_name]
    vcvarsall = msvc.msvc9_find_vcvarsall(build_version)
    return vcvarsall, plat_spec


def find_vcvarsall_env():

    if sys.version_info[0] == 2:
        vcvarsall, arch = find_vcvarsall2()
    else:
        vcvarsall, arch = find_vcvarsall3()

    cmd = '(call "%s" %s>nul)&&python -c "import os;print(repr(os.environ))"' % (
            vcvarsall, arch)
    env = check_output(cmd, shell=True)
    env = eval(env.decode('ascii').strip('environ'))
    return env


def main(args):

    check_call("C:/msys64/usr/bin/curl -sS https://codeload.github.com/win-iconv/win-iconv/zip/v0.0.8 -o win-iconv.zip", shell=True)
    check_call("C:/msys64/usr/bin/unzip -j win-iconv.zip -d win-iconv", shell=True)

    check_call("C:/msys64/usr/bin/curl -sS http://ftp.freetds.org/pub/freetds/stable/freetds-patched.tar.gz -o freetds.tar.gz", shell=True)
    check_call("C:/msys64/usr/bin/gzip -d freetds.tar.gz", shell=True)
    os.mkdir("freetds")
    check_call("C:/msys64/usr/bin/tar -xf freetds.tar -C freetds --strip-components=1", shell=True)

    env = find_vcvarsall_env()

    cmd = 'cmake -G "NMake Makefiles" ' \
            '-DCMAKE_BUILD_TYPE=Release -DBUILD_STATIC=on -DBUILD_SHARED=off ' \
            '-DBUILD_EXECUTABLE=off -DBUILD_TEST=off ' \
            '.'
    check_shell(cmd, cwd="win-iconv", env=env)
    check_shell("nmake", cwd="win-iconv", env=env)

    os.makedirs('freetds/lib')
    shutil.copy("win-iconv/iconv.h", "freetds/")
    shutil.copy("win-iconv/iconv.lib","freetds/lib")

    cmd = 'cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DWITH_OPENSSL=OFF -DCMAKE_INSTALL_PREFIX=. .'
    check_shell(cmd, cwd="freetds", env=env)
    check_shell("nmake install", cwd="freetds", env=env)

    check_call("python -m pip install --upgrade pip", shell=True)
    check_call("python -m pip install setuptools Cython wheel", shell=True)
    check_call("python setup.py sdist", shell=True)
    check_call("python -m pip wheel . -w dist", shell=True)



if __name__ == '__main__':

    main(sys.argv[1:])
