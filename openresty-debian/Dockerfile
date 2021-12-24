FROM debian:bullseye-slim

LABEL maintainer="jiang9217@foxmail.com"

RUN set -eux; \
# create nginx user/group first, to be consistent throughout docker variants
    	addgroup --system --gid 101 nginx; \
    	adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false --uid 101 nginx; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
# utilities for keeping Debian and OpenJDK CA certificates in sync
		ca-certificates p11-kit \
	; \
	rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/local/openjdk-11
RUN { echo '#/bin/sh'; echo 'echo "$JAVA_HOME"'; } > /usr/local/bin/docker-java-home && chmod +x /usr/local/bin/docker-java-home && [ "$JAVA_HOME" = "$(docker-java-home)" ] # backwards compatibility
ENV PATH $JAVA_HOME/bin:$PATH

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# https://adoptopenjdk.net/upstream.html
# >
# > What are these binaries?
# >
# > These binaries are built by Red Hat on their infrastructure on behalf of the OpenJDK jdk8u and jdk11u projects. The binaries are created from the unmodified source code at OpenJDK. Although no formal support agreement is provided, please report any bugs you may find to https://bugs.java.com/.
# >
ENV JAVA_VERSION 11.0.13
# https://github.com/docker-library/openjdk/issues/320#issuecomment-494050246
# >
# > I am the OpenJDK 8 and 11 Updates OpenJDK project lead.
# > ...
# > While it is true that the OpenJDK Governing Board has not sanctioned those releases, they (or rather we, since I am a member) didn't sanction Oracle's OpenJDK releases either. As far as I am aware, the lead of an OpenJDK project is entitled to release binary builds, and there is clearly a need for them.
# >

ENV OPENRESTY_VERSION 1.19.9.1
ENV OPENRESTY_DOWNLOAD_URL https://openresty.org/download/openresty-1.19.9.1.tar.gz
ENV NGINX_MODULE_VTS_DOWNLOAD_URL https://codeload.github.com/vozlt/nginx-module-vts/tar.gz/v0.1.18
ENV REDIS_VERSION 6.0.16
ENV REDIS_DOWNLOAD_URL http://download.redis.io/releases/redis-6.0.16.tar.gz
ENV REDIS_DOWNLOAD_SHA 3639bbf29aca1a1670de1ab2ce224d6511c63969e7e590d3cdf8f7888184fa19

COPY docker-entrypoint.sh /

RUN set -eux; \
	\
	arch="$(dpkg --print-architecture)"; \
	case "$arch" in \
		'amd64') \
			downloadUrl='https://github.com/AdoptOpenJDK/openjdk11-upstream-binaries/releases/download/jdk-11.0.13%2B8/OpenJDK11U-jre_x64_linux_11.0.13_8.tar.gz'; \
			;; \
		'arm64') \
			downloadUrl='https://github.com/AdoptOpenJDK/openjdk11-upstream-binaries/releases/download/jdk-11.0.13%2B8/OpenJDK11U-jre_aarch64_linux_11.0.13_8.tar.gz'; \
			;; \
		*) echo >&2 "error: unsupported architecture: '$arch'"; exit 1 ;; \
	esac; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	# redis
	apt-get install -y --no-install-recommends \
		ca-certificates \
		wget \
		\
		dpkg-dev \
		gcc \
		libc6-dev \
		libssl-dev \
		make \
	; \
	# jre
	apt-get install -y --no-install-recommends \
		dirmngr \
		gnupg \
		wget \
	; \
	# openresty
	apt-get install -y --no-install-recommends \
		zlib1g-dev \
		openssl \
		libssl-dev \
		libpcre3-dev \
		gettext-base \
		gnupg2 \
		lsb-base \
		lsb-release \
		software-properties-common \
		acl \
		ca-certificates \
		curl \
		gzip \
		libbsd0 \
		libc6 \
		libexpat1 \
		libfontconfig1 \
		libfreetype6 \
		libgcc1 \
		libgcrypt20 \
		libgd3 \
		libgeoip1 \
		libgpg-error0 \
		libjbig0 \
		libjpeg62-turbo \
		liblzma5 \
		libpcre3 \
		libpng16-16 \
		libssl1.1 \
		libstdc++6 \
		libtiff5 \
		libuuid1 \
		libwebp6 \
		libx11-6 \
		libxau6 \
		libxcb1 \
		libxdmcp6 \
		libxml2 \
		libxpm4 \
		libxslt1.1 \
		libzstd1 \
		perl \
		procps \
		tar \
		zlib1g \
	; \
	# misc
	apt-get install -y --no-install-recommends \
		iproute2 \
		git \
		curl \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
	wget --progress=dot:giga -O openjdk.tgz "$downloadUrl"; \
	wget --progress=dot:giga -O openjdk.tgz.asc "$downloadUrl.sign"; \
	\
	export GNUPGHOME="$(mktemp -d)"; \
