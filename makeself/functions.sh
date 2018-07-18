#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0+

# -----------------------------------------------------------------------------

# allow running the jobs by hand
[ -z "${HIBENCHMARKS_BUILD_WITH_DEBUG}" ] && export HIBENCHMARKS_BUILD_WITH_DEBUG=0
[ -z "${HIBENCHMARKS_INSTALL_PATH}" ] && export HIBENCHMARKS_INSTALL_PATH="${1-/opt/hibenchmarks}"
[ -z "${HIBENCHMARKS_MAKESELF_PATH}" ] && export HIBENCHMARKS_MAKESELF_PATH="$(dirname "${0}")/.."
[ "${HIBENCHMARKS_MAKESELF_PATH:0:1}" != "/" ] && export HIBENCHMARKS_MAKESELF_PATH="$(pwd)/${HIBENCHMARKS_MAKESELF_PATH}"
[ -z "${HIBENCHMARKS_SOURCE_PATH}" ] && export HIBENCHMARKS_SOURCE_PATH="${HIBENCHMARKS_MAKESELF_PATH}/.."
export NULL=

# make sure the path does not end with /
if [ "${HIBENCHMARKS_INSTALL_PATH:$(( ${#HIBENCHMARKS_INSTALL_PATH} - 1)):1}" = "/" ]
    then
    export HIBENCHMARKS_INSTALL_PATH="${HIBENCHMARKS_INSTALL_PATH:0:$(( ${#HIBENCHMARKS_INSTALL_PATH} - 1))}"
fi

# find the parent directory
export HIBENCHMARKS_INSTALL_PARENT="$(dirname "${HIBENCHMARKS_INSTALL_PATH}")"

# -----------------------------------------------------------------------------

# bash strict mode
set -euo pipefail

# -----------------------------------------------------------------------------

fetch() {
    local dir="${1}" url="${2}"
    local tar="${dir}.tar.gz"

    if [ ! -f "${HIBENCHMARKS_MAKESELF_PATH}/tmp/${tar}" ]
        then
        run wget -O "${HIBENCHMARKS_MAKESELF_PATH}/tmp/${tar}" "${url}"
    fi
    
    if [ ! -d "${HIBENCHMARKS_MAKESELF_PATH}/tmp/${dir}" ]
        then
        cd "${HIBENCHMARKS_MAKESELF_PATH}/tmp"
        run tar -zxvpf "${tar}"
        cd -
    fi

    run cd "${HIBENCHMARKS_MAKESELF_PATH}/tmp/${dir}"
}

# -----------------------------------------------------------------------------

# load the functions of the hibenchmarks-installer.sh
. "${HIBENCHMARKS_SOURCE_PATH}/installer/functions.sh"

# -----------------------------------------------------------------------------

# debug
echo "ME=${0}"
echo "HIBENCHMARKS_INSTALL_PARENT=${HIBENCHMARKS_INSTALL_PARENT}"
echo "HIBENCHMARKS_INSTALL_PATH=${HIBENCHMARKS_INSTALL_PATH}"
echo "HIBENCHMARKS_MAKESELF_PATH=${HIBENCHMARKS_MAKESELF_PATH}"
echo "HIBENCHMARKS_SOURCE_PATH=${HIBENCHMARKS_SOURCE_PATH}"
echo "PROCESSORS=${SYSTEM_CPUS}"
