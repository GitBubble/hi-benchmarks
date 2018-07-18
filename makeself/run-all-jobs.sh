#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0+

LC_ALL=C
umask 002

# be nice
renice 19 $$ >/dev/null 2>/dev/null

# -----------------------------------------------------------------------------
# prepare the environment for the jobs

# installation directory
export HIBENCHMARKS_INSTALL_PATH="${1-/opt/hibenchmarks}"

# our source directory
export HIBENCHMARKS_MAKESELF_PATH="$(dirname "${0}")"
if [ "${HIBENCHMARKS_MAKESELF_PATH:0:1}" != "/" ]
	then
	export HIBENCHMARKS_MAKESELF_PATH="$(pwd)/${HIBENCHMARKS_MAKESELF_PATH}"
fi

# hibenchmarks source directory
export HIBENCHMARKS_SOURCE_PATH="${HIBENCHMARKS_MAKESELF_PATH}/.."

# make sure ${NULL} is empty
export NULL=

# -----------------------------------------------------------------------------

cd "${HIBENCHMARKS_MAKESELF_PATH}" || exit 1

. ./functions.sh "${@}" || exit 1

for x in jobs/*.install.sh
do
	progress "running ${x}"
	"${x}" "${HIBENCHMARKS_INSTALL_PATH}"
done

echo >&2 "All jobs for static packaging done successfully."
exit 0
