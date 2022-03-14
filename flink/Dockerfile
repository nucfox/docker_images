#
FROM centos:centos7

RUN set -eux; \
        yum install -y \
            wget \
            bzip2 \
            unzip \
            xz \
            fontconfig \
            freetype \
            ca-certificates \
            p11-kit \
            java-1.8.0-openjdk ;\
	java -version

ENV LANG C.UTF-8

# Install dependencies
RUN set -ex; \
  yum install -y snappy jemalloc-devel nss_wrapper gettext

# Grab gosu for easy step-down from root
ENV GOSU_VERSION 1.11
RUN set -ex; \
  wget -nv -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64"; \
  chmod +x /usr/local/bin/gosu; \
  gosu nobody true

# nss wrapper
COPY passwd.template /tmp/passwd

ENV USER_ID='$(id -u)'
ENV GROUP_ID='$(id -g)'
ENV LD_PRELOAD=/usr/lib64/libnss_wrapper.so
ENV NSS_WRAPPER_PASSWD=/tmp/passwd
ENV NSS_WRAPPER_GROUP=/etc/group

# Configure Flink version
ENV FLINK_TGZ_URL=https://www.apache.org/dyn/closer.cgi?action=download&filename=flink/flink-1.13.2/flink-1.13.2-bin-scala_2.11.tgz

# Prepare environment
ENV FLINK_HOME=/opt/flink
ENV PATH=$FLINK_HOME/bin:$PATH
#RUN groupadd --system --gid=9999 flink && \
#    useradd --system --home-dir $FLINK_HOME --uid=9999 --gid=flink flink
WORKDIR $FLINK_HOME

# Install Flink
RUN set -ex; \
  wget -nv -O flink.tgz "$FLINK_TGZ_URL"; \
  \
  tar -xf flink.tgz --strip-components=1; \
  rm flink.tgz; \
  \
  chown -R flink:flink .


# Configure container
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 6123 8081
CMD ["help"]

