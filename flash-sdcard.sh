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

TI_PATH=vyos-build/ti-bdebstrap

set -e

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

#if [ "$EUID" -ne 0 ] ; then
#    echo "Failed to run: requires root privileges"
#    echo "Exiting"
#    exit 1
#fi

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
#    TARGET_NAME=${PLATFORM[0]}
else
    TARGET_NAME=$1
fi

for i in "${PLATFORM[@]}";
do
    platform_err=1
    if [ ${TARGET_NAME} = "$i" ]; then
        platform_err=0
        break;
    fi
done
if [ "$platform_err" = 1 ]; then
    echo "error: Unexpected target platform (${TARGET_NAME})"
    echo "Current supported platforms are:"
    for i in "${PLATFORM[@]}";
    do
        echo "    $i"
    done
    echo ""
    exit 1
fi

log_notice "+==================================================+"
log_notice "THIS SCRIPT SHOULD BE RUN$C_RED OUTSIDE$C_CYAN A DOCKER CONTAINER"
log_notice "+==================================================+"

echo "========================================"
echo "I: TARGET_NAME      : $TARGET_NAME"
echo "I: TI_PATH          : $TI_PATH"
echo "I: START Flashing   : $(date)"
echo "========================================"

TIME_START=$(date +%s)
cd $CWD/$TI_PATH
sudo ./create-sdcard.sh $TARGET_NAME
Elapse_Time "BSP Image build time" $TIME_START
