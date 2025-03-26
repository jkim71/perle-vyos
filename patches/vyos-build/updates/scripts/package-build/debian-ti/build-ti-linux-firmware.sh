#!/bin/sh
CWD=$(dirname $(pwd))
PATCH_DIR=${CWD}/debian-repos/debian/patches
DEB_SUITE=$1

DEBIAN_REPOS_SRC=${CWD}/debian-repos
if [ ! -d ${DEBIAN_REPOS_SRC} ]; then
    echo "DEBIAN_REPOS source not found"
    exit 1
fi

cd ${DEBIAN_REPOS_SRC}
for patch in $(ls ${PATCH_DIR})
do
    echo ""
    echo "I: Apply patch: ${PATCH_DIR}/${patch}"
    patch -p1 < ${PATCH_DIR}/${patch}
done

echo "I: Build Debian-repos... (SUITS=${DEB_SUITE})"
sudo DEB_SUITE=${DEB_SUITE} ./run.sh ti-linux-firmware

echo "I: Copy deb files..."
cp -rvf build/${DEB_SUITE}/ti-linux-firmware/*j7200*.deb ..
cp -rvf build/${DEB_SUITE}/ti-linux-firmware/*64*.deb ..