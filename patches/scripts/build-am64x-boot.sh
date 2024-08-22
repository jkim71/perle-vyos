#!/bin/bash
CWD=$(pwd)

TARGET_NAME=bookworm-am64xx-evm
PATCH_DIR=${CWD}/patches/ti_bdebstrap

set -e

if [ ! -d ${PATCH_DIR} ]; then
    echo "Patch directory does not exists"
    exit 1
fi

SRC=ti-bdebstrap
if [ ! -d $SRC ]; then
    echo "I: Clone TI packages"
    git clone https://github.com/TexasInstruments/ti-bdebstrap.git $SRC
#    echo "I: switch to branch XXX"
#    git checkout XXX
fi
cd $SRC

for patch in $(ls ${PATCH_DIR})
do
    echo "I: Apply patch: ${PATCH_DIR}/${patch}"
    patch -p1 < ${PATCH_DIR}/${patch}
done

echo "I: Builing BSP image for \"${TARGET_NAME}\" and creating Package"
sudo ./build.sh ${TARGET_NAME}
