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
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -e -x

# Install freetds. Yum info shows this as version 0.91. Need to look into getting version 1.0 on centos for bundling
yum install -y freetds-devel

# Install Python dependencies and compile wheels
for PYBIN in /opt/python/*/bin; do
    "${PYBIN}/pip" install --upgrade pip setuptools
    "${PYBIN}/pip" install pytest SQLAlchemy Sphinx sphinx-rtd-theme Cython wheel
    "${PYBIN}/pip" wheel /io/ -w /io/dist/
done

# We could make a source distribution by running setup.py sdist, but the current setup.py pathing throws an error
# since the commands above use /io as the mount. Could use -w or WORKDIR to support building this in the container
# eventually.
# /opt/python/cp36-cp36m/bin/python setup.py sdist

# Verify the wheels and move from *-linux_* to -manylinux_*
for whl in /io/dist/*.whl; do
   auditwheel repair "$whl" -w /io/dist/
done

# Install the wheels that were built. Need to be able to connect to mssql and to run the pytest suite after install
for PYBIN in /opt/python/*/bin/; do
    "${PYBIN}/pip" install pymssql --no-index -f /io/dist
done

# Upload the wheels to test.pypi.org
# twine upload --repository-url https://test.pypi.org/legacy/ dist/*manylinux*
