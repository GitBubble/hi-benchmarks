#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0+

export PATH="${PATH}:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
uniquepath() {
    local path=""
    while read
    do
        if [[ ! "${path}" =~ (^|:)"${REPLY}"(:|$) ]]
        then
            [ ! -z "${path}" ] && path="${path}:"
            path="${path}${REPLY}"
        fi
    done < <( echo "${PATH}" | tr ":" "\n" )

    [ ! -z "${path}" ] && [[ "${PATH}" =~ /bin ]] && [[ "${PATH}" =~ /sbin ]] && export PATH="${path}"
}
uniquepath

hibenchmarks_source_dir="$(pwd)"
installer_dir="$(dirname "${0}")"

if [ "${hibenchmarks_source_dir}" != "${installer_dir}" -a "${installer_dir}" != "." ]
    then
    echo >&2 "Warning: you are currently in '${hibenchmarks_source_dir}' but the installer is in '${installer_dir}'."
fi


# -----------------------------------------------------------------------------
# reload the user profile

[ -f /etc/profile ] && . /etc/profile

# make sure /etc/profile does not change our current directory
cd "${hibenchmarks_source_dir}" || exit 1


# -----------------------------------------------------------------------------
# load the required functions

if [ -f "${installer_dir}/installer/functions.sh" ]
    then
    source "${installer_dir}/installer/functions.sh" || exit 1
else
    source "${hibenchmarks_source_dir}/installer/functions.sh" || exit 1
fi

# make sure we save all commands we run
run_logfile="hibenchmarks-installer.log"


# -----------------------------------------------------------------------------
# fix PKG_CHECK_MODULES error

if [ -d /usr/share/aclocal ]
then
        ACLOCAL_PATH=${ACLOCAL_PATH-/usr/share/aclocal}
        export ACLOCAL_PATH
fi

export LC_ALL=C
umask 002

# Be nice on production environments
renice 19 $$ >/dev/null 2>/dev/null

# you can set CFLAGS before running installer
CFLAGS="${CFLAGS--g}"
[ "z${CFLAGS}" = "z-O3" ] && CFLAGS="-g"

# keep a log of this command
printf "\n# " >>hibenchmarks-installer.log
date >>hibenchmarks-installer.log
printf "CFLAGS=\"%s\" " "${CFLAGS}" >>hibenchmarks-installer.log
printf "%q " "$0" "${@}" >>hibenchmarks-installer.log
printf "\n" >>hibenchmarks-installer.log

REINSTALL_PWD="${PWD}"
REINSTALL_COMMAND="$(printf "%q " "$0" "${@}"; printf "\n")"
# remove options that shown not be inherited by hibenchmarks-updater.sh
REINSTALL_COMMAND="${REINSTALL_COMMAND// --dont-wait/}"
REINSTALL_COMMAND="${REINSTALL_COMMAND// --dont-start-it/}"

setcap="$(which setcap 2>/dev/null || command -v setcap 2>/dev/null)"

ME="$0"
DONOTSTART=0
DONOTWAIT=0
AUTOUPDATE=0
HIBENCHMARKS_PREFIX=
LIBS_ARE_HERE=0
HIBENCHMARKS_CONFIGURE_OPTIONS="${HIBENCHMARKS_CONFIGURE_OPTIONS-}"

usage() {
    hibenchmarks_banner "installer command line options"
    cat <<USAGE

${ME} <installer options>

Valid <installer options> are:

   --install /PATH/TO/INSTALL

        If you give: --install /opt
        hibenchmarks will be installed in /opt/hibenchmarks

   --dont-start-it

        Do not (re)start hibenchmarks.
        Just install it.

   --dont-wait

        Do not wait for the user to press ENTER.
        Start immediately building it.

   --auto-update | -u

        Install hibenchmarks-updater to cron,
        to update hibenchmarks automatically once per day
        (can only be done for installations from git)

   --enable-plugin-freeipmi
   --disable-plugin-freeipmi

        Enable/disable the FreeIPMI plugin.
        Default: enable it when libipmimonitoring is available.

   --enable-plugin-nfacct
   --disable-plugin-nfacct

        Enable/disable the nfacct plugin.
        Default: enable it when libmnl and libnetfilter_acct are available.

   --enable-lto
   --disable-lto

        Enable/disable Link-Time-Optimization
        Default: enabled

   --disable-x86-sse

        Disable SSE instructions
        Default: enabled

   --zlib-is-really-here
   --libs-are-really-here

        If you get errors about missing zlib,
        or libuuid but you know it is available,
        you have a broken pkg-config.
        Use this option to allow it continue
        without checking pkg-config.

HiBenchmarks will by default be compiled with gcc optimization -g
If you need to pass different CFLAGS, use something like this:

  CFLAGS="<gcc options>" ${ME} <installer options>

For the installer to complete successfully, you will need
these packages installed:

   gcc make autoconf automake pkg-config zlib1g-dev (or zlib-devel)
   uuid-dev (or libuuid-devel)

For the plugins, you will at least need:

   curl, bash v4+, python v2 or v3, node.js

USAGE
}

md5sum="$(which md5sum 2>/dev/null || command -v md5sum 2>/dev/null || command -v md5 2>/dev/null)"
get_git_config_signatures() {
    local x s file md5

    [ ! -d "conf.d" ] && echo >&2 "Wrong directory." && return 1
    [ -z "${md5sum}" -o ! -x "${md5sum}" ] && echo >&2 "No md5sum command." && return 1

    echo >configs.signatures.tmp

    for x in $(find conf.d -name \*.conf)
    do
            x="${x/conf.d\//}"
            echo "${x}"
            for c in $(git log --follow "conf.d/${x}" | grep ^commit | cut -d ' ' -f 2)
            do
                    git checkout ${c} "conf.d/${x}" || continue
                    s="$(cat "conf.d/${x}" | ${md5sum} | cut -d ' ' -f 1)"
                    echo >>configs.signatures.tmp "${s}:${x}"
                    echo "    ${s}"
            done
            git checkout HEAD "conf.d/${x}" || break
    done

    cat configs.signatures.tmp |\
        grep -v "^$" |\
        sort -u |\
        {
            echo "declare -A configs_signatures=("
            IFS=":"
            while read md5 file
            do
                echo "  ['${md5}']='${file}'"
            done
            echo ")"
        } >configs.signatures

    rm configs.signatures.tmp

    return 0
}


