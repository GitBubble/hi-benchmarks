#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0+

. $(dirname "${0}")/../functions.sh "${@}" || exit 1

run cd "${HIBENCHMARKS_SOURCE_PATH}" || exit 1

# -----------------------------------------------------------------------------
# find the hibenchmarks version

NOWNER="unknown"
ORIGIN="$(git config --get remote.origin.url || echo "unknown")"
if [[ "${ORIGIN}" =~ ^git@github.com:.*/hibenchmarks.*$ ]]
    then
    NOWNER="${ORIGIN/git@github.com:/}"
    NOWNER="${NOWNER/\/hibenchmarks*/}"

elif [[ "${ORIGIN}" =~ ^https://github.com/.*/hibenchmarks.*$ ]]
    then
    NOWNER="${ORIGIN/https:\/\/github.com\//}"
    NOWNER="${NOWNER/\/hibenchmarks*/}"
fi

# make sure it does not have any slashes in it
NOWNER="${NOWNER//\//_}"

if [ "${NOWNER}" = "firehol" ]
    then
    NOWNER=
else
    NOWNER="-${NOWNER}"
fi

VERSION="$(git describe || echo "undefined")"
[ -z "${VERSION}" ] && VERSION="undefined"

FILE_VERSION="${VERSION}-$(uname -m)-$(date +"%Y%m%d-%H%M%S")${NOWNER}"


# -----------------------------------------------------------------------------
# copy the files needed by makeself installation

run mkdir -p "${HIBENCHMARKS_INSTALL_PATH}/system"

run cp \
    makeself/post-installer.sh \
    makeself/install-or-update.sh \
    installer/functions.sh \
    configs.signatures \
    system/hibenchmarks-init-d \
    system/hibenchmarks-lsb \
    system/hibenchmarks-openrc \
    system/hibenchmarks.logrotate \
    system/hibenchmarks.service \
    "${HIBENCHMARKS_INSTALL_PATH}/system/"


# -----------------------------------------------------------------------------
# create a wrapper to start our hibenchmarks with a modified path

run mkdir -p "${HIBENCHMARKS_INSTALL_PATH}/bin/srv"

run mv "${HIBENCHMARKS_INSTALL_PATH}/bin/hibenchmarks" \
    "${HIBENCHMARKS_INSTALL_PATH}/bin/srv/hibenchmarks" || exit 1

cat >"${HIBENCHMARKS_INSTALL_PATH}/bin/hibenchmarks" <<EOF
#!${HIBENCHMARKS_INSTALL_PATH}/bin/bash
export HIBENCHMARKS_BASH_LOADABLES="DISABLE"
export PATH="${HIBENCHMARKS_INSTALL_PATH}/bin:\${PATH}"
exec "${HIBENCHMARKS_INSTALL_PATH}/bin/srv/hibenchmarks" "\${@}"
EOF
run chmod 755 "${HIBENCHMARKS_INSTALL_PATH}/bin/hibenchmarks"


# -----------------------------------------------------------------------------
# move etc to protect the destination when unpacked

if [ ! -z "${HIBENCHMARKS_INSTALL_PATH}" -a -d "${HIBENCHMARKS_INSTALL_PATH}/etc" ]
    then
    if [ -d "${HIBENCHMARKS_INSTALL_PATH}/etc.new" ]
        then
        run rm -rf "${HIBENCHMARKS_INSTALL_PATH}/etc.new" || exit 1
    fi

    run mv "${HIBENCHMARKS_INSTALL_PATH}/etc" \
        "${HIBENCHMARKS_INSTALL_PATH}/etc.new" || exit 1

    if [ -f "${HIBENCHMARKS_INSTALL_PATH}/etc.new/hibenchmarks/hibenchmarks.conf" ]
        then
        # delete the generated hibenchmarks.conf, so that the static installer will generate a new one
        run rm "${HIBENCHMARKS_INSTALL_PATH}/etc.new/hibenchmarks/hibenchmarks.conf"
    fi
fi


# -----------------------------------------------------------------------------
# remove the links to allow untaring the archive

run rm "${HIBENCHMARKS_INSTALL_PATH}/sbin" \
    "${HIBENCHMARKS_INSTALL_PATH}/usr/bin" \
    "${HIBENCHMARKS_INSTALL_PATH}/usr/sbin" \
    "${HIBENCHMARKS_INSTALL_PATH}/usr/local"


# -----------------------------------------------------------------------------
# create the makeself archive

run sed "s|HIBENCHMARKS_VERSION|${FILE_VERSION}|g" <"${HIBENCHMARKS_MAKESELF_PATH}/makeself.lsm" >"${HIBENCHMARKS_MAKESELF_PATH}/makeself.lsm.tmp"

run "${HIBENCHMARKS_MAKESELF_PATH}/makeself.sh" \
    --gzip \
    --complevel 9 \
    --notemp \
    --needroot \
    --target "${HIBENCHMARKS_INSTALL_PATH}" \
    --header "${HIBENCHMARKS_MAKESELF_PATH}/makeself-header.sh" \
    --lsm "${HIBENCHMARKS_MAKESELF_PATH}/makeself.lsm.tmp" \
    --license "${HIBENCHMARKS_MAKESELF_PATH}/makeself-license.txt" \
    --help-header "${HIBENCHMARKS_MAKESELF_PATH}/makeself-help-header.txt" \
    "${HIBENCHMARKS_INSTALL_PATH}" \
    "${HIBENCHMARKS_INSTALL_PATH}.gz.run" \
    "hibenchmarks, the real-time performance and health monitoring system" \
    ./system/post-installer.sh \
    ${NULL}

run rm "${HIBENCHMARKS_MAKESELF_PATH}/makeself.lsm.tmp"

# -----------------------------------------------------------------------------
# copy it to the hibenchmarks build dir

FILE="hibenchmarks-${FILE_VERSION}.gz.run"

run cp "${HIBENCHMARKS_INSTALL_PATH}.gz.run" "${FILE}"
echo >&2 "Self-extracting installer copied to '${FILE}'"

[ -f hibenchmarks-latest.gz.run ] && rm hibenchmarks-latest.gz.run
run ln -s "${FILE}" hibenchmarks-latest.gz.run
echo >&2 "Self-extracting installer linked to 'hibenchmarks-latest.gz.run'"