# pre-fetch Andrew Haley's (the OpenJDK 8 and 11 Updates OpenJDK project lead) key so we can verify that the OpenJDK key was signed by it
# (https://github.com/docker-library/openjdk/pull/322#discussion_r286839190)
# we pre-fetch this so that the signature it makes on the OpenJDK key can survive "import-clean" in gpg
	gpg --batch --keyserver keyserver.ubuntu.com --recv-keys EAC843EBD3EFDB98CC772FADA5CD6035332FA671; \
# TODO find a good link for users to verify this key is right (https://mail.openjdk.java.net/pipermail/jdk-updates-dev/2019-April/000951.html is one of the only mentions of it I can find); perhaps a note added to https://adoptopenjdk.net/upstream.html would make sense?
# no-self-sigs-only: https://salsa.debian.org/debian/gnupg2/commit/c93ca04a53569916308b369c8b218dad5ae8fe07
	gpg --batch --keyserver keyserver.ubuntu.com --keyserver-options no-self-sigs-only --recv-keys CA5F11C6CE22644D42C6AC4492EF8D39DC13168F; \
	gpg --batch --list-sigs --keyid-format 0xLONG CA5F11C6CE22644D42C6AC4492EF8D39DC13168F \
		| tee /dev/stderr \
		| grep '0xA5CD6035332FA671' \
		| grep 'Andrew Haley'; \
	gpg --batch --verify openjdk.tgz.asc openjdk.tgz; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME"; \
	\
	mkdir -p "$JAVA_HOME"; \
	tar --extract \
		--file openjdk.tgz \
		--directory "$JAVA_HOME" \
		--strip-components 1 \
		--no-same-owner \
	; \
	rm openjdk.tgz*; \
	\

# install redis
        tempDir="$(mktemp -d)"; \
        cd $tempDir; \
        curl -o redis.tar.gz "$REDIS_DOWNLOAD_URL"; \
        tar -xzf redis.tar.gz --strip-components=1; \
        rm redis.tar.gz; \
# disable Redis protected mode [1] as it is unnecessary in context of Docker
# (ports are not automatically exposed when running inside Docker, but rather explicitly by specifying -p / -P)
# [1]: https://github.com/redis/redis/commit/edd4d555df57dc84265fdfb4ef59a4678832f6da
        grep -E '^ *createBoolConfig[(]"protected-mode",.*, *1 *,.*[)],$' src/config.c; \
        sed -ri 's!^( *createBoolConfig[(]"protected-mode",.*, *)1( *,.*[)],)$!\10\2!' src/config.c; \
        grep -E '^ *createBoolConfig[(]"protected-mode",.*, *0 *,.*[)],$' src/config.c; \
# for future reference, we modify this directly in the source instead of just supplying a default configuration flag because apparently "if you specify any argument to redis-server, [it assumes] you are going to specify everything"
# see also https://github.com/docker-library/redis/issues/4#issuecomment-50780840
# (more exactly, this makes sure the default behavior of "save on SIGTERM" stays functional by default)
	\
# https://github.com/jemalloc/jemalloc/issues/467 -- we need to patch the "./configure" for the bundled jemalloc to match how Debian compiles, for compatibility
# (also, we do cross-builds, so we need to embed the appropriate "--build=xxx" values to that "./configure" invocation)
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	extraJemallocConfigureFlags="--build=$gnuArch"; \
# https://salsa.debian.org/debian/jemalloc/-/blob/c0a88c37a551be7d12e4863435365c9a6a51525f/debian/rules#L8-23
        dpkgArch="$(dpkg --print-architecture)"; \
        case "${dpkgArch##*-}" in \
                amd64 | i386 | x32) extraJemallocConfigureFlags="$extraJemallocConfigureFlags --with-lg-page=12" ;; \
                *) extraJemallocConfigureFlags="$extraJemallocConfigureFlags --with-lg-page=16" ;; \
        esac; \
        extraJemallocConfigureFlags="$extraJemallocConfigureFlags --with-lg-hugepage=21"; \
        grep -F 'cd jemalloc && ./configure ' deps/Makefile; \
        sed -ri 's!cd jemalloc && ./configure !&'"$extraJemallocConfigureFlags"' !' deps/Makefile; \
        grep -F "cd jemalloc && ./configure $extraJemallocConfigureFlags " deps/Makefile; \
        export BUILD_TLS=yes; \
        make -j "$(nproc)" all; \
        make install; \
        cd /tmp; \
        rm -rf $tempDir; \
        redis-cli --version; \
        redis-server --version; \
        \
