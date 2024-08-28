#!/bin/bash
CWD=$(pwd)

# BASE_DIR=$(dirname ${CWD})
BUILD_BY=$(git config user.email)
VYOS_BUILD_DIR=vyos_build
PATCH_DIR=${CWD}/patches

set -e

if [ "$EUID" -ne 0 ] ; then
    echo "Failed to run: requires root privileges"
    echo "Exiting"
    exit -1
fi

echo "========================================"
echo "I: BUILD_BY       : $BUILD_BY"
echo "I: VYOS_BUILD_DIR : $VYOS_BUILD_DIR"
echo "I: PATCH_DIR      : $PATCH_DIR"
echo "========================================"

if [ ! -d $VYOS_BUILD_DIR ]; then
    echo "I: Clone VyOS build packages"
    git clone https://github.com/vyos/vyos-build.git -b current $VYOS_BUILD_DIR
fi

cd $VYOS_BUILD_DIR
VYOS_BUILD_PATCH=$PATCH_DIR/$VYOS_BUILD_DIR
for patch in $(ls ${VYOS_BUILD_PATCH})
do
    echo "I: Apply patch: ${VYOS_BUILD_PATCH}/${patch}"
    patch -p1 < ${VYOS_BUILD_PATCH}/${patch}
done

echo "I: Builing VyOS Packages"
cp ${PATCH_DIR}/configs/arch/arm64/ti_evm_vyos_defconfig ${CWD}/${VYOS_BUILD_DIR}/linux-kernel/arch/arm64/configs/vyos_defconfig
./build-packages.sh all

echo "I: Creating VyOS Image"
./build-image.sh $BUILD_BY $PATCH_DIR

echo "I: Building BSP Images"
./build-am64x-boot.sh $PATCH_DIR

echo "I: Finished!!!"
