// SPDX-License-Identifier: GPL-3.0+
#ifndef HIBENCHMARKS_STATSD_H
#define HIBENCHMARKS_STATSD_H

#define STATSD_LISTEN_PORT 8125
#define STATSD_LISTEN_BACKLOG 4096

extern void *statsd_main(void *ptr);

#endif //HIBENCHMARKS_STATSD_H
