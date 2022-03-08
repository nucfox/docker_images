#
FROM postgres:10-bullseye
RUN set -ex; \
        apt-get update; \
        apt-get install -y --no-install-recommends \
                software-properties-common \
                build-essential \
                pkg-config \
                git \
                ; \
        add-apt-repository "deb http://ftp.debian.org/debian testing main contrib"; \
        apt-get update; \
        apt-get install -y --no-install-recommends \
                libproj-dev \
                liblwgeom-dev \
                libprotobuf-c-dev=1.2.1-1+b1 \
                protobuf-c-compiler=1.2.* \
                ; \
         tempDir="$(mktemp -d)"; \
         cd $tempDir; \
         git clone https://github.com/debezium/postgres-decoderbufs.git; \
         cd postgres-decoderbufs; \
         make; \
         make install; \
         cd /; \
         rm -rf /var/lib/apt/lists/*; \
         rm -rf $tmpDir
