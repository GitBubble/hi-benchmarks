#!/bin/bash

# author  : titpetric
# original: https://github.com/titpetric/hibenchmarks

set -e
DEBIAN_FRONTEND=noninteractive

# some mirrors have issues, i skipped httpredir in favor of an eu mirror

# install dependencies for build

apt-get -qq update
apt-get -y install zlib1g-dev uuid-dev libmnl-dev gcc make curl git autoconf autogen automake pkg-config netcat-openbsd jq
apt-get -y install autoconf-archive lm-sensors nodejs python python-mysqldb python-yaml

# use the provided installer

./hibenchmarks-installer.sh --dont-wait --dont-start-it

# remove build dependencies

cd /
rm -rf /hibenchmarks.git

dpkg -P zlib1g-dev uuid-dev libmnl-dev gcc make git autoconf autogen automake pkg-config
apt-get -y autoremove
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# symlink access log and error log to stdout/stderr

ln -sf /dev/stdout /var/log/hibenchmarks/access.log
ln -sf /dev/stdout /var/log/hibenchmarks/debug.log
ln -sf /dev/stderr /var/log/hibenchmarks/error.log
