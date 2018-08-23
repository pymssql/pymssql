#!/bin/bash
# Need to test the wheels that where build with build_manylinux_wheels.sh

# Rename test template file for CI
mv /io/tests/tests.cfg.tpl /io/tests/tests.cfg

# Setup xml results folder for CI if it does not exist
if [ ! -d /io/results ]; then
    mkdir /io/results
fi

# Install the wheels that were built. Need to be able to connect to mssql and to run the pytest suite after install
for PYBIN in /opt/python/*/bin/; do
    "${PYBIN}/pip" install pymssql --no-index -f /io/dist
    "${PYBIN}/python" -c "import pymssql; pymssql.__version__;"
    export TEST_PY="$(${PYBIN}/python -c 'import platform; major, minor, patch = platform.python_version_tuple(); print(major+minor+patch)')"
    "${PYBIN}/pytest" /io --junitxml=/io/results/${TEST_PY}_test_results.xml
done