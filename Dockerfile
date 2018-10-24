# ------------------------------------------------------------------------------
# This is a Dockerfile to build a Debian Docker image with pymssql and FreeTDS.
#
# Use a command like:
#     docker build -t pymssql/pymssql .
# ------------------------------------------------------------------------------

FROM  python:3
MAINTAINER  Marc Abramowitz <marc@marc-abramowitz.com> (@msabramo)

# Install apt packages
RUN apt-get update && apt-get install -y \
    freetds-bin \
    freetds-common \
    freetds-dev

RUN pip3 install Cython
RUN pip3 install ipython
RUN pip3 install SQLAlchemy
RUN pip3 install pandas
RUN pip3 install Alembic

# Add source directory to Docker image
# Note that it's beneficial to put this as far down in the Dockerfile as
# possible to maximize the chances of being able to use image caching
ADD . /opt/src/pymssql/

RUN pip install /opt/src/pymssql

CMD ["ipython"]
