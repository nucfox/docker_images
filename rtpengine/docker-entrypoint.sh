#!/bin/bash
set -e

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

if [ "$1" = 'rtpengine' ]; then
  shift
  exec rtpengine --config-file /etc/rtpengine/rtpengine.conf "$@"
elif [ "$1" = 'rtpengine-recording' ]; then
  shift
  exec rtpengine-recording --config-file /etc/rtpengine/rtpengine-recording.conf "$@"
fi

exec "$@"
