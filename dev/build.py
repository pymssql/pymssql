# -*- coding: utf-8 -*-
"""
Download and build FreeTDS library and build pymssql.
"""

import argparse
from distutils.util import get_platform
import multiprocessing
import os
from pathlib import Path
import platform
import shutil
from subprocess import check_call, check_output, STDOUT
import sys
import tarfile


def run(cmd, cwd=None, env=None, shell=True):

    check_call(str(cmd), cwd=str(cwd) if cwd else cwd, env=env, shell=shell, stderr=STDOUT)


def download(args):

    args.ws_dir.mkdir(parents=True, exist_ok=True)
    if args.freetds_version.lower() == 'latest':
        args.freetds_version ='patched'
    arcname = f"freetds-{args.freetds_version}.tar.gz"
    url = f"{args.freetds_url.strip('/')}/{arcname}"
    freetds_dest = args.ws_dir / arcname
    if freetds_dest.exists() and not args.force_download:
        print(f"{freetds_dest} already exists")
    else:
        print(f"downloading {url} to {freetds_dest}")
        run(f"curl -sSf --retry 10 --max-time 10  {url} -o {freetds_dest}")

    if platform.system() == 'Windows':
        url = f"{args.iconv_url.strip('/')}/v{args.iconv_version}"
        iconv_dest = args.ws_dir / "win-iconv.zip"
        if iconv_dest.exists() and not args.force_download:
            print(f"{iconv_dest} already exists")
        else:
            run(f"curl -sSf {url} -o {iconv_dest}")
    else:
        iconv_dest = None

    print("downloading DONE")
    return freetds_dest, iconv_dest


def build(args, freetds_archive):

    tar = tarfile.open(freetds_archive)
    topdir = tar.next().name
    srcdir = args.ws_dir / f"{topdir}"
    if srcdir.exists():
        shutil.rmtree(srcdir)
    tar.extractall(args.ws_dir)
    tar.close()
    if args.prefix is None:
        args.prefix = args.ws_dir / f"{topdir}-bin"

    blddir = args.ws_dir / f"{topdir}-build"
    if blddir.exists():
        shutil.rmtree(blddir)
    blddir.mkdir(parents=True)

    configure = srcdir / "configure"
    configure = [ f'"{configure}"',
                  f"--prefix={args.prefix}",
                  "--enable-msdblib",
                  f"--with-tdsver={args.with_tdsver}",
                  #"--disable-apps",
                  "--disable-server",
                  "--disable-pool",
                  "--disable-odbc",
                  f"--with-openssl={args.with_openssl}",
                  "--with-gnutls=no",
                  ]
    if args.enable_krb5:
        configure.append("--enable-krb5")
    if args.static_freetds:
        configure.extend(["--enable-static", "--disable-shared"])
    else:
        configure.extend(["--enable-shared", "--disable-static"])
    cmd = ' '.join(configure)
    env = os.environ.copy()
    env.update(CFLAGS="-fPIC")
    run(cmd, cwd=blddir, env=env)
    make = f"make -j {multiprocessing.cpu_count()}"
    run(make, cwd=blddir, env=env)
    make = "make install"
    run(make, cwd=blddir, env=env)


def find_vcvarsall_env():

    from distutils import _msvccompiler as _msvcc

    plat_name = get_platform()
    plat_spec = _msvcc.PLAT_TO_VCVARS[plat_name]
    vcvarsall, _ = _msvcc._find_vcvarsall(plat_spec)
    cmd = f'(call "{vcvarsall}" {plat_spec}>nul)&&"{sys.executable}" -c "import os;print(repr(os.environ))"'
    env = check_output(cmd, shell=True)
    env = eval(env.decode('ascii').strip('environ'))
    return env


