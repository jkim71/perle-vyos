#!/bin/bash
CWD=$(pwd)

C_DEF=$(tput sgr0) #"\e[0m"
C_BOLD=$(tput bold)
C_RED=$(tput setaf 1) #"\e[31m"
C_GREEN=$(tput setaf 2) #"\e[32m"
C_YELLOW=$(tput setaf 3) #"\e[33m"
C_BLUE=$(tput setaf 4) #"\e[34m"
C_MAGENTA=$(tput setaf 5) #"\e[35m"
C_CYAN=$(tput setaf 6) #"\e[36m"
C_WHITE=$(tput setaf 7)

PLATFORM=(
    "bookworm-am64xx-evm"
    "bookworm-j7200-evm"
)

# As we run this script in docker environment, we don't need sudo password
READ_SUDO_PIN=false

# BASE_DIR=$(dirname ${CWD})
BUILD_BY="$(git config user.email)"
VYOS_BUILD_DIR=vyos-build
VYOS_PKG_DIR=scripts/package-build
PATCH_DIR=${CWD}/patches
set -e

packages=(
    "ethtool"
    "telegraf"
    "owamp"
#    "net-snmp"
    "frr"
    "frr_exporter"
    "strongswan"
    "openvpn-otp"
    "aws-gwlbtun"
    "node_exporter"
    "blackbox_exporter"
    "podman"
    "ddclient"
#    "dropbear"
#    "hostap"
#    "kea"
#    "keepalived"
#    "netfilter"
#    "pmacct"
#    "radvd"
    "isc-dhcp"
#    "ndppd"
#    "hsflowd"
#    "pyhumps"
#    "opennhrp"
#    "pam_tacplus"
    "vpp"
    "vyos-1x"
    "vyos"
#    "waagent"
#    "wide-dhcpv6"
#    "xen-guest-agent"
    "linux-kernel"
    "debian-ti"
    "mwifiex"
    "libgpiod"
)

#if [ "$EUID" -ne 0 ] ; then
#    echo "Failed to run: requires root privileges"
#    echo "Exiting"
#    exit -1
#fi

if [ -z $BUILD_BY ]; then
    echo "W: BUILD_BY       : $BUILD_BY"
    BUILD_BY="jkim@perle.com"
fi

function log_error() {
    echo $C_BOLD$C_RED$1$C_DEF
}

function log_warning() {
    echo $C_BOLD$C_YELLOW$1$C_DEF
}

function log_notice() {
    echo $C_BOLD$C_CYAN$1$C_DEF
}

function Elapse_Time() {
    TITLE=$1
    START_TIME=$2
    END_TIME=$(date +%s)

    TIME_ELAPSE=$(($END_TIME-$START_TIME))
    echo "=== $TITLE ========="
    echo "I: START TIME      : $(date -d @$START_TIME)"
    echo "I: CURRENT TIME    : $(date -d @$END_TIME)"
    echo "I: ELAPSED TIME    : $(($TIME_ELAPSE / 86400 )) days $(($TIME_ELAPSE / 3600 )):$((($TIME_ELAPSE % 3600) / 60)):$(($TIME_ELAPSE % 60))"
    echo "========================================"
    TIME_START=$END_TIME
}

log_notice "+=================================================+"
log_notice "THIS SCRIPT SHOULD BE RUN$C_RED INSIDE$C_CYAN A DOCKER CONTAINER"
log_notice "+=================================================+"

if $READ_SUDO_PIN; then
    read -s -p "Enter Password for sudo: " SUDO_PIN
    if [ -z $SUDO_PIN ]; then
        SUDO_PIN="whatever"
        echo "W: Missing SUDO Password. Will use default PIN : $SUDO_PIN"
    fi
    #echo "SUDO_PIN = $SUDO_PIN"
fi

if [[ -z $1 ]]; then
    echo "E: Missing argument. ex> $0 <target platform>"
    echo "Current supported platforms are:"
    for i in "${PLATFORM[@]}";
    do
        echo "    $i"
    done
    echo ""
    exit 1
#    echo "Setting default target: ${PLATFORM[0]}"
#    TARGET=${PLATFORM[0]}
else
    TARGET=$1
fi

for i in "${PLATFORM[@]}";
do
    platform_err=1
    if [ ${TARGET} = "$i" ]; then
        platform_err=0
        break;
    fi
done
if [ "$platform_err" = 1 ]; then
    echo "error: Unexpected target platform (${TARGET})"
    echo "Current supported platforms are:"
    for i in "${PLATFORM[@]}";
    do
        echo "    $i"
    done
    echo ""
    exit 1
fi

echo "========================================"
echo "I: TARGET_PLATFORM  : $TARGET"
echo "I: BUILD_BY         : $BUILD_BY"
echo "I: VYOS_BUILD_DIR   : $VYOS_BUILD_DIR"
echo "I: VYOS_PACKAGE_DIR : $VYOS_PKG_DIR"
echo "I: PATCH_DIR        : $PATCH_DIR"
echo "I: START Building   : $(date)"
echo "========================================"

TIME_START=$(date +%s)
if [ ! -d $VYOS_BUILD_DIR ]; then
    echo ""
    echo "I: Clone VyOS build packages"
    git clone https://github.com/vyos/vyos-build.git -b current $VYOS_BUILD_DIR

    if true; then
        cp -a ${PATCH_DIR}/$VYOS_BUILD_DIR/updates/* ${CWD}/${VYOS_BUILD_DIR}/

        cd ${CWD}/${VYOS_BUILD_DIR}
        VYOS_BUILD_PATCH=$PATCH_DIR/$VYOS_BUILD_DIR/patches
        for patch in $(ls ${VYOS_BUILD_PATCH})
        do
            echo ""
            echo "I: Apply patch: ${VYOS_BUILD_PATCH}/${patch}"
            patch -p1 < ${VYOS_BUILD_PATCH}/${patch}
        done
    fi
    cp -rvf ${CWD}/packages/*.deb ${CWD}/${VYOS_BUILD_DIR}/packages | true
    Elapse_Time "$VYOS_BUILD_DIR set-up time" $TIME_START
fi

if true; then
    cd ${CWD}/${VYOS_BUILD_DIR}
    echo ""
    echo "I: Builing VyOS Packages"
    cp -a ${PATCH_DIR}/linux-kernel/${TARGET}/* ${CWD}/${VYOS_BUILD_DIR}/${VYOS_PKG_DIR}/linux-kernel
    for package in "${packages[@]}"
    do
        echo ""
        echo "I: Building package $package.."
        ./build-scripts-packages.sh < /dev/null $VYOS_PKG_DIR/$package
    done
    Elapse_Time "Package build time" $TIME_START
fi

if true; then
    cd ${CWD}/${VYOS_BUILD_DIR}
    echo ""
    echo "I: Creating VyOS Image"
    if $READ_SUDO_PIN; then
        sudo -S <<< $SUDO_PIN ./build-image.sh $BUILD_BY $PATCH_DIR
    else
        sudo ./build-image.sh $BUILD_BY $PATCH_DIR
    fi
    Elapse_Time "VyOS Image build time" $TIME_START
fi

if true; then
    host_arch=`uname -m`
    if [ "$host_arch" == "aarch64" ]; then
        cd ${CWD}
        echo ""
        echo "I: Build TI boot loader and file systems"
        ./ti-bsp-image.sh ${TARGET}
    fi
fi
