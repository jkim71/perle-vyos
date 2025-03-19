#!/bin/bash

source platform.sh

CWD=$(pwd)

TI_PATH=vyos-build/ti-bdebstrap

set -e

#if [ "$EUID" -ne 0 ] ; then
#    echo "Failed to run: requires root privileges"
#    echo "Exiting"
#    exit 1
#fi

log_notice "+==================================================+"
log_notice "THIS SCRIPT SHOULD BE RUN$C_RED OUTSIDE$C_CYAN A DOCKER CONTAINER"
log_notice "+==================================================+"

echo "========================================"
echo "I: TARGET           : $TARGET"
echo "I: TI_PATH          : $TI_PATH"
echo "I: START Flashing   : $(date)"
echo "========================================"

TIME_START=$(date +%s)
cd $CWD/$TI_PATH
sudo ./create-sdcard.sh $TARGET
Elapse_Time "BSP Image build time" $TIME_START
