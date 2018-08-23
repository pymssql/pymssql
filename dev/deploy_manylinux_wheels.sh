#!/bin/bash

# Pull in Windows artifacts from appveyor https://ci.appveyor.com/project/level12/pymssql if publishing

# Upload the wheels to test.pypi.org
# twine upload --repository-url https://test.pypi.org/legacy/ dist/*

# Test installing from test.pypi.org
# pip install --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple --pre pymssql
