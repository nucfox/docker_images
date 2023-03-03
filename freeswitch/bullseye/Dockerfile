#
FROM debian:bullseye
MAINTAINER Andrey Volk <andrey@signalwire.com>

# explicitly set user/group IDs
RUN groupadd -r freeswitch --gid=999 && useradd -r -g freeswitch --uid=999 freeswitch

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -yq install git

RUN git clone https://github.com/signalwire/freeswitch /usr/src/freeswitch
RUN git clone https://github.com/signalwire/libks /usr/src/libs/libks
RUN git clone https://github.com/freeswitch/sofia-sip /usr/src/libs/sofia-sip
RUN git clone https://github.com/freeswitch/spandsp /usr/src/libs/spandsp
#RUN git clone https://github.com/signalwire/signalwire-c /usr/src/libs/signalwire-c

RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install \
# build
    build-essential lsb-release wget dirmngr gnupg2 ca-certificates cmake automake autoconf 'libtool-bin|libtool' pkg-config \
# general
    libssl-dev zlib1g-dev libdb-dev unixodbc-dev libncurses5-dev libexpat1-dev libgdbm-dev bison erlang-dev libtpl-dev libtiff5-dev uuid-dev \
# core
    libpcre3-dev libedit-dev libsqlite3-dev libcurl4-openssl-dev nasm \
# core codecs
    libogg-dev libspeex-dev libspeexdsp-dev \
# mod_enum
    libldns-dev \
# mod_python3
    python3-dev \
# mod_av
    libavformat-dev libswscale-dev libavresample-dev \
# mod_lua
    liblua5.2-dev \
# mod_opus
    libopus-dev \
# mod_pgsql
    libpq-dev \
# mod_portaudio
    portaudio19-dev \
# mod_sndfile
    libsndfile1-dev libflac-dev libogg-dev libvorbis-dev \
# Basic ODBC tools and ODBC libraries for UNIX
    unixodbc unixodbc-dev \
# ODBC driver for PostgreSQL
    odbc-postgresql

# MySQL ODBC driver
RUN wget https://repo.mysql.com/mysql-apt-config_0.8.24-1_all.deb -O mysql-apt-config.deb \
    && export DEBIAN_FRONTEND=noninteractive && dpkg --install mysql-apt-config.deb \
    && rm -f mysql-apt-config.deb \
    && apt-get update \
    && apt-get -yq install mysql-connector-odbc

RUN gpg2 --keyserver hkp://keyserver.ubuntu.com --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu

RUN cd /usr/src/libs/libks && cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBBACKTRACE=1 && make install
RUN cd /usr/src/libs/sofia-sip && ./bootstrap.sh && ./configure --prefix=/usr && make -j`nproc --all` && make install
RUN cd /usr/src/libs/spandsp && ./bootstrap.sh && ./configure --prefix=/usr && make -j`nproc --all` && make install
#RUN cd /usr/src/libs/signalwire-c && PKG_CONFIG_PATH=/usr/lib/pkgconfig cmake . -DCMAKE_INSTALL_PREFIX=/usr && make install

RUN cd /usr/src/freeswitch && ./bootstrap.sh -j \
    && sed -i "/^#applications\/mod_curl$/s/^#//" modules.conf \
    && sed -i "/^#applications\/mod_esl$/s/^#//" modules.conf \
    && sed -i "s/^applications\/mod_signalwire/#&/g" modules.conf \
    && sed -i "/^#event_handlers\/mod_odbc_cdr$/s/^#//" modules.conf \
    && sed -i "/^#endpoints\/mod_portaudio$/s/^#//" modules.conf \
    && ./configure --enable-core-odbc-support \
    && make -j`nproc` && make install \
    && make mod_portaudio \
    && make mod_portaudio-install \
    && make cd-sounds-install \
    && make cd-moh-install \
    && make uhd-sounds-install \
    && make uhd-moh-install \
    && make hd-sounds-install \
    && make hd-moh-install \
    && make sounds-install \
    && make moh-install

RUN chown -R freeswitch:freeswitch /usr/local/freeswitch

# Cleanup the image
RUN apt-get clean

# Uncomment to cleanup even more
RUN rm -rf /usr/src/*
#-------------------------------

COPY docker-entrypoint.sh /
# Add anything else here

## Ports
# Open the container up to the world.
### 8021 fs_cli, 5060 5061 5080 5081 sip and sips, 64535-65535 rtp
EXPOSE 8021/tcp
EXPOSE 5060/tcp 5060/udp 5080/tcp 5080/udp
EXPOSE 5061/tcp 5061/udp 5081/tcp 5081/udp
EXPOSE 7443/tcp
EXPOSE 5070/udp 5070/tcp
#EXPOSE 64535-65535/udp
#EXPOSE 16384-32768/udp


# Volumes
## Freeswitch Configuration
VOLUME ["/usr/local/freeswitch/conf"]
## Tmp so we can get core dumps out
VOLUME ["/tmp"]

# Limits Configuration
COPY    build/freeswitch.limits.conf /etc/security/limits.d/

# Healthcheck to make sure the service is running
SHELL       ["/bin/bash"]
HEALTHCHECK --interval=15s --timeout=5s \
    CMD  fs_cli -x status | grep -q ^UP || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]


CMD ["freeswitch"]
