#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0+

. $(dirname "${0}")/../functions.sh "${@}" || exit 1

[ -d "${HIBENCHMARKS_INSTALL_PATH}.old" ] && run rm -rf "${HIBENCHMARKS_INSTALL_PATH}.old"
[ -d "${HIBENCHMARKS_INSTALL_PATH}" ] && run mv -f "${HIBENCHMARKS_INSTALL_PATH}" "${HIBENCHMARKS_INSTALL_PATH}.old"

run mkdir -p "${HIBENCHMARKS_INSTALL_PATH}/bin"
run mkdir -p "${HIBENCHMARKS_INSTALL_PATH}/usr"
run cd "${HIBENCHMARKS_INSTALL_PATH}"
run ln -s bin sbin
run cd "${HIBENCHMARKS_INSTALL_PATH}/usr"
run ln -s ../bin bin
run ln -s ../sbin sbin
run ln -s . local