while [ ! -z "${1}" ]
do
    if [ "$1" = "--install" ]
        then
        HIBENCHMARKS_PREFIX="${2}/hibenchmarks"
        shift 2
    elif [ "$1" = "--zlib-is-really-here" -o "$1" = "--libs-are-really-here" ]
        then
        LIBS_ARE_HERE=1
        shift 1
    elif [ "$1" = "--dont-start-it" ]
        then
        DONOTSTART=1
        shift 1
    elif [ "$1" = "--dont-wait" ]
        then
        DONOTWAIT=1
        shift 1
    elif [ "$1" = "--auto-update" -o "$1" = "-u" ]
        then
        AUTOUPDATE=1
        shift 1
    elif [ "$1" = "--enable-plugin-freeipmi" ]
        then
        HIBENCHMARKS_CONFIGURE_OPTIONS="${HIBENCHMARKS_CONFIGURE_OPTIONS//--enable-plugin-freeipmi/} --enable-plugin-freeipmi"
        shift 1
    elif [ "$1" = "--disable-plugin-freeipmi" ]
        then
        HIBENCHMARKS_CONFIGURE_OPTIONS="${HIBENCHMARKS_CONFIGURE_OPTIONS//--disable-plugin-freeipmi/} --disable-plugin-freeipmi"
        shift 1
    elif [ "$1" = "--enable-plugin-nfacct" ]
        then
        HIBENCHMARKS_CONFIGURE_OPTIONS="${HIBENCHMARKS_CONFIGURE_OPTIONS//--enable-plugin-nfacct/} --enable-plugin-nfacct"
        shift 1
    elif [ "$1" = "--disable-plugin-nfacct" ]
        then
        HIBENCHMARKS_CONFIGURE_OPTIONS="${HIBENCHMARKS_CONFIGURE_OPTIONS//--disable-plugin-nfacct/} --disable-plugin-nfacct"
        shift 1
    elif [ "$1" = "--enable-lto" ]
        then
        HIBENCHMARKS_CONFIGURE_OPTIONS="${HIBENCHMARKS_CONFIGURE_OPTIONS//--enable-lto/} --enable-lto"
        shift 1
    elif [ "$1" = "--disable-lto" ]
        then
        HIBENCHMARKS_CONFIGURE_OPTIONS="${HIBENCHMARKS_CONFIGURE_OPTIONS//--disable-lto/} --disable-lto"
        shift 1
    elif [ "$1" = "--disable-x86-sse" ]
        then
        HIBENCHMARKS_CONFIGURE_OPTIONS="${HIBENCHMARKS_CONFIGURE_OPTIONS//--disable-x86-sse/} --disable-x86-sse"
        shift 1
    elif [ "$1" = "--help" -o "$1" = "-h" ]
        then
        usage
        exit 1
    elif [ "$1" = "get_git_config_signatures" ]
        then
        get_git_config_signatures && exit 0
        exit 1
    else
        echo >&2
        echo >&2 "ERROR:"
        echo >&2 "I cannot understand option '$1'."
        usage
        exit 1
    fi
done

# replace multiple spaces with a single space
HIBENCHMARKS_CONFIGURE_OPTIONS="${HIBENCHMARKS_CONFIGURE_OPTIONS//  / }"

