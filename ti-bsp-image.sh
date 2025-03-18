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

READ_SUDO_PIN=false

# BASE_DIR=$(dirname ${CWD})
VYOS_BUILD_DIR=vyos-build
PATCH_DIR=${CWD}/patches
set -e

#if [ "$EUID" -ne 0 ] ; then
#    echo "Failed to run: requires root privileges"
#    echo "Exiting"
#    exit -1
#fi

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

host_arch=`uname -m`
log_notice "+==================================================+"
if [ "$host_arch" == "aarch64" ]; then
    log_notice "THIS SCRIPT SHOULD BE RUN$C_RED INSIDE$C_CYAN A DOCKER CONTAINER"
else
    log_notice "THIS SCRIPT SHOULD BE RUN$C_RED OUTSIDE$C_CYAN A DOCKER CONTAINER"
fi
log_notice "+==================================================+"

if [[ -z $1 ]]; then
    echo "E: Missing 1st argument. ex> $0 <target platform>"
    exit -1
else
    TARGET_PLATFORM="$1"
fi

if $READ_SUDO_PIN; then
    RETRY=3
    while ((RETRY > 0));
    do
        read -s -p "Enter Password for sudo: " SUDO_PIN
        echo ""
        if sudo -S <<< $SUDO_PIN ls; then
#        if sudo -nv 2>&1 ; then
            echo "correct password: $SUDO_PIN"
            break;
        else
            echo "wrong password: $SUDO_PIN"
        fi
        ((RETRY--))
    done
    if ((RETRY == 0 )); then
        echo "Wrong Password..."
        exit 1
    fi
fi
if [ -z $SUDO_PIN ]; then
    SUDO_PIN="whatever"
    if $READ_SUDO_PIN; then
        echo "W: Missing SUDO Password. Will use default PIN : $SUDO_PIN"
    fi
fi

echo "========================================"
echo "I: TARGET_PLATFORM  : $TARGET_PLATFORM"
echo "I: VYOS_BUILD_DIR   : $VYOS_BUILD_DIR"
echo "I: PATCH_DIR        : $PATCH_DIR"
echo "I: START Building   : $(date)"
echo "========================================"

TIME_START=$(date +%s)
echo ""
echo "I: Building BSP Images"
cd $VYOS_BUILD_DIR
if $READ_SUDO_PIN; then
    ./build-ti-boot.sh $TARGET_PLATFORM $PATCH_DIR $SUDO_PIN
else
    ./build-ti-boot.sh $TARGET_PLATFORM $PATCH_DIR
fi
Elapse_Time "BSP Image build time" $TIME_START
