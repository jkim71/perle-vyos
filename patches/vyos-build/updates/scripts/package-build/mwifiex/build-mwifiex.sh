#!/bin/sh
CWD=$(dirname $(pwd))
LINUX_DIR=$(dirname ${CWD})/linux-kernel
PATCH_DIR=$(dirname $(dirname $(dirname $(dirname ${CWD}))))/patches
IMX_FIRMWARE_REPO="https://github.com/nxp-imx/imx-firmware.git"
# IMX_FIRMWARE_BRANCH="lf-6.6.3_1.0.0"
IMX_FIRMWARE_BRANCH=$1

MWIFIEX_SRC=${CWD}/mwifiex
if [ ! -d ${MWIFIEX_SRC} ]; then
    echo "MWIFIEX source not found"
    exit 1
fi

FIRMWARE_SRC=${MWIFIEX_SRC}/imx-firmware
if [ ! -d $FIRMWARE_SRC ]; then
    git clone ${IMX_FIRMWARE_REPO} -b ${IMX_FIRMWARE_BRANCH} ${FIRMWARE_SRC}
fi

cd ${MWIFIEX_SRC}/mxm_wifiex/wlan_src
echo "I: Build MWIFIEX driver"
make -C ${LINUX_DIR}/linux M=$PWD

echo "Patch DIR: ${PATCH_DIR}"
mkdir -p ${PATCH_DIR}/fs/lib/modules/nxp
echo "Copying *.ko files to ${PATCH_DIR}/fs/lib/modules/nxp/"
cp -rvf ${MWIFIEX_SRC}/mxm_wifiex/wlan_src/*.ko ${PATCH_DIR}/fs/lib/modules/nxp/

mkdir -p ${PATCH_DIR}/fs/lib/firmware/nxp
cp -rvf ${FIRMWARE_SRC}/nxp/FwImage_9098_PCIE/*.bin ${PATCH_DIR}/fs/lib/firmware/nxp/
cp -rvf ${FIRMWARE_SRC}/nxp/wifi_mod_para.conf ${PATCH_DIR}/fs/lib/firmware/nxp/
