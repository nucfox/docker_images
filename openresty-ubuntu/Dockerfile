FROM ubuntu:20.04

LABEL maintainer="NGINX Docker Maintainers <docker-maint@nginx.com>"

ENV OPENRESTY_VERSION 1.19.9.1
ENV OPENRESTY_DOWNLOAD_URL https://openresty.org/download/openresty-1.19.9.1.tar.gz
ENV NGINX_MODULE_VTS_DOWNLOAD_URL https://codeload.github.com/vozlt/nginx-module-vts/tar.gz/v0.1.18

RUN set -eux \
        addgroup --system --gid 101 nginx; \
        adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false --uid 101 nginx; \
	apt-get update; \
	apt-get install -y --no-install-recommends \ 
		gcc \
		git \
		make \
		curl \
		libpcre3 \
		libpcre3-dev \
		zlib1g-dev \
		openssl \
		libssl-dev \
		iproute2 \
		openjdk-11-jre-headless \
	; \
	rm -rf /var/lib/apt/lists/*; \
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
        ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log; \
        ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log; \
        mkdir /docker-entrypoint.d; \
        mkdir /usr/local/openresty/lua-script; \
        chown -R nginx.nginx /usr/local/openresty; \
	
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
        apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false


ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

COPY docker-entrypoint.sh /
COPY 10-listen-on-ipv6-by-default.sh /docker-entrypoint.d
COPY 20-envsubst-on-templates.sh /docker-entrypoint.d
COPY 30-tune-worker-processes.sh /docker-entrypoint.d

WORKDIR /usr/local/openresty

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 80 443 8080 8443

STOPSIGNAL SIGQUIT

CMD ["openresty", "-g", "daemon off;"]
