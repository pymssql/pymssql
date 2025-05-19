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

# Install apt packages
RUN apt-get update && apt-get install -y \
    freetds-bin \
    freetds-common \
    freetds-dev

ADD ./dev/requirements-dev.txt /opt/src/pymssql/dev/requirements-dev.txt

RUN pip install -r /opt/src/pymssql/dev/requirements-dev.txt

CMD ["python", "-c", "import pymssql; print(pymssql.version_info())"]

# Add source directory to Docker image
# Note that it's beneficial to put this as far down in the Dockerfile as
# possible to maximize the chances of being able to use image caching
ADD . /opt/src/pymssql/

RUN pip install --no-build-isolation /opt/src/pymssql
