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
# sudo docker run --name manylinux_x86_x64 -it -d --rm -w=/io -v `pwd`:/io quay.io/pypa/manylinux1_x86_64
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
# docker run --name manylinux_x86_x64 --rm -w=/io -v `pwd`:/io quay.io/pypa/manylinux1_x86_64 /io/dev/build_wheels.sh
# docker run --name manylinux_i686 --rm -w=/io -v `pwd`:/io quay.io/pypa/manylinux1_i686 /io/dev/build_wheels.sh
#
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -e -x

# Install freetds and use in build. Yum channel shows version 0.91. Retrieving latest stable release for builds.
export PYMSSQL_BUILD_WITH_BUNDLED_FREETDS=1

rm -rf freetds
mkdir freetds
curl -sS ftp://ftp.freetds.org/pub/freetds/stable/freetds-patched.tar.gz > freetds.tar.gz
tar -zxvf freetds.tar.gz -C freetds --strip-components=1

export CFLAGS="-fPIC"  # for the 64 bits version

pushd freetds
./configure --enable-msdblib \
  --prefix=/usr --sysconfdir=/etc/freetds --with-tdsver=7.1 \
  --disable-apps --disable-server --disable-pool --disable-odbc \
  --with-openssl=no --with-gnutls=no

make install
popd


#Make wheelhouse directory if it doesn't exist yet
if [ ! -d wheelhouse ]; then
    mkdir wheelhouse
fi

# Install Python dependencies and compile wheels
for PYBIN in /opt/python/*/bin; do
    "${PYBIN}/pip" install --upgrade pip setuptools Cython wheel
    "${PYBIN}/pip" wheel . -w wheelhouse/
done

# Verify the wheels and move from *-linux_* to -manylinux_*
for wheel in ./wheelhouse/*.whl; do
    if ! auditwheel show "$wheel"; then
        echo "Skipping non-platform wheel $wheel"
    else
        auditwheel repair "$wheel" -w ./wheelhouse/
    fi
done

# Remove non manylinux wheels
find wheelhouse/ -type f ! -name '*manylinux*' -delete

# Create .tar.gz dist.
/opt/python/cp36-cp36m/bin/python setup.py sdist

# Move wheels to dist for install and upload
mv wheelhouse/* dist/

# Install the wheels that were built. Need to be able to connect to mssql and to run the pytest suite after install
for PYBIN in /opt/python/*/bin/; do
    "${PYBIN}/pip" install pymssql-plus --no-index -f dist
    "${PYBIN}/pip" install psutil pytest pytest-timeout SQLAlchemy
    "${PYBIN}/python" -c "import pymssql; pymssql.__version__;"
    # "${PYBIN}/pytest" -s .
done

# Remove wheel and egg directory for next container build (i686 vs x86_x64)
rm -rf wheelhouse/ .eggs/ pymssql.egg-info/

# Cleanup FreeTDS directories
rm -rf freetds/ # misc/ include/ doc/ samples/ vms/ wins32/

echo "Done building wheels."
