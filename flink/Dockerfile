#
FROM centos:centos7

RUN set -eux; \
        yum install -y epel-release; \
        yum install -y \
            openssh \
            openssh-clients \
            openssh-server \
            wget \
            bzip2 \
            unzip \
            xz \
            jemalloc \
            fontconfig \
            freetype \
            ca-certificates \
            p11-kit

ENV LANG C.UTF-8
ENV JAVA_HOME /usr/local/openjdk-11
ENV PATH $JAVA_HOME/bin:$PATH

# Install dependencies
RUN set -eux; \
  yum install -y snappy jemalloc-devel nss_wrapper gettext

# Install openjdk 11
RUN set -ex; \
  downloadUrl='https://github.com/AdoptOpenJDK/openjdk11-upstream-binaries/releases/download/jdk-11.0.14.1%2B1/OpenJDK11U-jdk_x64_linux_11.0.14.1_1.tar.gz'; \
  wget --progress=dot:giga -O openjdk.tgz "$downloadUrl"; \
  mkdir -p "$JAVA_HOME"; \
  tar --extract \
        --file openjdk.tgz \
        --directory "$JAVA_HOME" \
        --strip-components 1 \
        --no-same-owner \
  ; \
  rm openjdk.tgz*; \
  \
  find "$JAVA_HOME/lib" -name '*.so' -exec dirname '{}' ';' | sort -u > /etc/ld.so.conf.d/docker-openjdk.conf; \
  ldconfig; \
  \
  java --version

# Grab gosu for easy step-down from root
ENV GOSU_VERSION 1.11
RUN set -ex; \
  wget -nv -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64"; \
  chmod +x /usr/local/bin/gosu; \
  gosu nobody true

# Configure Flink version
ENV FLINK_TGZ_URL=https://www.apache.org/dyn/closer.cgi?action=download&filename=flink/flink-1.13.2/flink-1.13.2-bin-scala_2.11.tgz

# Prepare environment
ENV FLINK_HOME=/opt/flink
ENV PATH=$FLINK_HOME/bin:$PATH
RUN groupadd --system --gid=9999 flink && \
    useradd --system --home-dir $FLINK_HOME --uid=9999 --gid=flink flink
WORKDIR $FLINK_HOME

# nss wrapper
COPY passwd.template /opt/flink

# Install Flink
RUN set -ex; \
  wget -nv -O flink.tgz "$FLINK_TGZ_URL"; \
  \
  tar -xf flink.tgz --strip-components=1; \
  rm flink.tgz; \
  mkdir -p ./plugins/oss-fs-hadoop ./plugins/s3-fs-presto; \
  cp ./opt/flink-oss-fs-hadoop-1.13.2.jar ./plugins/oss-fs-hadoop/; \
  cp ./opt/flink-s3-fs-presto-1.13.2.jar ./plugins/s3-fs-presto/; \
  chown -R flink:flink .

# Install nexmark-flink
COPY nexmark-flink.tgz /opt
RUN set -ex; \
  tar zxf /opt/nexmark-flink.tgz -C /opt; \
  rm -f /opt/nexmark-flink.tgz; \
  mv /opt/nexmark-flink /opt/nexmark; \
  cp -r /opt/nexmark/lib/* $FLINK_HOME/lib; \
  chown -R flink:flink /opt/*
  

# Configure container
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 6123 8081
CMD ["help"]

