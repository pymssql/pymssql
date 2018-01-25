#!/bin/sh
#
# This script builds latest stable FreeTDS for building pymssql on Linux.
#

FREETDS="ftp://ftp.freetds.org/pub/freetds/"
STABLE="$FREETDS/stable/freetds-patched.tar.gz"
TEMPDIR=`mktemp -d`
OLD_DIR=`pwd`
OLD_CFLAGS=$CFLAGS

# Retrieve the sources and extract them into a temporary directory
wget $STABLE -O $TEMPDIR/freetds.tgz
tar zxf $TEMPDIR/freetds.tgz -C $TEMPDIR
rm $TEMPDIR/freetds.tgz

## Setup the linux 64 build environment
cd $TEMPDIR/freetds-*
mkdir -p build/linux/64
cd build/linux/64

export CFLAGS="-fPIC"

# Configure
../../../configure --enable-msdblib \
        --sysconfdir=/etc/freetds --with-tdsver=7.1 \
        --disable-apps --disable-server --disable-pool --disable-odbc \
        --with-openssl=no --with-gnutls=no --enable-static --disable-shared
# Build
make

# Install
mkdir ../../pkg
make install DESTDIR=`readlink -e ../../pkg`

# Package
cd ../../pkg/usr/local
mkdir -p $OLD_DIR/freetds/nix_64
mv bin etc include lib $OLD_DIR/freetds/nix_64/


# Setup the linux 32 build environment
cd $TEMPDIR/freetds-*
mkdir -p build/linux/32
cd build/linux/32
rm -rf ../../pkg

export CFLAGS="-m32 -fPIC" LDFLAGS="-m32"

# Configure
../../../configure --enable-msdblib \
        --sysconfdir=/etc/freetds --with-tdsver=7.1 \
        --disable-apps --disable-server --disable-pool --disable-odbc \
        --with-openssl=no --with-gnutls=no --enable-static --disable-shared
# Build
make

# Install
mkdir ../../pkg
make install DESTDIR=`readlink -e ../../pkg`

# Package
cd ../../pkg/usr/local
mkdir -p $OLD_DIR/freetds/nix_32
mv bin etc include lib $OLD_DIR/freetds/nix_32/

# Cleanup
cd $OLD_DIR
rm -rf $TEMPDIR
export CFLAGS=$OLD_CFLAGS
