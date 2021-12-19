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

if which yum; then
    yum install -y openssl-devel
else
    apt-get update
    apt-get install -y libssl1.1
    apt-get install -y libssl-dev
fi

/opt/python/cp38-cp38/bin/python dev/build.py \
    --ws-dir=./freetds \
    --dist-dir=. \
    --prefix=/usr/local \
    --freetds-version="1.3.4" \
    --with-openssl=yes \
    --static-freetds

# Install Python dependencies and compile wheels
PYTHONS="cp36-cp36m cp37-cp37m cp38-cp38 cp39-cp39"
for i in $PYTHONS; do
    PYBIN="/opt/python/$i/bin"
    "${PYBIN}/pip" install --upgrade pip setuptools Cython wheel
    "${PYBIN}/pip" wheel . -w .
done

# Verify the wheels and move from *-linux_* to -manylinux_*
for wheel in ./*.whl; do
    if ! auditwheel show "$wheel"; then
        echo "Skipping non-platform wheel $wheel"
    else
        auditwheel repair "$wheel" -w ./dist
    fi
done

# Create .tar.gz dist.
/opt/python/cp38-cp38/bin/python setup.py sdist

# Install the wheels that were built. Need to be able to connect to mssql and to run the pytest suite after install
for i in $PYTHONS; do
    PYBIN="/opt/python/$i/bin"
    "${PYBIN}/pip" install pymssql --no-index -f dist
    "${PYBIN}/pip" install psutil pytest pytest-timeout SQLAlchemy
    "${PYBIN}/pytest" -s .
    "${PYBIN}/python" -c "import pymssql; print(pymssql.version_info());"
done

# Remove wheel and egg directory for next container build (i686 vs x86_x64)
rm -rf .eggs/ pymssql.egg-info/

# Cleanup FreeTDS directories
rm -rf freetds/ # misc/ include/ doc/ samples/ vms/ wins32/

echo "Done building wheels."
