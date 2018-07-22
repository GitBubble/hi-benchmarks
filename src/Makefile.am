#
# Copyright (C) 2015 Alon Bar-Lev <alon.barlev@gmail.com>
# SPDX-License-Identifier: GPL-3.0+
#
MAINTAINERCLEANFILES= $(srcdir)/Makefile.in

AM_CPPFLAGS = \
	-DVARLIB_DIR="\"$(varlibdir)\"" \
	-DCACHE_DIR="\"$(cachedir)\"" \
	-DCONFIG_DIR="\"$(configdir)\"" \
	-DLOG_DIR="\"$(util/logdir)\"" \
	-DPLUGINS_DIR="\"$(pluginsdir)\"" \
	-DRUN_DIR="\"$(localstatedir)/run/hibenchmarks\"" \
	-DWEB_DIR="\"$(webdir)\"" \
	$(NULL)

AM_CFLAGS = \
	$(OPTIONAL_MATH_CFLAGS) \
	$(OPTIONAL_NFACCT_CLFAGS) \
	$(OPTIONAL_ZLIB_CFLAGS) \
	$(OPTIONAL_UUID_CFLAGS) \
	$(OPTIONAL_LIBCAP_CFLAGS) \
	$(OPTIONAL_IPMIMONITORING_CFLAGS)\
	$(NULL)

sbin_PROGRAMS = hibenchmarks
dist_cache_DATA = .keep
dist_varlib_DATA = .keep
dist_registry_DATA = .keep
dist_log_DATA = .keep
plugins_PROGRAMS =

if ENABLE_PLUGIN_APPS
plugins_PROGRAMS += apps.plugin
endif

if ENABLE_PLUGIN_FREEIPMI
plugins_PROGRAMS += freeipmi.plugin
endif

if ENABLE_PLUGIN_CGROUP_NETWORK
plugins_PROGRAMS += cgroup-network
endif

hibenchmarks_SOURCES = \
	util/adaptive_resortable_list.c \
	include/adaptive_resortable_list.h \
	util/appconfig.c \
	include/appconfig.h \
	util/avl.c \
	include/avl.h \
	backend/backend_prometheus.c \
	include/backend_prometheus.h \
	backend/backends.c \
	include/backends.h \
	host/locks.c \
	include/locks.h \
	util/common.c \
	include/common.h \
	host/daemon.c \
	include/daemon.h \
	util/dictionary.c \
	include/dictionary.h \
	util/eval.c \
	include/eval.h \
	stat/global_statistics.c \
	include/global_statistics.h \
	health/health.c \
	include/health.h \
	health/health_config.c \
	health/health_json.c \
	health/health_util/log.c \
	include/inlined.h \
	util/log.c \
	include/log.h \
	host/main.c \
	include/main.h \
	plugin/plugin_checks.c \
	include/plugin_checks.h \
	plugin/plugin_idlejitter.c \
	include/plugin_idlejitter.h \
	plugin/plugins_d.c \
	include/plugins_d.h \
	host/popen.c \
	include/popen.h \
	proc/procfile.c \
	include/procfile.h \
	proc/registry.c \
	include/registry.h \
	registry/registry_db.c \
	registry/registry_init.c \
	registry/registry_internals.c \
	include/registry_internals.h \
	registry/registey_log.c \
	registry/registry_machine.c \
	include/registry_machine.h \
	registry/registry_person.c \
	include/registry_person.h \
	registry/registry_url.c \
	include/registry_url.h \
	rrd/rrd.c \
	include/rrd.h \
	rrd/rrd2json.c \
	include/rrd2json.h \
	rrd/rrd2json_api_old.c \
	include/rrd2json_api_old.h \
	rrd/rrdcalc.c \
	rrd/rrdcalctemplate.c \
	rrd/rrddim.c \
	rrd/rrddimvar.c \
	rrd/rrdfamily.c \
	rrd/rrdhost.c \
	rrd/rrdpush.c \
	rrd/rrdpush.h \
	rrd/rrdset.c \
	rrd/rrdsetvar.c \
	rrd/rrdvar.c \
	host/signals.c \
	host/signals.h \
	util/simple_pattern.c \
	util/simple_pattern.h \
	host/socket.c \
	host/socket.h \
	stat/statistical.c \
	include/statistical.h \
	stat/statsd.c \
	include/statsd.h \
	stat/storage_number.c \
	include/storage_number.h \
	host/threads.c \
	include/threads.h \
	test/unit_test.c \
	test/unit_test.h \
	web/url.c \
	include/url.h \
	web/web_api_old.c \
	include/web_api_old.h \
	web/web_api_v1.c \
	include/web_api_v1.h \
	web/web_buffer.c \
	include/web_buffer.h \
	web/web_buffer_svg.c \
	include/web_buffer_svg.h \
	web/web_client.c \
	include/web_client.h \
	web/web_server.c \
	include/web_server.h \
	$(NULL)


