# --------------------------------------------------------------------------
# This is a Dockerfile to build an Ubuntu Docker image with
# pymssql and FreeTDS
#
# Use a command like:
#     docker build -t pymssql/pymssql .
#     docker run -it --rm pymssql/pymssql
# --------------------------------------------------------------------------

FROM python:3.12
LABEL maintainer="Marc Abramowitz <marc@marc-abramowitz.com> (@msabramo)"

WORKDIR /opt/src/pymssql
# print version, twine for check, pytest for tests
CMD ["bash", "-c", "python -c 'import pymssql; print(pymssql.version_info())' && twine check dist/* && pytest -sv --durations=0"]

# Install apt packages
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libkrb5-dev

ADD ./dev/requirements-dev.txt ./dev/requirements-dev.txt

RUN python -m pip install --upgrade pip

# twine for check
RUN pip install twine -r ./dev/requirements-dev.txt

# Add source directory to Docker image
# Note that it's beneficial to put this as far down in the Dockerfile as
# possible to maximize the chances of being able to use image caching
ADD . ./

RUN python dev/build.py \
    --ws-dir=./freetds \
    --dist-dir=./dist \
    --with-openssl=yes \
    --enable-krb5 \
    --sdist \
    --static-freetds

RUN pip install pymssql --no-index -f dist
