# FROM debian:bullseye
FROM debian:bullseye-slim@sha256:b771c35d1e6ecf2556718ad3c0f481b4a04c1fbc133c609643acc9dd6743ead2
MAINTAINER Seven Du <dujinfang@x-y-t.cn>

#COPY sources.list.163.bullseye /etc/apt/sources.list
#切换成163的debian 11 (bullseye)源
RUN set -eux; \
    echo "deb http://mirrors.163.com/debian/ bullseye main non-free contrib\n\
deb http://mirrors.163.com/debian/ bullseye-updates main non-free contrib\n\
deb http://mirrors.163.com/debian/ bullseye-backports main non-free contrib\n\
deb-src http://mirrors.163.com/debian/ bullseye main non-free contrib\n\
deb-src http://mirrors.163.com/debian/ bullseye-updates main non-free contrib\n\
deb-src http://mirrors.163.com/debian/ bullseye-backports main non-free contrib\n"\
    > /etc/apt/sources.list; \
    \
    DEBIAN_FRONTEND=noninteractive  apt-get update && apt-get install -y wget gnupg2 ca-certificates iproute2; \
    \
    echo "deb https://deb.sipwise.com/spce/mr10.5.5/ bullseye main" > /etc/apt/sources.list.d/sipwise.list; \
    \
    wget -q -O - https://deb.sipwise.com/spce/keyring/sipwise-keyring-bootstrap.gpg | apt-key add - ; \
    apt-get update && apt-get install -y ngcp-rtpengine ngcp-rtpengine-iptables; \
# Cleanup the image
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*


COPY docker-entrypoint.sh /

WORKDIR /

VOLUME ["/etc/rtpengine"]

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["rtpengine"]

