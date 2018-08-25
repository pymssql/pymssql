#!/bin/bash

# Test installing from test.pypi.org
# pip install --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple --pre pymssql

if [ -z "$CIRCLE_TAG" ]; then
  twine upload -u $TEST_PYPI_USERNAME -p $TEST_PYPI_PASSWORD --repository testpypi dist/*
else
  echo "Not a tagged release $CIRCLE_TAG"
fi

