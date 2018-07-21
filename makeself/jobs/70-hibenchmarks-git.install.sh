#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0+

. ${HIBENCHMARKS_MAKESELF_PATH}/functions.sh "${@}" || exit 1

cd "${HIBENCHMARKS_SOURCE_PATH}" || exit 1

if [ ${HIBENCHMARKS_BUILD_WITH_DEBUG} -eq 0 ]
then
    export CFLAGS="-static -O3"
else
    export CFLAGS="-static -g -ggdb -Wall -Wextra -Wformat-signedness -fstack-protector-all -D_FORTIFY_SOURCE=2 -DHIBENCHMARKS_INTERNAL_CHECKS=1"
#    export CFLAGS="-static -g -ggdb -Wall -Wextra -Wformat-signedness"
fi

if [ ! -z "${HIBENCHMARKS_INSTALL_PATH}" -a -d "${HIBENCHMARKS_INSTALL_PATH}/etc" ]
    then
    # make sure we don't have an old etc path, so that the installer
    # will install all files without examining changes
    run mv "${HIBENCHMARKS_INSTALL_PATH}/etc" "${HIBENCHMARKS_INSTALL_PATH}/etc.new"
fi

run ./hibenchmarks-installer.sh --install "${HIBENCHMARKS_INSTALL_PARENT}" \
    --dont-wait \
    --dont-start-it \
    ${NULL}

if [ ${HIBENCHMARKS_BUILD_WITH_DEBUG} -eq 0 ]
then
    run strip ${HIBENCHMARKS_INSTALL_PATH}/bin/hibenchmarks
    run strip ${HIBENCHMARKS_INSTALL_PATH}/usr/libexec/hibenchmarks/plugins.d/apps.plugin
    run strip ${HIBENCHMARKS_INSTALL_PATH}/usr/libexec/hibenchmarks/plugins.d/cgroup-network
fi
