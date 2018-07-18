#!/usr/bin/env bash

# hibenchmarks
# real-time performance and health monitoring, done right!
# (C) 2017 Costa Tsaousis <costa@tsaousis.gr>
# SPDX-License-Identifier: GPL-3.0+
#
# Script to test alarm notifications for hibenchmarks

dir="$(dirname "${0}")"
${dir}/alarm-notify.sh test "${1}"
exit $?