hibenchmarks_SOURCES += \
	host/ipc.c \
	include/ipc.h \
	plugin/plugin_nfacct.c \
	include/plugin_nfacct.h \
	plugin/plugin_proc.c \
	include/plugin_proc.h \
	plugin/plugin_proc_diskspace.c \
	include/plugin_proc_diskspace.h \
	plugin/plugin_tc.c \
	include/plugin_tc.h \
	proc/proc_diskstats.c \
	proc/proc_interrupts.c \
	proc/proc_softirqs.c \
	proc/proc_loadavg.c \
	proc/proc_meminfo.c \
	proc/proc_net_dev.c \
	proc/proc_net_ip_vs_stats.c \
	proc/proc_net_netstat.c \
	proc/proc_net_rpc_nfs.c \
	proc/proc_net_rpc_nfsd.c \
	proc/proc_net_snmp.c \
	proc/proc_net_snmp6.c \
	proc/proc_net_sctp_snmp.c \
	proc/proc_net_sockstat.c \
	proc/proc_net_sockstat6.c \
	proc/proc_net_softnet_stat.c \
	proc/proc_net_stat_conntrack.c \
	proc/proc_net_stat_synproxy.c \
	proc/proc_self_mountinfo.c \
	proc/proc_self_mountinfo.h \
	fs/zfs_common.c \
    include/zfs_common.h \
	proc/proc_spl_kstat_zfs.c \
	proc/proc_stat.c \
	proc/proc_sys_kernel_random_entropy_avail.c \
	proc/proc_vmstat.c \
	proc/proc_uptime.c \
	fs/sys_kernel_mm_ksm.c \
	fs/sys_devices_system_edac_mc.c \
	fs/sys_devices_system_node.c \
	fs/sys_fs_cgroup.c \
	fs/sys_fs_btrfs.c \
	util/clocks.c \
	include/clocks.h \
	$(NULL)


hibenchmarks_LDADD = \
	$(OPTIONAL_MATH_LIBS) \
	$(OPTIONAL_NFACCT_LIBS) \
	$(OPTIONAL_ZLIB_LIBS) \
	$(OPTIONAL_UUID_LIBS) \
	$(NULL)

apps_plugin_SOURCES = \
	plugin/apps_plugin.c \
	util/avl.c \
	include/avl.h \
	util/clocks.c \
	include/clocks.h \
	util/common.c \
	include/common.h \
	include/inlined.h \
	host/locks.c \
	host/locks.h \
	util/log.c util/log.h \
	proc/procfile.c \
	include/procfile.h \
	host/threads.c \
	include/threads.h \
	web/web_buffer.c \
	include/web_buffer.h \
	$(NULL)

apps_plugin_SOURCES += \
	util/adaptive_resortable_list.c \
	include/adaptive_resortable_list.h \
	$(NULL)

apps_plugin_LDADD = \
	$(OPTIONAL_MATH_LIBS) \
	$(OPTIONAL_LIBCAP_LIBS) \
	$(NULL)

