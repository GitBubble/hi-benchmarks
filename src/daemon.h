// SPDX-License-Identifier: GPL-3.0+
#ifndef HIBENCHMARKS_DAEMON_H
#define HIBENCHMARKS_DAEMON_H 1

extern int become_user(const char *username, int pid_fd);

extern int become_daemon(int dont_fork, const char *user);

extern void hibenchmarks_cleanup_and_exit(int i);

extern char pidfile[];

#endif /* HIBENCHMARKS_DAEMON_H */
