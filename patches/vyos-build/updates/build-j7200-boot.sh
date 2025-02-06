#!/bin/bash
CWD=$(pwd)

TARGET_NAME=bookworm-j7200-evm

set -e

# argument1 => patches folder
if [[ -z $1 ]]; then
    echo "E: Missing 1st arguments. ex> $0 <patch dir> <sudo password>"
    exit -1
else
    PATCH_DIR="$1"
fi

if [[ -z $2 ]]; then
    echo "W: Missing 2nd arguments. ex> $0 <patch dir> <sudo password>"
else
    SUDO_PIN="$2"
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

    for patch in $(ls ${TI_BDEB_PATCH})
    do
        echo "I: Apply patch: ${TI_BDEB_PATCH}/${patch}"
        patch -p1 < ${TI_BDEB_PATCH}/${patch}
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
