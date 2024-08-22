#!/bin/bash

set -x
set -e
ROOTDIR=$(pwd)

# Clean out the build-repo and copy all custom packages
# rm -rf vyos-build
# git clone -b current --single-branch https://github.com/johnlfeeney/vyos-build
#git clone -b sagitta --single-branch https://github.com/johnlfeeney/vyos-build

# fixing up issue with iso for arm builds
# cp -rf iso.toml data/build-flavors/iso.toml

#if [ ! -f build/telegraf*.deb ]; then
	pushd packages/telegraf
# 1.28.3 from Jenkins File - does not exist prebuild as deb on arm so must build it
	git clone https://github.com/influxdata/telegraf.git -b v1.28.3 telegraf
	bash -x ./build.sh
	popd
	mkdir -p build
	cp -rf packages/telegraf/telegraf/build/dist/telegraf_1.28.3-1_arm64.deb build/
#fi

#if [ ! -f build/owamp*.deb ]; then
	pushd packages/owamp
# 4.4.6 from Jenkins File - does not exist prebuild as deb on arm so must build it
	git clone https://github.com/perfsonar/owamp -b v4.4.6 owamp
	bash -x ./build.sh
	popd
	mkdir -p build
	cp -rf packages/owamp/owamp-server_4.4.6-1_arm64.deb build/
	cp -rf packages/owamp/twamp-server_4.4.6-1_arm64.deb build/
	cp -rf packages/owamp/owamp-client_4.4.6-1_arm64.deb build/
	cp -rf packages/owamp/twamp-client_4.4.6-1_arm64.deb build/
#fi

for a in $(find build -type f -name "*.deb" | grep -v -e "-dbgsym_" -e "libnetfilter-conntrack3-dbg"); do
	echo "Copying package: $a"
	cp $a packages/
done


cd packages/strongswan
git clone https://salsa.debian.org/debian/strongswan.git -b debian/5.9.11-2 strongswan

# this patch is to solve a newer compiler error, it is fixed in newer versions of strongswan
# cp $ROOTDIR/swanctl.h strongswan/src/swanctl/swanctl.h

./build.sh
find $ROOTDIR/packages/strongswan/ -type f | grep '\.deb$' | xargs -I {} cp {} $ROOTDIR/packages/

cd strongswan
# dpkg-buildpackage -uc -us -tc -b
# dpkg-buildpackage -uc -us -b

# the following is to build a version of vici for debian, some is described in the vyos packages documentation but the following three lines generate needed files. Check if all are required
./configure --enable-python-eggs
cd src/libcharon/plugins/vici/python
make
python3 setup.py --command-packages=stdeb.command bdist_deb
cd $ROOTDIR/packages
cp -rf strongswan/strongswan/src/libcharon/plugins/vici/python/deb_dist/python3-vici_5.7.2-1_all.deb python3-vici_5.7.2-1_all.deb

cd $ROOTDIR/packages/frr
git clone https://github.com/CESNET/libyang.git -b v2.1.148
cd libyang
pipx run apkg build -i && find pkg/pkgs -type f -name *.deb -exec mv -t .. {} +
cd ..

cd $ROOTDIR/packages/frr
git clone https://github.com/rtrlib/rtrlib.git -b v0.8.0
cd rtrlib
sudo mk-build-deps --install --tool "apt-get --yes --no-install-recommends"; dpkg-buildpackage -uc -us -tc -b
cd ..

cd $ROOTDIR/packages/frr
git clone https://github.com/FRRouting/frr.git -b stable/9.1
cd frr
sudo dpkg -i ../*.deb; sudo mk-build-deps --install --tool "apt-get --yes --no-install-recommends"; cd ..; ./build-frr.sh

find $ROOTDIR/packages/frr/ -type f | grep '\.deb$' | xargs -I {} cp {} $ROOTDIR/packages/

cd $ROOTDIR/packages
git clone https://github.com/vyos/vyos-1x -b current
cd vyos-1x
dpkg-buildpackage -uc -us -tc -b

cd $ROOTDIR/packages
git clone https://github.com/vyos/vyos-user-utils.git -b current
cd vyos-user-utils
dpkg-buildpackage -uc -us -tc -b

cd $ROOTDIR/packages
git clone https://github.com/vyos/vyos-xe-guest-utilities.git -b current
cd vyos-xe-guest-utilities
dpkg-buildpackage -b -us -uc -tc
# rm -f mk/Makefile.deb

cd $ROOTDIR/packages
git clone https://github.com/vyos/libvyosconfig.git -b current
cd libvyosconfig
eval \$(opam env --root=/opt/opam --set-root) && dpkg-buildpackage -b -us -uc -tc

cd $ROOTDIR

#cp ${ROOTDIR}/defaults.toml data/defaults.toml

# Build the image
#VYOS_BUILD_FLAVOR=data/generic-arm64.json
#./configure
#make iso
#./build-vyos-image iso --architecture arm64 --build-by "jfeeney@perle.com" --debug
# ./build-vyos-image iso --architecture arm64 --build-by "jfeeney@perle.com"
sudo ./build-vyos-image generic --debug --architecture arm64 --build-by "jkim@perle.com" --build-type development
cd $ROOTDIR

# Check ISO file
LIVE_IMAGE_ISO=build/live-image-arm64.hybrid.iso

if [ ! -e ${LIVE_IMAGE_ISO} ]; then
  echo "File ${LIVE_IMAGE_ISO} not exists."
  exit -1
fi

ISOLOOP=$(sudo losetup --show -f ${LIVE_IMAGE_ISO})
echo "Mounting iso on loopback: ${ISOLOOP}"

sudo rm -rf build/tmp/
mkdir build/tmp/
sudo mount -o ro ${ISOLOOP} build/tmp/

sudo rm -rf build/fs
sudo unsquashfs -d build/fs build/tmp/live/filesystem.squashfs

#rm -rf build/fs/boot/grub
sudo mkdir build/fs/boot/dtb

sudo cp -R build/fs/usr/lib/linux-image*/ti build/fs/boot/dtb

#rm -rf build/fs/boot/Image
cat build/fs/boot/vmlinuz* | sudo sh -c 'gunzip -d > build/fs/boot/Image'

echo "Copy new default configuration to the vyos image"
sudo cp -rf ${ROOTDIR}/patches/etc/config.boot.default ${ROOTDIR}/build/fs/usr/share/vyos/config.boot.default

sudo umount -d build/tmp/
#losetup -d ${ISOLOOP}

# Build u-boot
#bash build-u-boot.sh

# Generate CM4 image from the iso
#DEVTREE="bcm2711-rpi-cm4" PIVERSION=4 bash build-pi-image.sh ${LIVE_IMAGE_ISO}

# Generate PI4 image from the iso
#DEVTREE="bcm2711-rpi-4-b" PIVERSION=4 bash build-pi-image.sh ${LIVE_IMAGE_ISO}

# Generate PI3B image from the iso
#DEVTREE="bcm2710-rpi-3-b" PIVERSION=3 bash build-pi-image.sh ${LIVE_IMAGE_ISO}

# Generate PI3B+ image from the iso
#DEVTREE="bcm2710-rpi-3-b-plus" PIVERSION=3 bash build-pi-image.sh ${LIVE_IMAGE_ISO}

# Symlink pi4 image
#ln -s vyos-build/build/live-image-arm64.hybrid.img live-image-arm64.hybrid.img
