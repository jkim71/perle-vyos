#!/bin/bash

source platform.sh

CWD=$(pwd)

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

host_arch=`uname -m`
log_notice "+==================================================+"
if [ "$host_arch" == "aarch64" ]; then
    log_notice "THIS SCRIPT SHOULD BE RUN$C_RED INSIDE$C_CYAN A DOCKER CONTAINER"
else
    log_notice "THIS SCRIPT SHOULD BE RUN$C_RED OUTSIDE$C_CYAN A DOCKER CONTAINER"
fi
log_notice "+==================================================+"

echo "========================================"
echo "I: TARGET           : $TARGET"
echo "I: VYOS_BUILD_DIR   : $VYOS_BUILD_DIR"
echo "I: PATCH_DIR        : $PATCH_DIR"
echo "I: START Building   : $(date)"
echo "========================================"

TIME_START=$(date +%s)
echo ""
echo "I: Building BSP Images"
cd $VYOS_BUILD_DIR
if $READ_SUDO_PIN; then
    ./build-ti-boot.sh $TARGET $PATCH_DIR $SUDO_PIN
else
    ./build-ti-boot.sh $TARGET $PATCH_DIR
fi
Elapse_Time "BSP Image build time" $TIME_START
