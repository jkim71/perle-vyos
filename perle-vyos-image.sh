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

# As we run this script in docker environment, we don't need sudo password
READ_SUDO_PIN=false

# BASE_DIR=$(dirname ${CWD})
BUILD_BY="$(git config user.email)"
VYOS_BUILD_DIR=vyos-build
VYOS_PKG_DIR=packages
PATCH_DIR=${CWD}/patches
set -e

packages=(
    "isc-dhcp"
    "frr"
    "linux-kernel"
    "owamp"
    "podman"
    "strongswan"
    "telegraf"
    "vyos"
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

function recursive_copy_file_folder() {
    local SRC=$1
    local DST=$2
    for FILE in `ls $SRC`
    do
        if [ -d $SRC/$FILE ]; then
            # echo "$FILE is a directory. Making $DST/$FILE"
            mkdir -p $DST/$FILE
            recursive_copy_file_folder $SRC/$FILE $DST/$FILE
        else
            # echo "$FILE is not a directory(file?). Copying to $DST/$FILE"
            # echo "  Copying $SRC/$FILE to $DST/$FILE"
            cp -av $SRC/$FILE $DST/$FILE
        fi
    done
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

echo "========================================"
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

    cd $VYOS_BUILD_DIR
    VYOS_BUILD_PATCH=$PATCH_DIR/$VYOS_BUILD_DIR
    for patch in $(ls ${VYOS_BUILD_PATCH})
    do
        echo ""
        echo "I: Apply patch: ${VYOS_BUILD_PATCH}/${patch}"
        patch -p1 < ${VYOS_BUILD_PATCH}/${patch}
    done
    Elapse_Time "$VYOS_BUILD_DIR set-up time" $TIME_START
else
    cd $VYOS_BUILD_DIR
fi

if true; then
    echo ""
    echo "I: Builing VyOS Packages"
    recursive_copy_file_folder ${PATCH_DIR}/linux-kernel/arch ${CWD}/${VYOS_BUILD_DIR}/${VYOS_PKG_DIR}/linux-kernel/arch 
    #cp ${PATCH_DIR}/configs/arch/arm64/ti_evm_vyos_defconfig ${CWD}/${VYOS_BUILD_DIR}/${VYOS_PKG_DIR}/linux-kernel/arch/arm64/configs/vyos_defconfig
    for package in "${packages[@]}"
    do
        echo ""
        echo "I: Building package $package.."
        ./build-packages.sh < /dev/null $VYOS_PKG_DIR/$package
    done
    Elapse_Time "Package build time" $TIME_START
fi

if true; then
    echo ""
    echo "I: Creating VyOS Image"
    if $READ_SUDO_PIN; then
        sudo -S <<< $SUDO_PIN ./build-image.sh $BUILD_BY $PATCH_DIR
    else
        sudo ./build-image.sh $BUILD_BY $PATCH_DIR
    fi
    Elapse_Time "VyOS Image build time" $TIME_START
fi
