#!/bin/sh
VERSION=1.0.3

KIND=static
KIND=shared
PYVER=2.4
rm -rf build
rm dist/pymssql-$VERSION*
python$PYVER setup.py bdist
python$PYVER setup.py bdist --format=gztar
python$PYVER setup.py bdist --format=zip
python$PYVER setup.py bdist --format=rpm
mkdir dist/pymssql.$KIND.python$PYVER
cp dist/pymssql-$VERSION* dist/pymssql.$KIND.python$PYVER

#python setup.py bdist --format=ztar
#python setup.py bdist --format=tar