def build_windows(args, freetds_archive, iconv_archive):

    from zipfile import ZipFile
    wiconv = args.ws_dir / "win-iconv"
    if wiconv.exists():
        shutil.rmtree(wiconv)
    wiconv.mkdir(parents=True)
    print(f"extracting {iconv_archive.name} -> {wiconv}")
    with ZipFile(iconv_archive) as zipf:
        for m in zipf.namelist():
            fn = m.split('/', 1)[1]
            if fn:
                (wiconv / fn).write_bytes(zipf.read(m))

    env = find_vcvarsall_env()

    cmd = f'"{args.cmake}" -G "NMake Makefiles" ' \
            '-DCMAKE_BUILD_TYPE=Release -DBUILD_STATIC=on -DBUILD_SHARED=off ' \
            '-DBUILD_EXECUTABLE=off -DBUILD_TEST=off ' \
            '.'
    print(f"running cmake in {wiconv}")
    run(cmd, cwd=wiconv, env=env)
    print(f"running nmake in {wiconv}")
    run("nmake", cwd=wiconv, env=env)

    tar = tarfile.open(freetds_archive)
    topdir = tar.next().name
    srcdir = args.ws_dir / f"{topdir}"
    if srcdir.exists():
        shutil.rmtree(srcdir)
    tar.extractall(args.ws_dir)
    tar.close()
    if args.prefix is None:
        args.prefix = args.ws_dir / f"{topdir}-bin"

    blddir = args.ws_dir / f"{topdir}-build"
    if blddir.exists():
        shutil.rmtree(blddir)
    blddir.mkdir(parents=True)

    os.makedirs(blddir / "lib", exist_ok=True)
    shutil.copy(wiconv / "iconv.h", blddir)
    shutil.copy(wiconv / "iconv.lib", blddir / "lib")

    krb5 = "ON" if args.enable_krb5 else "OFF"
    cmd = f'"{args.cmake}" -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release " \
            "-DWITH_OPENSSL=ON -DENABLE_KRB5={krb5} -DCMAKE_INSTALL_PREFIX="{args.prefix}" "{srcdir}"'
    env["PATH"] += f";{args.msys}"
    run(cmd, cwd=blddir, env=env)

    run("nmake install", cwd=blddir, env=env)


def parse_args(argv):

    parser = argparse.ArgumentParser(description=(__doc__))
    a = parser.add_argument

    a('-f', '--force-download', action='store_true',
            help="force archive download")
    a('-u', '--freetds-url', default="http://ftp.freetds.org/pub/freetds/stable",
            help="URL to download FreeTDS archive")
    a('-v', '--freetds-version', default='latest',
            help="FreeTDS version to build")
    if platform.system() != 'Windows':
        a('-t', '--with-tdsver', choices=['5.0', '7.1', '7.2', '7.3', '7.4', 'auto'], default='auto',
                help="TDS protocol version")
        a('-o', '--with-openssl', choices=['yes', 'no'], default='yes',
                help="Build FreeTDS with or without OpenSSL support, default is 'yes'")
        a('-S', '--static-freetds', action='store_true',
                help="build FreeTDS staticly")
    a('-k', '--enable-krb5', dest="enable_krb5", action='store_true',
            help="enable krb5 support")

    base = Path('~/freetds').expanduser()
    a('-w', '--ws-dir', default=base, type=Path,
            help="workspace directory for building FreeTDS")
    a('-p', '--prefix', default=None, type=lambda x: Path(x) if x else None,
            help="prefix for installing FreeTDS, default is WS_DIR/prefix")
    a('-d', '--dist-dir', default=Path('./dist'), type=Path,
            help="where to put pymssql wheel, default is './dist'")
    a('-s', '--sdist', action='store_true',
            help="build sdist archive")

    if platform.system() == 'Windows':
        a('-U', '--iconv-url', default="https://codeload.github.com/win-iconv/win-iconv/zip",
                help="URL to download win-iconv.zip archive for build on Windows")
        a('-V', '--iconv-version', default='0.0.8',
                help="FreeTDS version to build")
        a('-m', '--msys', type=Path, default=Path("c:/tools/msys64/usr/bin"),
                help="Msys binaries installation directory")
        a('--cmake', type=Path, default=Path("C:/Program Files/CMake/bin/cmake.exe"),
                help="cmake executable for building FreeTDS")

    args = parser.parse_args(argv)
    return args


def main(argv):

    args = parse_args(argv)
    args.ws_dir = args.ws_dir.absolute()
    if args.prefix is not None:
        args.prefix = args.prefix.absolute()

    freetds_archive, iconv_archive = download(args)

    if platform.system() == 'Windows':
        os.environ["PATH"] += f";{args.msys}"
        build_windows(args, freetds_archive, iconv_archive)
    else:
        build(args, freetds_archive)

    args.dist_dir = args.dist_dir.absolute()
    env = os.environ.copy()
    env.update(PYMSSQL_FREETDS=f"{args.prefix}")
    run(f"{sys.executable} -m pip wheel . -w {args.dist_dir}", shell=True, env=env)
    if args.sdist:
        fmt = 'zip' if platform.system() == 'Windows' else 'gztar'
        run(f"{sys.executable} setup.py sdist --formats={fmt} -d {args.dist_dir}", shell=True, env=env)


if __name__ == '__main__':

    try:
        main(sys.argv[1:])
    except Exception as exc:
        print(f"Build failed: {exc}")
        sys.exit(1)

