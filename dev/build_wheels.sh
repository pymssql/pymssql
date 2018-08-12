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
# Pull in Windows artifacts from appveyor https://ci.appveyor.com/project/level12/pymssql if publishing
#
# Run python setup.py sdist in your base environment to build the tar.gz distribution. Do this before running
# build_wheels.sh in docker due to permissions.
#
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -e -x

# Install freetds. Yum info shows this as version 0.91. Need to look into getting version 1.0 on centos for bundling
yum install -y freetds-devel

# Make wheelhouse directory if it doesn't exist yet
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

# Move wheels to dist for install and upload
mv /io/wheelhouse/* /io/dist/

# Install the wheels that were built. Need to be able to connect to mssql and to run the pytest suite after install
for PYBIN in /opt/python/*/bin/; do
    "${PYBIN}/pip" install pymssql --no-index -f /io/dist
done

# We could make a source distribution by running setup.py sdist, but the current setup.py pathing throws an error
# since the commands above use /io as the mount. Could try using -w or WORKDIR to support building this in the container
# eventually.
# /opt/python/cp36-cp36m/bin/python setup.py sdist

# Remove wheel directory for next container build (i686 vs x86_x64)
rm -rf /io/wheelhouse/

# Upload the wheels to test.pypi.org
# twine upload --repository-url https://test.pypi.org/legacy/ dist/*

# Test installing from test.pypi.org
# pip install --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple --pre pymssql
