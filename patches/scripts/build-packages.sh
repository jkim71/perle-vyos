#!/bin/bash
CWD=$(pwd)

set -e

SRC=packages
cd $SRC

./build_debs.sh dropbear
find dropbear -name '*.deb' -exec cp -d -t . {} +
./build_debs.sh podman
find podman -name '*.deb' -exec cp -d -t . {} +
./build_debs.sh pyhumps
find pyhumps -name '*.deb' -exec cp -d -t . {} +
./build_debs.sh radvd
find radvd -name '*.deb' -exec cp -d -t . {} +
./build_debs.sh strongswan
find strongswan -name '*.deb' -exec cp -d -t . {} +
./build_debs.sh telegraf
find telegraf -name '*.deb' -exec cp -d -t . {} +
