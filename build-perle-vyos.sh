#!/bin/bash
CWD=$(pwd)

# BASE_DIR=$(dirname ${CWD})
BUILD_BY="$(git config user.email)"
VYOS_BUILD_DIR=vyos-build
VYOS_PKG_DIR=packages
PATCH_DIR=${CWD}/patches
set -e

packages=(
    "linux-kernel"
    "telegraf"
    "owamp"
    "frr"
    "strongswan"
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

# As we run this script in docker environment, we don't need sudo password
# read -s -p "Enter Password for sudo: " SUDO_PIN
SUDO_PIN="whatever"

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

echo ""
echo "I: Builing VyOS Packages"
cp ${PATCH_DIR}/configs/arch/arm64/ti_evm_vyos_defconfig ${CWD}/${VYOS_BUILD_DIR}/${VYOS_PKG_DIR}/linux-kernel/arch/arm64/configs/vyos_defconfig
for package in "${packages[@]}"
do
    echo ""
    echo "I: Building package $package.."
    ./build-packages.sh < /dev/null $VYOS_PKG_DIR/$package
done
Elapse_Time "Package build time" $TIME_START

echo ""
echo "I: Creating VyOS Image"
# As we run this script in docker environment, we don't need sudo password
#echo $SUDO_PIN | sudo ./build-image.sh $BUILD_BY $PATCH_DIR
sudo ./build-image.sh $BUILD_BY $PATCH_DIR
Elapse_Time "VyOS Image build time" $TIME_START

echo ""
echo "I: Building BSP Images"
./build-am64x-boot.sh $PATCH_DIR $SUDO_PIN
Elapse_Time "BSP Image build time" $TIME_START
