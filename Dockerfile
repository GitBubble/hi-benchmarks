# author  : titpetric
# original: https://github.com/titpetric/hibenchmarks
# SPDX-License-Identifier: CC0-1.0

FROM debian:stretch

ADD . /hibenchmarks.git

RUN cd ./hibenchmarks.git && chmod +x ./docker-build.sh && sync && sleep 1 && ./docker-build.sh

WORKDIR /

ENV HIBENCHMARKS_PORT 19999
EXPOSE $HIBENCHMARKS_PORT

CMD /usr/sbin/hibenchmarks -D -s /host -p ${HIBENCHMARKS_PORT}
