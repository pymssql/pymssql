#!/bin/sh
#
# This script builds FreeTDS using MinGW to produce usable binaries for
# building pymssql on Windows.
#

FREETDS="ftp://ftp.ibiblio.org/pub/Linux/ALPHA/freetds"
CURRENT="$FREETDS/current/freetds-current.tgz"
STABLE="$FREETDS/stable/freetds-stable.tgz"
TEMPDIR=`mktemp -d`
OLD_DIR=`pwd`

# Retrieve the sources and extract them into a temporary directory
wget $CURRENT -O $TEMPDIR/freetds-current.tgz
tar zxf $TEMPDIR/freetds-current.tgz -C $TEMPDIR
rm $TEMPDIR/freetds-current.tgz
cd $TEMPDIR/freetds-*

# Setup the build environment
mkdir -p build/win32
cd build/win32

# Configure
../../configure --prefix=/usr/i586-mingw32msvc --host=i586-mingw32msvc \
	--disable-rpath               \
	--disable-dependency-tracking \
	--disable-shared              \
	--enable-static               \
	--enable-iconv                \
	--with-tdsver=7.1             \
	--enable-sspi

# Build
make

# Install
mkdir ../pkg
make install DESTDIR=`readlink -e ../pkg`

# Package
cd ../pkg/usr/i586-mingw32msvc
mkdir freetds
mv bin etc include lib freetds
zip -r freetds.zip freetds
mv freetds.zip $OLD_DIR/

# Cleanup
rm -rf $TEMPDIR