# install openresty
        tempDir="$(mktemp -d)"; \
        cd $tempDir; \
        mkdir nginx-module-vts; \
        cd nginx-module-vts; \
        curl -o nginx-module-vts.tar.gz "$NGINX_MODULE_VTS_DOWNLOAD_URL"; \
        tar zxf nginx-module-vts.tar.gz --strip-components=1; \
        rm -f nginx-module-vtS.tar.gz; \
        cd ../; \
        mkdir openresty; \
        cd openresty; \
        curl -o openresty.tar.gz "$OPENRESTY_DOWNLOAD_URL"; \
        tar zxf openresty.tar.gz --strip-components=1; \
        rm -f openresty.tar.gz; \
        ./configure --add-module=../nginx-module-vts; \
        make; \
        make install; \
        cd /tmp; \
        rm -rf $tempDir; \
        ln -s /usr/local/openresty/nginx/sbin/nginx /usr/bin/; \
        cd /usr/local/openresty; \
        git clone https://github.com/knyar/nginx-lua-prometheus.git; \
        ln -sf /dev/stdout /usr/local/openresty/nginx/access.log; \
        ln -sf /dev/stderr /usr/local/openresty/nginx/error.log; \
        mkdir /docker-entrypoint.d; \
	chmod +x /docker-entrypoint.sh; \

	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
        find /usr/local -type f -executable -exec ldd '{}' ';' \
                | awk '/=>/ { print $(NF-1) }' \
                | sort -u \
                | xargs -r dpkg-query --search \
                | cut -d: -f1 \
                | sort -u \
                | xargs -r apt-mark manual \
	;\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	\
# update "cacerts" bundle to use Debian's CA certificates (and make sure it stays up-to-date with changes to Debian's store)
# see https://github.com/docker-library/openjdk/issues/327
#     http://rabexc.org/posts/certificates-not-working-java#comment-4099504075
#     https://salsa.debian.org/java-team/ca-certificates-java/blob/3e51a84e9104823319abeb31f880580e46f45a98/debian/jks-keystore.hook.in
#     https://git.alpinelinux.org/aports/tree/community/java-cacerts/APKBUILD?id=761af65f38b4570093461e6546dcf6b179d2b624#n29
	{ \
		echo '#!/usr/bin/env bash'; \
		echo 'set -Eeuo pipefail'; \
		echo 'trust extract --overwrite --format=java-cacerts --filter=ca-anchors --purpose=server-auth "$JAVA_HOME/lib/security/cacerts"'; \
	} > /etc/ca-certificates/update.d/docker-openjdk; \
	chmod +x /etc/ca-certificates/update.d/docker-openjdk; \
	/etc/ca-certificates/update.d/docker-openjdk; \
	\
# https://github.com/docker-library/openjdk/issues/331#issuecomment-498834472
	find "$JAVA_HOME/lib" -name '*.so' -exec dirname '{}' ';' | sort -u > /etc/ld.so.conf.d/docker-openjdk.conf; \
	ldconfig; \
	\
# https://github.com/docker-library/openjdk/issues/212#issuecomment-420979840
# https://openjdk.java.net/jeps/341
	java -Xshare:dump; \
	\
# basic smoke test
	java --version

ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin
WORKDIR /usr/local/openresty
COPY lua-script /usr/local/openresty/lua-script

COPY 10-listen-on-ipv6-by-default.sh /docker-entrypoint.d
COPY 20-envsubst-on-templates.sh /docker-entrypoint.d
COPY 30-tune-worker-processes.sh /docker-entrypoint.d

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 80 443 8080 8443

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off"]
