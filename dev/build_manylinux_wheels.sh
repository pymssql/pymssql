#!/bin/bash
# Need to build linux wheel using manylinux
#
# https://github.com/pypa/manylinux
# https://github.com/pypa/python-manylinux-demo
# https://www.python.org/dev/peps/pep-0513/
#
# You may need to make the build script executable
# chmod +x /dev/build_wheels.sh
#
# Standard manylinux docker containers provided by pypa. For more information see the links above.
# docker pull quay.io/pypa/manylinux1_x86_64
# docker pull quay.io/pypa/manylinux1_i686
#
# The next set of instructions will let you run the container interactively
# Provide a container name so it is easier to reference later
# sudo docker run --name manylinux_x86_x64 -it -d --rm -v `pwd`:/io quay.io/pypa/manylinux1_x86_64
# docker ps
#
# Use the docker exec command to interact with our container
# docker exec -it manylinux_x86_x64 ls
# docker exec -it manylinux_x86_x64 ./io/dev/build_wheels.sh
#
# Stop the conatiner when done
# docker stop manylinux_x86_x64
#
# These docker commands will run, build the wheel, attempt to install and then finally upload
# docker run --name manylinux_x86_x64 --rm -v `pwd`:/io quay.io/pypa/manylinux1_x86_64 /io/dev/build_wheels.sh
# docker run --name manylinux_i686 --rm -v `pwd`:/io quay.io/pypa/manylinux1_i686 /io/dev/build_wheels.sh
#
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -e -x

# Remove freetds package distributed with the repo if present.
rm -rf /io/freetds0.95

# Install freetds and use in build. Yum channel shows version 0.91. Retrieving latest stable release for builds.
export PYMSSQL_BUILD_WITH_BUNDLED_FREETDS=1

rm -rf /io/freetds
mkdir /io/freetds
curl -sS ftp://ftp.freetds.org/pub/freetds/stable/freetds-patched.tar.gz > freetds.tar.gz
tar -zxvf freetds.tar.gz -C /io/freetds --strip-components=1

export CFLAGS="-fPIC"  # for the 64 bits version

pushd /io/freetds
./configure --enable-msdblib \
  --prefix=/usr --sysconfdir=/etc/freetds --with-tdsver=7.1 \
  --disable-apps --disable-server --disable-pool --disable-odbc \
  --with-openssl=no --with-gnutls=no

make install
popd


#Make wheelhouse directory if it doesn't exist yet
mkdir /io/wheelhouse

# Install Python dependencies and compile wheels
for PYBIN in /opt/python/*/bin; do
    "${PYBIN}/pip" install --upgrade pip setuptools
    "${PYBIN}/pip" install pytest SQLAlchemy Sphinx sphinx-rtd-theme Cython wheel
    "${PYBIN}/pip" wheel /io/ -w /io/wheelhouse/
done

# Verify the wheels and move from *-linux_* to -manylinux_*
for whl in /io/wheelhouse/*.whl; do
   auditwheel repair "$whl" -w /io/wheelhouse/
done

# Remove non manylinux wheels
find /io/wheelhouse/ -type f ! -name '*manylinux*' -delete

# Create .tar.gz dist if it doesn't exists.
if [ ! -f /io/dist/*tar.gz* ]; then
    mkdir /io/dist
    pushd /io/
    /opt/python/cp36-cp36m/bin/python setup.py sdist
    popd
fi

# Move wheels to dist for install and upload
mv /io/wheelhouse/* /io/dist/

# Remove wheel and egg directory for next container build (i686 vs x86_x64)
rm -rf /io/wheelhouse/ /io/.eggs/ /io/pymssql.egg-info/

# Cleanup FreeTDS directories
rm -rf /io/freetds/ # /io/misc/ /io/include/ /io/doc/ /io/samples/ /io/vms/ /io/wins32/

echo "Done building wheels."
