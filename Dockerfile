FROM  ubuntu:18.04
MAINTAINER  Tyler French tylerfrench2@gmail.com (@frenchtoasters)

# Install dependices
RUN apt-get update && apt-get install -y \
    unixodbc \
    unixodbc-dev \
    unixodbc-bin \
    libodbc1 \
    odbcinst1debian2 \
    tdsodbc \
    php-odbc \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install FreeTDS
RUN apt-get update && apt-get install -y \
    freetds-bin \
    freetds-common \
    freetds-dev \
    libct4 \
    libsybdb5 \
    && rm -rf /var/lib/apt/lists/*

# Install pip dependencies
RUN pip3 install Cython

# Add source directory to Docker image
ADD . /opt/src/pymssql/

RUN pip3 install /opt/src/pymssql

CMD ["python3"]
