#!/bin/bash
CWD=$(pwd)

set -e

# argument1 => target platform
if [[ -z $1 ]]; then
    echo "E: Missing 1st arguments. ex> $0 <target platform> <patch dir> <sudo password>"
    exit -1
else
    TARGET_NAME="$1"
fi

# argument1 => patches folder
if [[ -z $1 ]]; then
    echo "E: Missing 2nd arguments. ex> $0 <target platform> <patch dir> <sudo password>"
    exit -1
else
    PATCH_DIR="$2"
fi

if [[ -z $2 ]]; then
    echo "W: Missing 3rd arguments. ex> $0 <target platform> <patch dir> <sudo password>"
else
    SUDO_PIN="$3"
fi

TI_BDEB_PATCH=${PATCH_DIR}/ti_bdebstrap
if [ ! -d ${TI_BDEB_PATCH} ]; then
    echo "Patch directory ($TI_BDEB_PATCH) does not exists"
    exit -1
fi

SRC=ti-bdebstrap
if [ ! -d $SRC ]; then
    echo "I: Clone TI packages"
    git clone https://github.com/TexasInstruments/ti-bdebstrap.git $SRC
#    echo "I: switch to branch XXX"
#    git checkout XXX
    cd $SRC

    cp -a ${TI_BDEB_PATCH}/updates/* .

    PATCH_DIR=${TI_BDEB_PATCH}/patches
    for patch in $(ls ${PATCH_DIR})
    do
        echo "I: Apply patch: ${PATCH_DIR}/${patch}"
        patch -p1 < ${PATCH_DIR}/${patch}
    done
else
    cd $SRC
fi

echo "I: Building BSP image for \"${TARGET_NAME}\" and creating Package"
if [ -z $SUDO_PIN ]; then
    sudo ./build.sh ${TARGET_NAME}
else
    # echo "I: Sudo PIN: $SUDO_PIN"
    sudo -S <<< $SUDO_PIN ./build.sh ${TARGET_NAME}
fi
