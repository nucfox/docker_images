FROM openjdk:11-jre-slim

LABEL maintainer="jiang9217@foxmail.com"

ENV OPENRESTY_VERSION 1.19.9.1
ENV OPENRESTY_DOWNLOAD_URL https://openresty.org/download/openresty-1.19.9.1.tar.gz
ENV NGINX_MODULE_VTS_DOWNLOAD_URL https://codeload.github.com/vozlt/nginx-module-vts/tar.gz/v0.1.18
ENV REDIS_VERSION 6.0.16
ENV REDIS_DOWNLOAD_URL http://download.redis.io/releases/redis-6.0.16.tar.gz
ENV REDIS_DOWNLOAD_SHA 3639bbf29aca1a1670de1ab2ce224d6511c63969e7e590d3cdf8f7888184fa19

RUN set -x \
        && savedAptMark="$(apt-mark showmanual)" \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
	                gcc \
			libc-dev \
			make \
			openssl-dev \
			pcre-dev \
			zlib-dev \
			linux-headers \
			libxslt-dev \
			gd-dev \
			geoip-dev \
			perl-dev \
			libedit-dev \
			bash \
			alpine-sdk \
			findutils \
	                git \
			curl \
			libpcre3 \
			libpcre3-dev \
			zlib1g-dev \
			libc6-dev \
			libssl-dev \
			dpkg-dev \
			iproute2 \
			
	&& rm -rf /var/lib/apt/lists/* \
# install redis
	&& tempDir="$(mktemp -d)"
        && cd $tempDir
        && curl -o redis.tar.gz "$REDIS_DOWNLOAD_URL" \
	&& tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
	&& rm redis.tar.gz \
# disable Redis protected mode [1] as it is unnecessary in context of Docker
# (ports are not automatically exposed when running inside Docker, but rather explicitly by specifying -p / -P)
# [1]: https://github.com/redis/redis/commit/edd4d555df57dc84265fdfb4ef59a4678832f6da
	&& grep -E '^ *createBoolConfig[(]"protected-mode",.*, *1 *,.*[)],$' src/config.c \
	&& sed -ri 's!^( *createBoolConfig[(]"protected-mode",.*, *)1( *,.*[)],)$!\10\2!' src/config.c \
	&& grep -E '^ *createBoolConfig[(]"protected-mode",.*, *0 *,.*[)],$' src/config.c \
# https://salsa.debian.org/debian/jemalloc/-/blob/c0a88c37a551be7d12e4863435365c9a6a51525f/debian/rules#L8-23
	&& dpkgArch="$(dpkg --print-architecture)" \
	&& case "${dpkgArch##*-}" in \
		amd64 | i386 | x32) extraJemallocConfigureFlags="$extraJemallocConfigureFlags --with-lg-page=12" ;; \
		*) extraJemallocConfigureFlags="$extraJemallocConfigureFlags --with-lg-page=16" ;; \
	esac \
	&& extraJemallocConfigureFlags="$extraJemallocConfigureFlags --with-lg-hugepage=21" \
	&& grep -F 'cd jemalloc && ./configure ' deps/Makefile \
	&& sed -ri 's!cd jemalloc && ./configure !&'"$extraJemallocConfigureFlags"' !' deps/Makefile \
	&& grep -F "cd jemalloc && ./configure $extraJemallocConfigureFlags " deps/Makefile \
	&& export BUILD_TLS=yes \
	&& make -j "$(nproc)" all \
	&& make -C install \
        && cd /tmp \
	&& rm -rf $tempDir \
        && apt-mark auto '.*' > /dev/null \
	&& [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null \
	&& find /usr/local -type f -executable -exec ldd '{}' ';' \
		| awk '/=>/ { print $(NF-1) }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual \
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
	&& redis-cli --version \
	&& redis-server --version \
        \
# install openresty
	&& tempDir="$(mktemp -d)"
	&& cd $tempDir
	&& mkdir nginx-module-vts
	&& cd nginx-module-vts
	&& curl -o nginx-module-vts.tar.gz "$NGINX_MODULE_VTS_DOWNLOAD_URL" \
	&& tar zxf nginx-module-vts.tar.gz --strip-components=1 \
	&& rm -f nginx-module-vtS.tar.gz \
	&& cd ../
	&& mkdir openresty
	&& cd openresty
	&& curl -o openresty.tar.gz "$OPENRESTY_DOWNLOAD_URL" \
	&& tar zxf openresty.tar.gz --strip-components=1 \
	&& rm -f openresty.tar.gz \
	&& ./configure --add-module=../nginx-module-vts \
        && make \
        && make install \
	&& cd /tmp \
	&& rm -rf $tempDir \
	&& ln -s /usr/local/openresty/nginx/sbin/nginx /usr/bin/ \
	&& cd /usr/local/openresty \
	&& git clone https://github.com/knyar/nginx-lua-prometheus.git \
	&& ln -sf /dev/stdout /usr/local/openresty/nginx/access.log \
        && ln -sf /dev/stderr /usr/local/openresty/nginx/error.log \
	&& mkdir /docker-entrypoint.d

ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin
WORKDIR /usr/local/openresty
COPY lua-script ./lua-script

COPY docker-entrypoint.sh /
COPY 10-listen-on-ipv6-by-default.sh /docker-entrypoint.d
COPY 20-envsubst-on-templates.sh /docker-entrypoint.d
COPY 30-tune-worker-processes.sh /docker-entrypoint.d
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 80

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off"]
