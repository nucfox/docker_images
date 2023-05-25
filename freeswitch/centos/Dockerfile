#
#FROM hub-mirror.c.163.com/library/centos:7
FROM 05f073ad3c0010ea0f4bc00b7105ec20.mirror.swr.myhuaweicloud.com/library/centos:7
MAINTAINER Andrey Volk <andrey@signalwire.com>

ARG FREESWITCH_VERSION=1.10.9

# explicitly set user/group IDs
RUN groupadd -r freeswitch --gid=1999 && useradd -r -g freeswitch --uid=1999 freeswitch

RUN echo -e "[irontec]\nname=Irontec RPMs repository\nbaseurl=http://packages.irontec.com/centos/\$releasever/\$basearch/" > /etc/yum.repos.d/irontec.repo

RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && yum -y install epel-release

RUN rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro \
    && rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm \
    && rpm --import http://packages.irontec.com/public.key

RUN yum -y update && yum -y install gcc gcc-c++ git redhat-lsb-core wget iproute gnupg2 ca-certificates make sngrep


RUN wget https://github.com/signalwire/freeswitch/archive/refs/tags/v$FREESWITCH_VERSION.tar.gz -P /usr/src/ && tar zxf /usr/src/v$FREESWITCH_VERSION.tar.gz -C /usr/src
#RUN git clone https://github.com/signalwire/freeswitch /usr/src/freeswitch
RUN git clone https://github.com/ianlancetaylor/libbacktrace /usr/src/libs/libbacktrace
RUN git clone https://github.com/signalwire/libks /usr/src/libs/libks
RUN git clone https://github.com/freeswitch/sofia-sip /usr/src/libs/sofia-sip
RUN git clone https://github.com/freeswitch/spandsp /usr/src/libs/spandsp
#RUN git clone https://github.com/signalwire/signalwire-c /usr/src/libs/signalwire-c

RUN yum -y install \
# build
    automake autoconf libtool pkgconfig \
# general
    ncurses-devel libpcap-devel pcre-devel openssl-devel openssl-libs openssl zlib-devel libdb-devel bison libjpeg-devel libtiff libtiff-devel uuid-devel \
# core
    pcre-devel pcre2-devel libedit-devel sqlite-devel libcurl-devel nasm uuid libuuid-devel libuuid libatomic \
# core codecs
    libogg-devel speex-devel \
# mod_enum
    ldns-devel \
# mod_python3
    python3 \
# mod_av
    ffmpeg ffmpeg-devel \
# mod_lua
    lua lua-devel \
# luasocket
# lua-iconv
# lua-bitop
# mod_opus
    opus-devel \
# mod_pgsql
    postgresql-devel \
# mod_portaudio
    alsa-utils portaudio \
# mod_flite
    flite flite-devel \
# mod_sndfile
    libsndfile-devel flac-devel libogg-devel libvorbis-devel \
# Basic ODBC tools and ODBC libraries for UNIX
    unixODBC unixodbc-devxODBC \
# ODBC driver for PostgreSQL
    postgresql-odbc \
# ODBC driver for Mysql
    mysql-connector-odbc

RUN #gpg2 --keyserver hkp://keyserver.ubuntu.com --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.16/gosu-amd64" \
    #&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.16/gosu-amd64" \
    #&& gpg --verify /usr/local/bin/gosu.asc \
    #&& rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu

#RUN cd /usr/src \
#    && wget https://github.com/Kitware/CMake/releases/download/v3.26.4/cmake-3.26.4.tar.gz \
#    && tar zxf cmake-3.26.4.tar.gz && rm -f cmake-3.26.4.tar.gz \
#    && cd cmake-3.26.4 \
#    && ./bootstrap \
#    && gmake \
#    && make install \
#    && cd ../ && rm -rf cmake-3.26.4
#
#RUN cd /usr/src/libs/libbacktrace && ./configure && make && make install
#RUN cd /usr/src/libs/libks && cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBBACKTRACE=1 && make install
RUN cd /usr/src/libs/sofia-sip && ./bootstrap.sh && ./configure --prefix=/usr && make -j`nproc --all` && make install
RUN cd /usr/src/libs/spandsp && ./bootstrap.sh && ./configure --prefix=/usr && make -j`nproc --all` && make install
#RUN cd /usr/src/libs/signalwire-c && PKG_CONFIG_PATH=/usr/lib/pkgconfig cmake . -DCMAKE_INSTALL_PREFIX=/usr && make install

RUN cd /usr/src/freeswitch-$FREESWITCH_VERSION && ./bootstrap.sh -j \
    && sed -i "/^#applications\/mod_curl$/s/^#//" modules.conf \
    && sed -i "/^#applications\/mod_esl$/s/^#//" modules.conf \
    && sed -i "s/^applications\/mod_signalwire/#&/g" modules.conf \
    && sed -i "s/^endpoints\/mod_verto/#&/g" modules.conf \
    && sed -i "/^#event_handlers\/mod_odbc_cdr$/s/^#//" modules.conf \
    && sed -i "/^#endpoints\/mod_portaudio$/s/^#//" modules.conf \
    && sed -i "/^#asr_tts\/mod_flite$/s/^#//" modules.conf \
    && sed -i "/^#languages\/mod_python3$/s/^#//" modules.conf \
    && sed -i "/^#event_handlers\/mod_cdr_pg_csv$/s/^#//" modules.conf \
    && ./configure --bindir=/usr/bin --enable-core-odbc-support \
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

# unimrcp-deps
RUN cd /usr/src \
    && wget https://www.unimrcp.org/project/component-view/unimrcp-deps-1-6-0-tar-gz/download -O unimrcp-deps-1.6.0.tar.gz \
    && tar xvzf unimrcp-deps-1.6.0.tar.gz \
    && cd unimrcp-deps-1.6.0 \
    && sh -c '/bin/echo -e "\ny\n\ny" | sh build-dep-libs.sh'
    #&& cd libs/apr \
    #&& ./configure --prefix=/usr/local/apr \
    #&& make && make install \
    #&& cd ../apr-util \
    #&& ./configure --prefix=/usr/local/apr --with-apr=/usr/local/apr \
    #&& make && make install

# unimrcp
RUN cd /usr/src \
    && git clone https://github.com/unispeech/unimrcp.git \
    && cd unimrcp \
    && ./bootstrap \
    && ./configure --with-sofia-sip=/usr \
    && make && make install

RUN echo "export PKG_CONFIG_PATH=\$PKG_CONFIG_PATH:/usr/local/freeswitch/lib/pkgconfig:/usr/local/unimrcp/lib/pkgconfig" >> /etc/bash.bashrc

# mod_unimrcp
RUN cd /usr/src \
    && git clone https://github.com/freeswitch/mod_unimrcp.git \
    && cd mod_unimrcp \
    && export PKG_CONFIG_PATH=/usr/local/freeswitch/lib/pkgconfig:/usr/local/unimrcp/lib/pkgconfig \
    && ./bootstrap.sh && ./configure && make && make install

RUN chown -R freeswitch:freeswitch /usr/local/freeswitch

# Cleanup the image
#RUN apt-get clean

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
#COPY    build/freeswitch.limits.conf /etc/security/limits.d/

# Healthcheck to make sure the service is running
SHELL       ["/bin/bash"]
HEALTHCHECK --interval=15s --timeout=5s \
    CMD  fs_cli -x status | grep -q ^UP || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]

WORKDIR /usr/local/freeswitch

CMD ["freeswitch"]
