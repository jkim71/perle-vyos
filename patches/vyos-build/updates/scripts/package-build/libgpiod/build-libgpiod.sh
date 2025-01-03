#!/bin/sh
PKG_BUILD_DIR=$(dirname $(dirname $(pwd)))
VYOS_BUILD_DIR=$(dirname $(dirname ${PKG_BUILD_DIR}))
FS_DIR=${VYOS_BUILD_DIR}/build/fs

echo "I: FS_DIR = ${FS_DIR}"

echo "I: Executing autogen..."
./autogen.sh --enable-tools=yes --prefix=${FS_DIR}

echo "I: building..."
make

echo "I: Installing..."
sudo make install

echo "I: Done."