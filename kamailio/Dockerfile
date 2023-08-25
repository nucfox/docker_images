# FROM debian:bullseye
FROM debian:bullseye-slim@sha256:b771c35d1e6ecf2556718ad3c0f481b4a04c1fbc133c609643acc9dd6743ead2
MAINTAINER Seven Du <dujinfang@x-y-t.cn>

COPY sources.list.163.bullseye /etc/apt/sources.list

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y wget gnupg2 ca-certificates iproute2

RUN echo "deb https://deb.sipwise.com/spce/mr10.2.1/ bullseye main" > /etc/apt/sources.list.d/sipwise.list

RUN wget -q -O - https://deb.sipwise.com/spce/keyring/sipwise-keyring-bootstrap.gpg | apt-key add -
RUN apt-get update && apt-get install -y ngcp-rtpengine

WORKDIR /
