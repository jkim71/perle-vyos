#!/bin/bash

set -e
ROOTDIR=$(pwd)

# argument1 => Build-by
if [[ -z $1 ]]; then
    echo "Missing 1st arguments. ex> $0 <build-by> <patch dir>"
    exit -1
else
    BUILD_BY="$1"
fi
# argument2 => patches folder
if [[ -z $2 ]]; then
    echo "Missing 2nd arguments. ex> $0 <build-by> <patch dir>"
    exit -1
else
    PATCH_DIR="$2"
fi

./build-vyos-image generic --debug --architecture arm64 --build-by $BUILD_BY --build-type development
cd $ROOTDIR

# Check ISO file
LIVE_IMAGE_ISO=build/live-image-arm64.hybrid.iso

if [ ! -e ${LIVE_IMAGE_ISO} ]; then
  echo "File ${LIVE_IMAGE_ISO} not exists."
  exit -1
fi

ISOLOOP=$(losetup --show -f ${LIVE_IMAGE_ISO})
echo "Mounting iso on loopback: ${ISOLOOP}"

rm -rf build/tmp/
mkdir build/tmp/
mount -o ro ${ISOLOOP} build/tmp/

rm -rf build/fs
unsquashfs -d build/fs build/tmp/live/filesystem.squashfs

mkdir build/fs/boot/dtb
cp -R build/fs/usr/lib/linux-image*/ti build/fs/boot/dtb

cat build/fs/boot/vmlinuz* | sh -c 'gunzip -d > build/fs/boot/Image'

echo "Copy new default configuration to the vyos image"
cp -a ${PATCH_DIR}/fs/* ${ROOTDIR}/build/fs
#cp -Rf ${PATCH_DIR}/fs/* ${ROOTDIR}/build/fs/
#cp -rf ${PATCH_DIR}/fs/usr/share/vyos/config.boot.default ${ROOTDIR}/build/fs/usr/share/vyos/config.boot.default
#cp -rf ${PATCH_DIR}/fs/usr/libexec/vyos/conf_mode/system_console.py ${ROOTDIR}/build/fs/usr/libexec/vyos/conf_mode

umount -d build/tmp/
#losetup -d ${ISOLOOP}
