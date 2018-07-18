#
# Copyright (C) 2015 Alon Bar-Lev <alon.barlev@gmail.com>
# SPDX-License-Identifier: GPL-3.0+
#
MAINTAINERCLEANFILES= $(srcdir)/Makefile.in
CLEANFILES = \
	hibenchmarks-openrc \
	hibenchmarks.logrotate \
	hibenchmarks.service \
	hibenchmarks-init-d \
	hibenchmarks-lsb \
	hibenchmarks-freebsd \
	hibenchmarks.plist \
	$(NULL)

include $(top_srcdir)/build/subst.inc

SUFFIXES = .in

nodist_noinst_DATA = \
	hibenchmarks-openrc \
	hibenchmarks.logrotate \
	hibenchmarks.service \
	hibenchmarks-init-d \
	hibenchmarks-lsb \
	hibenchmarks-freebsd \
	hibenchmarks.plist \
	$(NULL)

dist_noinst_DATA = \
	hibenchmarks-openrc.in \
	hibenchmarks.logrotate.in \
	hibenchmarks.service.in \
	hibenchmarks-init-d.in \
	hibenchmarks-lsb.in \
	hibenchmarks-freebsd.in \
	hibenchmarks.plist.in \
	hibenchmarks.conf \
	$(NULL)
