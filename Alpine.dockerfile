FROM python:3.7.0-alpine3.8

RUN sed -i -e 's/v3\.4/edge/g' /etc/apk/repositories  && \
    apk --no-cache add alpine-sdk librdkafka-dev openssl-dev libffi-dev unixodbc unixodbc-dev freetds-dev python python-dev py-pip build-base

RUN pip install cython==0.28.5

RUN pip install git+https://github.com/pymssql/pymssql.git