hibenchmarks_banner "real-time performance monitoring, done right!"
cat <<BANNER1

  You are about to build and install hibenchmarks to your system.

  It will be installed at these locations:

   - the daemon     at ${TPUT_CYAN}${HIBENCHMARKS_PREFIX}/usr/sbin/hibenchmarks${TPUT_RESET}
   - config files   in ${TPUT_CYAN}${HIBENCHMARKS_PREFIX}/etc/hibenchmarks${TPUT_RESET}
   - web files      in ${TPUT_CYAN}${HIBENCHMARKS_PREFIX}/usr/share/hibenchmarks${TPUT_RESET}
   - plugins        in ${TPUT_CYAN}${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks${TPUT_RESET}
   - cache files    in ${TPUT_CYAN}${HIBENCHMARKS_PREFIX}/var/cache/hibenchmarks${TPUT_RESET}
   - db files       in ${TPUT_CYAN}${HIBENCHMARKS_PREFIX}/var/lib/hibenchmarks${TPUT_RESET}
   - log files      in ${TPUT_CYAN}${HIBENCHMARKS_PREFIX}/var/log/hibenchmarks${TPUT_RESET}
BANNER1

[ "${UID}" -eq 0 ] && cat <<BANNER2
   - pid file       at ${TPUT_CYAN}${HIBENCHMARKS_PREFIX}/var/run/hibenchmarks.pid${TPUT_RESET}
   - logrotate file at ${TPUT_CYAN}/etc/logrotate.d/hibenchmarks${TPUT_RESET}
BANNER2

cat <<BANNER3

  This installer allows you to change the installation path.
  Press Control-C and run the same command with --help for help.

BANNER3

if [ "${UID}" -ne 0 ]
    then
    if [ -z "${HIBENCHMARKS_PREFIX}" ]
        then
        hibenchmarks_banner "wrong command line options!"
        cat <<NONROOTNOPREFIX
  
  ${TPUT_RED}${TPUT_BOLD}Sorry! This will fail!${TPUT_RESET}
  
  You are attempting to install hibenchmarks as non-root, but you plan
  to install it in system paths.
  
  Please set an installation prefix, like this:
  
      $0 ${@} --install /tmp
  
  or, run the installer as root:
  
      sudo $0 ${@}
  
  We suggest to install it as root, or certain data collectors will
  not be able to work. HiBenchmarks drops root privileges when running.
  So, if you plan to keep it, install it as root to get the full
  functionality.
  
NONROOTNOPREFIX
        exit 1

    else
        cat <<NONROOT
 
  ${TPUT_RED}${TPUT_BOLD}IMPORTANT${TPUT_RESET}:
  You are about to install hibenchmarks as a non-root user.
  HiBenchmarks will work, but a few data collection modules that
  require root access will fail.
  
  If you installing hibenchmarks permanently on your system, run
  the installer like this:
  
     ${TPUT_YELLOW}${TPUT_BOLD}sudo $0 ${@}${TPUT_RESET}

NONROOT
    fi
fi

have_autotools=
if [ "$(type autoreconf 2> /dev/null)" ]
then
    autoconf_maj_min() {
        local maj min IFS=.-

        maj=$1
        min=$2

        set -- $(autoreconf -V | sed -ne '1s/.* \([^ ]*\)$/\1/p')
        eval $maj=\$1 $min=\$2
    }
    autoconf_maj_min AMAJ AMIN

    if [ "$AMAJ" -gt 2 ]
    then
        have_autotools=Y
    elif [ "$AMAJ" -eq 2 -a "$AMIN" -ge 60 ]
    then
        have_autotools=Y
    else
        echo "Found autotools $AMAJ.$AMIN"
    fi
else
    echo "No autotools found"
fi

if [ ! "$have_autotools" ]
then
    if [ -f configure ]
    then
        echo "Will skip autoreconf step"
    else
        hibenchmarks_banner "autotools v2.60 required"
        cat <<"EOF"

-------------------------------------------------------------------------------
autotools 2.60 or later is required

Sorry, you do not seem to have autotools 2.60 or later, which is
required to build from the git sources of hibenchmarks.

You can either install a suitable version of autotools and automake
or download a hibenchmarks package which does not have these dependencies.

Source packages where autotools have already been run are available
here:
       https://firehol.org/download/hibenchmarks/

The unsigned/master folder tracks the head of the git tree and released
packages are also available.
EOF
        exit 1
    fi
fi

if [ ${DONOTWAIT} -eq 0 ]
    then
    if [ ! -z "${HIBENCHMARKS_PREFIX}" ]
        then
        eval "read >&2 -ep \$'\001${TPUT_BOLD}${TPUT_GREEN}\002Press ENTER to build and install hibenchmarks to \'\001${TPUT_CYAN}\002${HIBENCHMARKS_PREFIX}\001${TPUT_YELLOW}\002\'\001${TPUT_RESET}\002 > ' -e -r REPLY"
        [ $? -ne 0 ] && exit 1
    else
        eval "read >&2 -ep \$'\001${TPUT_BOLD}${TPUT_GREEN}\002Press ENTER to build and install hibenchmarks to your system\001${TPUT_RESET}\002 > ' -e -r REPLY"
        [ $? -ne 0 ] && exit 1
    fi
fi

build_error() {
    hibenchmarks_banner "sorry, it failed to build..."
    cat <<EOF

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Sorry! hibenchmarks failed to build...

You may need to check these:

1. The package uuid-dev (or libuuid-devel) has to be installed.

   If your system cannot find libuuid, although it is installed
   run me with the option:  --libs-are-really-here

2. The package zlib1g-dev (or zlib-devel) has to be installed.

   If your system cannot find zlib, although it is installed
   run me with the option:  --libs-are-really-here

3. You need basic build tools installed, like:

   gcc make autoconf automake pkg-config

   Autoconf version 2.60 or higher is required.

If you still cannot get it to build, ask for help at github:

   https://github.com/firehol/hibenchmarks/issues


EOF
    trap - EXIT
    exit 1
}

if [ ${LIBS_ARE_HERE} -eq 1 ]
    then
    shift
    echo >&2 "ok, assuming libs are really installed."
    export ZLIB_CFLAGS=" "
    export ZLIB_LIBS="-lz"
    export UUID_CFLAGS=" "
    export UUID_LIBS="-luuid"
fi

trap build_error EXIT


# -----------------------------------------------------------------------------
echo >&2
progress "Run autotools to configure the build environment"

if [ "$have_autotools" ]
then
    run ./autogen.sh || exit 1
fi

run ./configure \
    --prefix="${HIBENCHMARKS_PREFIX}/usr" \
    --sysconfdir="${HIBENCHMARKS_PREFIX}/etc" \
    --localstatedir="${HIBENCHMARKS_PREFIX}/var" \
    --with-zlib \
    --with-math \
    --with-user=hibenchmarks \
    ${HIBENCHMARKS_CONFIGURE_OPTIONS} \
    CFLAGS="${CFLAGS}" || exit 1

# remove the build_error hook
trap - EXIT

# -----------------------------------------------------------------------------
progress "Cleanup compilation directory"

[ -f src/hibenchmarks ] && run make clean

# -----------------------------------------------------------------------------
progress "Compile hibenchmarks"

run make -j${SYSTEM_CPUS} || exit 1


# -----------------------------------------------------------------------------
progress "Migrate configuration files for node.d.plugin and charts.d.plugin"

# migrate existing configuration files
# for node.d and charts.d
if [ -d "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks" ]
    then
    # the configuration directory exists

    if [ ! -d "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/charts.d" ]
        then
        run mkdir "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/charts.d"
    fi

    # move the charts.d config files
    for x in apache ap cpu_apps cpufreq example exim hddtemp load_average mem_apps mysql nginx nut opensips phpfpm postfix sensors squid tomcat
    do
        for y in "" ".old" ".orig"
        do
            if [ -f "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/${x}.conf${y}" -a ! -f "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/charts.d/${x}.conf${y}" ]
                then
                run mv -f "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/${x}.conf${y}" "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/charts.d/${x}.conf${y}"
            fi
        done
    done

    if [ ! -d "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/node.d" ]
        then
        run mkdir "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/node.d"
    fi

    # move the node.d config files
    for x in named sma_webbox snmp
    do
        for y in "" ".old" ".orig"
        do
            if [ -f "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/${x}.conf${y}" -a ! -f "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/node.d/${x}.conf${y}" ]
                then
                run mv -f "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/${x}.conf${y}" "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/node.d/${x}.conf${y}"
            fi
        done
    done
fi

# -----------------------------------------------------------------------------
progress "Backup existing hibenchmarks configuration before installing it"

if [ "${BASH_VERSINFO[0]}" -ge "4" ]
then
    declare -A configs_signatures=()
    if [ -f "configs.signatures" ]
        then
        source "configs.signatures" || echo >&2 "ERROR: Failed to load configs.signatures !"
    fi
fi

config_signature_matches() {
    local md5="${1}" file="${2}"

    if [ "${BASH_VERSINFO[0]}" -ge "4" ]
        then
        [ "${configs_signatures[${md5}]}" = "${file}" ] && return 0
        return 1
    fi

    if [ -f "configs.signatures" ]
        then
        grep "\['${md5}'\]='${file}'" "configs.signatures" >/dev/null
        return $?
    fi

    return 1
}

# backup user configurations
installer_backup_suffix="${PID}.${RANDOM}"
for x in $(find -L "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks" -name '*.conf' -type f)
do
    if [ -f "${x}" ]
        then
        # make a backup of the configuration file
        cp -p "${x}" "${x}.old"

        if [ -z "${md5sum}" -o ! -x "${md5sum}" ]
            then
            # we don't have md5sum - keep it
            echo >&2 "File '${TPUT_CYAN}${x}${TPUT_RESET}' ${TPUT_RET}is not known to distribution${TPUT_RESET}. Keeping it."
            run cp -a "${x}" "${x}.installer_backup.${installer_backup_suffix}"
        else
            # find it relative filename
            f="${x/*\/etc\/hibenchmarks\//}"

            # find its checksum
            md5="$(cat "${x}" | ${md5sum} | cut -d ' ' -f 1)"

            # copy the original
            if [ -f "conf.d/${f}" ]
                then
                cp "conf.d/${f}" "${x}.orig"
            fi

            if config_signature_matches "${md5}" "${f}"
                then
                # it is a stock version - don't keep it
                echo >&2 "File '${TPUT_CYAN}${x}${TPUT_RESET}' is stock version."
            else
                # edited by user - keep it
                echo >&2 "File '${TPUT_CYAN}${x}${TPUT_RESET}' ${TPUT_RED} has been edited by user${TPUT_RESET}. Keeping it."
                run cp -a "${x}" "${x}.installer_backup.${installer_backup_suffix}"
            fi
        fi

    elif [ -f "${x}.installer_backup.${installer_backup_suffix}" ]
        then
        rm -f "${x}.installer_backup.${installer_backup_suffix}"
    fi
done


# -----------------------------------------------------------------------------
progress "Install hibenchmarks"

run make install || exit 1


# -----------------------------------------------------------------------------
progress "Restore user edited hibenchmarks configuration files"

for x in $(find -L "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/" -name '*.conf' -type f)
do
    if [ -f "${x}.installer_backup.${installer_backup_suffix}" ]
        then
        run cp -a "${x}.installer_backup.${installer_backup_suffix}" "${x}" && \
            run rm -f "${x}.installer_backup.${installer_backup_suffix}"
    fi
done


# -----------------------------------------------------------------------------
progress "Fix generated files permissions"

run find ./system/ -type f -a \! -name \*.in -a \! -name Makefile\* -a \! -name \*.conf -a \! -name \*.service -a \! -name \*.logrotate -exec chmod 755 {} \;


# -----------------------------------------------------------------------------
progress "Add user hibenchmarks to required user groups"

homedir="${HIBENCHMARKS_PREFIX}/var/lib/hibenchmarks"
[ ! -z "${HIBENCHMARKS_PREFIX}" ] && homedir="${HIBENCHMARKS_PREFIX}"
add_hibenchmarks_user_and_group "${homedir}" || run_failed "The installer does not run as root."


# -----------------------------------------------------------------------------
progress "Install logrotate configuration for hibenchmarks"

install_hibenchmarks_logrotate


# -----------------------------------------------------------------------------
progress "Read installation options from hibenchmarks.conf"

# create an empty config if it does not exist
[ ! -f "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/hibenchmarks.conf" ] && \
    touch "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/hibenchmarks.conf"

# function to extract values from the config file
config_option() {
    local section="${1}" key="${2}" value="${3}"

    if [ -s "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/hibenchmarks.conf" ]
        then
        "${HIBENCHMARKS_PREFIX}/usr/sbin/hibenchmarks" \
            -c "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/hibenchmarks.conf" \
            -W get "${section}" "${key}" "${value}" || \
            echo "${value}"
    else
        echo "${value}"
    fi
}

# the user hibenchmarks will run as
if [ "${UID}" = "0" ]
    then
    HIBENCHMARKS_USER="$( config_option "global" "run as user" "hibenchmarks" )"
    ROOT_USER="root"
else
    HIBENCHMARKS_USER="${USER}"
    ROOT_USER="${HIBENCHMARKS_USER}"
fi
HIBENCHMARKS_GROUP="$(id -g -n ${HIBENCHMARKS_USER})"
[ -z "${HIBENCHMARKS_GROUP}" ] && HIBENCHMARKS_GROUP="${HIBENCHMARKS_USER}"

# the owners of the web files
HIBENCHMARKS_WEB_USER="$(  config_option "web" "web files owner" "${HIBENCHMARKS_USER}" )"
HIBENCHMARKS_WEB_GROUP="${HIBENCHMARKS_GROUP}"
if [ "${UID}" = "0" -a "${HIBENCHMARKS_USER}" != "${HIBENCHMARKS_WEB_USER}" ]
then
    HIBENCHMARKS_WEB_GROUP="$(id -g -n ${HIBENCHMARKS_WEB_USER})"
    [ -z "${HIBENCHMARKS_WEB_GROUP}" ] && HIBENCHMARKS_WEB_GROUP="${HIBENCHMARKS_WEB_USER}"
fi
HIBENCHMARKS_WEB_GROUP="$( config_option "web" "web files group" "${HIBENCHMARKS_WEB_GROUP}" )"

# port
defport=19999
HIBENCHMARKS_PORT="$( config_option "web" "default port" ${defport} )"

# directories
HIBENCHMARKS_LIB_DIR="$( config_option "global" "lib directory" "${HIBENCHMARKS_PREFIX}/var/lib/hibenchmarks" )"
HIBENCHMARKS_CACHE_DIR="$( config_option "global" "cache directory" "${HIBENCHMARKS_PREFIX}/var/cache/hibenchmarks" )"
HIBENCHMARKS_WEB_DIR="$( config_option "global" "web files directory" "${HIBENCHMARKS_PREFIX}/usr/share/hibenchmarks/web" )"
HIBENCHMARKS_LOG_DIR="$( config_option "global" "log directory" "${HIBENCHMARKS_PREFIX}/var/log/hibenchmarks" )"
HIBENCHMARKS_CONF_DIR="$( config_option "global" "config directory" "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks" )"
HIBENCHMARKS_RUN_DIR="${HIBENCHMARKS_PREFIX}/var/run"

cat <<OPTIONSEOF

    Permissions
    - hibenchmarks user     : ${HIBENCHMARKS_USER}
    - hibenchmarks group    : ${HIBENCHMARKS_GROUP}
    - web files user   : ${HIBENCHMARKS_WEB_USER}
    - web files group  : ${HIBENCHMARKS_WEB_GROUP}
    - root user        : ${ROOT_USER}

    Directories
    - hibenchmarks conf dir : ${HIBENCHMARKS_CONF_DIR}
    - hibenchmarks log dir  : ${HIBENCHMARKS_LOG_DIR}
    - hibenchmarks run dir  : ${HIBENCHMARKS_RUN_DIR}
    - hibenchmarks lib dir  : ${HIBENCHMARKS_LIB_DIR}
    - hibenchmarks web dir  : ${HIBENCHMARKS_WEB_DIR}
    - hibenchmarks cache dir: ${HIBENCHMARKS_CACHE_DIR}

    Other
    - hibenchmarks port     : ${HIBENCHMARKS_PORT}

OPTIONSEOF

# -----------------------------------------------------------------------------
progress "Fix permissions of hibenchmarks directories (using user '${HIBENCHMARKS_USER}')"

if [ ! -d "${HIBENCHMARKS_RUN_DIR}" ]
    then
    # this is needed if HIBENCHMARKS_PREFIX is not empty
    run mkdir -p "${HIBENCHMARKS_RUN_DIR}" || exit 1
fi

# --- conf dir ----

for x in "python.d" "charts.d" "node.d"
do
    if [ ! -d "${HIBENCHMARKS_CONF_DIR}/${x}" ]
        then
        echo >&2 "Creating directory '${HIBENCHMARKS_CONF_DIR}/${x}'"
        run mkdir -p "${HIBENCHMARKS_CONF_DIR}/${x}" || exit 1
    fi
done
run chown -R "${ROOT_USER}:${HIBENCHMARKS_GROUP}" "${HIBENCHMARKS_CONF_DIR}"
run find "${HIBENCHMARKS_CONF_DIR}" -type f -exec chmod 0640 {} \;
run find "${HIBENCHMARKS_CONF_DIR}" -type d -exec chmod 0755 {} \;

# --- web dir ----

if [ ! -d "${HIBENCHMARKS_WEB_DIR}" ]
    then
    echo >&2 "Creating directory '${HIBENCHMARKS_WEB_DIR}'"
    run mkdir -p "${HIBENCHMARKS_WEB_DIR}" || exit 1
fi
run chown -R "${HIBENCHMARKS_WEB_USER}:${HIBENCHMARKS_WEB_GROUP}" "${HIBENCHMARKS_WEB_DIR}"
run find "${HIBENCHMARKS_WEB_DIR}" -type f -exec chmod 0664 {} \;
run find "${HIBENCHMARKS_WEB_DIR}" -type d -exec chmod 0775 {} \;

# --- data dirs ----

for x in "${HIBENCHMARKS_LIB_DIR}" "${HIBENCHMARKS_CACHE_DIR}" "${HIBENCHMARKS_LOG_DIR}"
do
    if [ ! -d "${x}" ]
        then
        echo >&2 "Creating directory '${x}'"
        run mkdir -p "${x}" || exit 1
    fi

    run chown -R "${HIBENCHMARKS_USER}:${HIBENCHMARKS_GROUP}" "${x}"
    #run find "${x}" -type f -exec chmod 0660 {} \;
    #run find "${x}" -type d -exec chmod 0770 {} \;
done

run chmod 755 "${HIBENCHMARKS_LOG_DIR}"

# --- plugins ----

if [ ${UID} -eq 0 ]
    then
    # find the admin group
    admin_group=
    test -z "${admin_group}" && getent group root >/dev/null 2>&1 && admin_group="root"
    test -z "${admin_group}" && getent group daemon >/dev/null 2>&1 && admin_group="daemon"
    test -z "${admin_group}" && admin_group="${HIBENCHMARKS_GROUP}"

    run chown "${HIBENCHMARKS_USER}:${admin_group}" "${HIBENCHMARKS_LOG_DIR}"
    run chown -R root "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks"
    run find "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks" -type d -exec chmod 0755 {} \;
    run find "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks" -type f -exec chmod 0644 {} \;
    run find "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks" -type f -a -name \*.plugin -exec chmod 0755 {} \;
    run find "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks" -type f -a -name \*.sh -exec chmod 0755 {} \;

    if [ -f "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/apps.plugin" ]
    then
        setcap_ret=1
        if ! iscontainer
            then
            if [ ! -z "${setcap}" ]
                then
                run chown root:${HIBENCHMARKS_GROUP} "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/apps.plugin"
                run chmod 0750 "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/apps.plugin"
                run setcap cap_dac_read_search,cap_sys_ptrace+ep "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/apps.plugin"
                setcap_ret=$?
            fi

            if [ ${setcap_ret} -eq 0 ]
                then
                # if we managed to setcap
                # but we fail to execute apps.plugin
                # trigger setuid to root
                "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/apps.plugin" -t >/dev/null 2>&1
                setcap_ret=$?
            fi
        fi

        if [ ${setcap_ret} -ne 0 ]
            then
            # fix apps.plugin to be setuid to root
            run chown root:${HIBENCHMARKS_GROUP} "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/apps.plugin"
            run chmod 4750 "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/apps.plugin"
        fi
    fi

    if [ -f "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/freeipmi.plugin" ]
        then
        run chown root:${HIBENCHMARKS_GROUP} "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/freeipmi.plugin"
        run chmod 4750 "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/freeipmi.plugin"
    fi

    if [ -f "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/cgroup-network" ]
        then
        run chown root:${HIBENCHMARKS_GROUP} "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/cgroup-network"
        run chmod 4750 "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/cgroup-network"
    fi

    if [ -f "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/cgroup-network-helper.sh" ]
        then
        run chown root "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/cgroup-network-helper.sh"
        run chmod 0550 "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/cgroup-network-helper.sh"
    fi

else
    # non-privileged user installation
    run chown "${HIBENCHMARKS_USER}:${HIBENCHMARKS_GROUP}" "${HIBENCHMARKS_LOG_DIR}"
    run chown -R "${HIBENCHMARKS_USER}:${HIBENCHMARKS_GROUP}" "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks"
    run find "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks" -type f -exec chmod 0755 {} \;
    run find "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks" -type d -exec chmod 0755 {} \;
fi

# --- fix #1292 bug ---

[ -d "${HIBENCHMARKS_PREFIX}/usr/libexec" ]       && run chmod a+rX "${HIBENCHMARKS_PREFIX}/usr/libexec"
[ -d "${HIBENCHMARKS_PREFIX}/usr/share/hibenchmarks" ] && run chmod a+rX "${HIBENCHMARKS_PREFIX}/usr/share/hibenchmarks"



# -----------------------------------------------------------------------------
progress "Install hibenchmarks at system init"

HIBENCHMARKS_START_CMD="${HIBENCHMARKS_PREFIX}/usr/sbin/hibenchmarks"
install_hibenchmarks_service || run_failed "Cannot install hibenchmarks init service."


# -----------------------------------------------------------------------------
# check if we can re-start hibenchmarks

started=0
if [ ${DONOTSTART} -eq 1 ]
    then
    generate_hibenchmarks_conf "${HIBENCHMARKS_USER}" "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/hibenchmarks.conf" "http://localhost:${HIBENCHMARKS_PORT}/hibenchmarks.conf"

else
    restart_hibenchmarks ${HIBENCHMARKS_PREFIX}/usr/sbin/hibenchmarks "${@}"
    if [ $? -ne 0 ]
        then
        echo >&2
        echo >&2 "SORRY! FAILED TO START HIBENCHMARKS!"
        echo >&2
        exit 1
    fi

    started=1
    echo >&2 "OK. HiBenchmarks Started!"
    echo >&2

    # -----------------------------------------------------------------------------
    # save a config file, if it is not already there

    download_hibenchmarks_conf "${HIBENCHMARKS_USER}" "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks/hibenchmarks.conf" "http://localhost:${HIBENCHMARKS_PORT}/hibenchmarks.conf"
fi

if [ "$(uname)" = "Linux" ]
then
    # -------------------------------------------------------------------------
    progress "Check KSM (kernel memory deduper)"

    ksm_is_available_but_disabled() {
        cat <<KSM1

${TPUT_BOLD}Memory de-duplication instructions${TPUT_RESET}

You have kernel memory de-duper (called Kernel Same-page Merging,
or KSM) available, but it is not currently enabled.

To enable it run:

    ${TPUT_YELLOW}${TPUT_BOLD}echo 1 >/sys/kernel/mm/ksm/run${TPUT_RESET}
    ${TPUT_YELLOW}${TPUT_BOLD}echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs${TPUT_RESET}

If you enable it, you will save 40-60% of hibenchmarks memory.

KSM1
    }

    ksm_is_not_available() {
        cat <<KSM2

${TPUT_BOLD}Memory de-duplication not present in your kernel${TPUT_RESET}

It seems you do not have kernel memory de-duper (called Kernel Same-page
Merging, or KSM) available.

To enable it, you need a kernel built with CONFIG_KSM=y

If you can have it, you will save 40-60% of hibenchmarks memory.

KSM2
    }

    if [ -f "/sys/kernel/mm/ksm/run" ]
        then
        if [ $(cat "/sys/kernel/mm/ksm/run") != "1" ]
            then
            ksm_is_available_but_disabled
        fi
    else
        ksm_is_not_available
    fi
fi


# -----------------------------------------------------------------------------
progress "Check version.txt"

if [ ! -s web/version.txt ]
    then
    cat <<VERMSG

${TPUT_BOLD}Version update check warning${TPUT_RESET}

The way you downloaded hibenchmarks, we cannot find its version. This means the
Update check on the dashboard, will not work.

If you want to have version update check, please re-install it
following the procedure in:

https://github.com/firehol/hibenchmarks/wiki/Installation

VERMSG
fi

if [ -f "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/apps.plugin" ]
then
    # -----------------------------------------------------------------------------
    progress "Check apps.plugin"

    if [ "${UID}" -ne 0 ]
        then
        cat <<SETUID_WARNING

${TPUT_BOLD}apps.plugin needs privileges${TPUT_RESET}

Since you have installed hibenchmarks as a normal user, to have apps.plugin collect
all the needed data, you have to give it the access rights it needs, by running
either of the following sets of commands:

To run apps.plugin with escalated capabilities:

    ${TPUT_YELLOW}${TPUT_BOLD}sudo chown root:${HIBENCHMARKS_GROUP} \"${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/apps.plugin\"${TPUT_RESET}
    ${TPUT_YELLOW}${TPUT_BOLD}sudo chmod 0750 \"${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/apps.plugin\"${TPUT_RESET}
    ${TPUT_YELLOW}${TPUT_BOLD}sudo setcap cap_dac_read_search,cap_sys_ptrace+ep \"${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/apps.plugin\"${TPUT_RESET}

or, to run apps.plugin as root:

    ${TPUT_YELLOW}${TPUT_BOLD}sudo chown root:${HIBENCHMARKS_GROUP} \"${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/apps.plugin\"${TPUT_RESET}
    ${TPUT_YELLOW}${TPUT_BOLD}sudo chmod 4750 \"${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks/plugins.d/apps.plugin\"${TPUT_RESET}

apps.plugin is performing a hard-coded function of data collection for all
running processes. It cannot be instructed from the hibenchmarks daemon to perform
any task, so it is pretty safe to do this.

SETUID_WARNING
    fi
fi

# -----------------------------------------------------------------------------
progress "Generate hibenchmarks-uninstaller.sh"

cat >hibenchmarks-uninstaller.sh <<UNINSTALL
#!/usr/bin/env bash

# this script will uninstall hibenchmarks

if [ "\$1" != "--force" ]
    then
    echo >&2 "This script will REMOVE hibenchmarks from your system."
    echo >&2 "Run it again with --force to do it."
    exit 1
fi

source installer/functions.sh || exit 1

echo >&2 "Stopping a possibly running hibenchmarks..."
for p in \$(pidof hibenchmarks); do run kill \$p; done
sleep 2

if [ ! -z "${HIBENCHMARKS_PREFIX}" -a -d "${HIBENCHMARKS_PREFIX}" ]
    then
    # installation prefix was given

    portable_deletedir_recursively_interactively "${HIBENCHMARKS_PREFIX}"

else
    # installation prefix was NOT given

    if [ -f "${HIBENCHMARKS_PREFIX}/usr/sbin/hibenchmarks" ]
        then
        echo "Deleting ${HIBENCHMARKS_PREFIX}/usr/sbin/hibenchmarks ..."
        run rm -i "${HIBENCHMARKS_PREFIX}/usr/sbin/hibenchmarks"
    fi

    portable_deletedir_recursively_interactively "${HIBENCHMARKS_PREFIX}/etc/hibenchmarks"
    portable_deletedir_recursively_interactively "${HIBENCHMARKS_PREFIX}/usr/share/hibenchmarks"
    portable_deletedir_recursively_interactively "${HIBENCHMARKS_PREFIX}/usr/libexec/hibenchmarks"
    portable_deletedir_recursively_interactively "${HIBENCHMARKS_PREFIX}/var/lib/hibenchmarks"
    portable_deletedir_recursively_interactively "${HIBENCHMARKS_PREFIX}/var/cache/hibenchmarks"
    portable_deletedir_recursively_interactively "${HIBENCHMARKS_PREFIX}/var/log/hibenchmarks"
fi

if [ -f /etc/logrotate.d/hibenchmarks ]
    then
    echo "Deleting /etc/logrotate.d/hibenchmarks ..."
    run rm -i /etc/logrotate.d/hibenchmarks
fi

if [ -f /etc/systemd/system/hibenchmarks.service ]
    then
    echo "Deleting /etc/systemd/system/hibenchmarks.service ..."
    run rm -i /etc/systemd/system/hibenchmarks.service
fi

if [ -f /etc/init.d/hibenchmarks ]
    then
    echo "Deleting /etc/init.d/hibenchmarks ..."
    run rm -i /etc/init.d/hibenchmarks
fi

if [ -f /etc/periodic/daily/hibenchmarks-updater ]
    then
    echo "Deleting /etc/periodic/daily/hibenchmarks-updater ..."
    run rm -i /etc/periodic/daily/hibenchmarks-updater
fi

if [ -f /etc/cron.daily/hibenchmarks-updater ]
    then
    echo "Deleting /etc/cron.daily/hibenchmarks-updater ..."
    run rm -i /etc/cron.daily/hibenchmarks-updater
fi

portable_check_user_exists hibenchmarks
if [ \$? -eq 0 ]
    then
    echo
    echo "You may also want to remove the user hibenchmarks"
    echo "by running:"
    echo "   userdel hibenchmarks"
fi

portable_check_group_exists hibenchmarks > /dev/null
if [ \$? -eq 0 ]
    then
    echo
    echo "You may also want to remove the group hibenchmarks"
    echo "by running:"
    echo "   groupdel hibenchmarks"
fi

for g in ${HIBENCHMARKS_ADDED_TO_GROUPS}
do
    portable_check_group_exists \$g > /dev/null
    if [ \$? -eq 0 ]
        then
        echo
        echo "You may also want to remove the hibenchmarks user from the \$g group"
        echo "by running:"
        echo "   gpasswd -d hibenchmarks \$g"
    fi
done

UNINSTALL
chmod 750 hibenchmarks-uninstaller.sh

# -----------------------------------------------------------------------------
progress "Basic hibenchmarks instructions"

cat <<END

hibenchmarks by default listens on all IPs on port ${HIBENCHMARKS_PORT},
so you can access it with:

  ${TPUT_CYAN}${TPUT_BOLD}http://this.machine.ip:${HIBENCHMARKS_PORT}/${TPUT_RESET}

To stop hibenchmarks run:

  ${TPUT_YELLOW}${TPUT_BOLD}${HIBENCHMARKS_STOP_CMD}${TPUT_RESET}

To start hibenchmarks run:

  ${TPUT_YELLOW}${TPUT_BOLD}${HIBENCHMARKS_START_CMD}${TPUT_RESET}


END
echo >&2 "Uninstall script generated: ${TPUT_RED}${TPUT_BOLD}./hibenchmarks-uninstaller.sh${TPUT_RESET}"

if [ -d .git ]
    then
    cat >hibenchmarks-updater.sh.new <<REINSTALL
#!/usr/bin/env bash

force=0
[ "\${1}" = "-f" ] && force=1

export PATH="\${PATH}:${PATH}"
export CFLAGS="${CFLAGS}"
export HIBENCHMARKS_CONFIGURE_OPTIONS="${HIBENCHMARKS_CONFIGURE_OPTIONS}"

# make sure we have a UID
[ -z "\${UID}" ] && UID="\$(id -u)"
INSTALL_UID="${UID}"
if [ "\${INSTALL_UID}" != "\${UID}" ]
    then
    echo >&2 "This script should be run as user with uid \${INSTALL_UID} but it now runs with uid \${UID}"
    exit 1
fi

# make sure we cd to the working directory
cd "${REINSTALL_PWD}" || exit 1

# make sure there is .git here
[ \${force} -eq 0 -a ! -d .git ] && echo >&2 "No git structures found at: ${REINSTALL_PWD} (use -f for force re-install)" && exit 1

# signal hibenchmarks to start saving its database
# this is handy if your database is big
pids=\$(pidof hibenchmarks)
do_not_start=
if [ ! -z "\${pids}" ]
    then
    kill -USR1 \${pids}
else
    # hibenchmarks is currently not running, so do not start it after updating
    do_not_start="--dont-start-it"
fi

tmp=
if [ -t 2 ]
    then
    # we are running on a terminal
    # open fd 3 and send it to stderr
    exec 3>&2
else
    # we are headless
    # create a temporary file for the log
    tmp=\$(mktemp /tmp/hibenchmarks-updater.log.XXXXXX)
    # open fd 3 and send it to tmp
    exec 3>\${tmp}
fi

info() {
    echo >&3 "\$(date) : INFO: " "\${@}"
}

emptyline() {
    echo >&3
}

error() {
    echo >&3 "\$(date) : ERROR: " "\${@}"
}

# this is what we will do if it fails (head-less only)
failed() {
    error "FAILED TO UPDATE HIBENCHMARKS : \${1}"

    if [ ! -z "\${tmp}" ]
    then
        cat >&2 "\${tmp}"
        rm "\${tmp}"
    fi
    exit 1
}

get_latest_commit_id() {
	git rev-parse HEAD 2>&3
}

update() {
    [ -z "\${tmp}" ] && info "Running on a terminal - (this script also supports running headless from crontab)"

    emptyline

    if [ -d .git ]
        then
        info "Updating hibenchmarks source from github..."

        last_commit="\$(get_latest_commit_id)"
        [ \${force} -eq 0 -a -z "\${last_commit}" ] && failed "CANNOT GET LAST COMMIT ID (use -f for force re-install)"

        git pull >&3 2>&3 || failed "CANNOT FETCH LATEST SOURCE (use -f for force re-install)"

        new_commit="\$(get_latest_commit_id)"
        if [ \${force} -eq 0 ]
            then
            [ -z "\${new_commit}" ] && failed "CANNOT GET NEW LAST COMMIT ID (use -f for force re-install)"
            [ "\${new_commit}" = "\${last_commit}" ] && info "Nothing to be done! (use -f to force re-install)" && exit 0
        fi
    elif [ \${force} -eq 0 ]
        then
        failed "CANNOT FIND GIT STRUCTURES IN \$(pwd) (use -f for force re-install)"
    fi

    emptyline
    info "Re-installing hibenchmarks..."
    ${REINSTALL_COMMAND} --dont-wait \${do_not_start} >&3 2>&3 || failed "FAILED TO COMPILE/INSTALL HIBENCHMARKS"

    [ ! -z "\${tmp}" ] && rm "\${tmp}" && tmp=
    return 0
}

# the installer updates this script - so we run and exit in a single line
update && exit 0
###############################################################################
###############################################################################
REINSTALL
    chmod 755 hibenchmarks-updater.sh.new
    mv -f hibenchmarks-updater.sh.new hibenchmarks-updater.sh
    echo >&2 "Update script generated   : ${TPUT_GREEN}${TPUT_BOLD}./hibenchmarks-updater.sh${TPUT_RESET}"
    echo >&2
    echo >&2 "${TPUT_DIM}${TPUT_BOLD}hibenchmarks-updater.sh${TPUT_RESET}${TPUT_DIM} can work from cron. It will trigger an email from cron"
    echo >&2 "only if it fails (it does not print anything when it can update hibenchmarks).${TPUT_RESET}"
    if [ "${UID}" -eq "0" ]
    then
        crondir=
        [ -d "/etc/periodic/daily" ] && crondir="/etc/periodic/daily"
        [ -d "/etc/cron.daily" ] && crondir="/etc/cron.daily"

        if [ ! -z "${crondir}" ]
        then
            if [ -f "${crondir}/hibenchmarks-updater.sh" -a ! -f "${crondir}/hibenchmarks-updater" ]
            then
                # remove .sh from the filename under cron
                progress "Fixing hibenchmarks-updater filename at cron"
                mv -f "${crondir}/hibenchmarks-updater.sh" "${crondir}/hibenchmarks-updater"
            fi

            if [ ! -f "${crondir}/hibenchmarks-updater" ]
            then
                if [ "${AUTOUPDATE}" = "1" ]
                then
                    progress "Installing hibenchmarks-updater at cron"
                    run ln -s "${PWD}/hibenchmarks-updater.sh" "${crondir}/hibenchmarks-updater"
                else
                    echo >&2 "${TPUT_DIM}Run this to automatically check and install hibenchmarks updates once per day:${TPUT_RESET}"
                    echo >&2
                    echo >&2 "${TPUT_YELLOW}${TPUT_BOLD}sudo ln -s ${PWD}/hibenchmarks-updater.sh ${crondir}/hibenchmarks-updater${TPUT_RESET}"
                fi
            else
                progress "Refreshing hibenchmarks-updater at cron"
                run rm "${crondir}/hibenchmarks-updater"
                run ln -s "${PWD}/hibenchmarks-updater.sh" "${crondir}/hibenchmarks-updater"
            fi
        else
            [ "${AUTOUPDATE}" = "1" ] && echo >&2 "Cannot figure out the cron directory to install hibenchmarks-updater."
        fi
    else
        [ "${AUTOUPDATE}" = "1" ] && echo >&2 "You need to run the installer as root for auto-updating via cron."
    fi
else
    [ -f "hibenchmarks-updater.sh" ] && rm "hibenchmarks-updater.sh"
    [ "${AUTOUPDATE}" = "1" ] && echo >&2 "Your installation method does not support daily auto-updating via cron."
fi

# -----------------------------------------------------------------------------
echo >&2
progress "We are done!"

if [ ${started} -eq 1 ]
    then
    hibenchmarks_banner "is installed and running now!"
else
    hibenchmarks_banner "is installed now!"
fi

echo >&2 "  enjoy real-time performance and health monitoring..."
echo >&2 
exit 0
