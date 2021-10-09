FROM openjdk:11
MAINTAINER jiang9217@foxmail.com

WORKDIR /root

# install hadoop 
RUN curl -O https://mirror.its.dal.ca/apache/hadoop/common/hadoop-3.3.1/hadoop-3.3.1.tar.gz && \
    tar -zxf hadoop-3.3.1.tar.gz && \
    mv hadoop-3.3.1 /usr/local/hadoop && \
    rm -f hadoop-3.3.1.tar.gz

# set environment variable
