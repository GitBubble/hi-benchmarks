# SPDX-License-Identifier: GPL-3.0+
MAINTAINERCLEANFILES= $(srcdir)/Makefile.in

dist_noinst_DATA = \
	README.md \
	debian/copyright \
	debian/hibenchmarks.conf \
	debian/source/format \
	debian/control.wheezy \
	debian/compat \
	debian/hibenchmarks.install \
	debian/hibenchmarks.lintian-overrides \
	debian/rules \
	debian/hibenchmarks.docs \
	debian/hibenchmarks.default \
	debian/control \
	debian/hibenchmarks.postinst.in \
	debian/hibenchmarks.service \
	debian/changelog \
	debian/hibenchmarks.postrm \
	rhel/build-hibenchmarks-rpm.sh \
	$(NULL)

dist_noinst_SCRIPTS = \
	debian/hibenchmarks.init \
	nc-backend.sh \
	$(NULL)

debian/changelog:
	echo "hibenchmarks ($(PACKAGE_VERSION)) UNRELEASED; urgency=medium" | \
		tr '_' '~' > $@
	echo "  * Latest release" >> $@
	echo " -- Netdata Team <>  `date -R`" >> $@
